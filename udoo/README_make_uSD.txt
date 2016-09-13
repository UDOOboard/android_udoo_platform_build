To write the Android image.
 
Howto write Android image on uSD card:
    
   From a Linux PC (or Linux virtual machine):

    - Locate your uSD device:
	$ sudo lsblk

    - Run make_sd script to write Android image on uSD card:
	$ sudo -E ./make_sd.sh /dev/sdX [ or /dev/mmcblkX ]

Howto write Android image on onboard eMMC:
    
   Boot the board with a Linux uSD downloaded from uDOO site:

    - Enter in the directory with the unpacked Android image;

    - Run make_sd script to write Android image on eMMC card:
	$ sudo -E ./make_sd.sh /dev/mmcblk0
