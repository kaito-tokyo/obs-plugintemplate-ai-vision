<div align="center">

# 🤖 OBS AI Vision Plugin Template

### *Supercharge Your Streaming with Artificial Intelligence*

[![Build Status](https://img.shields.io/github/actions/workflow/status/kaito-tokyo/obs-plugintemplate-ai-vision/build-project.yaml?style=for-the-badge&logo=github)](https://github.com/kaito-tokyo/obs-plugintemplate-ai-vision/actions/workflows/build-project.yaml)
[![License](https://img.shields.io/badge/license-GPL%20v3-blue.svg?style=for-the-badge)](LICENSE)
[![OBS Studio](https://img.shields.io/badge/OBS-31.1.1-8A2BE2?style=for-the-badge&logo=obsstudio)](https://obsproject.com/)
[![C++](https://img.shields.io/badge/C++-17-00599C?style=for-the-badge&logo=cplusplus)](https://isocpp.org/)

**A cutting-edge template for building AI-powered vision plugins for OBS Studio**

[Features](#features) • [Quick Start](#quick-start) • [Documentation](#documentation) • [Contributing](#contributing)

---

</div>

## 🌟 Overview

Welcome to the **OBS AI Vision Plugin Template** — your launchpad for creating next-generation streaming plugins powered by artificial intelligence! This template provides a robust foundation for developing computer vision and AI-enhanced features for OBS Studio, the world's leading open-source streaming and recording software.

### 🎯 What Makes This Special?

This isn't just another plugin template. It's a **production-ready starting point** designed specifically for AI and vision-based applications:

- 🧠 **AI-Ready Architecture**: Pre-configured structure optimized for integrating machine learning models
- 👁️ **Vision Processing**: Built with computer vision workflows in mind
- 🚀 **Modern C++17**: Clean, maintainable code following industry best practices
- 🔧 **Cross-Platform**: Seamless development on Windows, macOS, and Linux
- ⚡ **CMake Presets**: Simplified build process with zero configuration headaches
- 🤖 **CI/CD Pipeline**: Automated builds and releases via GitHub Actions

## ✨ Features

<table>
<tr>
<td width="50%">

### 🛠️ Development Ready
- Complete boilerplate source code
- CMake project configuration
- Modern C++17 standards
- Cross-platform compatibility
- Professional code structure

</td>
<td width="50%">

### 🔄 Automation First
- GitHub Actions workflows
- Automated testing & builds
- Continuous deployment
- Release management
- Code signing support

</td>
</tr>
<tr>
<td width="50%">

### 🎨 Integration Friendly
- OBS Studio API integration
- Qt6 GUI framework
- Plugin lifecycle management
- Locale support
- Resource management

</td>
<td width="50%">

### 📦 Distribution Ready
- Packaging automation
- Multi-platform artifacts
- Version management
- Dependency handling
- Professional releases

</td>
</tr>
</table>

## 🚀 Quick Start

Get up and running in minutes with our streamlined build process powered by **CMake Presets**.

### 📋 Prerequisites

Ensure you have the following tools installed:

| Tool | Version | Purpose |
|------|---------|---------|
| **CMake** | 3.28+ | Build system generator |
| **C++ Compiler** | VS2022/Xcode16/GCC | Code compilation |
| **Git** | Latest | Version control |

### 💻 Supported Platforms

<table>
<thead>
<tr>
<th>🖥️ Platform</th>
<th>🔧 Environment</th>
<th>✅ Status</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Windows</strong></td>
<td>Visual Studio 17 2022</td>
<td>✅ Fully Supported</td>
</tr>
<tr>
<td><strong>macOS</strong></td>
<td>Xcode 16</td>
<td>✅ Fully Supported</td>
</tr>
<tr>
<td><strong>Ubuntu</strong></td>
<td>Ubuntu 24.04</td>
<td>✅ Fully Supported</td>
</tr>
</tbody>
</table>

### 🔧 Build Instructions

<details>
<summary><b>🪟 Windows (PowerShell)</b></summary>

#### Step 1: Install Dependencies
```powershell
cmake -P scripts/download-deps.cmake
```

#### Step 2: Configure & Build
```powershell
# Configure the project
cmake --preset windows-x64

# Build the plugin
cmake --build --preset windows-x64

# Install to local release folder
cmake --install build_x64 --prefix release
```

#### Step 3: Deploy
Copy the contents of the `release` directory to your OBS Studio installation:
```
C:\Program Files\obs-studio
```

</details>

<details>
<summary><b>🍎 macOS (Terminal)</b></summary>

#### Step 1: Install Dependencies
```bash
cmake -P scripts/download-deps.cmake
```

#### Step 2: Configure & Build
```bash
# Configure the project
cmake --preset macos

# Build the plugin
cmake --build --preset macos

# Install directly to OBS plugins folder
cmake --install build_macos --prefix "$HOME/Library/Application Support/obs-studio/plugins"
```

✨ The plugin will be immediately available in OBS Studio!

</details>

<details>
<summary><b>🐧 Ubuntu (Bash)</b></summary>

#### Step 1: Install Dependencies
```bash
# Add OBS Studio PPA
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt-get update

# Install required packages
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

#### Step 2: Configure & Build
```bash
# Configure the project
cmake --preset ubuntu-x86_64

# Build the plugin
cmake --build --preset ubuntu-x86_64

# Install system-wide
sudo cmake --install build_x86_64 --prefix /usr
```

</details>

## 🏗️ Architecture

```
obs-plugintemplate-ai-vision/
├── 📁 src/                  # Plugin source code
├── 📁 data/                 # Resources & localization
├── 📁 cmake/                # Build configuration
├── 📁 scripts/              # Helper scripts
├── 📁 .github/              # CI/CD workflows
└── 📄 CMakeLists.txt        # Main build file
```

## 🎨 Use Cases

This template is perfect for creating:

- 🎭 **Face & Object Detection**: Real-time recognition in streams
- 🖼️ **Scene Analysis**: Intelligent scene switching and composition
- 🎯 **Motion Tracking**: Follow subjects automatically
- 🌈 **Style Transfer**: Apply AI-powered filters and effects
- 📊 **Analytics**: Gather insights from video content
- 🔍 **Background Removal**: AI-powered chroma-free keying
- 👥 **Multi-Person Tracking**: Follow multiple subjects
- 🎨 **Content-Aware Effects**: Smart filters that understand your scene

## 📦 Packaging & Release

### Automated Workflow

The template includes a complete CI/CD pipeline powered by **GitHub Actions**:

| Trigger | Action | Output |
|---------|--------|--------|
| 🔄 Push to `main`/`master` | Build & Test | Validation |
| 📥 Pull Request | Build & Test | CI Checks |
| 🏷️ Tag Push (e.g., `v1.0.0`) | Build, Sign & Package | Draft Release |

### Release Process

1. **Create a tag**: `git tag v1.0.0 && git push origin v1.0.0`
2. **Automated build**: GitHub Actions compiles for all platforms
3. **Code signing**: Artifacts are signed (macOS/Windows)
4. **Draft release**: Binaries are attached and ready for publishing

## 🍎 macOS Code Signing

For distribution on macOS, you'll need to configure **code signing** and **notarization**. 

📚 Detailed instructions: [Codesigning on macOS](https://github.com/obsproject/obs-plugintemplate/wiki/Codesigning-On-macOS)

## 📚 Documentation

Expand your knowledge with our comprehensive documentation:

| Resource | Description |
|----------|-------------|
| [🚀 Getting Started](https://github.com/obsproject/obs-plugintemplate/wiki/Getting-Started) | Begin your plugin development journey |
| [🔧 Build Requirements](https://github.com/obsproject/obs-plugintemplate/wiki/Build-System-Requirements) | System prerequisites and setup |
| [⚙️ CMake Options](https://github.com/obsproject/obs-plugintemplate/wiki/CMake-Build-System-Options) | Advanced build configuration |
| [📖 OBS Plugin API](https://docs.obsproject.com/) | Official OBS Studio documentation |

## 🤝 Contributing

We welcome contributions! Whether you're fixing bugs, improving documentation, or proposing new features:

1. 🍴 Fork the repository
2. 🌿 Create a feature branch (`git checkout -b feature/amazing-feature`)
3. 💾 Commit your changes (`git commit -m 'Add amazing feature'`)
4. 📤 Push to the branch (`git push origin feature/amazing-feature`)
5. 🎉 Open a Pull Request

## 📄 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

## 🌐 Community & Support

- 💬 **Discussions**: [GitHub Discussions](https://github.com/kaito-tokyo/obs-plugintemplate-ai-vision/discussions)
- 🐛 **Issues**: [Bug Reports](https://github.com/kaito-tokyo/obs-plugintemplate-ai-vision/issues)
- 📧 **Contact**: For questions and support

## 🙏 Acknowledgments

Built with ❤️ using:
- [OBS Studio](https://obsproject.com/) - The best streaming software
- [Qt Framework](https://www.qt.io/) - Cross-platform GUI framework
- [CMake](https://cmake.org/) - Build system generator

---

<div align="center">

**⭐ Star this repository if you find it helpful!**

Made with 🤖 for the AI-powered streaming future

[Report Bug](https://github.com/kaito-tokyo/obs-plugintemplate-ai-vision/issues) · [Request Feature](https://github.com/kaito-tokyo/obs-plugintemplate-ai-vision/issues) · [Documentation](https://github.com/obsproject/obs-plugintemplate/wiki)

</div>
