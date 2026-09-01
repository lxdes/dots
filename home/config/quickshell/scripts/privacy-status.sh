#!/usr/bin/env sh

microphone=false
microphone_corked=false
recording=false
screen_share=false

if command -v pactl >/dev/null 2>&1; then
	if source_outputs=$(LC_ALL=C pactl list source-outputs 2>/dev/null); then
		output_state=$(printf '%s\n' "$source_outputs" | awk '
			/^Source Output #[0-9]+/ { outputs++; next }
			/^[[:space:]]*Corked:/ {
				known++
				if ($2 == "no") active=1
				if ($2 == "yes") corked=1
			}
			END {
				if (outputs == known) printf "%d %d known", active, corked
				else print "0 0 unknown"
			}
		')
		case "$output_state" in
			"1 0 known"|"1 1 known") microphone=true ;;
		esac
		case "$output_state" in
			"0 1 known"|"1 1 known") microphone_corked=true ;;
		esac
	fi

	# Older/localized pactl output may lack Corked; only then retain the old heuristic.
	case "${output_state-unknown}" in
		*unknown)
			if [ -n "$(pactl list short source-outputs 2>/dev/null)" ]; then
				microphone=true
			fi
			;;
	esac
fi

if command -v pgrep >/dev/null 2>&1; then
	if pgrep -x "obs|obs-studio|ffmpeg|avconv|arecord|parec|pw-record|kooha|vokoscreenNG|simplescreenrecorder" >/dev/null 2>&1; then
		recording=true
	else
		for process in obs obs-studio ffmpeg avconv arecord parec pw-record kooha vokoscreenNG simplescreenrecorder; do
			if pgrep -x "$process" >/dev/null 2>&1; then
				recording=true
				break
			fi
		done
	fi
fi

if command -v pw-dump >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
	if pw-dump 2>/dev/null | jq -e '
		any(.[]?;
			(.info.props? // {}) as $props
			| [
				$props["node.name"],
				$props["media.name"],
				$props["application.name"],
				$props["media.role"]
			  ]
			| map(select(type == "string"))
			| join(" ")
			| test("webrtc|screen[ -]?(share|cast|capture)|screencast"; "i")
		)
	' >/dev/null 2>&1; then
		screen_share=true
	fi
fi

printf '{"microphoneActive":%s,"recordingProcess":%s,"screenShareActive":%s,"microphoneCorked":%s}\n' \
	"$microphone" "$recording" "$screen_share" "$microphone_corked"
