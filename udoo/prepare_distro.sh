#!/bin/bash

BASE_OUT="$OUT/../../.."

if [[ "x$1" == "x" ]]
  then
    echo ""
    echo "   Error ! Missing argument."
    echo "        Usage:  $0 <DISTRONAME>"
    echo ""
    exit 0
fi

NAME="$1"

UDOO=`echo "$OUT" | grep -c udoo_6dq`
UDOONEO=`echo "$OUT" | grep -c udooneo_6sx`
A62=`echo "$OUT" | grep -c a62_6dq`

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
    echo "   Unrecognized board. Path = $OUT"
    echo ""
    exit 0
fi

echo Distro Name selected: $NAME
rm -rf $NAME
rm -rf $NAME.tar.gz
mkdir $NAME

cp -v $OUT/u-boot-*.imx $NAME
cp -v $OUT/boot-*.img $NAME
cp -v $OUT/recovery*.img $NAME
simg2img $OUT/system.img $NAME/system.img
cp -v make_${board}_distro_sd.sh $NAME/make_sd.sh
cp -v README_make_uSD_${board}.txt ${NAME}
cp -v README_compile_Android_${board}.txt ${NAME}

tar czvf $NAME.tar.gz $NAME
