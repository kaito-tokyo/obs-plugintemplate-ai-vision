# OBS Plugin Template

## Introduction

The plugin template is meant to be used as a starting point for OBS Studio plugin development. It includes:

- Boilerplate plugin source code
- A CMake project file
- GitHub Actions workflows and repository actions

## Supported Build Environments

| Platform | Environment           |
| -------- | --------------------- |
| Windows  | Visual Studio 17 2022 |
| macOS    | Xcode 16              |
| Ubuntu   | Ubuntu 24.04          |

## Quick Start

This project utilizes **CMake Presets** to simplify the configuration and build process.

### 1. Prerequisites

Ensure the following tools are installed on your system:

- **CMake** (3.28 or newer)
- **C++ Compiler** (Visual Studio 2022, Xcode 16, or GCC/Clang)

### 2. Build Instructions

Execute the following commands in your terminal to install dependencies, build the plugin, and install the artifacts.

#### Step 1: Install Dependencies

**Windows and macOS:**
Run the helper script to download OBS Studio headers, Qt6, and other pre-built dependencies automatically.

```bash
cmake -P scripts/download-deps.cmake
```

**Ubuntu:**
Install the required packages via `apt`.

```bash
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt-get update
sudo apt-get install \
  cmake \
  libgles2-mesa-dev \
  libqt6svg6-dev \
  libsimde-dev \
  ninja-build \
  obs-studio \
  pkg-config \
  qt6-base-dev \
  qt6-base-private-dev
```

#### Step 2: Configure, Build, and Install

Select the appropriate preset for your platform.

**Windows (PowerShell):**
Installs artifacts to a local `release` directory.
To use the plugin, copy the contents of the `release` directory to your OBS Studio installation path (typically `C:\Program Files\obs-studio`).

```powershell
# Configure
cmake --preset windows-x64

# Build
cmake --build --preset windows-x64

# Install (to a local 'release' folder)
cmake --install build_x64 --prefix release
```

**macOS:**
Installs directly to the OBS Studio plugins folder, allowing immediate use.

```bash
# Configure
cmake --preset macos

# Build
cmake --build --preset macos

# Install (to OBS Studio plugins folder)
cmake --install build_macos --prefix "$HOME/Library/Application Support/obs-studio/plugins"
```

**Ubuntu:**
Installs to the system directory (`/usr`).

```bash
# Configure
cmake --preset ubuntu-x86_64

# Build
cmake --build --preset ubuntu-x86_64

# Install (to /usr)
sudo cmake --install build_x86_64 --prefix /usr
```

## Packaging and Release

Packaging is handled automatically via GitHub Actions. The repository includes configured workflows for Continuous Integration and Continuous Delivery (CI/CD):

- **Build**: Triggered on push to `main` and `master` and Pull Requests.
- **Release**: Triggered when a tag is pushed (e.g., `1.0.0`). This workflow builds, signs, and creates a Draft Release with artifacts.

## macOS Code Signing and Notarization

For information regarding macOS code signing and notarization setup (required for distribution), please refer to [Codesigning on macOS](https://github.com/obsproject/obs-plugintemplate/wiki/Codesigning-On-macOS).

## Documentation

Comprehensive documentation is available in the [Plugin Template Wiki](https://github.com/obsproject/obs-plugintemplate/wiki).

- [Getting Started](https://github.com/obsproject/obs-plugintemplate/wiki/Getting-Started)
- [Build System Requirements](https://github.com/obsproject/obs-plugintemplate/wiki/Build-System-Requirements)
- [CMake Build System Options](https://github.com/obsproject/obs-plugintemplate/wiki/CMake-Build-System-Options)
