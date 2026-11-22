#
# OrangeFox product for Infinix Smart 9 HD (X6532C)
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/infinix/X6532C/device.mk)

PRODUCT_DEVICE := X6532C
PRODUCT_NAME := twrp_X6532C
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X6532C
PRODUCT_MANUFACTURER := INFINIX

PRODUCT_GMS_CLIENTID_BASE := android-infinix
