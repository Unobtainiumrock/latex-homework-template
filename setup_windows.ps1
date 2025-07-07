# LaTeX Homework Template - Windows Setup Script
# This script installs all required dependencies for Windows systems
# Run this script as Administrator in PowerShell

param(
    [switch]$SkipChocoInstall = $false,
    [switch]$Help = $false
)

# Colors for output (PowerShell 5.1+ compatible)
$colors = @{
    Red = 'Red'
    Green = 'Green'
    Yellow = 'Yellow'
    Blue = 'Blue'
    White = 'White'
}

# Functions for colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $colors.Red
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Test-InternetConnection {
    Write-Status "Checking internet connection..."
    try {
        $ping = Test-Connection -ComputerName "google.com" -Count 1 -Quiet
        if ($ping) {
            Write-Success "Internet connection verified"
            return $true
        } else {
            Write-Error "No internet connection detected"
            return $false
        }
    } catch {
        Write-Error "Failed to test internet connection"
        return $false
    }
}

function Install-Chocolatey {
    Write-Status "Checking for Chocolatey..."
    
    if (Test-CommandExists "choco") {
        Write-Success "Chocolatey already installed"
        Write-Status "Updating Chocolatey..."
        choco upgrade chocolatey -y
    } else {
        Write-Status "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        if (Test-CommandExists "choco") {
            Write-Success "Chocolatey installed successfully"
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } else {
            Write-Error "Failed to install Chocolatey"
            exit 1
        }
    }
}

function Install-MiKTeX {
    Write-Status "Installing MiKTeX (this may take a while - ~2GB download)..."
    
    if (Test-CommandExists "pdflatex") {
        Write-Warning "LaTeX appears to be already installed. Checking version..."
        pdflatex --version | Select-Object -First 1
        
        $response = Read-Host "Do you want to reinstall/upgrade MiKTeX? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-Status "Skipping MiKTeX installation"
            return
        }
    }
    
    try {
        choco install miktex -y
        Write-Success "MiKTeX installed successfully"
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Initialize MiKTeX
        Write-Status "Initializing MiKTeX..."
        if (Test-CommandExists "miktex") {
            # Set MiKTeX to install packages on the fly
            miktex packages --set-repository="https://miktex.org/pkg/miktex/tm/packages/"
            miktex packages --update-db
        }
    } catch {
        Write-Error "Failed to install MiKTeX via Chocolatey"
        Write-Status "Please install MiKTeX manually from: https://miktex.org/download"
        Write-Status "Make sure to select 'Install packages on-the-fly' during installation"
        
        Read-Host "Press Enter after installing MiKTeX manually, or Ctrl+C to exit"
        
        if (-not (Test-CommandExists "pdflatex")) {
            Write-Error "pdflatex still not found. Please ensure MiKTeX is properly installed."
            exit 1
        }
    }
}

function Install-PythonAndPygments {
    Write-Status "Installing Python and Pygments..."
    
    # Install Python
    if (-not (Test-CommandExists "python")) {
        try {
            choco install python -y
            Write-Success "Python installed successfully"
            
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-Error "Failed to install Python"
            Write-Status "Please install Python manually from: https://www.python.org/downloads/"
            Write-Status "Make sure to check 'Add Python to PATH' during installation"
            
            Read-Host "Press Enter after installing Python manually, or Ctrl+C to exit"
            
            if (-not (Test-CommandExists "python")) {
                Write-Error "Python still not found. Please ensure Python is properly installed."
                exit 1
            }
        }
    } else {
        Write-Success "Python already installed"
    }
    
    # Install Pygments
    Write-Status "Installing Pygments..."
    try {
        python -m pip install --upgrade pip
        python -m pip install pygments
        Write-Success "Pygments installed successfully"
    } catch {
        Write-Error "Failed to install Pygments"
        exit 1
    }
    
    # Verify pygments installation
    if (Test-CommandExists "pygmentize") {
        Write-Success "Pygments verification: $(pygmentize -V)"
    } else {
        Write-Warning "Pygments not found in PATH. Trying alternative..."
        try {
            $pygmentizeVersion = python -c "import pygments; print(f'Pygments, version {pygments.__version__}')"
            Write-Success "Pygments verification: $pygmentizeVersion"
        } catch {
            Write-Error "Failed to verify Pygments installation"
            exit 1
        }
    }
}

function Install-FileWatching {
    Write-Status "Installing file watching tools..."
    
    # Install watchdog for Python-based file watching
    try {
        python -m pip install watchdog
        Write-Success "File watching tools (watchdog) installed successfully"
    } catch {
        Write-Error "Failed to install file watching tools"
        exit 1
    }
}

function Install-AdditionalPackages {
    Write-Status "Installing additional useful packages..."
    
    # Install git if not present
    if (-not (Test-CommandExists "git")) {
        try {
            choco install git -y
            Write-Success "Git installed successfully"
        } catch {
            Write-Warning "Failed to install Git via Chocolatey"
        }
    }
    
    # Install 7zip (useful for handling archives)
    try {
        choco install 7zip -y
        Write-Success "7zip installed successfully"
    } catch {
        Write-Warning "Failed to install 7zip"
    }
    
    Write-Success "Additional packages installation completed"
}

function Create-WindowsWatchScript {
    Write-Status "Creating Windows file watching script..."
    
    $watchScriptContent = @'
# LaTeX Auto-Compiler with File Watching - Windows Version
# This script watches for changes to .tex files and automatically recompiles them

param(
    [string]$TexFile = "homework_template.tex"
)

# Configuration
$LATEX_CMD = "pdflatex --shell-escape -synctex=1 -interaction=nonstopmode -file-line-error"

Write-Host "LaTeX Auto-Compiler Started (Windows)" -ForegroundColor Green
Write-Host "Watching directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host "Main file: $TexFile" -ForegroundColor Yellow
Write-Host "Command: $LATEX_CMD" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop watching" -ForegroundColor Green
Write-Host ""

# Function to compile LaTeX
function Compile-LaTeX {
    param([string]$File)
    
    Write-Host "Compiling $File..." -ForegroundColor Yellow
    
    $process = Start-Process -FilePath "cmd" -ArgumentList "/c $LATEX_CMD `"$File`"" -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Compilation successful!" -ForegroundColor Green
        Write-Host "PDF updated: $($File.Replace('.tex', '.pdf'))" -ForegroundColor Green
    } else {
        Write-Host "Compilation failed! Check the log for errors." -ForegroundColor Red
    }
    Write-Host ""
}

# Initial compilation
if (Test-Path $TexFile) {
    Compile-LaTeX -File $TexFile
} else {
    Write-Host "Warning: $TexFile not found!" -ForegroundColor Yellow
}

# Watch for changes
Write-Host "Watching for file changes..." -ForegroundColor Green
Write-Host ""

# Use FileSystemWatcher for watching
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = Get-Location
$watcher.Filter = "*.tex"
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $true

# Register event handler
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
    $path = $Event.SourceEventArgs.FullPath
    $filename = Split-Path $path -Leaf
    
    # Add a small delay to ensure file is fully written
    Start-Sleep -Milliseconds 500
    
    Write-Host "Detected change in: $filename" -ForegroundColor Yellow
    Compile-LaTeX -File $filename
}

# Keep the script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Clean up
    $watcher.Dispose()
}
'@

    $watchScriptContent | Out-File -FilePath "watch_latex_windows.ps1" -Encoding UTF8
    Write-Success "Created Windows watch script: watch_latex_windows.ps1"
}

function Setup-Directories {
    Write-Status "Setting up directory structure..."
    
    # Create assets directory if it doesn't exist
    if (-not (Test-Path "assets")) {
        New-Item -ItemType Directory -Path "assets" | Out-Null
        Write-Success "Created assets directory"
    }
    
    # Create a sample bibliography file if it doesn't exist
    if (-not (Test-Path "references.bib")) {
        $bibContent = @'
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
'@
        $bibContent | Out-File -FilePath "references.bib" -Encoding UTF8
        Write-Success "Created sample references.bib file"
    }
}

function Test-Installation {
    Write-Status "Verifying installation..."
    
    $errors = 0
    
    # Check pdflatex
    if (Test-CommandExists "pdflatex") {
        $version = pdflatex --version | Select-Object -First 1
        Write-Success "pdflatex: $version"
    } else {
        Write-Error "pdflatex not found"
        $errors++
    }
    
    # Check python
    if (Test-CommandExists "python") {
        $version = python --version
        Write-Success "python: $version"
    } else {
        Write-Error "python not found"
        $errors++
    }
    
    # Check pygments
    try {
        $pygmentsVersion = python -c "import pygments; print(f'Pygments, version {pygments.__version__}')"
        Write-Success "pygments: $pygmentsVersion"
    } catch {
        Write-Error "pygments not found or not working"
        $errors++
    }
    
    # Check choco
    if (Test-CommandExists "choco") {
        $version = choco --version | Select-Object -First 1
        Write-Success "choco: $version"
    } else {
        Write-Error "choco not found"
        $errors++
    }
    
    if ($errors -eq 0) {
        Write-Success "All components verified successfully!"
        return $true
    } else {
        Write-Error "Verification failed with $errors errors"
        return $false
    }
}

function Test-Compilation {
    Write-Status "Testing LaTeX compilation..."
    
    if (Test-Path "homework_template.tex") {
        Write-Status "Compiling homework_template.tex..."
        
        $process = Start-Process -FilePath "pdflatex" -ArgumentList "--shell-escape -interaction=nonstopmode homework_template.tex" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Test compilation successful!"
            Write-Success "PDF created: homework_template.pdf"
            
            # Clean up auxiliary files
            $auxFiles = @("homework_template.aux", "homework_template.log", "homework_template.out", "homework_template.synctex.gz")
            foreach ($file in $auxFiles) {
                if (Test-Path $file) {
                    Remove-Item $file -Force
                }
            }
        } else {
            Write-Warning "Test compilation failed. Check homework_template.log for details."
        }
    } else {
        Write-Warning "homework_template.tex not found. Skipping compilation test."
    }
}

function Show-Help {
    Write-Host ""
    Write-Host "LaTeX Homework Template - Windows Setup Script" -ForegroundColor Blue
    Write-Host "=============================================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Usage: .\setup_windows.ps1 [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -SkipChocoInstall    Skip Chocolatey installation" -ForegroundColor Yellow
    Write-Host "  -Help               Show this help message" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor White
    Write-Host "  - Run as Administrator" -ForegroundColor Yellow
    Write-Host "  - PowerShell 5.1 or later" -ForegroundColor Yellow
    Write-Host "  - Internet connection" -ForegroundColor Yellow
    Write-Host ""
}

# Main function
function Main {
    if ($Help) {
        Show-Help
        return
    }

    Write-Host "======================================" -ForegroundColor Blue
    Write-Host "  LaTeX Homework Template Setup      " -ForegroundColor Blue
    Write-Host "  Windows Installer                  " -ForegroundColor Blue
    Write-Host "======================================" -ForegroundColor Blue
    Write-Host ""
    
    # Pre-installation checks
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        Write-Status "Right-click on PowerShell and select 'Run as Administrator'"
        exit 1
    }
    
    if (-not (Test-InternetConnection)) {
        Write-Error "Internet connection required"
        exit 1
    }
    
    # Set execution policy
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    
    # Installation steps
    if (-not $SkipChocoInstall) {
        Install-Chocolatey
    }
    
    Install-MiKTeX
    Install-PythonAndPygments
    Install-FileWatching
    Install-AdditionalPackages
    Create-WindowsWatchScript
    Setup-Directories
    
    # Refresh environment variables one final time
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Post-installation verification
    Write-Host ""
    Write-Status "Installation completed. Running verification..."
    if (Test-Installation) {
        Test-Compilation
        
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Green
        Write-Host "  Installation Successful!           " -ForegroundColor Green
        Write-Host "======================================" -ForegroundColor Green
        Write-Host ""
        Write-Success "LaTeX homework template is ready to use!"
        Write-Host ""
        Write-Status "Next steps:"
        Write-Host "  1. Restart PowerShell to ensure PATH is updated"
        Write-Host "  2. Edit homework_template.tex with your content"
        Write-Host "  3. Compile with: pdflatex --shell-escape homework_template.tex"
        Write-Host "  4. Or use auto-compilation: .\watch_latex_windows.ps1"
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Red
        Write-Host "  Installation Issues Detected       " -ForegroundColor Red
        Write-Host "======================================" -ForegroundColor Red
        Write-Host ""
        Write-Error "Some components failed verification. Please check the errors above."
        Write-Status "You may need to manually install missing components."
        exit 1
    }
}

# Run main function
Main 