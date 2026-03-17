#!/system/bin/sh
# Select the correct touch HAL service binary based on device model
MODEL=$(getprop ro.product.model)
case "$MODEL" in
    PLQ110)
        # Ace 6 (ktm/tianma)
        exec /odm/bin/hw/vendor.oplus.hardware.touch.V2-hbp5-service "$@"
        ;;
    *)
        # Turbo 6 (vw/BOE) and other devices
        exec /odm/bin/hw/vendor-oplus-hardware-touch-V2-hbp5-service "$@"
        ;;
esac
