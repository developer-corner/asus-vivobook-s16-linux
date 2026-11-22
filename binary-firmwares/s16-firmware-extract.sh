#!/bin/bash
# s16-firmware-extract.sh — copy the device-specific firmware of the
# ASUS Vivobook S16 S3607QA (Snapdragon X X1P42100) from the user's own
# Windows installation (or an ASUS driver package) to the Linux paths,
# check the redistributable firmware from Debian/linux-firmware, and print
# the complete firmware inventory with SHA-256 checksums.
#
# The Windows files are signed for/by ASUS and are not redistributable, so
# they are not shipped with Linux distributions. This script does not
# contain any firmware; it only copies files the user already has.
#
# Usage:
#   sudo ./s16-firmware-extract.sh --source /mnt/win [--dest /lib/firmware]
#
#   --source    a mounted Windows partition (C:), or any directory with the
#               ASUS/Qualcomm driver packages (searched recursively)
#   --dest      target firmware root (default /lib/firmware); use a staging
#               directory, e.g. ./firmware, to feed remaster-debian-iso.sh
#   --no-video  skip the video codec firmware (qcvss8380.mbn, not working yet)
#   --dry-run   show what would be copied, change nothing
#
# Mounting the Windows partition read-only (find it with lsblk -f):
#   sudo mkdir -p /mnt/win && sudo mount -t ntfs3 -o ro /dev/nvme0n1pX /mnt/win
# If Windows uses BitLocker/device encryption, unlock it first
# (e.g. "dislocker" with the recovery key) or copy
# C:\Windows\System32\DriverStore\FileRepository to a USB stick in Windows.

set -euo pipefail

SRC= DEST=/lib/firmware DRY=0 VIDEO=1
die()  { echo "error: $*" >&2; exit 1; }
warn() { echo "warning: $*" >&2; }

while [ $# -gt 0 ]; do
	case "$1" in
	--source)   SRC=$2; shift 2 ;;
	--dest)     DEST=$2; shift 2 ;;
	--no-video) VIDEO=0; shift ;;
	--dry-run)  DRY=1; shift ;;
	-h|--help)  sed -n '2,26p' "$0"; exit 0 ;;
	*)          die "unknown option $1" ;;
	esac
done
[ -n "$SRC" ] && [ -d "$SRC" ] || die "--source DIR required (see --help)"

# Search only the driver store if SRC is a whole Windows partition
STORE=$(find "$SRC" -maxdepth 4 -type d -ipath '*/windows/system32/driverstore/filerepository' 2>/dev/null | head -1)
[ -n "$STORE" ] || STORE=$SRC
echo "Searching: $STORE"

FWDIR=qcom/x1p42100/ASUSTeK/vivobook-s16

# Files from the Windows installation:
# <name in Windows>  <path below the firmware root>  <required|optional>  <pair>
# <pair>: take this file from the same driver folder as the named file
# (an .mbn and its _dtbs.elf must belong together).
MAP="
qcdxkmsucpurwa.mbn                           $FWDIR/qcdxkmsucpurwa.mbn  required -
qcadsp8380.mbn                               $FWDIR/qcadsp8380.mbn      required -
adsp_dtbs.elf                                $FWDIR/adsp_dtbs.elf       required qcadsp8380.mbn
qccdsp8380.mbn                               $FWDIR/qccdsp8380.mbn      required -
cdsp_dtbs.elf                                $FWDIR/cdsp_dtbs.elf       required qccdsp8380.mbn
bdwlan_wcn685x_2p1_nfa765a_AS_SA_S3607QA.elf ath11k/WCN6855/hw2.1/board.bin required -
"
[ $VIDEO = 1 ] && MAP="$MAP
qcvss8380.mbn                                $FWDIR/qcvss8380.mbn       optional -
"

# Optional: SHA-256 of files known to work, "name=hash" (fill in from a
# working installation with: sha256sum <files>). A different hash only warns.
KNOWN_SHA256='
'

declare -A PICKED_DIR      # Windows name -> driver folder it was taken from
INVENTORY=()               # "path|origin|sha256" for the summary
missing=0

sha() { # sha256 of a firmware file, also when it is stored compressed
	case "$1" in
	*.zst) zstdcat "$1" | sha256sum | cut -d' ' -f1 ;;
	*.xz)  xzcat "$1" | sha256sum | cut -d' ' -f1 ;;
	*)     sha256sum "$1" | cut -d' ' -f1 ;;
	esac
}

echo
echo "Firmware from the Windows installation -> $DEST:"
while read -r win dst need pair; do
	[ -n "$win" ] || continue
	mapfile -t found < <(find "$STORE" -type f -iname "$win" 2>/dev/null)
	if [ ${#found[@]} -eq 0 ]; then
		if [ "$need" = required ]; then
			warn "$win not found"; missing=$((missing + 1))
		else
			echo "  (optional, not found) $win"
		fi
		continue
	fi
	pick=
	# keep pairs together: prefer the copy next to its partner file
	if [ "$pair" != - ] && [ -n "${PICKED_DIR[$pair]:-}" ]; then
		for f in "${found[@]}"; do
			[ "$(dirname "$f")" = "${PICKED_DIR[$pair]}" ] && pick=$f
		done
		[ -n "$pick" ] || warn "$win: no copy next to $pair, picking separately"
	fi
	if [ -z "$pick" ]; then
		# several driver folders may contain copies: they should be
		# identical, otherwise take the newest and say so
		nhash=$(sha256sum "${found[@]}" | cut -d' ' -f1 | sort -u | wc -l)
		pick=$(ls -t "${found[@]}" | head -1)
		if [ "$nhash" -gt 1 ]; then
			warn "$win: ${#found[@]} copies with $nhash different contents, using the newest:"
			for f in "${found[@]}"; do echo "    $(sha256sum "$f" | cut -c1-16)…  $f" >&2; done
		fi
	fi
	PICKED_DIR[$win]=$(dirname "$pick")
	hash=$(sha256sum "$pick" | cut -d' ' -f1)
	known=$(printf '%s\n' "$KNOWN_SHA256" | sed -n "s/^$win=//p")
	if [ -n "$known" ] && [ "$known" != "$hash" ]; then
		warn "$win: SHA-256 differs from the known working file (other driver version?)"
	fi
	echo "  $pick"
	echo "    -> $DEST/$dst"
	[ $DRY = 1 ] || install -D -m 0644 "$pick" "$DEST/$dst"
	drv=$(basename "$(dirname "$pick")")
	case "$drv" in *.inf_*) drv="${drv%%.inf_*}.inf" ;; esac
	INVENTORY+=("$dst|Windows: $drv\\$win|$hash")
done <<< "$MAP"

# ------------------------------------------------------------ redistributable parts
# These come from linux-firmware / Debian packages (firmware-qcom-soc,
# firmware-atheros, firmware-realtek, wireless-regdb; preferably from
# trixie-backports). Only check and link, never copy.
echo
echo "Redistributable firmware (linux-firmware / Debian) in $DEST:"
check() { # <path> <origin> <required|optional>
	local f
	for f in "$DEST/$1" "$DEST/$1.zst" "$DEST/$1.xz"; do
		if [ -e "$f" ]; then
			echo "  ok        $1"
			INVENTORY+=("$1|$2|$(sha "$f")")
			return
		fi
	done
	if [ "$3" = required ]; then
		echo "  MISSING   $1  ($2)"; missing=$((missing + 1))
	else
		echo "  (optional, missing) $1  ($2)"
	fi
}
check qcom/gen71500_sqe.fw                  "linux-firmware / firmware-qcom-soc" required
check qcom/gen71500_gmu.bin                 "linux-firmware / firmware-qcom-soc" required
check ath11k/WCN6855/hw2.1/nfa765/amss.bin  "linux-firmware / firmware-atheros"  required
check ath11k/WCN6855/hw2.1/nfa765/m3.bin    "linux-firmware / firmware-atheros"  required
check qca/hpbtfw21.tlv                      "linux-firmware / firmware-atheros"  required
check qca/hpnv21g.b10c                      "linux-firmware / firmware-atheros"  required
check rtl_nic/rtl8153b-2.fw                 "firmware-realtek (USB-C dock LAN)"  optional
check regulatory.db                         "wireless-regdb"                     optional
check regulatory.db.p7s                     "wireless-regdb"                     optional

# Audio: the S16 uses the Zenbook A14 topology under its own name (symlink)
tp=qcom/x1e80100/ASUSTeK/zenbook-a14/X1E80100-ASUS-Zenbook-A14-tplg.bin
ln_name=qcom/x1e80100/X1P42100-ASUS-Vivobook-S16-tplg.bin
linked=0
for ext in "" .zst .xz; do
	if [ -e "$DEST/$tp$ext" ]; then
		echo "  ok        $tp$ext (linking $ln_name$ext)"
		[ $DRY = 1 ] || ln -sfn "ASUSTeK/zenbook-a14/X1E80100-ASUS-Zenbook-A14-tplg.bin$ext" "$DEST/$ln_name$ext"
		INVENTORY+=("$ln_name|linux-firmware: symlink to Zenbook A14 topology|$(sha "$DEST/$tp$ext")")
		linked=1; break
	fi
done
[ $linked = 1 ] || { echo "  MISSING   $tp  (linux-firmware / firmware-qcom-soc)"; missing=$((missing + 1)); }

# ------------------------------------------------------------ summary
echo
echo "Inventory (paste into the firmware table):"
echo
echo "| Firmware file | Origin | SHA-256 |"
echo "|---|---|---|"
for row in "${INVENTORY[@]}"; do
	IFS='|' read -r p o h <<< "$row"
	echo "| \`$p\` | $o | \`$h\` |"
done

echo
if [ "$missing" -gt 0 ]; then
	echo "$missing required file(s) missing. Redistributable ones: install firmware-qcom-soc,"
	echo "firmware-atheros (trixie-backports) or copy them from linux-firmware.git."
fi
if [ $VIDEO = 1 ]; then
	echo "Note: qcvss8380.mbn (video codec) is copied for later tests only; the"
	echo "      device tree does not enable iris, so it is not loaded."
fi
if [ $DRY = 0 ] && { [ "$DEST" = /lib/firmware ] || [ "$DEST" = /usr/lib/firmware ]; }; then
	echo "Done. Run 'sudo update-initramfs -u' so the GPU/ADSP firmware is in the initramfs."
fi
