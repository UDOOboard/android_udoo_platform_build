To compile Android distribution.

Prerequisites:
   Linux os 64 bit with:
      - Java compiler version >= 1.7
      - a complete compilation environment (gcc, libc header, mkimage tool)
 
Run following commands from THIS directory:

- setup build environment
   $ source build/envsetup.sh

- configure your target device:
     $ lunch a62_6dq-eng 
   or:
     $ lunch udoo_6dq-eng 
   or:
     $ lunch udooneo_6sx-eng 

- compile
   $ make -j N 
    [ where N = number of cpu on your system - 6. Eg. make -j 6 ]

- take a long coffee

- prepare tar.gz archive with Android binary image:
   $ ./prepare_distro.sh 

- write image on uSD following instruction in "README_make_uSD.txt" file:
   $ sudo ./make_sd.sh /dev/sdX [ or /dev/mmcblkX ]
