#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly REPO_URL="${NUX_REPO_URL:-https://codeberg.org/lxde/dots.git}"
readonly VM_CURATOR_VERSION="${VM_CURATOR_VERSION:-1.4.0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
USER_NAME="${SUDO_USER:-${USER}}"
readonly USER_NAME
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
readonly USER_HOME

SKIP_DOOM=0
REPO_DIR="$SCRIPT_DIR"

log() {
    printf '\n==> %s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Install the nux bspwm + Quickshell desktop on Fedora minimal.

Options:
  --skip-doom       Do not clone or install Doom Emacs.
  --repo DIR        Use an existing nux checkout.
  -h, --help        Show this help.

The script must be run as the normal desktop user, not with sudo.
EOF
}

run_as_user() {
    if [[ "$(id -un)" == "$USER_NAME" ]]; then
        "$@"
    else
        sudo -u "$USER_NAME" -H "$@"
    fi
}

parse_args() {
    while (($#)); do
        case "$1" in
            --skip-doom)
                SKIP_DOOM=1
                ;;
            --repo)
                (($# >= 2)) || die "--repo requires a directory"
                REPO_DIR="$2"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "unknown option: $1"
                ;;
        esac
        shift
    done
}

check_prerequisites() {
    [[ "$(id -u)" -ne 0 ]] || die "run this script as your normal user; it uses sudo when needed"
    [[ -n "$USER_NAME" ]] || die "could not determine the desktop user"
    id "$USER_NAME" >/dev/null 2>&1 || die "user does not exist: $USER_NAME"
    command -v sudo >/dev/null || die "sudo is required"
    command -v dnf >/dev/null || die "this installer requires Fedora's dnf"
    [[ -f /etc/fedora-release ]] || die "this installer only supports Fedora"
}

install_repositories() {
    log "Enabling Fedora COPRs and Terra"
    sudo dnf install -y dnf-plugins-core

    local copr configured
    for copr in errornointernet/quickshell @xlibre/xlibre-xserver lxdes/xcolor wezfurlong/wezterm-nightly; do
        configured="$(sudo dnf copr list 2>/dev/null || true)"
        if [[ $configured == *"copr.fedorainfracloud.org/$copr"* ]]; then
            log "COPR already enabled: $copr"
        else
            sudo dnf copr enable -y "$copr"
        fi
    done

    local enabled_repositories
    enabled_repositories="$(sudo dnf repolist --enabled 2>/dev/null || true)"
    if [[ $enabled_repositories == *$'\nterra '* || $enabled_repositories == terra\ * ]]; then
        log "Terra repository already enabled"
    elif rpm -q terra-release >/dev/null 2>&1; then
        log "Terra release package already installed"
    else
        sudo dnf install -y --nogpgcheck \
            --repofrompath "terra-bootstrap,https://repos.fyralabs.com/terra\$releasever" \
            terra-release \
            terra-gpg-keys
    fi

    rpm -q terra-release-extras >/dev/null 2>&1 ||
        sudo dnf install -y terra-release-extras

    if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
        log "Enabling RPM Fusion for Steam"
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi
}

install_system_packages() {
    log "Installing full Xorg, bspwm, audio, and desktop prerequisites"
    sudo dnf group install -y "base-x"
    sudo dnf install -y \
        bash-completion \
        bat \
        btop \
        bluez \
        bluez-tools \
        brightnessctl \
        bspwm \
        curl \
        dbus-x11 \
        dunst \
        emacs \
        feh \
        fastfetch \
        git \
        ImageMagick \
        adwaita-icon-theme \
        file-roller \
        gvfs \
        gvfs-mtp \
        hicolor-icon-theme \
        libnotify \
        lxpolkit \
        maim \
        NetworkManager \
        pamixer \
        pavucontrol \
        picom \
        pipewire \
        pipewire-pulseaudio \
        polkit \
        polybar \
        quickshell \
        qemu \
        qemu-kvm \
        rofi \
        sddm \
        sddm-breeze \
        shared-mime-info \
        steam \
        steam-devices \
        sxhkd \
        thunar \
        thunar-archive-plugin \
        thunar-media-tags-plugin \
        thunar-volman \
        tumbler \
        udiskie \
        unzip \
        wezterm \
        wireplumber \
        wmname \
        xcolor \
        xarchiver \
        xclip \
        xdotool \
        xdg-user-dirs \
        xdg-user-dirs-gtk \
        xdg-utils \
        xorg-x11-drv-libinput \
        xorg-x11-server-Xorg \
        xkill \
        xprop \
        xrdb \
        xorg-x11-xauth \
        xorg-x11-xinit \
        xrandr \
        xsetroot \
        zsh

    sudo systemctl enable --now NetworkManager.service
    sudo systemctl enable --now bluetooth.service || true
}

install_vm_curator() {
    if rpm -q vm-curator >/dev/null 2>&1; then
        log "vm-curator is already installed"
        return 0
    fi

    log "Installing vm-curator RPM"
    sudo dnf install -y \
        "https://github.com/mroboff/vm-curator/releases/download/v${VM_CURATOR_VERSION}/vm-curator-${VM_CURATOR_VERSION}-1.x86_64.rpm"
}

configure_display_manager() {
    log "Configuring SDDM with the Breeze theme"
    sudo install -d -m 0755 /etc/sddm.conf.d
    printf '%s\n' '[Theme]' 'Current=breeze' |
        sudo tee /etc/sddm.conf.d/10-nux-theme.conf >/dev/null
    sudo systemctl enable --force sddm.service
    sudo systemctl set-default graphical.target
}

convert_to_xlibre() {
    log "Replacing the Fedora Xorg server with XLibre"
    sudo dnf install -y xlibre-xserver xlibre-xf86-input-libinput --allowerasing
}

install_nix() {
    log "Installing and configuring Nix"
    sudo dnf install -y nix nix-daemon
    sudo systemctl enable --now nix-daemon.socket nix-daemon.service || true

    run_as_user mkdir -p "$USER_HOME/.config/nix"
    # The inner shell expands its own HOME, not the installer's environment.
    # shellcheck disable=SC2016
    run_as_user bash -c '
        config="$HOME/.config/nix/nix.conf"
        touch "$config"
        grep -qxF "experimental-features = nix-command flakes" "$config" ||
            printf "%s\\n" "experimental-features = nix-command flakes" >> "$config"
    '
}

prepare_repo() {
    if [[ ! -f "$REPO_DIR/flake.nix" ]]; then
        if [[ -e "$REPO_DIR" && -n "$(ls -A "$REPO_DIR" 2>/dev/null)" ]]; then
            die "--repo does not contain flake.nix: $REPO_DIR"
        fi
        log "Cloning nux"
        run_as_user git clone "$REPO_URL" "$REPO_DIR"
    fi
    [[ -f "$REPO_DIR/flake.nix" ]] || die "nux checkout not found: $REPO_DIR"
    [[ -f "$REPO_DIR/home.nix" ]] || die "home.nix not found in: $REPO_DIR"
}

enable_user_services() {
    log "Enabling user audio services"
    run_as_user systemctl --user daemon-reload || true
    run_as_user systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service || true
}

clean_flake_runtime_files() {
    # Nix rejects Unix sockets while copying a local flake source. They are
    # runtime state and must never be part of the Home Manager input.
    local socket_path
    shopt -s nullglob
    for socket_path in "$REPO_DIR/home/config/herdr/"*.sock; do
        [[ -S "$socket_path" ]] && rm -f "$socket_path"
    done
    shopt -u nullglob
}

apply_home_manager() {
    log "Applying Home Manager configuration"
    clean_flake_runtime_files
    # The inner shell needs to cd as the desktop user before invoking Nix.
    # shellcheck disable=SC2016
    run_as_user bash -c 'cd "$1" && NIXPKGS_ALLOW_UNFREE=1 nix run github:nix-community/home-manager -- switch --flake ".#array" --impure' _ "$REPO_DIR"
}

install_doom() {
    ((SKIP_DOOM)) && return 0

    log "Installing Doom Emacs"
    if [[ ! -d "$USER_HOME/.config/emacs/.git" ]]; then
        run_as_user git clone --depth 1 https://github.com/doomemacs/doomemacs "$USER_HOME/.config/emacs"
    fi
    run_as_user "$USER_HOME/.config/emacs/bin/doom" install --force
}

set_default_shell() {
    log "Setting zsh as the login shell"
    local zsh_path=/usr/bin/zsh
    [[ -x "$zsh_path" ]] || die "Fedora's zsh package did not install $zsh_path"
    if [[ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != "$zsh_path" ]]; then
        sudo chsh -s "$zsh_path" "$USER_NAME"
    fi
}

run_post_install() {
    log "Initializing user directories and checking the desktop"
    run_as_user xdg-user-dirs-update || true
    run_as_user fc-cache -f || true

    local missing=()
    local command_name
    for command_name in bspwm sxhkd picom rofi maim xrandr qs wezterm fastfetch; do
        run_as_user bash -c "command -v '$command_name' >/dev/null" || missing+=("$command_name")
    done
    ((${#missing[@]} == 0)) || die "installed profile is missing commands: ${missing[*]}"
}

main() {
    parse_args "$@"
    check_prerequisites
    install_repositories
    install_system_packages
    install_vm_curator
    convert_to_xlibre
    configure_display_manager
    install_nix
    prepare_repo
    enable_user_services
    apply_home_manager
    install_doom
    set_default_shell
    run_post_install

    cat <<EOF

nux is installed for $USER_NAME.

Reboot to start the SDDM login manager with the Breeze theme.

If this is a fresh Fedora installation, log out and back in once before
rebooting so the new Nix profile and login shell are loaded.
EOF
}

main "$@"
