# TWRP device tree for OPLUS sm87xx sreies

## Supported devices
- Realme GT7 Pro (CN)

## Build it yourself?

```
mkdir twrp && cd twrp
repo init --depth=1 -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0
repo sync
git clone --depth=1 https://github.com/kmiit/twrp_device_oplus_sm87xx device/oplus/sm87xx
```

```
source build/envsetup.sh
lunch twrp_sm87xx
make recoveryimage
```

If there is no error, recovery.img will be found in out/target/product/sm87xx/recovery.img  


## Features
Works:
- [X] ADB
- [X] Display
- [X] Decryption
- [X] Fasbootd
- [X] Flashing
- [X] MTP
- [X] Sideload
- [X] Touch
- [X] USB OTG
- [X] Vibrator

## To use it:

```
fastboot flash recovery recovery.img
or
fastboot flash recovery_a recovery.img
fastboot flash recovery_b recovery.img
```
