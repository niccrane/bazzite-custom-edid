# Bazzite OS - Install custom EDID
Simple script to handle the install/uninstall of a custom EDID file for the Bazzite OS.

The script performs the following:
1) Installs [nFPM package manager](https://nfpm.goreleaser.com/) using HomeBrew
2) Generates a nFPM configuration file referencing the given EDID bin
3) Generates the RPM package
4) Installs the package using rpm-ostree
5) Creates Dracut config file to include the bin within initramfs
6) Enables initramfs generation
7) Appends the EDID

## Usage

### Installation
Place your custom EDID file in the same directory as the script and execute installation:

```shell
./bazzite-custom-edid.sh -i -f [YOUR_BIN_FILE]
```

### Uninstallation
The bin file doesn't need to be present for an uninstallation to succeed:

```shell
./bazzite-custom-edid.sh -u -f [YOUR_BIN_FILE]
```