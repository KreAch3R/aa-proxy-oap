kernel config (either y or m and load in /etc/modules)
sudo modprobe module

CONFIG_CONFIGFS_FS=y               # ConfigFS support
CONFIG_USB=y                       # USB support
CONFIG_USB_GADGET=y                # USB gadget framework
CONFIG_USB_DUMMY_HCD=y             # dummy_hcd, our emulated USB host and device
CONFIG_USB_CONFIGFS=y              # composing USB gadgets with ConfigFS
CONFIG_USB_CONFIGFS_F_FS=y         # make FunctionFS a component for creating USB gadgets with ConfigFS


REQUIRES RE-BUILD
# Add f_accessory function for usb gadget
CONFIG_USB_CONFIGFS_UEVENT=y
CONFIG_USB_CONFIGFS_F_ACC=y

with two patches for 5.10y raspberry pi 32bit armhf kernel
0001-Backport-and-apply-patches-for-Android-Accessory-mod.patch
0002-Remove-cyclic-dependency-between-f_accessory-and-lib.patch