#!/bin/bash

# LaTeX Auto-Compiler with Cross-Platform File Watching (macOS & Linux)
# This script watches for changes to .tex files and automatically recompiles them.
# It detects the operating system and uses the appropriate file watcher.

# --- Configuration ---
TEX_FILE="homework_template.tex"  # Change this to your main .tex file
LATEX_CMD="pdflatex --shell-escape -synctex=1 -interaction=nonstopmode -file-line-error"

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Utility Functions ---
# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Main Script Functions ---
# Function to compile the LaTeX document
compile_latex() {
    echo -e "${YELLOW}🔄 Compiling $TEX_FILE...${NC}"
    
    # Run the compilation command. The 'if' statement checks the exit code.
    if $LATEX_CMD "$TEX_FILE"; then
        echo -e "${GREEN}✅ Compilation successful!${NC}"
        echo -e "${GREEN}📄 PDF updated: ${TEX_FILE%.tex}.pdf${NC}"
    else
        echo -e "${RED}❌ Compilation failed! Check the log for errors.${NC}"
    fi
    echo ""
}

# --- Script Start ---
echo -e "${GREEN}🔍 LaTeX Auto-Compiler Started${NC}"
echo -e "${YELLOW}📁 Watching directory: $(pwd)${NC}"
echo -e "${YELLOW}📄 Main file: $TEX_FILE${NC}"
echo -e "${YELLOW}🔧 Command: $LATEX_CMD${NC}"
echo -e "${GREEN}💡 Press Ctrl+C to stop watching${NC}"
echo ""

# Perform an initial compilation before starting to watch
compile_latex

# --- OS-Specific File Watching Logic ---
echo -e "${GREEN}👀 Detecting OS and starting file watcher...${NC}"
echo ""

# Check the operating system using uname
OS_TYPE=$(uname)

if [[ "$OS_TYPE" == "Darwin" ]]; then
    # --- macOS Logic (using fswatch) ---
    echo -e "${BLUE}[INFO]${NC} macOS detected. Using fswatch."
    
    if ! command_exists fswatch; then
        echo -e "${RED}[ERROR]${NC} fswatch is not installed."
        echo -e "${YELLOW}[HINT]${NC} Please install it using Homebrew: brew install fswatch"
        exit 1
    fi
    
    # fswatch is more efficient when filtering by extension directly
    fswatch -o -e ".*" -i "\\.tex$" . | while read -r file; do
        echo -e "${YELLOW}📝 Detected change in a .tex file.${NC}"
        # Optional delay to handle rapid saves from some editors
        sleep 0.5
        compile_latex
    done

elif [[ "$OS_TYPE" == "Linux" ]]; then
    # --- Linux Logic (using inotifywait) ---
    echo -e "${BLUE}[INFO]${NC} Linux detected. Using inotifywait."

    if ! command_exists inotifywait; then
        echo -e "${RED}[ERROR]${NC} inotifywait is not installed."
        echo -e "${YELLOW}[HINT]${NC} Please install it via your package manager (e.g., sudo apt-get install inotify-tools)"
        exit 1
    fi

    # The original inotifywait command works well here
    inotifywait -m -e close_write,moved_to,create,modify . --format '%w%f' |
    while read -r file; do
        # Check if the modified file is a .tex file
        if [[ "$file" == *.tex ]]; then
            echo -e "${YELLOW}📝 Detected change in: $file${NC}"
            # Small delay to ensure the file is fully written to disk
            sleep 0.5
            compile_latex
        fi
    done

else
    # --- Unsupported OS ---
    echo -e "${RED}[ERROR]${NC} Unsupported operating system: $OS_TYPE"
    echo "This script currently supports macOS (Darwin) and Linux."
    exit 1
fi
