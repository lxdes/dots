#!/usr/bin/env sh

cpu=null
memory=null
temperature=null
gpu=null
power_profile=unknown

if [ -r /proc/stat ]; then
	set -- $(awk 'NR == 1 { idle=$5+$6; total=0; for (i=2; i<=NF; i++) total+=$i; print idle, total; exit }' /proc/stat)
	idle_before=$1
	total_before=$2
	sleep 0.15
	set -- $(awk 'NR == 1 { idle=$5+$6; total=0; for (i=2; i<=NF; i++) total+=$i; print idle, total; exit }' /proc/stat)
	idle_delta=$(( $1 - idle_before ))
	total_delta=$(( $2 - total_before ))
	if [ "$total_delta" -gt 0 ]; then
		cpu=$(awk -v idle="$idle_delta" -v total="$total_delta" 'BEGIN { printf "%.1f", 100 * (total - idle) / total }')
	fi
fi

if [ -r /proc/meminfo ]; then
	memory=$(awk '
		/^MemTotal:/ { total=$2 }
		/^MemAvailable:/ { available=$2 }
		END { if (total > 0) printf "%.1f", 100 * (total - available) / total }
	' /proc/meminfo)
	[ -n "$memory" ] || memory=null
fi

for sensor in /sys/class/hwmon/hwmon*/temp*_input; do
	[ -r "$sensor" ] || continue
	value=$(awk 'NR == 1 && $1 >= 0 && $1 <= 150000 { printf "%.1f", $1 / 1000 }' "$sensor")
	[ -n "$value" ] || continue
	temperature=$(awk -v current="$temperature" -v value="$value" 'BEGIN { if (current == "null" || value > current) print value; else print current }')
done

for busy in /sys/class/drm/card*/device/gpu_busy_percent; do
	[ -r "$busy" ] || continue
	value=$(awk 'NR == 1 && $1 >= 0 && $1 <= 100 { print $1 }' "$busy")
	[ -n "$value" ] || continue
	gpu=$(awk -v current="$gpu" -v value="$value" 'BEGIN { if (current == "null" || value > current) print value; else print current }')
done

if command -v nvidia-smi >/dev/null 2>&1; then
	value=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | awk '$1 >= 0 && $1 <= 100 { if ($1 > max) max=$1; found=1 } END { if (found) print max }')
	if [ -n "$value" ]; then
		gpu=$(awk -v current="$gpu" -v value="$value" 'BEGIN { if (current == "null" || value > current) print value; else print current }')
	fi
fi

if [ -r /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference ]; then
	preference=$(awk 'NR == 1 { print; exit }' /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference)
	case "$preference" in
		performance) power_profile=performance ;;
		power) power_profile=power-saver ;;
		*) power_profile=balanced ;;
	esac
fi

printf '{"cpuPercent":%s,"memoryPercent":%s,"temperatureC":%s,"gpuPercent":%s,"powerProfile":"%s"}\n' \
	"$cpu" "$memory" "$temperature" "$gpu" "$power_profile"
