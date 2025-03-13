#! /bin/bash

list0=(1 "\t" 3 4 5)
# list1=(9 8 5 3 2)
#
# for item in ${list0[@]} ${list1[@]}; do
# 	echo "item = ${item}"
# done
while read item0 item1 item2; do
	echo -e "item:\n${item0}\n${item1}\n${item2}"
done <<<${list0[@]}
