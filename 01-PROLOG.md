# ASUS Vivobook S16 - the prolog

[TOC]

The ASUS Vivobook S16 comes with MS Windows HOME Edition on ARM pre-installed. There is some kind of 'chicken-and-egg' problem creating a Linux installation: We need a running ARM64 Linux to create everything we need in order to make this happen. Alternatively, you may setup a cross-compilation environment on a, e.g., X86-64 machine running Linux, which I did not perform.

## The hardware part

The ASUS Vivobook S16 I bought came with a 1TB SSD, which was too small for me running MS Windows **AND** Linux side-by-side.

Furthermore, an UEFI Secure Boot is possible, which I did not perform until now. For now, you have to enter the UEFI setup (press and hold ESC while booting or F2, enter UEFI setup, disable UEFI secure boot).

A bigger SSD is necessary, I suggest a 2TB SSD (I am currently using a Samsung Pro NVMe SSD with 4TB).

For the very first step, attach a new SSD in an USB case to the ASUS Vivobook S16 on Windows, use a tool (comparable to 'dd' on Linux, please just google for it) to copy the entire, original, SSD content to the USB-attached device.

**This ensures that you have a full backup on the original (internal) SSD if something should go wrong.**

This notebook boots using the UEFI firmware, i.e. a GUID Partition Table (GPT) is on the original SSD. There is an ESP (EFI System Partition), the partition (FAT32-formatted) the UEFI firmware boots from (a Windows bootloader is on it already, obviously, and a GRUB2 EFI binary goes on that partition later on, too - for booting Linux).

The original Windows installation remains and will be usable in parallel to the Linux installation.

## Binary firmwares

The Linux installation DOES NOT WORK without the help of several binary firmwares that come with your notebook (on the MS Windows side). You have to extract those files adding them to the Linux installation. Nothing works without this.

Yes, there are Debian repos named 'non-free' and 'non-free-firmware' but they don't help you right now because there a licensing issues, i.e. Debian needs explicit 'Firmware Redistribution Licenses' from the OEM (e.g. ASUS or Qualcomm, respectively) to incorporate these binary firmwares into their software (non-free) repos.

The key point is: You have bought an ASUS Vivobook S16 with MS Windows on ARM coming with all these required binary firmware files. You MUST NOT redistribute these files but MAY use them on your own device (this is the reason why you have to extract them from the Windows installation transferring them to Linux).

## SSD preparation

After having copied the entire, original, SSD, you have to use partitioning tools (use your favorite one) to perform two major things:

1. Make the ESP a little bigger (I am using a 512MB partition now) - optional;
2. Depending on the size of the new SSD, you may also make the NTFS partition somewhat bigger for MS Windows - optional;
3. Leave room for Linux (or partition it now) - one single EXT4 partition is sufficient although some people might decide to perform a fine-granular partitioning (e.g. /var, /usr, /home as separate partitions - or even a logical volume setup - LVM).

Please note that I did not check any LVM setup - on another AMD64-based notebook, I had the problem with two physical volumes on two different SSDs (one was NVMe, one SATA) build one logical volume for Linux. The crucial point here is the /boot folder (sometimes this is also a separate partition) where the GRUB2 configuration, Linux kernel, initial ramdisk, yes, and also the binary device tree all 'live'. If your GRUB2 EFI binary cannot access this properly, it simply does not boot.

[*Comment on this UEFI LVM boot issue: It was solved by disabling 'fast boot' in the UEFI settings because GRUB2 only found the NVMe part, not the SATA part and refused to use this 'half logical volume'.*]

After that, you are ready to open the case of the Laptop exchanging the old, internal SSD with the new, bigger/external, one. Keep the original one for backup purposes.

**<u>PLEASE DO NOTE:</u> WARRANTY OF YOUR HARDWARE MAY BE VOID OPENING AND MODIFYING THE NOTEBOOK!!!**

It is VERY important to keep all the existing GPT partitions (if I recall correctly, these were 16 to 20 small partitions) with their current UUIDs. Do not partition your new SSD from scratch. This results in new GPT partitions being created with new (random) UUIDs. Your MS Windows might not boot anymore on such an SSD.

To be honest, it is completely beyond me, what is in these many OEM partitions. But I don't care, this text is about Linux...

## Hyper-V Linux virtual machine (ARM64)

Because I did not wanted to use a cross-compilation environment, I needed a running Linux on ARM64 to apply (patch) everything needed to make this box natively booting.

You can enable the Hyper-V support also on a Home edition of MS Windows (again, google for it, it requires some PowerShell steps). After that, you can install a stock Debian Trixie (ARM64) in such a Hyper-V VM. This was my very first ARM64 Linux environment - but: It is veeeerrrryyyy slow (kernel builds take many hours, sometimes half-a-day).

So this is quite 'ugly'. The good thing is that you do not have to perform it because I am providing Debian packages (pre-built Linux kernels) plus a modified Debian Installer, which you have to modify with your own binary firmware files. This is then a ready-to-go image, which you can transfer via RUFUS on a USB stick. Boot from there and install Debian Trixie.

I also installed an Oracle VirtualBox on MS Windows on ARM but did not have time until now to make this working, too.

The very first bootable media came from a de-bootstrapped Linux from that virtual machine.

