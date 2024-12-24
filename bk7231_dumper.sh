#!/bin/bash

# Define the virtual environment directory
VENV_DIR="venv"


if ["$1" == ""];then
    echo
    echo "Usage: bk7231_dumper.sh <Folder name> <Device name>"
    echo
    exit 1
fi


# Check if the virtual environment exists, and create it if not
if [ ! -d "$VENV_DIR" ]; then
  echo "Virtual environment not found. Creating one..."
  echo
  python3 -m venv "$VENV_DIR"
fi

# Activate the virtual environment
echo "Activating the virtual environment..."
echo
source "$VENV_DIR/bin/activate"

# Check if 'bk7231tools' is installed
if ! pip show bk7231tools > /dev/null 2>&1; then
  echo "bk7231tools is not installed. Installing now..."
  echo
  pip install bk7231tools[cli]
else
  echo "bk7231tools is already installed."
  echo
fi

echo "Virtual environment is now active. You can use 'bk7231tools'."
echo
echo "Run 'exit' when you're done."


# Creating a directory if it not exists
if [ ! -d "$1" ];then
  mkdir "$1"
fi

# Dumping Flash
if [ ! -f $1/$1.dump ];then
  bk7231tools read_flash $1/$1.dump -d $2 --no-verify-checksum -b 921600 --timeout 30
fi

if [ ! -f $1/$1.dump ];then
  echo "Nothing dumped :("
  exit
fi

# Remove previous files 
for f in $1/*bin $1/*cpr $1/*out ;do
  rm $f
done

# Extracting from Dump
mkdir $1/dissected_dump
bk7231tools dissect_dump $1/$1.dump -e -O $1/dissected_dump/

rm $2/dissected_dump/*cpr
rm $2/dissected_dump/*out
ls -la $2/dissected_dump/

binwalk $2/dissected_dump/$2_bootloader_1.00_decrypted.bin
binwalk $2/dissected_dump/$2_app_1.00_decrypted.bin











# To maintain the virtual env shell
$SHELL