# Binary device tree(s)

This folder contains the two compiled device trees for the ASUS Vivobook S16 (for informational purposes).

Normally, the notebook boots on EL1 (operating system kernel privilege level). Alternatively, you may also boot Linux on EL2 (higher-privilege hypervisor level).

Some things do not work on EL2, though (e.g. date/time messed up, battery charge level always shows 0%, sound not working).

## Notes on EL2

Booting on EL2 requires additional work in your machine's ESP (EFI System Partition).

First of all, you need the EFI binary 'slbounce.efi' - please refer to: https://github.com/TravMurav/slbounce/releases (you may also build it from source as I did).

Furthermore, you have to extract the executable 'tcblaunch.exe' from C:\Windows\System32 from your MS Windows on ARM installation (that comes with your notebook).

Because I did not want this stuff to be used as an EFI driver, I just ran it from the EFI shell (EFI shell available here: https://github.com/pbatard/UEFI-Shell/releases); my EFI partition is mapped to fs3: in this example:

`fs3:`

`load slbounce.efi`

`\EFI\debian\grubaa64.efi`

My GRUB2 bootloader sits in \EFI\debian on my ESP. Some points to keep in mind here:

1. Microsoft has recently removed the error handling in the executable 'tcblaunch.exe' the EFI binary slbounce.efi relies on;
2. Both files 'slbounce.efi' and 'tcblaunch,exe' have to be placed in the root folder of the ESP (otherwise tcblaunch.exe is not found);
3. A dedicated GRUB2 boot entry is required, see below.

### Example GRUB2 entry (using EL2 device tree)

The boot partition is on an EXT4 with label 'Debian' in this example:

<pre>
menuentry "Debian 7.4.0-RC3 (EL2)" {
    search --no-floppy --label Debian --set=root
    devicetree /boot/dtb/x1p42100-asus-vivobook-s16-7.4.0-RC3-el2.dtb
    linux /boot/vmlinuz-7.4.0-rc3-next-20261119-s16-dirty root=LABEL=Debian rw pci=noaer
    initrd /boot/initrd.img-7.4.0-rc3-next-20261119-s16-dirty
}
</pre>