### _____________________________________________________________________________________________________________
###
###                                       VIRTUAL MACHINCE - QEMU-KVM
### _____________________________________________________________________________________________________________

#(https://computingforgeeks.com/install-kvm-qemu-virt-manager-arch-manjar/)
#(https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/)
#(https://www.youtube.com/watch?v=BUSrdUoedTo)
#(https://www.youtube.com/watch?v=3yhwJxWSqXI)

#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local COLOR=$1
    local MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${NC}"
}

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

# Call the function
update_grub_iommu

sudo pacman -S dmidecode
sudo pacman -Syy
sudo reboot
sudo pacman -S archlinux-keyring
sudo pacman -S qemu libvirt virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat libguestfs edk2-ovmf vfio
sudo pacman -S ebtables iptables    # Yes

sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo systemctl enable virtlogd.socket
sudo systemctl start virtlogd.socket

sudo systemctl status libvirtd.service

sudo virsh net-autostart default
sudo virsh net-start default

sudo nano /etc/libvirt/libvirtd.conf

# Set the UNIX domain socket group ownership to libvirt, (around line 85)
    unix_sock_group = "libvirt"
# Set the UNIX socket permissions for the R/W socket (around line 102)
    unix_sock_rw_perms = "0770"

sudo usermod -a -G libvirt $(whoami)
newgrp libvirt

sudo systemctl restart libvirtd.service

# PRELOAD vfio
sudo nano /etc/mkinitcpio.conf
MODULES=(vfio_pci vfio vfio_iommu_type1 vfio_virqfd)

### _____________________________________________________________________________________________________________
###
###                             CPU PINNING (https://youtu.be/WYrTajuYhCk?t=725)
### _____________________________________________________________________________________________________________

lscpu -e    # See the CPU cores


# PASSTHROUGH GPU - (https://www.youtube.com/watch?v=BUSrdUoedTo | https://www.youtube.com/watch?v=WYrTajuYhCk | https://www.youtube.com/watch?v=3yhwJxWSqXI)
sudo pacman -S tree


https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/
https://github.com/joeknock90/Single-GPU-Passthrough
https://www.reddit.com/r/VFIO/

# PATCHED BIOS
https://www.techpowerup.com/vgabios/192500/asus-rx580-8192-170328



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

# VirtualBox 6.1.28 Oracle VM VirtualBox Extension Pack (https://www.virtualbox.org/wiki/Downloads)
    All supported platforms # Download to your ~/ folder
virtualbox
# Open VirtualBox >> Preferences & Extensions >> Choose the Extension file and install it.
