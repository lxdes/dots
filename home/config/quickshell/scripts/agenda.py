#!/usr/bin/env python3

import json
import os
import tempfile
import urllib.request
from datetime import date, datetime, time, timedelta
from pathlib import Path
from urllib.parse import urlsplit
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

try:
    from dateutil.rrule import rruleset, rrulestr
    from icalendar import Calendar
except ImportError:
    print(
        '{"configured":false,"error":"Calendar dependencies unavailable",'
        '"events":[],"cacheAgeSeconds":null,"cacheStale":false}'
    )
    raise SystemExit(0)


URL_FILE = Path.home() / ".config" / "proton-calendar-url"
CACHE_DIR = Path.home() / ".cache" / "quickshell"
CACHE_FILE = CACHE_DIR / "agenda.ics"
CACHE_SECONDS = 15 * 60
MAX_RESPONSE_BYTES = 10 * 1024 * 1024
WINDOW_DAYS = 14


def output(configured, error=None, events=None, cache_age=None, cache_stale=False):
    print(
        json.dumps(
            {
                "configured": configured,
                "error": error,
                "events": events or [],
                "cacheAgeSeconds": cache_age,
                "cacheStale": cache_stale,
            },
            separators=(",", ":"),
        )
    )


def cache_age(now=None):
    try:
        age = (now or datetime.now().timestamp()) - CACHE_FILE.stat().st_mtime
        return max(0, int(age))
    except OSError:
        return None


def read_cache():
    with CACHE_FILE.open("rb") as cache:
        data = cache.read(MAX_RESPONSE_BYTES + 1)
    if len(data) > MAX_RESPONSE_BYTES:
        raise ValueError("Cached calendar is too large")
    return data


def valid_calendar_url(url):
    try:
        return urlsplit(url).scheme.lower() in {"http", "https"}
    except ValueError:
        return False


def fetch_calendar(url):
    if not valid_calendar_url(url):
        return None, "Calendar URL must use http or https", None, False
    CACHE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    age = cache_age()
    fresh = age is not None and age < CACHE_SECONDS

    if fresh:
        try:
            return read_cache(), None, age, False
        except (OSError, ValueError):
            pass

    temporary_name = None
    try:
        request = urllib.request.Request(url, headers={"User-Agent": "quickshell-agenda/1"})
        with urllib.request.urlopen(request, timeout=15) as response:
            if urlsplit(response.geturl()).scheme.lower() not in {"http", "https"}:
                raise ValueError("Calendar redirect used an unsupported URL scheme")
            content_length = response.headers.get("Content-Length")
            if content_length is not None and int(content_length) > MAX_RESPONSE_BYTES:
                raise ValueError("Calendar response is too large")
            data = response.read(MAX_RESPONSE_BYTES + 1)
            if len(data) > MAX_RESPONSE_BYTES:
                raise ValueError("Calendar response is too large")
        with tempfile.NamedTemporaryFile(dir=CACHE_DIR, delete=False) as temporary:
            temporary_name = temporary.name
            temporary.write(data)
        os.chmod(temporary_name, 0o600)
        os.replace(temporary_name, CACHE_FILE)
        temporary_name = None
        return data, None, 0, False
    except Exception:
        try:
            age = cache_age()
            return (
                read_cache(),
                "Calendar refresh failed; showing cached events",
                age,
                age is None or age >= CACHE_SECONDS,
            )
        except (OSError, ValueError):
            return None, "Unable to fetch calendar", None, False
    finally:
        if temporary_name is not None:
            try:
                Path(temporary_name).unlink()
            except OSError:
                pass


def system_timezone():
    zone_name = os.environ.get("TZ", "").lstrip(":")
    if zone_name:
        try:
            return ZoneInfo(zone_name)
        except (ValueError, ZoneInfoNotFoundError):
            pass

    try:
        zone_path = Path("/etc/localtime").resolve()
        marker = "/zoneinfo/"
        if marker in str(zone_path):
            return ZoneInfo(str(zone_path).split(marker, 1)[1])
    except (OSError, ValueError, ZoneInfoNotFoundError):
        pass
    return datetime.now().astimezone().tzinfo


def as_local_datetime(value, local_tz):
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=local_tz)
        return value.astimezone(local_tz), False
    if isinstance(value, date):
        return datetime.combine(value, time.min, tzinfo=local_tz), True
    raise TypeError("Unsupported calendar date")


def property_dates(component, name, local_tz):
    properties = component.get(name)
    if properties is None:
        return []
    if not isinstance(properties, list):
        properties = [properties]

    values = []
    for prop in properties:
        entries = getattr(prop, "dts", [prop])
        for entry in entries:
            value = getattr(entry, "dt", entry)
            try:
                values.append(as_local_datetime(value, local_tz)[0])
            except TypeError:
                pass
    return values


def recurrence_key(uid, value, local_tz):
    start, _ = as_local_datetime(value, local_tz)
    return uid, start.isoformat()


def event_duration(component, start, all_day, local_tz):
    end_property = component.get("dtend")
    if end_property is not None:
        end, _ = as_local_datetime(end_property.dt, local_tz)
        return max(end - start, timedelta(0))
    duration_property = component.get("duration")
    if duration_property is not None:
        duration = duration_property.dt
        if isinstance(duration, timedelta):
            return max(duration, timedelta(0))
    return timedelta(days=1) if all_day else timedelta(0)


def event_in_window(start, duration, all_day, now, day_start, window_end):
    range_start = day_start if all_day else now
    end = start + duration
    return start < window_end and (end > range_start or start >= range_start)


def labels(start, all_day, today):
    event_date = start.date()
    if event_date == today:
        date_label = "Today"
    elif event_date == today + timedelta(days=1):
        date_label = "Tomorrow"
    else:
        date_label = start.strftime("%a, %b %d").replace(" 0", " ")

    time_label = "All day" if all_day else start.strftime("%I:%M %p").lstrip("0")
    local_display = date_label if all_day else f"{date_label}, {time_label}"
    return date_label, time_label, local_display


def event_json(component, start, all_day, today):
    date_label, time_label, local_display = labels(start, all_day, today)
    return {
        "start": start.isoformat(),
        "localDisplay": local_display,
        "dateLabel": date_label,
        "timeLabel": time_label,
        "summary": str(component.get("summary", "Untitled event")),
        "location": str(component.get("location", "")),
    }


def parse_events(data, now=None):
    calendar = Calendar.from_ical(data)
    if now is None:
        local_tz = system_timezone()
        now = datetime.now(local_tz)
    else:
        local_tz = now.tzinfo or system_timezone()
        now = now.replace(tzinfo=local_tz) if now.tzinfo is None else now.astimezone(local_tz)
    day_start = datetime.combine(now.date(), time.min, tzinfo=local_tz)
    window_end = now + timedelta(days=WINDOW_DAYS)
    today = now.date()
    components = [item for item in calendar.walk("VEVENT")]

    overrides = {}
    for component in components:
        try:
            recurrence_id = component.get("recurrence-id")
            if recurrence_id is not None:
                uid = str(component.get("uid", ""))
                overrides[recurrence_key(uid, recurrence_id.dt, local_tz)] = component
        except (AttributeError, TypeError, ValueError):
            continue

    events = []
    for component in components:
        try:
            if str(component.get("status", "")).upper() == "CANCELLED":
                continue
            start, all_day = as_local_datetime(component.decoded("dtstart"), local_tz)
            duration = event_duration(component, start, all_day, local_tz)
            if component.get("recurrence-id") is not None:
                if event_in_window(start, duration, all_day, now, day_start, window_end):
                    events.append(event_json(component, start, all_day, today))
                continue

            recurrence = component.get("rrule")
            rdates = property_dates(component, "rdate", local_tz)
            if recurrence is None and not rdates:
                if event_in_window(start, duration, all_day, now, day_start, window_end):
                    events.append(event_json(component, start, all_day, today))
                continue

            occurrences = rruleset()
            if recurrence is not None:
                rule = recurrence.to_ical().decode("utf-8")
                occurrences.rrule(rrulestr(rule, dtstart=start))
            else:
                occurrences.rdate(start)
            for rdate in rdates:
                occurrences.rdate(rdate)
            for exdate in property_dates(component, "exdate", local_tz):
                occurrences.exdate(exdate)

            uid = str(component.get("uid", ""))
            range_start = day_start if all_day else now
            search_start = range_start - duration
            for occurrence in occurrences.between(search_start, window_end, inc=True):
                occurrence, _ = as_local_datetime(occurrence, local_tz)
                if (uid, occurrence.isoformat()) in overrides:
                    continue
                if event_in_window(
                    occurrence, duration, all_day, now, day_start, window_end
                ):
                    events.append(event_json(component, occurrence, all_day, today))
        except (AttributeError, KeyError, TypeError, ValueError, OverflowError):
            # A malformed VEVENT should not hide otherwise valid calendar entries.
            continue

    events.sort(key=lambda event: event["start"])
    return events


def main():
    try:
        url = URL_FILE.read_text(encoding="utf-8").strip()
    except OSError:
        output(False)
        return
    if not url:
        output(False)
        return
    if not valid_calendar_url(url):
        output(True, "Calendar URL must use http or https")
        return

    data, refresh_error, age, stale = fetch_calendar(url)
    if data is None:
        output(True, refresh_error, cache_age=age, cache_stale=stale)
        return
    try:
        events = parse_events(data)
    except Exception:
        output(True, "Unable to parse calendar", cache_age=age, cache_stale=stale)
        return
    output(True, refresh_error, events, age, stale)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        output(True, "Unable to load calendar")
