#!/bin/bash

# Choose right target dir
target_dir_udoo="out/target/product/udoo_6dq"
target_dir_a62="out/target/product/a62_6dq"
target_dir_udooneo="out/target/product/udooneo_6sx"

for d in $target_dir_udoo $target_dir_a62 $target_dir_udooneo
  do
    if [ -e "$d/system.img" ]; then
       if [ -e "${target_dir}/system.img" ]; then
          if [ "${target_dir}/system.img" -ot "$d/system.img" ]; then
              target_dir=$d
          fi
       else
	    target_dir=$d
       fi
   fi
done

if [ ! -e "${target_dir}/system.img" ]
  then
    echo ""
    echo " --> Can't find valid target dir. Exit."
    echo ""
    exit 1
fi

if [[ "x$1" == "x" ]]
  then
    echo ""
    echo "   Error ! Missing argument."
    echo "        Usage:  $0 <DISTRONAME>"
    echo ""
    exit 0
fi

NAME="$1"

UDOO=`echo "$target_dir" | grep -c udoo_6dq`
UDOONEO=`echo "$target_dir" | grep -c udooneo_6sx`
A62=`echo "$target_dir" | grep -c a62_6dq`

if [[ $UDOO -gt 0 ]]
  then
    board="udoo"
elif [[ $A62 -gt 0 ]]
  then
    board="a62"
elif [[ $UDOONEO -gt 0 ]]
  then
    board="udooneo"
else
    echo ""
    echo "   Unrecognized board. Path = $target_dir"
    echo ""
    exit 0
fi

echo Distro Name selected: $NAME
rm -rf $NAME
rm -rf $NAME.tar.gz
mkdir $NAME

cp -v $target_dir/u-boot-imx6qdl_2Giga.imx $NAME
cp -v $target_dir/u-boot-imx6qdl_1Giga.imx $NAME
cp -v $target_dir/u-boot.imx $NAME
cp -v $target_dir/boot.img $NAME
cp -v $target_dir/recovery.img $NAME
simg2img $target_dir/system.img $NAME/system_raw.img
cp -v make_sd.sh $NAME/make_sd.sh
cp -v README_make_uSD.txt ${NAME}
cp -v README_compile_Android.txt ${NAME}

tar czvf $NAME.tar.gz $NAME
rm -rf $NAME
