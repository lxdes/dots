#!/usr/bin/env sh

cpu=null
memory=null
temperature=null
gpu=null
power_profile=unknown
: "${PROC_ROOT:=/proc}"
: "${SYS_ROOT:=/sys}"

if [ -r "$PROC_ROOT/stat" ]; then
	idle_before=$(awk 'NR == 1 { print $5+$6 }' "$PROC_ROOT/stat")
	total_before=$(awk 'NR == 1 { total=0; for (i=2; i<=NF; i++) total+=$i; print total }' "$PROC_ROOT/stat")
	sleep 0.10
	idle_after=$(awk 'NR == 1 { print $5+$6 }' "$PROC_ROOT/stat")
	total_after=$(awk 'NR == 1 { total=0; for (i=2; i<=NF; i++) total+=$i; print total }' "$PROC_ROOT/stat")
	idle_delta=$((idle_after - idle_before))
	total_delta=$((total_after - total_before))
	if [ "$total_delta" -gt 0 ]; then
		cpu=$(awk -v idle="$idle_delta" -v total="$total_delta" 'BEGIN { printf "%.1f", 100 * (total - idle) / total }')
	fi
fi

if [ -r "$PROC_ROOT/meminfo" ]; then
	memory=$(awk '
		/^MemTotal:/ { total=$2 }
		/^MemAvailable:/ { available=$2 }
		END { if (total > 0) printf "%.1f", 100 * (total - available) / total }
	' "$PROC_ROOT/meminfo")
	[ -n "$memory" ] || memory=null
fi

temperature_priority=999
for sensor in "$SYS_ROOT"/class/hwmon/hwmon*/temp*_input; do
	[ -r "$sensor" ] || continue
	read -r raw < "$sensor" 2>/dev/null || continue
	case "$raw" in
		''|*[!0-9]*) continue ;;
	esac
	if [ "$raw" -lt 0 ] || [ "$raw" -gt 150000 ]; then
		continue
	fi
	value=$(awk -v raw="$raw" 'BEGIN { printf "%.1f", raw / 1000 }')
	[ -n "$value" ] || continue
	label_file=${sensor%_input}_label
	label=
	[ ! -r "$label_file" ] || read -r label < "$label_file" 2>/dev/null
	hwmon_dir=${sensor%/*}
	driver=
	[ ! -r "$hwmon_dir/name" ] || read -r driver < "$hwmon_dir/name" 2>/dev/null
	case "$label" in
		"Package id 0"|Tctl|CPU) priority=1 ;;
		Tdie|Package*|Physical*) priority=2 ;;
		Core*) priority=3 ;;
		*)
			case "$driver" in
				coretemp|k10temp|zenpower|cpu_thermal) priority=4 ;;
				*) priority=100 ;;
			esac
		;;
	esac
	if [ "$priority" -lt "$temperature_priority" ]; then
		temperature=$value
		temperature_priority=$priority
	elif [ "$priority" -eq "$temperature_priority" ]; then
		temperature=$(awk -v current="$temperature" -v value="$value" 'BEGIN { if (value > current) print value; else print current }')
	fi
done

for busy in "$SYS_ROOT"/class/drm/card*/device/gpu_busy_percent; do
	[ -r "$busy" ] || continue
	read -r raw_gpu < "$busy" 2>/dev/null || continue
	case "$raw_gpu" in
		''|*[!0-9]*) continue ;;
	esac
	if [ "$raw_gpu" -ge 0 ] && [ "$raw_gpu" -le 100 ]; then
		if [ "$gpu" = "null" ] || [ -z "$gpu" ] || [ "$raw_gpu" -gt "$gpu" ]; then
			gpu=$raw_gpu
		fi
	fi
done

if command -v nvidia-smi >/dev/null 2>&1; then
	value=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | awk '$1 >= 0 && $1 <= 100 { if ($1 > max) max=$1; found=1 } END { if (found) print max }')
	if [ -n "$value" ]; then
		if [ "$gpu" = "null" ] || [ -z "$gpu" ] || [ "$value" -gt "$gpu" ] 2>/dev/null; then
			gpu=$value
		fi
	fi
fi

preference_file="$SYS_ROOT/devices/system/cpu/cpufreq/policy0/energy_performance_preference"
if [ -r "$preference_file" ]; then
	preference=$(awk 'NR == 1 { print; exit }' "$preference_file")
	case "$preference" in
		performance) power_profile=performance ;;
		power) power_profile=power-saver ;;
		*) power_profile=balanced ;;
	esac
fi

printf '{"cpuPercent":%s,"memoryPercent":%s,"temperatureC":%s,"gpuPercent":%s,"powerProfile":"%s"}\n' \
	"$cpu" "$memory" "$temperature" "$gpu" "$power_profile"
