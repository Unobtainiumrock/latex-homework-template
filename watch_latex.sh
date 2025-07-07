#!/bin/bash

# LaTeX Auto-Compiler with File Watching
# This script watches for changes to .tex files and automatically recompiles them

# Configuration
TEX_FILE="homework_template.tex"  # Change this to your main .tex file
LATEX_CMD="pdflatex --shell-escape -synctex=1 -interaction=nonstopmode -file-line-error"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 LaTeX Auto-Compiler Started${NC}"
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

# Watch for changes
echo -e "${GREEN}👀 Watching for file changes...${NC}"
echo ""

inotifywait -m -e close_write,moved_to,create,modify . --format '%w%f %e' |
while read file event; do
    # Check if the file is a .tex file
    if [[ "$file" == *.tex ]]; then
        echo -e "${YELLOW}📝 Detected change in: $file${NC}"
        # Small delay to ensure file is fully written
        sleep 0.5
        compile_latex
    fi
done 