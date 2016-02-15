To write the Android image.
 
From a Linux PC (or a Linux virtual machine):

    - Locate your uSD device:
	$ sudo lsblk

    - Run make_sd script to flashes the android images on uSD card:
	$ sudo ./make_sd.sh /dev/sdX [ or /dev/mmcblkX ]

