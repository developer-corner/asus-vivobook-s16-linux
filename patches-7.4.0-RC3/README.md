# Kernel patches 'ASUS Vivobook S16' for Linux 7.4.0-RC3

This folder contains **eleven patch files** for the Linux kernel.

They introduce the 'ASUS Vivobook S16', define a device tree for EL1 and EL2.

## External work: ASUS EC

Neither the keyboard backlight (brightnessctl) nor the fan control initially worked on the ASUS Vivobook S16.

Help came in from this website: https://github.com/Sombre-Osmoze/asus-zenbook-a14-ec

This work was performed for the ASUS Zenbook A14 but is applicable to the ASUS Vivobook S16 as well.

The three patches 0007 thru 0009 came from them.

The patches 0010 and 0011 were added by me (co-authored by Anthropic's Claude).

With all eleven patches applied to the kernel, the keyboard backlight can be controlled using brightnessctl (levels 0..3), and the fan control works properly (I have a Wayfire bar that shows the left and right fans continuously).

## Upstream work

All patches except for the ASUS EC work, which would have to be sent upstream by the original authors, have been submitted upstream to the actual kernel maintainers they are targeted to.

In mid of November 2026, only one patch has been accepted already, the others are still pending.