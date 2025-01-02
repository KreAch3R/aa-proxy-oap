# Build dummy_hcd

1. Git clone the repository:  https://github.com/xairy/raw-gadget

2. Go into `dummy_hcd` subdirectory

3. Follow these instructions: https://github.com/xairy/raw-gadget/tree/master/dummy_hcd

4. Raspberry Pi linux headers should be already installed. In case they aren't, use:
```
sudo apt-get install raspberrypi-kernel-headers
```

5. In my case, I needed to include two patches so that the above source code can be built. Also check [update.sh](https://github.com/xairy/raw-gadget/blob/master/dummy_hcd/update.sh) for more info on that. 

```
# This patch is needed in case the kernel you're building against doesn't have
# commit 7dc0c55e9f30 ("USB: UDC core: Add udc_async_callbacks gadget op").
# git apply ./patches/dummy_udc_async_callbacks.patch

# This patch is needed in case the kernel you're building against doesn't have
# commit 2dd3f64fcc11 ("usb: gadget/dummy_hcd: Convert to platform remove
# callback returning void").
# git apply ./patches/dummy_driver_remove_new.patch
```

6. and build with `make` or use my pre-built one from `aa-proxy-oap/lib/modules/UNAME-R/kernel/drivers/dummy_hcd.ko` and install with:
```
sudo cp dummy_hcd.ko /lib/modules/$(uname -r)/kernel/drivers/
```

7. Then update the module list:
```
sudo depmod
```

# Result

After reboot, you can check if the module is loaded correctly with: 
```
pi@raspberrypi:~ $ lsmod | grep dummy
dummy_hcd              32768  0
```

**OR**

```
pi@raspberrypi:~ $ ls -l /sys/class/udc
total 0
lrwxrwxrwx 1 root root 0 Feb 14  2019 dummy_udc.0 -> ../../devices/platform/dummy_udc.0/udc/dummy_udc.0
```