# Binary firmwares

This 'thing' (ASUS Vivobook S16) **does not work without a lot of binary firmware files**. Several of them are non-redistributable and have to be extracted / copied over from your local MS Windows 11 on ARM64 installation.

The following table clarifies the situation on my ASUS box.

Paths are relative to `/lib/firmware/`. 🟢 = loaded and working (EL1), 🔴 = not working.

| Firmware file                                           | Origin                                                       | Description                                                  | SHA-256                                                      | Status                                                |
| ------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ----------------------------------------------------- |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qcdxkmsucpurwa.mbn` | Local Windows installation (`DriverStore\FileRepository`, Qualcomm GPU driver package) | GPU zap shader (ASUS-signed), needed by `msm` for the Adreno X1-45 | `5b8b1ea1de11b9acc74fdd4919aa4aeac924520e4b11cf27782c593640e11e44` | 🟢                                                     |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qcadsp8380.mbn`     | Local Windows installation (DriverStore)                     | ADSP firmware: audio, battery/charging (`pmic_glink`/battmgr), USB-C role | `320f885752554f344d067a617313b5ae6dd6f1c422b84699e22e37e5b018c689` | 🟢 (🔴 at EL2)                                          |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/adsp_dtbs.elf`      | Local Windows installation (DriverStore)                     | ADSP device-tree blob, loaded together with `qcadsp8380.mbn` | `09030fd322a5419dd70cd722e23ac2b8248d06020fc6dce385ef0ce6133e73e0` | 🟢 (🔴 at EL2)                                          |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qccdsp8380.mbn`     | Local Windows installation (DriverStore)                     | CDSP firmware (compute DSP/NPU); boots, not used by any userspace yet | `3df4de099b23df0969c172fa2660e02c1ba4e1b5c280eb0198a89194f400d875` | 🟢 (🔴 at EL2)                                          |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/cdsp_dtbs.elf`      | Local Windows installation (DriverStore)                     | CDSP device-tree blob                                        | `664758a227f38043cb5fc21ad56154e57449a759e703d3b1d84b41c8ce138914` | 🟢 (🔴 at EL2)                                          |
| `ath11k/WCN6855/hw2.1/board.bin`                        | Local Windows installation: `qcwlanhsp8380.inf_arm64_…\bdwlan_wcn685x_2p1_nfa765a_AS_SA_S3607QA.elf`, renamed | Wi-Fi board/calibration data for this laptop                 | `1558270f70122c8c0ebf8caf5820f785adc7fbd2fbd2af578f92e3b83c364e55` | 🟢                                                     |
| `ath11k/WCN6855/hw2.1/nfa765/amss.bin`                  | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-atheros`) | Wi-Fi firmware, NFA765 build `WLAN.HSP.1.1-04866.5…IOE-1`    | `8cb5e63877c7cfdc5002a7d28bc5d7f7d20368183e6f93b12c977bfd0351c7b7` | 🟢                                                     |
| `ath11k/WCN6855/hw2.1/nfa765/m3.bin`                    | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-atheros`) | Wi-Fi M3 coprocessor firmware (NFA765)                       | `d20460e104b85a7be9cdb5199c4d8b94a9787912e3f920acd845694d4d71f730` | 🟢                                                     |
| `qcom/gen71500_sqe.fw`                                  | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-qcom-soc`) | Adreno X1-45 command processor (SQE) microcode               | `eee95622aa1e487e96de55469a65c5642ce9b8c724f9da768c79fe54df760eff` | 🟢                                                     |
| `qcom/gen71500_gmu.bin`                                 | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-qcom-soc`) | Adreno X1-45 GMU (GPU power management) firmware             | `5e655569c21bf964e0af1cb8a06e710b360fadba238d7d9d0dd1167a8395022c` | 🟢                                                     |
| `qcom/x1e80100/X1P42100-ASUS-Vivobook-S16-tplg.bin`     | linux-firmware.git: copy of (or symlink to) `qcom/x1e80100/ASUSTeK/zenbook-a14/X1E80100-ASUS-Zenbook-A14-tplg.bin` | AudioReach audio topology (speakers, headphone jack)         | `aa303397750f883ecaeed874d7547da658500596247676a6d405bf1ec43290b5` | 🟢                                                     |
| `qca/hpbtfw21.tlv`                                      | Debian `firmware-atheros` (linux-firmware)                   | Bluetooth patch firmware for the WCN6855                     | `a911f66a137ec8b9e65f90942e1c21ea2604734a88e486519b77e750d0fc20d2` | 🟢                                                     |
| `qca/hpnv21g.b10c`                                      | Debian `firmware-atheros` (linux-firmware)                   | Bluetooth NVM configuration for the WCN6855                  | `61b4bd03d85b4bf167029469a3dcb26efd63745c24101ffb964841ab71215d9c` | 🟢                                                     |
| `rtl_nic/rtl8153b-2.fw`                                 | Debian `firmware-realtek` (linux-firmware)                   | Ethernet of the USB-C dock (RTL8153B, `r8152`); dock only    | `137c9c752e8648ecfcf3b74ffc7d675c098145c222e2969721e6257af31716bc` | 🟢                                                     |
| `regulatory.db`, `regulatory.db.p7s`                    | Debian `wireless-regdb`, located at /lib/firmware/regulatory.db-debian and regulatory.db.p7s-debian | Wi-Fi regulatory database (country `DE`); data, not firmware, but loaded via the firmware loader | `7e236caecd939c8ec98be4870bf30422f28ffef2565a38aaaa2d9ddabd0c2641 a99178473a425a1e14cf821f18f9aef4c8f2a6582dfdc1d89b31e87b924765e1` | 🟢                                                     |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qcvss8380.mbn`      | Local Windows installation (DriverStore)                     | Video codec firmware (iris)                                  | `2e37684e8c84b7d945396da24c295c3267e97087a537386bb10ad1fa5ef85ebc` | 🔴 rejected with `-22` on 7.3.3; worth retrying on 7.4 |
| `qcom/vpu/vpu30_p1_s7.mbn`                              | linux-firmware.git (handed over by Claude)                   | Generic iris video codec firmware (VPU 3.0, one pipe)        | `d0912c3d5ab0eaa361acbbb6a653a5bce2f83ba40a83accd24b8ab6718111656` | 🔴 rejected with `-22`; not needed                     |

Notes:

- Licenses: the linux-firmware files are redistributable with their license files (`LICENSE.qcom`/`NOTICE.qcom`, the ath11k `Notice.txt`, `LICENCE.linaro`). The files from the Windows installation are **not** redistributable; `s16-firmware-extract.sh` copies them from the user's own Windows partition.
- The `-2` messages for `qca/wcnhpbtfw21.tlv`, `qca/wcnhpnv21g.b10c` and `qca/wcnhpnv21g.bin` are harmless: the driver tries those newer names first and then loads the two `qca/` files above.

## Firmware extraction from Windows

Can be performed either manually on Windows (to a USB stick and then copied over to Linux) or on Linux using the shell script 's16-firmware-extract.sh'

Example run for a NVMe SSD having the Windows C: drive (obviously NTFS-formatted, adjust the NVMe partition!):

<pre>
    sudo mount -t ntfs3 -o ro /dev/nvme0n1pX /mnt/win
    sudo ./s16-firmware-extract.sh --source /mnt/win --dry-run     # first only look, change nothing
    sudo ./s16-firmware-extract.sh --source /mnt/win               # then for real
    sudo update-initramfs -u
</pre>
