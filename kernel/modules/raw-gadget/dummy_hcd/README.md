# Build dummy_hcd

Built with these instructions: https://github.com/xairy/raw-gadget/tree/master/dummy_hcd

against 32 bit RPI 4b armhf 5.10.y linux kernel

Needs to be installed at:
```
/lib/modules/$(uname -r)/kernel/drivers/
```

In my case, I needed to include two patches so that the above source code can be built. Follow the [update.sh](https://github.com/xairy/raw-gadget/blob/master/dummy_hcd/update.sh) script for instructions on how to do that. 

You can build your own or use my pre-built one from `aa-proxy-oap/lib/modules/UNAME-R/kernel/drivers/dummy_hcd.ko` and install with:
```
sudo cp dummy_hcd.ko /lib/modules/$(uname -r)/kernel/drivers/
```