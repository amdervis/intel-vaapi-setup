# Intel VA-API Driver Auto-Installer

This script automatically detects your Intel GPU, installs the appropriate VA-API driver (`iHD` or `i965`), configures the `LIBVA_DRIVER_NAME` environment variable system-wide, and prints helpful graphics information.  
It simplifies VA-API setup for hardware-accelerated video playback on Intel GPUs.

## 🔧 Features

- ✅ Auto-detects Intel GPU device ID using `lspci`
- ✅ Selects the correct VA-API driver (`iHD` or `i965`)
- ✅ Installs required packages via `apt` (e.g., `intel-media-va-driver`, `i965-va-driver`, `vainfo`)
- ✅ Configures `LIBVA_DRIVER_NAME` in `/etc/environment`
- ✅ Displays useful graphics and VA-API info
- ✅ Stylish, color-coded terminal output
- ✅ Idempotent — safe to run multiple times

## 🖥️ Supported OS

- Debian / Ubuntu (APT-based systems)
- Tested on Intel iGPU systems using VA-API

## 📦 Requirements

- `lspci`, `vainfo`, `apt`
- Run as root (`sudo`) — script auto-elevates if needed
