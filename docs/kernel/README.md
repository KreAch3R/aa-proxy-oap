# Build 5.10.y kernel for RPI 4 or RPI 3

32bit armhf Raspbian Buster image.

Stock OpenAuto-Pro kernel: 5.10.103  
Target kernel: 5.10.110

## 1. Check current kernel

###  A. Firstly, we need to check our current kernel `configs`:

```
sudo modprobe configs
sudo cat /proc/config.gz | gunzip > running.config
```

Then grep the `running.config` for the above configs:
```
cat running.config | grep -e CONFIG_CONFIGFS_FS= \
                         -e CONFIG_USB= \
                         -e CONFIG_USB_GADGET= \
                         -e CONFIG_USB_DUMMY_HCD= \
                         -e CONFIG_USB_CONFIGFS= \
                         -e CONFIG_USB_CONFIGFS_F_FS= \
                         -e CONFIG_USB_CONFIGFS_UEVENT= \
                         -e CONFIG_USB_CONFIGFS_F_ACC=
```

### B. Necessary kernel config for USB-GADGET and DUMMY_HCD to work

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

These **must** be done on target, i.e. on the **Host** system, RPI-4 or RPI-3, in order to build *natively*. 

```
sudo apt install bc bison flex libssl-dev make
git clone --branch rpi-5.10.y https://github.com/raspberrypi/linux
```

Apply the necessary patches for the `accessory` function, according to your board. The patch(es) should be able to be applied on top of the `rpi-5.10.y` kernel source.

For the Raspberry Pi 4 `bcm2711`, only one is needed:
```
git am < 0001-Backport-and-apply-patches-for-Android-Accessory-mod.patch
```

While for the Raspberry Pi 3 `bcm2709`, both are needed:

```
git am < 0001-Backport-and-apply-patches-for-Android-Accessory-mod.patch
git am < 0002-Remove-cyclic-dependency-between-f_accessory-and-lib.patch
```

After applying, continue with building the correct board. 

For the Raspberry Pi 4 `bcm2711`:

```
cd linux
KERNEL=kernel7l
make bcm2711_defconfig
```

While for the Raspberry Pi 3 `bcm2709`:

```
cd linux
KERNEL=kernel7
make bcm2709_defconfig
```

Now we edit the `.config` file and add our modifications. At least:
```
# change the following line in .config:
CONFIG_LOCALVERSION="-MY_CUSTOM_KERNEL"

# replace lines as necessary (search the file, remove "is not set")
CONFIG_USB_DUMMY_HCD=y
CONFIG_USB_LIBCOMPOSITE=y
CONFIG_USB_CONFIGFS=y
CONFIG_USB_CONFIGFS_UEVENT=y
CONFIG_USB_CONFIGFS_F_ACC=y
```
Don't leave duplicate lines about the same config.

You can also use the pre-created [bcm2711_defconfig](kernel/defconfig/bcm2711_defconfig) or [bcm2709_defconfig](kernel/defconfig/bcm2709_defconfig).

Then:

```
# Run the following command to build a 32-bit kernel:
make -j6 zImage modules dtbs

# install modules
sudo make -j6 modules_install

# For the commands below, the original guide wrongly uses the updated new/64bit paths for older 32bit kernels. Instead, use:
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

## 3. Result

If everything went as planned, remove `running.config` and **recreate** it again. Now, it should contain something like this: 

```
CONFIG_USB=y
CONFIG_USB_GADGET=y
CONFIG_USB_DUMMY_HCD=y
CONFIG_USB_CONFIGFS=y
CONFIG_USB_CONFIGFS_UEVENT=y
CONFIG_USB_CONFIGFS_F_FS=y
CONFIG_USB_CONFIGFS_F_ACC=y
CONFIG_CONFIGFS_FS=y
```

Because we compile `libcomposite`, `usb_configfs` and `dummy_hcd` directly into the kernel, we don't need to modify `/etc/modules`.

After reboot, you can check if the `dummy_udc` controller is running by:

```
pi@raspberrypi:~ $ ls -l /sys/class/udc
total 0
lrwxrwxrwx 1 root root 0 Feb 14  2019 dummy_udc.0 -> ../../devices/platform/dummy_udc.0/udc/dummy_udc.0
```