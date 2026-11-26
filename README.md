# TWRP for the Infinix Smart 9 HD (X6532C)

Team Win Recovery Project (TWRP) **3.7.1_12** device tree for the
**Infinix Smart 9 HD / X6532C**, MediaTek MT6765, Android 12 (Go) vendor,
A/B + Virtual A/B.

> This is **not** for the Infinix Smart 9 (X6532) — that model is a Helio G81 /
> MT6769Z, with a different chipset and partition layout.

The device tree is carried over unchanged from the working OrangeFox build: same
blobs, same fstab, same Trustonic TEE stack, same VINTF fix. Only the recovery
base changed, from OrangeFox 12.1 to stock TWRP 3.7.1 (`android-12.1`).

## Ready-made image

[`twrp-3.7.1-crypto-v1`](https://github.com/ryu4nn/twrp_X6532C/releases/tag/twrp-3.7.1-crypto-v1):

```
vendor_boot.img  67,108,864 bytes (exactly 64 MiB)
sha256 43b84c2a17ebbfa03cda883e0debb7005429dbe784520efcbe59bef4fef81c67
```

Flashes as `vendor_boot`; reports itself as `3.7.1_12-X6532C`.

## `3.7.1_12` or `3.7.1_14`?

Both are TWRP 3.7.1 — the suffix is the Android base. This device's vendor
partition is Android 12 / VNDK 31, so `_12` is the matching base. `_14.1` is
available as a workflow option, but it adds an API 34 recovery on top of a VNDK 31
vendor, which is extra risk with no functional gain.

## Decryption

`/data` is FBE with metadata encryption (`keydirectory=/metadata/vold/metadata_encryption`,
`/metadata` on `md_udc`, wrappedkey). The keys are sealed by the Trustonic TEE,
so a software keymaster cannot unwrap them. TWRP prompts for the PIN / password /
pattern only when all of this is true:

| Requirement | Where |
| --- | --- |
| `TW_INCLUDE_CRYPTO := true` (also enables FBE + metadata decrypt in TWRP's `Android.mk`) | `BoardConfig.mk` |
| `TW_USE_FSCRYPT_POLICY := 2` | `BoardConfig.mk` |
| keymaster 4.1 + gatekeeper 1.0 + Trustonic driver shipped in the ramdisk | `recovery/root/vendor/` |
| TEE stack started by init | `recovery/root/init.decrypt.rc` |
| HIDL services declared in a VINTF manifest **inside the ramdisk** | `recovery/root/vendor/etc/vintf/manifest.xml` |

The VINTF manifest is the non-obvious one. This recovery is built with
`PRODUCT_ENFORCE_VINTF_MANIFEST`, so `libhidlbase` compiles in
`registerAsServiceInternal()`'s check and refuses to register a HIDL service that
is not declared as `hwbinder`. TWRP starts `hwservicemanager` at `on init`, long
before it mounts the real `/vendor`, so without the manifest in the ramdisk the
keymaster/gatekeeper services never register, metadata decryption has no TEE
backend and `/data` never prompts for the PIN.

## Tree contents

```
device/infinix/X6532C/
├── BoardConfig.mk            numbers from the dump: header v4, base/offset, partition sizes
├── device.mk                 Virtual A/B, dynamic partitions, fastbootd
├── twrp_X6532C.mk            twrp_X6532C product (lunch target)
├── AndroidProducts.mk
├── system.prop               getprop values from the device (incl. keymaster_ver=4.1)
├── prebuilt/dtb.img          from vendor_boot
└── recovery/root/
    ├── init.recovery.mt6765.rc      vendor_boot's own rc + imports init.decrypt.rc
    ├── init.decrypt.rc              starts the Trustonic TEE, keymaster, gatekeeper
    ├── first_stage_ramdisk/fstab.mt6765
    ├── lib/modules/*.ko             kernel modules, vermagic 5.10.237
    ├── vendor/                      keymaster/gatekeeper services + libs + TA (32-bit)
    │   └── etc/vintf/manifest.xml   stock vendor HAL manifest
    └── system/etc/
        ├── recovery.fstab, twrp.flags
        └── vintf/manifest.xml       AOSP framework HAL manifest
```

## Why recovery lives in `vendor_boot`

This phone has no `recovery` partition. The stock firmware keeps all recovery
resources in the **vendor ramdisk** inside `vendor_boot`:

```
vendor_boot_a/b.img
├── vendor_ramdisk00   (lz4, 23.4 MB)  -> system/bin/recovery, recovery.fstab, init.recovery.mt6765.rc
├── dtb                (145,728 bytes)
└── AVB footer         (unsigned, Algorithm NONE)
```

The build therefore uses `BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true`
and the `vendorbootimage` target, not `recoveryimage`. The kernel stays in
`boot` and is never touched.

Note that `vendor_boot` is not recovery-only on this device: the `boot` ramdisk is
a 20-entry stub, so normal Android boot also reads the first-stage fstab and
tools from the vendor ramdisk. The first-stage pieces (`first_stage_ramdisk/fstab.mt6765`,
`e2fsck`, `linker`, `system/lib/*`) are kept byte-identical to stock so a normal
boot still works.

## Building

The `Build TWRP for X6532C` workflow syncs the
[minimal TWRP manifest](https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp)
(`twrp-12.1`) and runs `mka adbd vendorbootimage`.

1. Actions -> **Build TWRP for X6532C** -> **Run workflow**, branch `twrp-12.1`.
2. The sync takes 30-60 minutes, the build 40-90 minutes.
3. The artifact contains `vendor_boot.img`, `build-info.txt` and `SHA256SUMS`.
   The workflow also unpacks the produced ramdisk and asserts that the VINTF
   manifests, `init.decrypt.rc`, the TEE binaries and `keymaster_ver=4.1` are
   all present, so a regression like the one that produced no PIN prompt cannot
   ship silently.

Locally:

```bash
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags
cp -a device/infinix/X6532C twrp/device/infinix/
cd twrp
source build/envsetup.sh
lunch twrp_X6532C-eng
mka adbd vendorbootimage
```

## Flashing

```
fastboot flash vendor_boot vendor_boot.img
fastboot reboot recovery
```

`vendor_boot` is slot-aware; fastboot writes the active slot. The stock image is
kept in the dump (`vendor_boot_a.img` / `vendor_boot_b.img`) as the restore path.
