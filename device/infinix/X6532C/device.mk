#
# Device makefile for Infinix Smart 9 HD (X6532C)
#

LOCAL_PATH := device/infinix/X6532C

# Base
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Virtual A/B with vendor ramdisk (super has header flag virtual_ab_device)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

PRODUCT_SHIPPING_API_LEVEL := 31
PRODUCT_TARGET_VNDK_VERSION := 31

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Recovery is started from vendor_boot, so TWRP must not look for
# a /recovery partition when installing updates.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.twrp.vendor_boot=true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    product \
    system \
    system_ext \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot

# Fastbootd (needed to flash logical partitions while in recovery)
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    fastbootd

# Health HAL used by fastbootd/battery display
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service
