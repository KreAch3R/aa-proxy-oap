# aa-proxy-oap

**Terms** used:
```
Host/Headunit:              RPI 4B running OpenAuto-Pro
Device/USB Gadget:          RPI 4B running an emulated OTG/USB Gadget device and using dummy_hcd to become a device to itself
aawg/aa-proxy-rs:           The program providing the wired to wireless AA proxy
```

### History

Starting on September 2023, with Android Auto update 12.7+, wireless AA stopped working on OpenAuto-Pro, and produced a black screen. At the same time, the same bug presented on Crankshaft, the original opensource  project that OpenAuto-Pro was based upon, but which never had working wireless AA.

OpenAuto-Pro went out of business, while OpenAuto-Pro and Crankshaft users started debugging the problem. Many found out that by using aftermarket AA wireless dongles, everything worked correctly.

That sent me into a research about opensource AA wireless dongles, and I found the awesome project of [nisargjhaveri/WirelessAndroidAutoDongle](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle). After I tested it successfully using a RPI-zero2w, I wanted to bypass the step of using two separate PIs and started looking for ways of emulating the second pi.

### Feasibility

I came around the awesome blog of Andrzej Pietrasiewicz:
https://www.collabora.com/news-and-blog/blog/2019/06/24/using-dummy-hcd/

There, he explains that using a kernel module named `dummy_hcd` we can emulate a USB UDC controller, so we can create a controller that *accepts connections from itself as if a USB-GADGET DEVICE is connected to it*.

The next step was incorporating the configurations of the `WirelessAndroidAutoDongle` image inside our own Raspbian Buster 32bit version of our RPI 4B pi, which proved to be a big task on its own.

That was because, the OpenAuto-Pro raspbian buster image is based on the 5.10.y rpi kernel (specifically, 5.10.103), while the `AAWirelessDongle` images are built using `buildroot` and are based on far newer kernels. 

That means that the `aawg` binary wasn't able to be installed as-is, because it required far newer *"runtime libraries"* like `libc`. As far as I searched, I couldn't find any way to build `aawg` statically.

Then, another awesome project based on `WirelessAndroidAutoDongle` came to the rescue, [manio/aa-proxy-rs](https://github.com/manio/aa-proxy-rs). This one can be built completely statically!

# How-To DIY

So, to sum up, we need to:

1. Re-build the kernel for our OpenAuto-Pro image, include all the necessary modifications for `usb-gadget` and `dummy_hcd` to work.
2. Build `uMTP-Responder` or use the pre-built binary
3. Build `aa-proxy-rs` statically or use the pre-built binary
4. Install the `kernel`, `uMTP-Responder` and the `bluetooth`, `hostapd`, `dhcpcd`, `dnsmasq` to our **Host** system, alongside the `aa-proxy` folder in `/usr/local/bin` and `systemd` services.

## Build and install the kernel

Instructions: [kernel/README.md](docs/kernel/README.md).


## Build and install `uMTP-Responder`

* This is needed for the `usb-gadget` service to work.  
* Instructions: [uMTP-Responder/README.md](docs/uMTP-Responder/README.md).

## Install all files inside `aa-proxy-oap`

* The file structure of the `aa-proxy-oap` subfolder is following the structure of another project of mine, [navipi-usb-update](https://github.com/KreAch3R/navipi-usb-update).  
Basically, it's a copy-paste mechanism so the folders correspond to the **Host** system root folders and subfolders. It's not necessary to use this mechanism to install the files.

### 1. Bluetooth

* `aa-proxy-rs` is handling the Bluetooth connection. 
* The `main.conf` file is needed.
* You can edit the BLE device name [here](aa-proxy-oap/blob/main/aa-proxy-oap/usr/local/bin/aa-proxy/aa-proxy-rs.sh#L11).
* Use Host's `Bluetooth Manager` to delete your phone and re-create a new pair from scratch. 

### 2. Wi-Fi Hotspot / hostapd / dhcpcd / dnsmasq

* AA wireless requires a working Wi-Fi Hotspot setup by the **Host** system, and then `aa-proxy-rs` conveys the `ssid` and `password` to the phone through the established Bluetooth connection. 
* `hostapd` and `dhcpcd` modifications are required for this. In constract to `WirelessAndroidAutoDongle` modifications, we need to use `dhcpcd`. 
* Important: `OpenAuto-Pro` provides a `hotspot` toggle that modifies the same files. Make sure to enable it first, then edit the files. That makes sure that there aren't any conficts. 
* You can edit the `ssid` and `password` of the hotspot [here](aa-proxy-oap/etc/hostapd/hostapd.conf#L16), while the IP address [here](aa-proxy-oap/etc/dhcpcd.conf#L62) and range [here](aa-proxy-oap/etc/dnsmasq.conf#L2).

### 3. Systemd

* In constract to `WirelessAndroidAutoDongle` modifications, we can't use `/etc/init.d`. At least, I didn't find out how. 
* I translated the necessary startup scripts to `systemd` services, so that the `usb-gadget` can be setup after boot and `aa-proxy-rs` can be run.

#### d. Install `aa-proxy-rs` folder inside `/usr/local/bin`

* It contains the script used by `systemd` as well as a statically built `aa-proxy-rs` working binary. 
* If you want to build it on your own, check [here](https://github.com/KreAch3R/aa-proxy-rs?tab=readme-ov-file#dependencies).