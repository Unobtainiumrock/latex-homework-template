# LaTeX Homework Template

A comprehensive LaTeX template for academic homework assignments with automatic compilation and file watching capabilities.

## 📋 Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
  - [Linux (Ubuntu/Debian)](#linux-ubuntudebian)
  - [Windows](#windows)
  - [macOS](#macos)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Template Features](#template-features)
- [File Structure](#file-structure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

- **Clean, Professional Layout**: Modern academic document formatting
- **Comprehensive Package Support**: Mathematics, algorithms, code highlighting, figures, tables
- **Auto-Compilation**: Watch for file changes and automatically recompile
- **Syntax Highlighting**: Support for multiple programming languages via `minted` and `listings`
- **Bibliography Management**: BibLaTeX with author-year citation style
- **Cross-Platform**: Works on Linux, Windows, and macOS
- **Warning-Free Compilation**: All package conflicts resolved
- **Customizable**: Easy to modify for different assignment types

## 🖥️ System Requirements

### Minimum Requirements
- **Operating System**: Linux (Ubuntu 20.04+), Windows 10+, or macOS 10.14+
- **Disk Space**: ~4GB for full TeXLive installation
- **RAM**: 2GB minimum, 4GB recommended
- **Python**: 3.6+ (for syntax highlighting)

### Assumptions
- You have administrator/sudo access on your system
- You're comfortable running terminal/command prompt commands
- You have a text editor or IDE for editing LaTeX files

## 🚀 Installation

### Linux (Ubuntu/Debian)

#### Option 1: Automatic Installation (Recommended)
```bash
# Clone or download this repository
git clone <repository-url>
cd latex-homework-template

# Run the setup script
chmod +x setup_linux.sh
./setup_linux.sh
```

#### Option 2: Manual Installation
```bash
# Update package list
sudo apt update

# Install TeXLive (full distribution)
sudo apt install -y texlive-full

# Install Python and Pygments for syntax highlighting
sudo apt install -y python3 python3-pip python3-pygments

# Install file watching tools
sudo apt install -y inotify-tools

# Install bibliography tools
sudo apt install -y biber

# Verify installation
pdflatex --version
pygmentize -V
```

### Windows

#### Option 1: Automatic Installation (Recommended)
1. Download and run `setup_windows.ps1` as Administrator:
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup_windows.ps1
```

#### Option 2: Manual Installation
1. **Install MiKTeX or TeX Live**:
   - Download MiKTeX from [miktex.org](https://miktex.org/download)
   - Or download TeX Live from [tug.org](https://tug.org/texlive/)
   - Run the installer and select "Full installation"

2. **Install Python**:
   - Download Python from [python.org](https://www.python.org/downloads/)
   - During installation, check "Add Python to PATH"

3. **Install Pygments**:
   ```cmd
   pip install pygments
   ```

4. **Install File Watcher** (Optional):
   ```cmd
   pip install watchdog
   ```

### macOS

#### Option 1: Automatic Installation (Recommended)
```bash
# Run the setup script
chmod +x setup_mac.sh
./setup_mac.sh
```

#### Option 2: Manual Installation
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install MacTeX (full TeX Live distribution)
brew install --cask mactex

# Install Python and Pygments
brew install python
pip3 install pygments

# Install file watching tools
brew install fswatch

# Add TeX to PATH (add to ~/.zshrc or ~/.bash_profile)
echo 'export PATH="/usr/local/texlive/2023/bin/universal-darwin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
pdflatex --version
pygmentize -V
```

## 🏃‍♂️ Quick Start

1. **Create your homework file**:
   ```bash
   cp homework_template.tex my_homework.tex
   ```

2. **Edit the template**:
   - Change the title, author, and date
   - Replace template content with your homework problems
   - Add your solutions

3. **Compile manually**:
   ```bash
   pdflatex --shell-escape -synctex=1 -interaction=nonstopmode -file-line-error my_homework.tex
   ```

4. **Or use auto-compilation**:
   ```bash
   # Edit the watch script to point to your file
   sed -i 's/homework_template.tex/my_homework.tex/g' watch_latex.sh
   
   # Start watching
   ./watch_latex.sh
   ```

## 📖 Usage

### Basic Compilation
```bash
# Basic compilation
pdflatex my_homework.tex

# With shell escape (required for minted)
pdflatex --shell-escape my_homework.tex

# Full compilation with all features
pdflatex --shell-escape -synctex=1 -interaction=nonstopmode -file-line-error my_homework.tex
```

### Auto-Compilation
```bash
# Start file watching (will auto-compile on save)
./watch_latex.sh

# Stop watching
# Press Ctrl+C in the terminal
```

### Bibliography
If you're using citations:
```bash
# Compile with bibliography
pdflatex --shell-escape my_homework.tex
biber my_homework
pdflatex --shell-escape my_homework.tex
pdflatex --shell-escape my_homework.tex
```

## 🎯 Template Features

### Document Structure
- **Title Page**: Automatic title, author, and date
- **Abstract**: Optional abstract section
- **Sections**: Organized problem sections
- **Headers/Footers**: Professional page layout

### Mathematical Support
- **AMS Math**: Full AMS mathematics package suite
- **Theorems**: Predefined theorem, lemma, proposition environments
- **Custom Commands**: Common mathematical notation shortcuts

### Code Support
- **Minted**: Syntax highlighting for 200+ languages
- **Listings**: Alternative code display package
- **Inline Code**: `\texttt{}` and `\verb||` support

### Figures and Tables
- **Graphics**: Support for PNG, PDF, JPEG images
- **Float Control**: Precise figure and table placement
- **Captions**: Automatic numbering and referencing

### Bibliography
- **BibLaTeX**: Modern bibliography management
- **Author-Year Style**: Academic citation format
- **Automatic Generation**: Easy reference management

## 📁 File Structure

```
latex-homework-template/
├── README.md                 # This file
├── homework_template.tex     # Main LaTeX template
├── watch_latex.sh           # Auto-compilation script (Linux/Mac)
├── setup_linux.sh           # Linux installation script
├── setup_mac.sh             # macOS installation script
├── setup_windows.ps1        # Windows installation script
├── references.bib           # Bibliography file (create as needed)
├── assets/                  # Directory for images and figures
└── .gitignore              # Git ignore file
```

## 🔧 Troubleshooting

### Common Issues

#### "minted Error: You must invoke LaTeX with the -shell-escape flag"
**Solution**: Always use `--shell-escape` flag:
```bash
pdflatex --shell-escape my_homework.tex
```

#### "pygmentize: command not found"
**Solution**: Install Pygments:
```bash
# Linux/Mac
pip3 install pygments

# Windows
pip install pygments
```

#### "Package not found" errors
**Solution**: Install missing packages:
```bash
# Linux (Ubuntu/Debian)
sudo apt install texlive-full

# Mac
brew install --cask mactex

# Windows
# Use MiKTeX Package Manager or install TeX Live
```

#### File watching not working
**Solution**: Check if file watcher is installed:
```bash
# Linux
sudo apt install inotify-tools

# Mac
brew install fswatch

# Windows
pip install watchdog
```

### Performance Tips

1. **Use `pdflatex`** instead of `latex` for better performance
2. **Enable `nonstopmode`** for automated compilation
3. **Use `synctex`** for editor integration
4. **Compile incrementally** - only full recompile when needed

### Debug Mode
To see detailed compilation output:
```bash
# Remove -interaction=nonstopmode for interactive debugging
pdflatex --shell-escape -synctex=1 -file-line-error my_homework.tex
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## 📄 License

This template is licensed under the **GNU General Public License v3.0 or later**.

You are free to:
- Use this template for any purpose
- Modify and distribute it
- Use it in commercial projects

Under the conditions that:
- You include the original license
- You state changes made to the original
- You distribute derivative works under the same license

For the full license text, see [LICENSE](LICENSE) or visit [gnu.org/licenses/gpl-3.0.en.html](https://www.gnu.org/licenses/gpl-3.0.en.html).

---

## 🔗 Additional Resources

- [LaTeX Documentation](https://www.latex-project.org/help/documentation/)
- [Overleaf Learn](https://www.overleaf.com/learn) - Excellent LaTeX tutorials
- [LaTeX Wikibook](https://en.wikibooks.org/wiki/LaTeX) - Comprehensive guide
- [Minted Documentation](https://ctan.org/pkg/minted) - Code highlighting package
- [BibLaTeX Documentation](https://ctan.org/pkg/biblatex) - Bibliography management

---

**Happy LaTeX writing!** 🎓✨
