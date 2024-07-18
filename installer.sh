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
APPLICATION="hypervisor"
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

# Function to update /etc/mkinitcpio.conf with additional modules
update_mkinitcpio_conf() {
    MODULES_TO_ADD="vfio_pci vfio vfio_iommu_type1 vfio_virqfd"
    MKINITCPIO_CONF="/etc/mkinitcpio.conf"

    # Backup the original file
    print_message "$PURPLE" "Backing up the original $MKINITCPIO_CONF..."
    cp "$MKINITCPIO_CONF" "$MKINITCPIO_CONF.bak"

    # Check if backup was successful
    if [[ $? -ne 0 ]]; then
        print_message "$RED" "Backup failed. Exiting."
        exit 1
    fi

    print_message "$PURPLE" "Modifying $MKINITCPIO_CONF..."
    # Use sed to add the modules to the MODULES=() line, ensuring existing entries are preserved
    sed -i "/^MODULES=/ s/(\(.*\))/(\1 $MODULES_TO_ADD)/" "$MKINITCPIO_CONF"

    # Check if sed command was successful
    if [[ $? -ne 0 ]]; then
        print_message "$RED" "Failed to update $MKINITCPIO_CONF. Exiting."
        exit 1
    fi

    print_message "$GREEN" "MODULES in $MKINITCPIO_CONF updated successfully."
}

# Function to ask if the user wants to install VirtualBox alongside QEMU/KVM
check_install_virtualbox() {
    read -p "$(print_message "${CYAN}" "Do you want to install VirtualBox alongside QEMU/KVM? (y/n): ")" install_choice
    if [[ "$install_choice" == "y" ]]; then
        echo "\"pacman\" \"virtualbox\" # Virtual Machine Manager" >> "$HOME/bash.vmhost/files/packages.txt"
        print_message "${GREEN}" "Added VirtualBox to packages.txt."
    else
        print_message "${YELLOW}" "Skipped adding VirtualBox to packages.txt."
    fi
}

# Function to check if VirtualBox is installed
check_virtualbox_installed() {
    if command -v virtualbox &> /dev/null; then
        print_message "${GREEN}" "VirtualBox is installed. Proceeding with configuration..."
        configure_virtualbox
    else
        print_message "${RED}" "VirtualBox is not installed. Skipping configuration."
    fi
}

# Function to configure VirtualBox and install the extension pack
configure_virtualbox() {
    # Load the VirtualBox kernel module
    print_message "${CYAN}" "Loading VirtualBox kernel module..."
    sudo modprobe vboxdrv

    # Start and exit VirtualBox to initialize necessary settings
    print_message "${CYAN}" "Starting and exiting VirtualBox to initialize settings..."
    virtualbox & sleep 5 && pkill virtualbox

    # Create and configure the modules-load.d file for VirtualBox
    print_message "${CYAN}" "Creating configuration file for VirtualBox kernel module..."
    echo "vboxdrv" | sudo tee /etc/modules-load.d/virtualbox.conf

    # Add the current user to the vboxusers group
    print_message "${CYAN}" "Adding the current user to the vboxusers group..."
    sudo usermod -aG vboxusers "$USER"

    # Check if the vboxdrv module is loaded
    print_message "${CYAN}" "Checking if the vboxdrv module is loaded..."
    sudo lsmod | grep vboxdrv

    # Download the latest version of the VirtualBox Extension Pack
    print_message "${CYAN}" "Downloading the latest version of the VirtualBox Extension Pack..."
    extension_pack_url=$(curl -s https://www.virtualbox.org/wiki/Downloads | grep -oP 'https://download.virtualbox.org/virtualbox/\d+\.\d+\.\d+/Oracle_VM_VirtualBox_Extension_Pack-\d+\.\d+\.\d+\.vbox-extpack' | head -n 1)
    extension_pack_path="$HOME/Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack"
    curl -L -o "$extension_pack_path" "$extension_pack_url"
    print_message "${GREEN}" "Downloaded the VirtualBox Extension Pack to $extension_pack_path."

    # Install the Extension Pack
    print_message "${CYAN}" "Installing the VirtualBox Extension Pack..."
    sudo VBoxManage extpack install --replace "$extension_pack_path"
    print_message "${GREEN}" "Installed the VirtualBox Extension Pack."

    # Cleanup
    print_message "${CYAN}" "Cleaning up the downloaded Extension Pack file..."
    rm "$extension_pack_path"
    print_message "${GREEN}" "Cleaned up the downloaded Extension Pack file."

    print_message "${PURPLE}" "VirtualBox is now configured with the latest Extension Pack."
}

packages_txt() {
    # Check if $HOME/bash directory exists, if not create it
    if [ ! -d "$HOME/bash" ]; then
        mkdir -p "$HOME/bash"
        print_message "$GREEN" "Created directory: $HOME/bash"
    fi
    
    # Check if $HOME/bash.pkmgr exists, delete it if it does
    if [ -d "$HOME/bash.pkmgr" ]; then
        print_message "$YELLOW" "Removing existing $HOME/bash.pkmgr"
        rm -rf "$HOME/bash.pkmgr"
    fi
    
    # Copy ../files/packages.txt to /home/user/bash
    cp "$APP_LIST" "$BASH"
    print_message "$CYAN" "Copied $APP_LIST to $BASH"
    
    # Get the Package Manager & Package Installer
    git clone https://github.com/Querzion/bash.pkmgr.git "$HOME/bash.pkmgr"
    chmod +x -R "$HOME/bash.pkmgr"
    sh "$HOME/bash.pkmgr/installer.sh"
    
    print_message "$GREEN" "Applications installed successfully."
}

################################################################################################## MAIN LOGIC

# Call the function
update_grub_iommu

# Main script execution
check_install_virtualbox

# Install applications from packages.txt
packages_txt

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
update_mkinitcpio_conf

check_virtualbox_installed

print_message "${PURPLE}" "THE VMHOST INSTALLATION IS COMPLETE."
