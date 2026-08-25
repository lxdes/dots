#!/usr/bin/env sh

microphone=false
recording=false
screen_share=false

if command -v pactl >/dev/null 2>&1 && [ -n "$(pactl list short source-outputs 2>/dev/null)" ]; then
	microphone=true
fi

for process in obs obs-studio ffmpeg avconv arecord parec pw-record kooha vokoscreenNG simplescreenrecorder; do
	if command -v pgrep >/dev/null 2>&1 && pgrep -x "$process" >/dev/null 2>&1; then
		recording=true
		break
	fi
done

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

printf '{"microphoneActive":%s,"recordingProcess":%s,"screenShareActive":%s}\n' \
	"$microphone" "$recording" "$screen_share"
