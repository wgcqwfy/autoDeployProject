#!/bin/bash
parentPath='/opt/20160205/apps'
#是否从根目录创建
flag='N'
if [ $flag == 'Y' ];then
	cd /
fi

index_pPath=1
while((1==1))
do
	split=`echo $parentPath|cut -d "/" -f$index_pPath`
	((index_pPath++))
	split2=`echo $parentPath|cut -d "/" -f$index_pPath`

	#如果父目录参数包含‘/’则进行分割，创建每一个目录
	if [[ $parentPath =~ "/" ]];then
		if [ "$split" != "" ] || [ "$split2" != "" ];then
			if [ "$split" != "" ] ;then
					#如果当前目录下有该目录，则不创建，否则创建该目录
					if [ ! -d "$split" ]; then
							mkdir $split
					fi
					cd $split
			else
					continue
			fi
		else
			break
		fi
	else
		if [ "$split" != "" ];then
			if [ ! -d "$split" ]; then
				 mkdir $split
				 cd $split
				 break
			fi
		fi
	fi
done