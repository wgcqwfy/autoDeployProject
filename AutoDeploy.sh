#!/bin/bash
if [ $# -lt 10 ]; then
    echo "AutoDeploy.sh脚本缺少参数，执行AutoDeploy.sh脚本失败。"
fi

#获取需要的下载文件的服务器IP
#url=$1
#获取当前的日期
today=$(date +%Y%m%d)
#获取当前系统时间
time=$(date +%Y%m%d%H%M%S)
#fetchZipFile.sh脚本的路径
shell_fetch_file_script_path=$1
#发布实例的实例文件的路径
releasePath=$2
#实例zip名
app_file=$3
#配置文件zip名
config_file=$4
#实例日志名
instance_log=$5_${time}
#实例名称
instanceName=$6
#实例的父级目录
parentPath=$7
#实例路径
path=$8
#要获取文件的服务器IP
ip=$9
#发布实例所需文件所在的服务器的路径
fetch_file_service_path=${10}
#要获取文件的服务器的root用户的密码
password=${11}
#创建父级目录是否从根目录创建
createDirFromRootDirectory=${12}

if [ ! -n "$createDirFromRootDirectory" ]; then
	createDirFromRootDirectory="N"
fi

#创建实例的父级目录
if [ "$createDirFromRootDirectory" = "Y" ];then
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

#日志输出
cd /var/log/
if [ ! -d "ofbizRelease" ]; then
	echo "创建工程日志根目录ofbizRelease"
	mkdir ofbizRelease
fi
cd /var/log/ofbizRelease/
if [ ! -e "${instance_log}.log" ]; then
	echo "在ofbizRelease中创建日志文件${instance_log}.log"
	touch ${instance_log}.log
fi
log_file="/var/log/ofbizRelease/${instance_log}.log"

echo "------------------------------------${time}.log.START---------------------------------------" >> ${log_file}
#在实例服务器上创建目录存放获取更新后的zip包的路径
cd /${releasePath}/ >> ${log_file}
if [ ! -d "${today}" ]; then
	echo "在${releasePath}目录中创建目录${today}" >> ${log_file}
	mkdir ${today}
fi
#进入目标目录
cd ${today}/ >> ${log_file}
#每个实例一个文件，防止多线程出现错误
if [ ! -d "${instanceName}" ]; then
	echo "创建目录${instanceName}" >> ${log_file}
	mkdir ${instanceName} 
	cd ${instanceName}/ >> ${log_file}
fi
#获取需要更新的sourceCode
if [[ $? -eq 0 ]]; then
	echo "开始获取本次发布所需要更新的文件！" >> ${log_file}
fi

#wget ${url}:8080/images/app.zip

getFile=$(${shell_fetch_file_script_path}/fetchZipFile.sh ${app_file}.zip ${releasePath}/${today}/${instanceName}/ ${ip} ${fetch_file_service_path} ${password})
errorMessage="Unable to access jarfile"

echo "${getFile}" |grep -q "${errorMessage}"
if [ $? -eq 0 ]; then
	echo "当前没有jarfile ofbiz.jar，先进行编译，开始编译。" >> ${log_file}
	cd ${path}/ >> ${log_file}
	./ant clean >> ${log_file}
	./ant >> ${log_file}
	echo "编译结束，开始重新获取本次发布所需要更新的文件！" >> ${log_file}
	getFile=$(${shell_fetch_file_script_path}/fetchZipFile.sh ${app_file}.zip ${releasePath}/${today}/${instanceName}/ ${ip} ${fetch_file_service_path} ${password})
	echo "${getFile}" |grep -q "${errorMessage}"
	if [ $? -eq 0 ]; then
		echo "获取本次发布所需要更新的文件，请联系管理员！" >> ${log_file}
		exit 1
	else 
		echo "重新命名source的zip文件" >> ${log_file}
	fi
else
	echo "重新命名source的zip文件" >> ${log_file}
fi

#重新命名该zip文件为app_XXXXXXXXXXXXXX.zip
cd /${releasePath}/${today}/${instanceName}/ >> ${log_file}
rename ${app_file}.zip app_${time}.zip ${app_file}.zip >> ${log_file}
if [[ $? -eq 0 ]]; then
	echo "开始获取配置文件！" >> ${log_file}
else
	echo "重命名${app_file}.zip失败！" >> ${log_file}
	exit 1
fi
#获取配置文件
${shell_fetch_file_script_path}/fetchZipFile.sh ${config_file}.zip ${releasePath}/${today}/${instanceName}/ ${ip} ${fetch_file_service_path} ${password} >> ${log_file}
if [[ $? -eq 0 ]]; then
	echo "重新命名config的zip文件！" >> ${log_file}
else
	echo "从获取配置文件失败！" >> ${log_file}
	exit 1
fi
#重新命名该zip文件为appConfig1_XXXXXXXXXXX.zip
cd /${releasePath}/${today}/${instanceName}/ >> ${log_file}
rename ${config_file}.zip ${config_file}_${time}.zip ${config_file}.zip >> ${log_file}
if [[ $? -eq 0 ]]; then
	echo "开始解压app_${time}.zip！" >> ${log_file}
else
	echo "重命名${config_file}.zip失败！" >> ${log_file}
	exit 1
fi
#解压获取的sourceCode
cd /${releasePath}/${today}/${instanceName}/ >> ${log_file}
unzip -o app_${time}.zip -d ${path} >> ${log_file}
if [[ $? -eq 0 ]]; then
	echo "开始解压${config_file}_${time}.zip！" >> ${log_file}
else
	echo "解压app_${time}.zip失败！" >> ${log_file}
	exit 1
fi

#解压获取的配置文件
unzip -o ${config_file}_${time}.zip -d ${path} >> ${log_file}
if [[ $? -eq 0 ]]; then
	echo "开始停止当前实例进程" >> ${log_file}
else
	echo "解压${config_file}_${time}.zip失败！" >> ${log_file}
	exit 1
fi
#停止当前进程中的实例
cd ${path}/

#修改ant、stopofbiz.sh,startofbiz.sh等文件的属性
#chmod -R 755 tools/
chmod 755 stopb2csys.sh
chmod 755 startb2csys.sh
chmod 755 ant

pwd >> ${log_file}
#result=$(./tools/stopofbiz.sh 2>&1);
result=$(./stopb2csys.sh 2>&1);
#resultStr="OFBiz is Down"
resultStr="Connection refused"
#通过判断打印字符串中是否包含OFBiz is Down，来确定当前进程是否停止成功
echo "${result}" |grep -q "${resultStr}"
if [ $? -eq 0 ]; then
	echo "停止当前实例进程成功" >> ${log_file}
	echo "正在编译文件" >> ${log_file}
else
	resultErrorStr="Unable to access jarfile"
	echo "${result}" |grep -q "${resultErrorStr}"
	if [ $? -eq 0 ]; then
		echo "当前还未启动工程。" >> ${log_file}
		#如果是第一次发布则需要先对项目进行ant
		./ant clean >> ${log_file}
		./ant >> ${log_file}
	else
		index=2
		while((${index}<11))
		do
			result=$(./stopb2csys.sh 2>&1);
			echo "${result}" |grep -q "${resultStr}"
			if [ $? -eq 0 ]; then
				break
			else
				echo "正在第${index}次尝试停止当前实例进程。" >> ${log_file}
			fi
			index=$((${index}+1));
		done
		echo "${result}" |grep -q "${resultStr}"
		if [ $? -eq 0 ]; then
			echo "停止当前实例进程成功" >> ${log_file}
			echo "正在编译文件" >> ${log_file}
		else
			echo "停止当前实例进程失败，请联系管理员。" >> ${log_file}
			echo "------------------------------------${time}.log.END---------------------------------------" >> ${log_file}
			exit 1
		fi
	fi
fi

#编译
cd ${path}/ >> ${log_file}
./ant clean >> ${log_file}
./ant >> ${log_file}
if [[ $? -eq 0 ]]; then
	echo "编译成功" >> ${log_file}
	echo "正在启动实例" >> ${log_file}
else
	echo "编译失败，请确认！" >> ${log_file}
	exit 1
fi
#启动实例
#setsid ./tools/startofbiz.sh &
setsid ./startb2csys.sh &
if [[ $? -eq 0 ]]; then
	echo "启动实例${instanceName}成功" >> ${log_file}
	echo "------------------------------------${time}.log.END---------------------------------------" >> ${log_file}
else
	echo "启动实例${instanceName}失败" >> ${log_file}
	echo "------------------------------------${time}.log.END---------------------------------------" >> ${log_file}
	exit 1
fi

exit 0