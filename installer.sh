### _____________________________________________________________________________________________________________
###
###                                       VIRTUAL MACHINCE - QEMU-KVM
### _____________________________________________________________________________________________________________

#(https://computingforgeeks.com/install-kvm-qemu-virt-manager-arch-manjar/)
#(https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/)
#(https://www.youtube.com/watch?v=BUSrdUoedTo)
#(https://www.youtube.com/watch?v=3yhwJxWSqXI)

#!/bin/bash

############ COLOURED BASH TEXT

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


################################################################################################## FILE & FOLDER PATHS

# Location
APPLICATION="vmhost"
BASE="$HOME/bash.$APPLICATION"
FILES="$BASE/files"
APP_LIST="$FILES/packages.txt"

# Pre-Configuration
BASH="$HOME/order_66"
mkdir -p $BASH
cp $APP_LIST $BASH


################################################################################################## PRINT MESSAGE

# Function to print colored messages
print_message() {
    local COLOR=$1
    local MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${NC}"
}


################################################################################################## INSTALLATION FUNCTIONS

# Function to update GRUB with IOMMU settings based on GPU type
update_grub_iommu() {
    print_message "$CYAN" "Detecting GPU type..."
    GPU=$(lspci | grep -i 'vga' | grep -E 'AMD|NVIDIA|Intel')

    if [[ $GPU == *"AMD"* ]]; then
        IOMMU="iommu=1 amd_iommu=on"
        print_message "$GREEN" "AMD GPU detected."
    elif [[ $GPU == *"NVIDIA"* ]]; then
        IOMMU="iommu=1 nvidia_iommu=on"
        print_message "$GREEN" "NVIDIA GPU detected."
    elif [[ $GPU == *"Intel"* ]]; then
        IOMMU="iommu=1 intel_iommu=on"
        print_message "$GREEN" "Intel GPU detected."
    else
        print_message "$RED" "No supported GPU found."
        exit 1
    fi

    # File to edit
    GRUB_FILE="/etc/default/grub"

    # Backup the original file
    print_message "$PURPLE" "Backing up the original $GRUB_FILE..."
    cp "$GRUB_FILE" "$GRUB_FILE.bak"

    # Check if backup was successful
    if [[ $? -ne 0 ]]; then
        print_message "$RED" "Backup failed. Exiting."
        exit 1
    fi

    print_message "$PURPLE" "Modifying $GRUB_FILE..."
    # Use sed to append the IOMMU settings after 'quiet' in the 'GRUB_CMDLINE_LINUX_DEFAULT' line
    sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/s/quiet/& $IOMMU/" "$GRUB_FILE"

    # Check if sed command was successful
    if [[ $? -ne 0 ]]; then
        print_message "$RED" "Failed to update $GRUB_FILE. Exiting."
        exit 1
    fi

    print_message "$PURPLE" "Updating GRUB configuration..."
    update-grub

    # Check if update-grub command was successful
    if [[ $? -ne 0 ]]; then
        print_message "$RED" "Failed to update GRUB. Exiting."
        exit 1
    fi

    print_message "$GREEN" "GRUB_CMDLINE_LINUX_DEFAULT updated successfully. Please reboot your system."
}

uncomment_and_change_libvirt_conf() {
    # Path to the configuration file
    local config_file="/etc/libvirt/libvirtd.conf"

    # Ensure the file exists
    if [[ ! -f "$config_file" ]]; then
        print_message "$RED" "Configuration file not found: $config_file"
        return 1
    fi

    # Uncomment and change the lines using sed
    sed -i 's/#\s*\(unix_sock_group\s*=\s*"\).*\("\)/\1libvirt\2/' "$config_file"
    sed -i 's/#\s*\(unix_sock_rw_perms\s*=\s*"\).*\("\)/\10770\2/' "$config_file"

    # Verify the changes
    grep -E 'unix_sock_group\s*=\s*"libvirt"' "$config_file" && print_message "$GREEN" "unix_sock_group set to libvirt"
    grep -E 'unix_sock_rw_perms\s*=\s*"0770"' "$config_file" && print_message "$GREEN" "unix_sock_rw_perms set to 0770"
}


################################################################################################## MAIN LOGIC

# Call the function
update_grub_iommu

# Copy the ../files/packages.txt to /home/user/bash
cp $APP_LIST $BASH

# Get the Package Manager & Package Installer (Need it for the ../files/package.txt file)
git clone https://github.com/Querzion/bash.pkmgr.git $HOME
chmod +x -r $HOME/bash.pkmgr
sh $HOME/bash.pkmgr/start.sh

sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo systemctl enable virtlogd.socket
sudo systemctl start virtlogd.socket

sudo systemctl status libvirtd.service

sudo virsh net-autostart default
sudo virsh net-start default

uncomment_and_change_libvirt_conf

sudo usermod -a -G libvirt $(whoami)
newgrp libvirt

sudo systemctl restart libvirtd.service

# PRELOAD vfio
sudo nano /etc/mkinitcpio.conf
MODULES=(vfio_pci vfio vfio_iommu_type1 vfio_virqfd)





### _____________________________________________________________________________________________________________
###
###                                     VIRTUAL MACHINE - VIRTUALBOX
### _____________________________________________________________________________________________________________

(https://linuxhint.com/install-virtualbox-arch-linux/)

sudo pacman -Syu
sudo pacman -S virtualbox
# choose 2 and enter
sudo modprobe vboxdrv
virtualbox # Start and Exit
sudo nano /etc/modules-load.d/virtualbox.conf # Create the file!
    vboxdrv # Save & Exit
sudo usermod -aG vboxusers querzion
sudo lsmod | grep vboxdrv

# VirtualBox Oracle VM VirtualBox Extension Pack (https://www.virtualbox.org/wiki/Downloads)
    All supported platforms # Download to your ~/ folder
virtualbox
# Open VirtualBox >> Preferences & Extensions >> Choose the Extension file and install it.
