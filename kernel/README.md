# Build 5.10.y kernel for RPI 4B 

32bit armhf Raspbian Buster image

## 1. Check current kernel

###  A. Firstly, we need to check our current kernel `configs`:

```
sudo modprobe configs
sudo cat /proc/config.gz | gunzip > running.config
```

Then grep the `running.config` for the above configs:
```
cat running.config | grep -e CONFIG_CONFIGFS_FS= 
                         -e CONFIG_USB= 
                         -e CONFIG_USB_GADGET= 
                         -e CONFIG_USB_DUMMY_HCD= 
                         -e CONFIG_USB_CONFIGFS= 
                         -e CONFIG_USB_CONFIGFS_F_FS= 
                         -e CONFIG_USB_CONFIGFS_UEVENT= 
                         -e CONFIG_USB_CONFIGFS_F_ACC=
```

### B. Necessary kernel config for USB-GADGET to work (either y or *m and load in /etc/modules*)

```
CONFIG_CONFIGFS_FS=y               # ConfigFS support
CONFIG_USB=y                       # USB support
CONFIG_USB_GADGET=y                # USB gadget framework
CONFIG_USB_DUMMY_HCD=y             # dummy_hcd, our emulated USB host and device
CONFIG_USB_CONFIGFS=y              # composing USB gadgets with ConfigFS
CONFIG_USB_CONFIGFS_F_FS=y         # make FunctionFS a component for creating USB gadgets with ConfigFS
```

**AND**

```
# Add f_accessory function for usb gadget
CONFIG_USB_CONFIGFS_UEVENT=y
CONFIG_USB_CONFIGFS_F_ACC=y
```

Given that you haven't modified your kernel, at least two of the above **required** configs won't be enabled. So, ***we need to build the kernel and add them in.*** 

## 2. Build the kernel 

Used these instructions: https://www.raspberrypi.com/documentation/computers/linux_kernel.html

These **must** be done on target, i.e. on the **Host** system, RPI-4B, in order to build *natively*. 

```
sudo apt install bc bison flex libssl-dev make
git clone --branch rpi-5.10.y https://github.com/raspberrypi/linux
```
Then, you need to apply the necessary patches for the `accessory` function. The two patches included in the repo are for 5.10y raspberry pi 32bit armhf kernel:  


These patches should be able to be applied on top of the `rpi-5.10.y` kernel source, by running:
```
git am < 0001-Backport-and-apply-patches-for-Android-Accessory-mod.patch
git am < 0002-Remove-cyclic-dependency-between-f_accessory-and-lib.patch
```

After applying, continue with building:

```
cd linux
KERNEL=kernel7l
make bcm2711_defconfig
```

Now we edit the `.config` file and add our modifications. At least:
```
# replace lines as necessary or add to the end
CONFIG_USB_CONFIGFS_UEVENT=y
CONFIG_USB_CONFIGFS_F_ACC=y

#change the following line in .config:
CONFIG_LOCALVERSION="-v7l-MY_CUSTOM_KERNEL"
```
Don't leave duplicate lines about the same config. 

and whatever else is missing. Then: 

```
# Run the following command to build a 32-bit kernel:
make -j6 zImage modules dtbs

# install modules
sudo make -j6 modules_install

# For the commands below, the original guide is providing WRONG paths. These are the correct ones
# Install kernel 
sudo cp /boot/$KERNEL.img /boot/$KERNEL-backup.img
sudo cp arch/arm/boot/zImage /boot/$KERNEL.img

# Install .dtb
sudo cp arch/arm/boot/dts/*.dtb /boot/

# install overlays and README
sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/

# Reboot
sudo reboot
```

## 3. Check Result

If everything went as planned, running again the command to check configs should produce something like this: 

```
CONFIG_USB=y
CONFIG_USB_GADGET=y
CONFIG_USB_CONFIGFS=m
CONFIG_USB_CONFIGFS_UEVENT=y
CONFIG_USB_CONFIGFS_F_FS=y
CONFIG_USB_CONFIGFS_F_ACC=y
CONFIG_CONFIGFS_FS=y
```

Notice that `CONFIG_USB_DUMMY_HCD` doesn't exist. It is because it is installed manually at `/lib/modules/$(uname -r)/kernel/drivers/` as [per instructions](https://github.com/KreAch3R/aa-proxy-oap/blob/16f4c7f9a2fe108d42cd9adb5f29aae58695281d/kernel/modules/README.md) after booting into the new freshly compiled kernel. 

For the above output, I should only need to load `libcomposite` and `dummy_hcd` in `/etc/modules`.