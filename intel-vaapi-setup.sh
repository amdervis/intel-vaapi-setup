#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
NC='\033[0m'

log()      { echo -e "${BLU}[INFO]${NC} $1"; }
success()  { echo -e "${GRN}[OK]${NC} $1"; }
warning()  { echo -e "${YLW}[WARN]${NC} $1"; }
error()    { echo -e "${RED}[ERR]${NC} $1"; }
heading()  { echo -e "\n${CYN}==> $1${NC}"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "Re-running as sudo..."
        exec sudo "$0" "$@"
    fi
}

get_device_id() {
    lspci -nn | grep -iE 'vga|display|3d' | grep -i intel | grep -oP '8086:\K[0-9a-fA-F]{4}' | tr '[:lower:]' '[:upper:]'
}

detect_driver() {
    local id="$1"
    local i965_ids=(
        0042 0046 0102 0106 0112 0116 0122 0126 0152 0156 0162 0166
        0402 0412 0416 041E 0A06 0A16 0A26 0A2E 0BE0 0BE1 0BE2 0BE3
        22B0 22B1 22B2 22B3 161E 1602 160A 1606 160B 160D 160E
    )

    for known in "${i965_ids[@]}"; do
        if [[ "$id" == "$known" ]]; then
            echo "i965"
            return
        fi
    done

    echo "iHD"
}

install_driver() {
    local driver="$1"
    heading "Installing packages for driver: $driver"
    apt update
    if [[ "$driver" == "iHD" ]]; then
        apt install -y intel-media-va-driver vainfo
    else
        apt install -y i965-va-driver vainfo
    fi
}

configure_env() {
    local driver="$1"
    heading "Configuring environment variable"
    if grep -q "LIBVA_DRIVER_NAME=" /etc/environment; then
        sed -i "s/^LIBVA_DRIVER_NAME=.*/LIBVA_DRIVER_NAME=$driver/" /etc/environment
        success "Updated LIBVA_DRIVER_NAME to $driver in /etc/environment"
    else
        echo "LIBVA_DRIVER_NAME=$driver" >> /etc/environment
        success "Added LIBVA_DRIVER_NAME=$driver to /etc/environment"
    fi
}

show_graphics_info() {
    heading "Graphics Device Info"
    lspci | grep -iE 'vga|display|3d' | grep -i intel || warning "No Intel GPU found via lspci"

    echo ""
    heading "vainfo (may fail if driver not installed yet)"
    if vainfo &>/dev/null; then
        vainfo | grep -iE 'driver|profile' | sed 's/^/  /'
    else
        warning "vainfo failed. It will likely work after installing the correct driver."
    fi
}

main() {
    check_root

    device_id=$(get_device_id)
    if [[ -z "$device_id" ]]; then
        error "No Intel GPU device ID detected."
        exit 1
    fi

    heading "Intel GPU Detected"
    log "Device ID: ${CYN}$device_id${NC}"

    driver=$(detect_driver "$device_id")
    success "Selected VA-API driver: ${GRN}$driver${NC}"

    show_graphics_info

    echo ""
    read -rp "Do you want to install the $driver driver and configure the environment? [Y/n] " yn
    [[ "$yn" =~ ^[Nn]$ ]] && exit 0

    install_driver "$driver"
    configure_env "$driver"

    echo ""
    heading "Rechecking VA-API"
    su - "$SUDO_USER" -c 'vainfo 2>/dev/null || echo "vainfo still failed (you may need to reboot)"'

    success "Installation and configuration complete."
    echo -e "${YLW}You may need to reboot for changes to take full effect.${NC}"
}

main "$@"
