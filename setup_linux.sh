#!/bin/bash

# LaTeX Homework Template - Linux Setup Script
# This script installs all required dependencies for Ubuntu/Debian systems

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user."
        print_error "The script will prompt for sudo password when needed."
        exit 1
    fi
}

# Function to detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect Linux distribution. This script is designed for Ubuntu/Debian."
        exit 1
    fi
}

# Function to check internet connection
check_internet() {
    print_status "Checking internet connection..."
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection detected. Please check your network."
        exit 1
    fi
    print_success "Internet connection verified"
}

# Function to update package list
update_packages() {
    print_status "Updating package list..."
    if sudo apt update; then
        print_success "Package list updated successfully"
    else
        print_error "Failed to update package list"
        exit 1
    fi
}

# Function to install TeXLive
install_texlive() {
    print_status "Installing TeXLive (this may take a while - ~4GB download)..."
    
    if command_exists pdflatex; then
        print_warning "LaTeX appears to be already installed. Checking version..."
        pdflatex --version | head -1
        
        read -p "Do you want to reinstall/upgrade TeXLive? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Skipping TeXLive installation"
            return 0
        fi
    fi
    
    if sudo apt install -y texlive-full; then
        print_success "TeXLive installed successfully"
    else
        print_error "Failed to install TeXLive"
        print_status "Trying alternative installation..."
        if sudo apt install -y texlive-latex-extra texlive-fonts-recommended texlive-fonts-extra texlive-bibtex-extra texlive-science texlive-publishers; then
            print_success "TeXLive (essential packages) installed successfully"
        else
            print_error "Failed to install TeXLive packages"
            exit 1
        fi
    fi
}

# Function to install Python and Pygments
install_python_pygments() {
    print_status "Installing Python and Pygments..."
    
    if sudo apt install -y python3 python3-pip python3-pygments; then
        print_success "Python and Pygments installed successfully"
    else
        print_error "Failed to install Python/Pygments"
        exit 1
    fi
    
    # Verify pygments installation
    if command_exists pygmentize; then
        print_success "Pygments verification: $(pygmentize -V)"
    else
        print_warning "Pygments not found in PATH. Trying pip installation..."
        if pip3 install pygments; then
            print_success "Pygments installed via pip"
        else
            print_error "Failed to install Pygments via pip"
            exit 1
        fi
    fi
}

# Function to install file watching tools
install_file_watching() {
    print_status "Installing file watching tools..."
    
    if sudo apt install -y inotify-tools; then
        print_success "File watching tools installed successfully"
    else
        print_error "Failed to install file watching tools"
        exit 1
    fi
}

# Function to install bibliography tools
install_bibliography() {
    print_status "Installing bibliography tools..."
    
    if sudo apt install -y biber; then
        print_success "Bibliography tools installed successfully"
    else
        print_error "Failed to install bibliography tools"
        exit 1
    fi
}

# Function to install additional useful packages
install_additional_packages() {
    print_status "Installing additional useful packages..."
    
    # Install git if not present
    if ! command_exists git; then
        sudo apt install -y git
    fi
    
    # Install curl if not present
    if ! command_exists curl; then
        sudo apt install -y curl
    fi
    
    # Install essential build tools
    sudo apt install -y build-essential
    
    print_success "Additional packages installed"
}

# Function to setup directory structure
setup_directories() {
    print_status "Setting up directory structure..."
    
    # Create assets directory if it doesn't exist
    if [[ ! -d "assets" ]]; then
        mkdir -p assets
        print_success "Created assets directory"
    fi
    
    # Create a sample bibliography file if it doesn't exist
    if [[ ! -f "references.bib" ]]; then
        cat > references.bib << EOF
% Sample bibliography file
% Add your references here

@article{sample2024,
  title={Sample Article Title},
  author={Author, Sample},
  journal={Journal Name},
  year={2024},
  volume={1},
  number={1},
  pages={1--10}
}
EOF
        print_success "Created sample references.bib file"
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local errors=0
    
    # Check pdflatex
    if command_exists pdflatex; then
        print_success "pdflatex: $(pdflatex --version | head -1)"
    else
        print_error "pdflatex not found"
        ((errors++))
    fi
    
    # Check pygmentize
    if command_exists pygmentize; then
        print_success "pygmentize: $(pygmentize -V)"
    else
        print_error "pygmentize not found"
        ((errors++))
    fi
    
    # Check biber
    if command_exists biber; then
        print_success "biber: $(biber --version | head -1)"
    else
        print_error "biber not found"
        ((errors++))
    fi
    
    # Check inotifywait
    if command_exists inotifywait; then
        print_success "inotifywait: available"
    else
        print_error "inotifywait not found"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "All components verified successfully!"
        return 0
    else
        print_error "Verification failed with $errors errors"
        return 1
    fi
}

# Function to test compilation
test_compilation() {
    print_status "Testing LaTeX compilation..."
    
    if [[ -f "homework_template.tex" ]]; then
        print_status "Compiling homework_template.tex..."
        
        if pdflatex --shell-escape -interaction=nonstopmode homework_template.tex > /dev/null 2>&1; then
            print_success "Test compilation successful!"
            print_success "PDF created: homework_template.pdf"
            
            # Clean up auxiliary files
            rm -f homework_template.aux homework_template.log homework_template.out homework_template.synctex.gz
        else
            print_warning "Test compilation failed. Check homework_template.log for details."
        fi
    else
        print_warning "homework_template.tex not found. Skipping compilation test."
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  LaTeX Homework Template Setup      ${NC}"
    echo -e "${BLUE}  Linux (Ubuntu/Debian) Installer    ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo
    
    # Pre-installation checks
    check_root
    detect_distro
    print_status "Detected OS: $OS $VER"
    check_internet
    
    # Installation steps
    update_packages
    install_texlive
    install_python_pygments
    install_file_watching
    install_bibliography
    install_additional_packages
    setup_directories
    
    # Post-installation verification
    echo
    print_status "Installation completed. Running verification..."
    if verify_installation; then
        test_compilation
        
        echo
        echo -e "${GREEN}======================================${NC}"
        echo -e "${GREEN}  Installation Successful!           ${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo
        print_success "LaTeX homework template is ready to use!"
        echo
        print_status "Next steps:"
        echo "  1. Edit homework_template.tex with your content"
        echo "  2. Compile with: pdflatex --shell-escape homework_template.tex"
        echo "  3. Or use auto-compilation: ./watch_latex.sh"
        echo
    else
        echo
        echo -e "${RED}======================================${NC}"
        echo -e "${RED}  Installation Issues Detected       ${NC}"
        echo -e "${RED}======================================${NC}"
        echo
        print_error "Some components failed verification. Please check the errors above."
        print_status "You may need to manually install missing components."
        exit 1
    fi
}

# Run main function
main "$@" 