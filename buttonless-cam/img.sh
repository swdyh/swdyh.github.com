#!/bin/sh

declare -a array=("IMG_0660.jpg" "IMG_8190.jpg" "IMG_8420.jpg" "IMG_9793.jpg" "IMG_9302.jpg")
i=0
for e in ${array[@]}; do
    cp ~/dev/ios/buttonless-cam-asset/itunesconnect_sc/${e} .
    f=`echo ${e} | sed 's/\..*//g'`
    sips -Z 600 ${e} --out ${f}_t.jpg
    let i++
done

i=0
for e in ${array[@]}; do
    f=`echo ${e} | sed 's/\..*//g'`
    echo '<a href="'${e}'"><img class="photo" src="'${f}_t.jpg'"/></a>'
done
