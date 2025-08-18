# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **end_4's Hyprland dotfiles repository** - a comprehensive Linux desktop environment configuration based on Hyprland compositor with Quickshell widgets. The repository provides a complete desktop setup with Material Design 3 theming, AI integration, and modern Linux desktop features.

**Primary Technologies:**
- **Hyprland**: Wayland compositor (window manager)
- **Quickshell**: QtQuick-based widget system (primary, actively maintained)
- **AGS**: Alternative widget system (deprecated branch: ii-ags)

## Installation and Management Commands

**Main Installation:**
```bash
./install.sh              # Interactive installation for Arch Linux only
```

**Maintenance:**
```bash
./update.sh               # Update dotfiles, handle conflicts, rebuild packages
./diagnose                # Generate diagnostic information
./uninstall.sh            # Remove installed configurations
```

**Manual Helper:**
```bash
./manual-install-helper.sh # Manual installation assistance
```

## Repository Architecture

### Core Structure
- `scriptdata/` - Installation scripts and dependency management
  - `dependencies.conf` - Package dependencies (mostly moved to arch-packages)
  - `functions` - Bash functions for installation scripts
  - `installers` - Installation logic
- `arch-packages/` - PKGBUILD files for meta packages
  - `illogical-impulse-*` packages containing grouped dependencies
- `.config/` - User configuration files for various applications

### Widget System (Quickshell)
**Location:** `.config/quickshell/ii/`

**Key Files:**
- `shell.qml` - Main shell entry point
- `modules/` - Modular widget components:
  - `bar/` - Top status bar components
  - `overview/` - Application launcher and window overview
  - `sidebarLeft/` - AI chat, translator, anime
  - `sidebarRight/` - Notifications, calendar, quick toggles
  - `dock/` - Application dock
  - `common/` - Shared widgets and utilities
  - `cheatsheet/` - Keybind help and periodic table
- `services/` - Backend service integrations

### Hyprland Configuration
**Location:** `.config/hypr/`

**Structure:**
- `hyprland.conf` - Main config file that sources others
- `hyprland/` - Default configurations:
  - `keybinds.conf`, `general.conf`, `rules.conf`, etc.
- `custom/` - User customizations (override defaults)

## Development Guidelines

### Quickshell Widget Development
- Components are written in QML (Qt Quick)
- Use Material Design 3 patterns from `common/widgets/`
- Import structure: `import "./modules/common/"`
- Styling handled through `Appearance.qml` and auto-generated colors

### Configuration Patterns
- Hyprland configs use source hierarchy: defaults in `hyprland/`, overrides in `custom/`
- Colors auto-generated from wallpaper using matugen
- Widget scaling via `QT_SCALE_FACTOR` environment variable

### Installation Script Architecture
- All scripts source: `scriptdata/environment-variables`, `scriptdata/functions`
- Interactive execution with `v()` function (ask before each command)
- Error handling with retry/skip/exit options via `x()` function
- Arch Linux package manager (pacman/yay) dependency

### Package Management
- Dependencies organized into meta packages in `arch-packages/`
- Each `illogical-impulse-*` package groups related dependencies
- Custom PKGBUILD files for specific requirements

## Key Features
- **AI Integration**: Gemini API and Ollama model support
- **Material Theming**: Auto-generated colors from wallpaper
- **Overview Widget**: Live window previews with search/calculator
- **Multi-monitor Support**: Per-monitor workspace management
- **Transparent Installation**: All commands shown before execution

## Compatibility Notes
- **Platform**: Arch Linux and derivatives only
- **Widget Migration**: AGS version deprecated, Quickshell is current
- **Branch Structure**: `main` (Quickshell), `ii-ags` (deprecated AGS)