#!/usr/bin/env bash

set -euo pipefail

host_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$host_dir/../.." && pwd)
packages=()
copr_repos=(
  errornointernet/quickshell
  @xlibre/xlibre-xserver
  lxdes/xcolor
  wezfurlong/wezterm-nightly
)

while IFS= read -r package; do
  [[ -z "$package" || "$package" == \#* ]] && continue
  packages+=("$package")
done < "$host_dir/packages.txt"

sudo dnf install -y dnf-plugins-core
for repo in "${copr_repos[@]}"; do
  sudo dnf copr enable -y "$repo"
done

if ((${#packages[@]})); then
  sudo dnf install "${packages[@]}"
fi

sudo systemctl enable --now nix-daemon.service
sudo systemctl enable --now qemu-guest-agent.service

mkdir -p "$HOME/.config/nix"
touch "$HOME/.config/nix/nix.conf"
if ! grep -qxF 'experimental-features = nix-command flakes' "$HOME/.config/nix/nix.conf"; then
  printf '%s\n' 'experimental-features = nix-command flakes' >> "$HOME/.config/nix/nix.conf"
fi

nix run github:nix-community/home-manager -- switch --flake "$repo_root#vm"
