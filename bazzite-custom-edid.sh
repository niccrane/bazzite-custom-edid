#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --- Initialise Vars --- 
EDID_FILE=""
DO_INSTALL=false
DO_UNINSTALL=false

# --- Parse options safely ---
while getopts ":iu:f:h" opt; do
  case $opt in
    f) EDID_FILE="$OPTARG" ;;
    i) DO_INSTALL=true ;;
    u) DO_UNINSTALL=true ;;
    h) usage ;;
    \?) echo "Error: Invalid option -$OPTARG" >&2; usage ;;
    :)  echo "Error: Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done
shift $((OPTIND -1))


usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -i            Install custom EDID
  -u            Uninstall custom EDID
  -f EDID_FILE  Input bin file
  -h            Show this help and exit

Examples:
  $0 -f edid.bin
EOF
  exit 1
}


install() { 
  echo "EDID_FILE is: '$1'"
  
  # Install nfpm:
  brew install nfpm

  # Generate nfpm.yaml
  FILENAME="${1%.*}"
  echo $FILENAME
  EDID_FILE=$1
  cat > nfpm.yaml <<EOF
name: "$FILENAME-edid"
arch: "all"
platform: "linux"
version: "1.0.0"
section: "misc"
priority: "extra"
maintainer: "$USER"
description: |
  Custom EDID firmware file.
vendor: "$USER"
license: "GPL-2.0"
rpm:
  summary: "EDID firmware file"
contents:
  - src: $EDID_FILE
    dst: /usr/lib/firmware/edid/$EDID_FILE
EOF

  # Make and install the rpm package from the bin:
  nfpm pkg --packager rpm --config nfpm.yaml
  rpm-ostree install $FILENAME-edid-1.0.0-1.noarch.rpm

  # Update initramfs:
  echo 'install_items+=" /usr/lib/firmware/edid/$EDID_NAME "' | sudo tee /etc/dracut.conf.d/99-edid.conf
  rpm-ostree initramfs --enable

  # Add the kernel argument
  rpm-ostree kargs --append=drm.edid_firmware=edid/$EDID_NAME.

  return 0
}


uninstall() {
  exit
  FILENAME="${$1%.*}"
  rpm-ostree uninstall $FILENAME-edid-1.0.0-1.noarch
  sudo rm -rf /etc/dracut.conf.d/99-edid.conf
  rpm-ostree initramfs --disable
  brew uninstall nfpm

  return 0
}


# --- Validate required arguments ---
# Check that either -i or -u is set, but not both
if [[ "$DO_INSTALL" == false && "$DO_UNINSTALL" == false ]]; then
    echo "Error: You must specify either -i (install) or -u (uninstall)." >&2
    usage
    exit 1
fi

# Optionally enforce mutually exclusive
if [[ "$DO_INSTALL" == true && "$DO_UNINSTALL" == true ]]; then
    echo "Error: Cannot specify both -i and -u at the same time." >&2
    usage
    exit 1
fi

# Check that -f is provided
if [[ -z "${EDID_FILE}" ]]; then
    echo "Error: -f <EDID file> is required with -i or -u." >&2
    usage
    exit 1
fi

# Check that EDID_FILE exists, but only for install
if [[ "$DO_INSTALL" == true && ! -f "$EDID_FILE" ]]; then
    echo "Error: EDID file '$EDID_FILE' does not exist." >&2
    usage
    exit 1
fi


# --- Now we run ---
if [[ ${DO_INSTALL:-false} == true ]]; then
  echo "Installing custom EDID file..."
  install "$EDID_FILE"
  if [[ $? -eq 0 ]]; then
    echo "Installation succeeded, reboot for changes to take affect"
    exit -0
  else
    echo "Installation failed"
    exit -1
  fi
fi

if [[ ${DO_UNINSTALL:-false} == true ]]; then
  echo "Uninstalling custom EDID file..."
  uninstall "$EDID_FILE"
  if [[ $? -eq 0 ]]; then
    echo "Uninstallation succeeded, reboot for changes to take affect"
    exit -0
  else
    echo "Uninstallation failed"
    exit -1
  fi
fi

exit -0 