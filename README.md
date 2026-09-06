English | [简体中文](README_zh.md)

<div align="center">

# PlistBar

Lightweight `launchd` menu bar control panel for macOS, designed for users who want to inspect, control, edit, and monitor Launch Agents and Daemons within a single unified entry point.

<p>
  <img alt="Platform" src="https://img.shields.io/badge/macOS-14%2B-111111?style=flat&logo=apple" />
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6.2-F05138?style=flat&logo=swift" />
  <img alt="Build" src="https://img.shields.io/badge/Build-SwiftPM-0A84FF?style=flat" />
  <img alt="i18n" src="https://img.shields.io/badge/i18n-zh--Hans%20%7C%20en-34C759?style=flat" />
  <img alt="Version" src="https://img.shields.io/github/v/release/SakagamiJun/PlistBar?style=flat&logo=github" />
  <img alt="License" src="https://img.shields.io/badge/License-GPL%20v3-blue.svg?style=flat" />
</p>

</div>

## Requirements

- macOS 14.0 (Sonoma) or later
- Local builds require Xcode 16+ or the Swift toolchain compatible with Swift 6.2
- Standard user permissions for User Agents; viewing and managing Global Agents and Global Daemons may require administrator or root privileges

## Quick Start

### Method 1: Install via Homebrew

```sh
brew tap SakagamiJun/tap
brew install --cask plistbar
```

### Method 2: Install Pre-built Release

1. Download the latest `PlistBar.zip` from [GitHub Releases](https://github.com/SakagamiJun/PlistBar/releases).
2. Unzip and drag `PlistBar.app` to your `Applications` folder.
3. Launch PlistBar from `Applications`.
4. Click the PlistBar icon in the macOS menu bar to open the control panel.

### Method 3: Build from Source

1. Clone the repository:

```sh
git clone https://github.com/SakagamiJun/PlistBar.git
cd PlistBar
```

2. Build the application bundle:

```sh
make build
```

3. Build the release archive (ZIP):

```sh
make dist
```

4. Run the built application:

```sh
make run
```

## Features Overview

### 1. Service Browsing & Scope Management

- **Multi-Scope Organization**: Seamlessly switch between **User Agents** (`~/Library/LaunchAgents`), **Global Agents** (`/Library/LaunchAgents`), and **Global Daemons** (`/Library/LaunchDaemons`).
- **Real-Time Status**: Visual status indicators for Running, Loaded (idle), Not Running (stopped), and error exits, complete with PID and exit code tracking.
- **Fast Search & Filter**: Instant filtering by status and real-time keyword search across labels, program commands, and plist filenames.

### 2. Lifecycle & Process Control

- **Modern API with Fallback**: Utilizes modern `launchctl bootstrap` / `bootout` commands with automatic fallback to `load` / `unload`.
- **Fast Start & Stop**: One-click start/restart via `kickstart -kp` and graceful stop via `kill SIGTERM`.
- **KeepAlive Awareness & Safety**: Specially handles `KeepAlive` services to prevent unwanted respawn loops; dangerous actions (such as deletion) require secondary confirmation.
- **System Integration**: Quick access to reveal `.plist` files in Finder and copy service labels or file paths with one click.

### 3. Visual Plist Editor & Templates

- **Form-Based Plist Editor**: Create and modify launchd configurations without writing raw XML (supports Label, Program, ProgramArguments, RunAtLoad, KeepAlive, StandardOutPath, StandardErrorPath, WorkingDirectory, EnvironmentVariables, and more).
- **Built-in Templates**: Ready-to-use templates for common patterns (background daemons, periodic intervals via `StartInterval` / `StartCalendarInterval`, and file watcher tasks via `WatchPaths`).
- **Atomic & Validated Saving**: Pre-save syntax validation and atomic file writes prevent configuration corruption.

### 4. Real-time Logs & Intelligent Alerting

- **Stdout & Stderr Streaming**: Real-time tailing of configured `StandardOutPath` and `StandardErrorPath` logs.
- **Memory-Safe Sliding Window**: 64KB tail sliding window and capped 500-line buffer ensure minimal memory usage even with massive log files.
- **Visual Rule Builder**: Built-in rules for `Fatal`, `Error`, `Exception`, `Panic`, `Crash`, with support for custom keyword matching and regular expressions.
- **Menu Bar Alert Integration**: Dynamic menu bar icon transitions (warning / error states) and macOS system notifications keep you informed of issues immediately.

### 5. Native Design & Extreme Efficiency

- **NSPanel Floating UI**: Custom borderless floating panel with native `.regularMaterial` frosted glass, responsive auto-height, and smooth animations.
- **Zero Idle Background Drain**: Background heartbeat polling and global event monitors suspend immediately when the panel is closed.
- **Full Localization**: Native support for Simplified Chinese (`zh-Hans`) and English (`en`).

## License

This project is licensed under the [GNU GPL v3.0](LICENSE).
