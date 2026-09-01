#!/usr/bin/env bash

set -euo pipefail

host_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$host_dir/../.." && pwd)
packages=()
copr_repos=(
	errornointernet/quickshell
	@xlibre/xlibre-xserver
	lxdes/xcolor
	lxdes/i3lock-color
	lxdes/betterlockscreen
	wezfurlong/wezterm-nightly
)

for manifest in "$repo_root/hosts/base.txt" "$host_dir/packages.txt"; do
	while IFS= read -r package; do
		[[ -z "$package" || "$package" == \#* ]] && continue
		packages+=("$package")
	done <"$manifest"
done

sudo dnf install -y dnf-plugins-core
for repo in "${copr_repos[@]}"; do
	sudo dnf copr enable -y "$repo"
done
sudo dnf config-manager addrepo --overwrite \
	--from-repofile=https://repo.librewolf.net/librewolf.repo

if ((${#packages[@]})); then
	sudo dnf install "${packages[@]}"
fi

sudo dnf install -y --allowerasing \
	xlibre-xserver \
	xlibre-xf86-input-libinput

if [[ -f /etc/vconsole.conf ]]; then
	sudo sed -i '/^FONT=/d' /etc/vconsole.conf
	echo 'FONT="ter-v32n"' | sudo tee -a /etc/vconsole.conf >/dev/null
else
	echo 'FONT="ter-v32n"' | sudo tee /etc/vconsole.conf >/dev/null
fi
sudo setfont ter-v32n 2>/dev/null || true

sudo chsh -s /usr/bin/zsh "$USER"
sudo systemctl enable --now nix-daemon.service
sudo systemctl enable --now tailscaled.service
sudo tailscale set --operator="$USER" || true

mkdir -p "$HOME/.config/nix"
touch "$HOME/.config/nix/nix.conf"
if ! grep -qxF 'experimental-features = nix-command flakes' "$HOME/.config/nix/nix.conf"; then
	printf '%s\n' 'experimental-features = nix-command flakes' >>"$HOME/.config/nix/nix.conf"
fi

nix run github:nix-community/home-manager -- switch --flake "$repo_root#thinkfor"

if [[ ! -d "$HOME/.config/emacs/.git" ]]; then
	git clone --depth 1 https://github.com/doomemacs/core "$HOME/.config/emacs"
fi
"$HOME/.config/emacs/bin/doom" install
