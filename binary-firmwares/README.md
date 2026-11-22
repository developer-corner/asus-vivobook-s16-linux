# Binary firmwares

This 'thing' (ASUS Vivobook S16) **does not work without a lot of binary firmware files**. Several of them are non-redistributable and have to be extracted / copied over from your local MS Windows 11 on ARM64 installation.

The following table clarifies the situation on my ASUS box.

Paths are relative to `/lib/firmware/`. 🟢 = loaded and working (EL1), 🔴 = not working.

| Firmware file                                           | Origin                                                       | Description                                                  | SHA-256 | Status                                                |
| ------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------- | ----------------------------------------------------- |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qcdxkmsucpurwa.mbn` | Local Windows installation (`DriverStore\FileRepository`, Qualcomm GPU driver package) | GPU zap shader (ASUS-signed), needed by `msm` for the Adreno X1-45 |         | 🟢                                                     |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qcadsp8380.mbn`     | Local Windows installation (DriverStore)                     | ADSP firmware: audio, battery/charging (`pmic_glink`/battmgr), USB-C role |         | 🟢 (🔴 at EL2)                                          |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/adsp_dtbs.elf`      | Local Windows installation (DriverStore)                     | ADSP device-tree blob, loaded together with `qcadsp8380.mbn` |         | 🟢 (🔴 at EL2)                                          |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qccdsp8380.mbn`     | Local Windows installation (DriverStore)                     | CDSP firmware (compute DSP/NPU); boots, not used by any userspace yet |         | 🟢 (🔴 at EL2)                                          |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/cdsp_dtbs.elf`      | Local Windows installation (DriverStore)                     | CDSP device-tree blob                                        |         | 🟢 (🔴 at EL2)                                          |
| `ath11k/WCN6855/hw2.1/board.bin`                        | Local Windows installation: `qcwlanhsp8380.inf_arm64_…\bdwlan_wcn685x_2p1_nfa765a_AS_SA_S3607QA.elf`, renamed | Wi-Fi board/calibration data for this laptop                 |         | 🟢                                                     |
| `ath11k/WCN6855/hw2.1/nfa765/amss.bin`                  | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-atheros`) | Wi-Fi firmware, NFA765 build `WLAN.HSP.1.1-04866.5…IOE-1`    |         | 🟢                                                     |
| `ath11k/WCN6855/hw2.1/nfa765/m3.bin`                    | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-atheros`) | Wi-Fi M3 coprocessor firmware (NFA765)                       |         | 🟢                                                     |
| `qcom/gen71500_sqe.fw`                                  | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-qcom-soc`) | Adreno X1-45 command processor (SQE) microcode               |         | 🟢                                                     |
| `qcom/gen71500_gmu.bin`                                 | linux-firmware.git (handed over by Claude; also in newer Debian `firmware-qcom-soc`) | Adreno X1-45 GMU (GPU power management) firmware             |         | 🟢                                                     |
| `qcom/x1e80100/X1P42100-ASUS-Vivobook-S16-tplg.bin`     | linux-firmware.git: copy of (or symlink to) `qcom/x1e80100/ASUSTeK/zenbook-a14/X1E80100-ASUS-Zenbook-A14-tplg.bin` | AudioReach audio topology (speakers, headphone jack)         |         | 🟢                                                     |
| `qca/hpbtfw21.tlv`                                      | Debian `firmware-atheros` (linux-firmware)                   | Bluetooth patch firmware for the WCN6855                     |         | 🟢                                                     |
| `qca/hpnv21g.b10c`                                      | Debian `firmware-atheros` (linux-firmware)                   | Bluetooth NVM configuration for the WCN6855                  |         | 🟢                                                     |
| `rtl_nic/rtl8153b-2.fw`                                 | Debian `firmware-realtek` (linux-firmware)                   | Ethernet of the USB-C dock (RTL8153B, `r8152`); dock only    |         | 🟢                                                     |
| `regulatory.db`, `regulatory.db.p7s`                    | Debian `wireless-regdb`                                      | Wi-Fi regulatory database (country `DE`); data, not firmware, but loaded via the firmware loader |         | 🟢                                                     |
| `qcom/x1p42100/ASUSTeK/vivobook-s16/qcvss8380.mbn`      | Local Windows installation (DriverStore)                     | Video codec firmware (iris)                                  |         | 🔴 rejected with `-22` on 7.3.3; worth retrying on 7.4 |
| `qcom/vpu/vpu30_p1_s7.mbn`                              | linux-firmware.git (handed over by Claude)                   | Generic iris video codec firmware (VPU 3.0, one pipe)        |         | 🔴 rejected with `-22`; not needed                     |

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

