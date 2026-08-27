import importlib.util
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import datetime, timezone
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).parents[1] / "scripts" / "agenda.py"
SPEC = importlib.util.spec_from_file_location("quickshell_agenda", SCRIPT)
agenda = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = agenda
SPEC.loader.exec_module(agenda)


def calendar(*events):
    return (
        "BEGIN:VCALENDAR\r\n"
        "VERSION:2.0\r\n"
        "PRODID:-//quickshell tests//EN\r\n"
        + "".join(events)
        + "END:VCALENDAR\r\n"
    ).encode()


def event(*lines):
    return "BEGIN:VEVENT\r\n" + "\r\n".join(lines) + "\r\nEND:VEVENT\r\n"


NOW = datetime(2026, 8, 27, 12, 0, tzinfo=timezone.utc)


class AgendaTests(unittest.TestCase):
    def test_unconfigured_does_not_fetch_or_parse(self):
        with tempfile.TemporaryDirectory() as directory:
            missing_url = Path(directory) / "missing-calendar-url"
            output = io.StringIO()
            with (
                mock.patch.object(agenda, "URL_FILE", missing_url),
                mock.patch.object(agenda, "fetch_calendar") as fetch,
                mock.patch.object(agenda, "parse_events") as parse,
                redirect_stdout(output),
            ):
                agenda.main()

        self.assertEqual(
            json.loads(output.getvalue()),
            {
                "configured": False,
                "error": None,
                "events": [],
                "cacheAgeSeconds": None,
                "cacheStale": False,
            },
        )
        fetch.assert_not_called()
        parse.assert_not_called()

    def test_single_timed_event(self):
        data = calendar(
            event(
                "UID:timed",
                "DTSTART:20260827T143000Z",
                "DTEND:20260827T153000Z",
                "SUMMARY:Planning",
                "LOCATION:Room 4",
            )
        )

        self.assertEqual(
            agenda.parse_events(data, now=NOW),
            [
                {
                    "start": "2026-08-27T14:30:00+00:00",
                    "localDisplay": "Today, 2:30 PM",
                    "dateLabel": "Today",
                    "timeLabel": "2:30 PM",
                    "summary": "Planning",
                    "location": "Room 4",
                }
            ],
        )

    def test_all_day_event(self):
        data = calendar(
            event(
                "UID:all-day",
                "DTSTART;VALUE=DATE:20260828",
                "DTEND;VALUE=DATE:20260829",
                "SUMMARY:Holiday",
            )
        )

        result = agenda.parse_events(data, now=NOW)

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["start"], "2026-08-28T00:00:00+00:00")
        self.assertEqual(result[0]["localDisplay"], "Tomorrow")
        self.assertEqual(result[0]["timeLabel"], "All day")

    def test_recurrence_honors_exclusion(self):
        data = calendar(
            event(
                "UID:standup",
                "DTSTART:20260827T130000Z",
                "DTEND:20260827T133000Z",
                "RRULE:FREQ=DAILY;COUNT=3",
                "EXDATE:20260828T130000Z",
                "SUMMARY:Standup",
            )
        )

        result = agenda.parse_events(data, now=NOW)

        self.assertEqual(
            [item["start"] for item in result],
            ["2026-08-27T13:00:00+00:00", "2026-08-29T13:00:00+00:00"],
        )

    def test_malformed_event_does_not_hide_valid_event(self):
        data = calendar(
            event("UID:missing-start", "SUMMARY:Broken"),
            event(
                "UID:valid",
                "DTSTART:20260827T160000Z",
                "SUMMARY:Still visible",
            ),
        )

        result = agenda.parse_events(data, now=NOW)

        self.assertEqual([item["summary"] for item in result], ["Still visible"])

    def test_ongoing_event_is_included(self):
        data = calendar(
            event(
                "UID:ongoing",
                "DTSTART:20260827T110000Z",
                "DTEND:20260827T123000Z",
                "SUMMARY:In progress",
            )
        )

        result = agenda.parse_events(data, now=NOW)

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["summary"], "In progress")

    def test_injected_aware_now_does_not_consult_system_timezone(self):
        data = calendar(
            event(
                "UID:injected-now",
                "DTSTART:20260828T090000Z",
                "SUMMARY:Deterministic",
            )
        )

        with mock.patch.object(
            agenda, "system_timezone", side_effect=AssertionError("host timezone used")
        ):
            result = agenda.parse_events(data, now=NOW)

        self.assertEqual(result[0]["dateLabel"], "Tomorrow")

    def test_parse_error_is_reported_without_leaking_exception_details(self):
        with tempfile.TemporaryDirectory() as directory:
            url_file = Path(directory) / "calendar-url"
            url_file.write_text("https://example.invalid/calendar.ics")
            output = io.StringIO()
            with (
                mock.patch.object(agenda, "URL_FILE", url_file),
                mock.patch.object(
                    agenda,
                    "fetch_calendar",
                    return_value=(b"not an icalendar", None, 12, False),
                ),
                redirect_stdout(output),
            ):
                agenda.main()

        result = json.loads(output.getvalue())
        self.assertTrue(result["configured"])
        self.assertEqual(result["error"], "Unable to parse calendar")
        self.assertEqual(result["events"], [])
        self.assertEqual(result["cacheAgeSeconds"], 12)


if __name__ == "__main__":
    unittest.main()
