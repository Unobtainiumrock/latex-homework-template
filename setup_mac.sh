#!/bin/bash

# LaTeX Homework Template - macOS Setup Script
# This script installs all required dependencies for macOS systems

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

# Function to detect macOS version
detect_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
    
    local version=$(sw_vers -productVersion)
    print_status "Detected macOS version: $version"
    
    # Check if macOS is supported (10.14+)
    local major_version=$(echo "$version" | cut -d. -f1)
    local minor_version=$(echo "$version" | cut -d. -f2)
    
    if [[ $major_version -lt 10 ]] || [[ $major_version -eq 10 && $minor_version -lt 14 ]]; then
        print_error "macOS 10.14 (Mojave) or later is required."
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

# Function to install Homebrew
install_homebrew() {
    print_status "Checking for Homebrew..."
    
    if command_exists brew; then
        print_success "Homebrew already installed"
        print_status "Updating Homebrew..."
        brew update
    else
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for the current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon Mac
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        elif [[ -f "/usr/local/bin/brew" ]]; then
            # Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
        fi
        
        print_success "Homebrew installed successfully"
    fi
}

# Function to install MacTeX
install_mactex() {
    print_status "Installing MacTeX (this may take a while - ~4GB download)..."
    
    if command_exists pdflatex; then
        print_warning "LaTeX appears to be already installed. Checking version..."
        pdflatex --version | head -1
        
        read -p "Do you want to reinstall/upgrade MacTeX? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Skipping MacTeX installation"
            return 0
        fi
    fi
    
    if brew install --cask mactex; then
        print_success "MacTeX installed successfully"
        
        # Add TeX to PATH
        local tex_path="/usr/local/texlive/2024/bin/universal-darwin"
        if [[ ! -d "$tex_path" ]]; then
            tex_path="/usr/local/texlive/2023/bin/universal-darwin"
        fi
        
        if [[ -d "$tex_path" ]]; then
            if [[ ":$PATH:" != *":$tex_path:"* ]]; then
                echo "export PATH=\"$tex_path:\$PATH\"" >> ~/.zshrc
                export PATH="$tex_path:$PATH"
            fi
            print_success "TeX added to PATH"
        else
            print_warning "TeX path not found. You may need to add it to PATH manually."
        fi
    else
        print_error "Failed to install MacTeX"
        print_status "Trying alternative installation..."
        
        print_status "Please download and install MacTeX manually from:"
        print_status "https://tug.org/mactex/mactex-download.html"
        
        read -p "Press Enter after installing MacTeX manually, or Ctrl+C to exit..."
        
        if ! command_exists pdflatex; then
            print_error "pdflatex still not found. Please ensure MacTeX is properly installed."
            exit 1
        fi
    fi
}

# Function to install Python and Pygments
install_python_pygments() {
    print_status "Installing Python and Pygments..."
    
    # Install Python via Homebrew
    if ! command_exists python3; then
        if brew install python; then
            print_success "Python installed successfully"
        else
            print_error "Failed to install Python"
            exit 1
        fi
    else
        print_success "Python already installed"
    fi
    
    # Install Pygments
    if pip3 install pygments; then
        print_success "Pygments installed successfully"
    else
        print_error "Failed to install Pygments"
        exit 1
    fi
    
    # Verify pygments installation
    if command_exists pygmentize; then
        print_success "Pygments verification: $(pygmentize -V)"
    else
        print_error "Pygments not found in PATH after installation"
        exit 1
    fi
}

# Function to install file watching tools
install_file_watching() {
    print_status "Installing file watching tools..."
    
    if brew install fswatch; then
        print_success "File watching tools installed successfully"
    else
        print_error "Failed to install file watching tools"
        exit 1
    fi
}

# Function to install bibliography tools
install_bibliography() {
    print_status "Installing bibliography tools..."
    
    # Biber should be included with MacTeX, but let's verify
    if command_exists biber; then
        print_success "Biber already available"
    else
        print_status "Installing Biber..."
        if brew install biber; then
            print_success "Biber installed successfully"
        else
            print_warning "Failed to install Biber via Homebrew. It should be included with MacTeX."
        fi
    fi
}

# Function to install additional useful packages
install_additional_packages() {
    print_status "Installing additional useful packages..."
    
    # Install git if not present
    if ! command_exists git; then
        brew install git
    fi
    
    # Install curl if not present (usually pre-installed on macOS)
    if ! command_exists curl; then
        brew install curl
    fi
    
    print_success "Additional packages checked/installed"
}

# Function to create a macOS-specific watch script
create_mac_watch_script() {
    print_status "Creating macOS file watching script..."
    
    cat > watch_latex_mac.sh << 'EOF'
#!/bin/bash

# LaTeX Auto-Compiler with File Watching - macOS Version
# This script watches for changes to .tex files and automatically recompiles them

# Configuration
TEX_FILE="homework_template.tex"  # Change this to your main .tex file
LATEX_CMD="pdflatex --shell-escape -synctex=1 -interaction=nonstopmode -file-line-error"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 LaTeX Auto-Compiler Started (macOS)${NC}"
echo -e "${YELLOW}📁 Watching directory: $(pwd)${NC}"
echo -e "${YELLOW}📄 Main file: $TEX_FILE${NC}"
echo -e "${YELLOW}🔧 Command: $LATEX_CMD${NC}"
echo -e "${GREEN}💡 Press Ctrl+C to stop watching${NC}"
echo ""

# Function to compile LaTeX
compile_latex() {
    echo -e "${YELLOW}🔄 Compiling $TEX_FILE...${NC}"
    
    if $LATEX_CMD "$TEX_FILE"; then
        echo -e "${GREEN}✅ Compilation successful!${NC}"
        echo -e "${GREEN}📄 PDF updated: ${TEX_FILE%.tex}.pdf${NC}"
    else
        echo -e "${RED}❌ Compilation failed! Check the log for errors.${NC}"
    fi
    echo ""
}

# Initial compilation
compile_latex

# Watch for changes using fswatch
echo -e "${GREEN}👀 Watching for file changes...${NC}"
echo ""

fswatch -o . | while read num; do
    # Check if any .tex files have changed
    if [[ $(find . -name "*.tex" -newer .last_compile 2>/dev/null) ]]; then
        echo -e "${YELLOW}📝 Detected change in .tex file${NC}"
        compile_latex
        touch .last_compile
    fi
done
EOF

    chmod +x watch_latex_mac.sh
    print_success "Created macOS watch script: watch_latex_mac.sh"
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
    
    # Check fswatch
    if command_exists fswatch; then
        print_success "fswatch: available"
    else
        print_error "fswatch not found"
        ((errors++))
    fi
    
    # Check brew
    if command_exists brew; then
        print_success "brew: $(brew --version | head -1)"
    else
        print_error "brew not found"
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
    echo -e "${BLUE}  macOS Installer                    ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo
    
    # Pre-installation checks
    check_root
    detect_macos
    check_internet
    
    # Installation steps
    install_homebrew
    install_mactex
    install_python_pygments
    install_file_watching
    install_bibliography
    install_additional_packages
    create_mac_watch_script
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
        echo "  1. Restart your terminal to ensure PATH is updated"
        echo "  2. Edit homework_template.tex with your content"
        echo "  3. Compile with: pdflatex --shell-escape homework_template.tex"
        echo "  4. Or use auto-compilation: ./watch_latex_mac.sh"
        echo
        print_status "Note: You may need to restart your terminal for PATH changes to take effect."
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