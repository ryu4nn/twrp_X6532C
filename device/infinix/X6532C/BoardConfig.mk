#
# BoardConfig for Infinix Smart 9 HD (X6532C), MT6765, Android 12, A/B + Virtual A/B.
#
# Every value below was read from this device's own partitions:
#   unpack_bootimg on boot_b.img / vendor_boot_b.img
#   avbtool info_image on vbmeta_b.img
#   lpdump on /dev/block/by-name/super
#   blockdev --getsize64 on every by-name node
#
# The device has no recovery partition. Recovery resources live inside
# vendor_boot (vendor ramdisk), which is what BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT
# reproduces. The kernel stays in boot and is never touched.
#

DEVICE_PATH := device/infinix/X6532C

# Build hacks required by the AOSP 12.1 minimal manifest
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Architecture: userspace is 32-bit only (ro.product.cpu.abilist=armeabi-v7a,armeabi)
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a53
TARGET_USES_64_BIT_BINDER := true

ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Platform
TARGET_BOARD_PLATFORM := mt6765
TARGET_BOOTLOADER_BOARD_NAME := mt6765
TARGET_NO_BOOTLOADER := true
BOARD_USES_MTK_HARDWARE := true

# Display: 720x1600 physical, ro.sf.lcd_density=320
TARGET_SCREEN_DENSITY := 320

# Kernel: not built, not packed. boot.img (untouched) carries the 5.10.237 kernel.
TARGET_NO_KERNEL := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img

# Boot / vendor_boot header layout (unpack_bootimg, header version 4)
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x11a88000
BOARD_KERNEL_TAGS_OFFSET := 0x07808000
BOARD_DTB_OFFSET := 0x07808000
BOARD_PAGE_SIZE := 4096
BOARD_KERNEL_PAGESIZE := 4096
BOARD_VENDOR_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_RAMDISK_USE_LZ4 := true

BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)

# Partitions (blockdev --getsize64)
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_SUPER_PARTITION_SIZE := 5368709120
BOARD_SUPER_PARTITION_GROUPS := infinix_dynamic_partitions
BOARD_INFINIX_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext vendor product
BOARD_INFINIX_DYNAMIC_PARTITIONS_SIZE := 5364514816
BOARD_USES_METADATA_PARTITION := true

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product

# Recovery: vendor_boot as recovery, exactly like the stock image
TARGET_NO_RECOVERY := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true

# Kernel modules shipped in the ramdisk.
# The value must be quoted: TWRP turns it into -DTW_LOAD_VENDOR_MODULES=<value>
# and the flag is assembled into a shell command line, so an unquoted list is
# split by the shell and every .ko after the first becomes a compiler input.
TW_LOAD_VENDOR_MODULES := "$(shell cd $(DEVICE_PATH)/recovery/root/lib/modules && echo *.ko)"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_LOAD_VENDOR_BOOT_MODULES := true

# Verified boot. Stock vendor_boot carries an unsigned hash footer
# (avbtool: Algorithm NONE) and vbmeta_b has flags=3 (verification and
# hashtree disabled), so an unsigned footer is the correct output here.
BOARD_AVB_ENABLE := true
BOARD_AVB_ALGORITHM := NONE

# FBE + metadata decryption. /data is f2fs with
# fileencryption=aes-256-xts:aes-256-cts:v2 and
# keydirectory=/metadata/vold/metadata_encryption; /metadata (md_udc) is
# wrappedkey, so the keys are sealed by the Trustonic TEE. The 32-bit keymaster
# stack that unwraps them is shipped in recovery/root/vendor and started by
# recovery/root/init.decrypt.rc, because TWRP unmounts the real /vendor before
# decrypting.
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_USE_FSCRYPT_POLICY := 2

# VNDK
BOARD_VNDK_VERSION := current

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Anti-rollback guard (build-time only, never flashed)
PLATFORM_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Recovery UI
TW_THEME := portrait_hdpi
TW_FRAMERATE := 60
TW_MAX_BRIGHTNESS := 4095
TW_DEFAULT_BRIGHTNESS := 2047
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone4/temp"
TW_HAS_NO_RECOVERY_PARTITION := true
TW_NO_FLASH_CURRENT_TWRP := true
TW_EXTRA_LANGUAGES := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPTOOLS := true
TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_FB2PNG := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_FUSE_EXFAT := true
TW_USB_STORAGE := true
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TW_DEVICE_VERSION := X6532C
