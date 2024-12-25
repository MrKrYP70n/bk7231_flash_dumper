#!/bin/bash

# Define the virtual environment directory
VENV_DIR="venv"

# Define color codes
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# Usage function
usage() {
    echo -e "${YELLOW}Usage: $0 <Folder name> <Device name> [options]${RESET}"
    echo
    echo "Options:"
    echo -e "  ${BLUE}--baud <rate>${RESET}        Set baud rate (default: 921600)"
    echo -e "  ${BLUE}--timeout <seconds>${RESET}  Set timeout (default: 30)"
    echo -e "  ${BLUE}--verbose${RESET}            Enable verbose output (hear all my secrets)"
    echo -e "  ${BLUE}--silent${RESET}             Suppress output (because silence is golden)"
    echo
    exit 1
}

# Parse arguments
BAUD_RATE=921600
TIMEOUT=30
VERBOSE=true
SILENT=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --baud) BAUD_RATE="$2"; shift ;;
        --timeout) TIMEOUT="$2"; shift ;;
        --verbose) VERBOSE=true ;;
        --silent) SILENT=true ;;
        -h|--help) usage ;;
        *) break ;;
    esac
    shift
done

if [ -z "$1" ] || [ -z "$2" ]; then
    usage
fi

FOLDER="$1"
DEVICE="$2"

log() {
    $SILENT || echo -e "$1"
}

# Create virtual environment if needed
if [ ! -d "$VENV_DIR" ]; then
    log "${YELLOW}Creating virtual environment...${RESET}"
    python3 -m venv "$VENV_DIR" || { echo -e "${RED}Failed to create virtual environment.${RESET}"; exit 1; }
fi

# Activate virtual environment
log "${GREEN}Activating virtual environment...${RESET}"
source "$VENV_DIR/bin/activate"

# Install 'bk7231tools' if needed
if ! pip show bk7231tools > /dev/null 2>&1; then
    log "${YELLOW}Installing bk7231tools...${RESET}"
    pip install bk7231tools[cli] || { echo -e "${RED}Failed to install bk7231tools.${RESET}"; exit 1; }
else
    log "${GREEN}'bk7231tools' is already installed.${RESET}"
fi

# Create folder if it doesn't exist
mkdir -p "$FOLDER"

# Dump flash
DUMP_FILE="$FOLDER/$FOLDER.dump"
if [ ! -f "$DUMP_FILE" ]; then
    log "${BLUE}Starting the dumping process... Hold tight! 🕶️${RESET}"
    bk7231tools read_flash "$DUMP_FILE" -d "$DEVICE" --no-verify-checksum -b "$BAUD_RATE" --timeout "$TIMEOUT" || {
        echo -e "${RED}Failed to dump flash.${RESET}";
        exit 1;
    }
fi

if [ ! -f "$DUMP_FILE" ]; then
    echo -e "${RED}Uh-oh! Looks like we dumped... nothing. 😞${RESET}"
    exit 1
fi

# Clean up previous files
log "${YELLOW}Cleaning up previous files...${RESET}"
rm -f "$FOLDER"/*.{bin,cpr,out}

# Dissect dump
DISSECT_DIR="$FOLDER/dissected_dump"
mkdir -p "$DISSECT_DIR"
log "${BLUE}Performing surgery on the dump file... Scalpel, please! 🩺${RESET}"
bk7231tools dissect_dump "$DUMP_FILE" -e -O "$DISSECT_DIR" || {
    echo -e "${RED}Dissection failed! Paging Dr. Debugger. 🏥${RESET}";
    exit 1;
}

# Remove unnecessary files
log "${GREEN}Throwing out the trash... Goodbye, unnecessary files! 🚮${RESET}"
rm -f "$DISSECT_DIR"/*.{cpr,out}

# List files
log "${BLUE}Here's the treasure we found in the dump! 🪙${RESET}"
ls -la "$DISSECT_DIR"

# Analyze with binwalk
log "${BLUE}Let's unleash 'binwalk', the file archaeologist! 🕵️‍♂️${RESET}"

log "${GREEN}Analyzing Bootloader file with binwalk...${RESET}"
binwalk "$DISSECT_DIR/${FOLDER}_bootloader_1.00_decrypted.bin" || {
    echo -e "${RED}Binwalk failed on the bootloader file.${RESET}";
}

log "${GREEN}Analyzing App file with binwalk...${RESET}"
binwalk "$DISSECT_DIR/${FOLDER}_app_1.00_decrypted.bin" || {
    echo -e "${RED}Binwalk failed on the app file.${RESET}";
}

echo
echo -e "${GREEN}All done! Enjoy your freshly dissected files. 🍻${RESET}"
echo -e "${YELLOW}Stay in the virtual environment as long as you'd like. Enter 'exit' to leave. 🚪${RESET}"
# Keep the virtual environment shell
$SHELL

