#!/bin/bash

#获取当前系统的日期
today=$(date +%Y%m%d)

#获取当前系统的时间
time=$(date +%Y%m%d%H%M%S)

#配置文件的路径
properties_file_path=$PWD
if [ $# -ge 1 ]; then
	properties_file_path=$1
fi

#判断日志目录是否存在
cd /var/log/
if [ ! -d "ofbizRelease" ]; then 
	echo "创建日志目录ofbizRelease"
	mkdir ofbizRelease
fi

#判断当前日志目录是否存在当天的日志文件
cd ofbizRelease/
if [ ! -e "release_${today}.log" ]; then 
	echo "创建日志release_${today}.log"
	touch release_${today}.log
fi
	 
#日志文件路径
log_file="/var/log/ofbizRelease/release_${today}.log"

#远程操作用户
user=root
echo "------------------------ReleaseControlCenter.sh---${time}----START---------------------------------" >>  ${log_file}

#读取工程发布所需的配置文件
serviceDeployControlFile="${properties_file_path}/serviceDeploy.properties"

if [ ! -f "${serviceDeployControlFile}" ]; then
	echo "没有读取到工程发布所需的配置文件（serviceDeploy.properties）" >>  ${log_file}
	echo "没有读取到工程发布所需的配置文件（serviceDeploy.properties）"
	echo "------------------------ReleaseControlCenter.sh---${time}----END---------------------------------" >>  ${log_file}
	exit 1
fi

cat ${serviceDeployControlFile} | while read LINE
do
	#发布实例的服务器IP
	ip=$(echo ${LINE} | awk -F ',' '{print $1}')
	#自动发布的脚本所在的路径
	shell_deploy_script_path=$(echo ${LINE} | awk -F ',' '{print $2}')
	#获取文件脚本所在的路径
	shell_fetch_file_script_path=$(echo ${LINE} | awk -F ',' '{print $3}')
	#发布实例的日志名
	log_file_name=$(echo ${LINE} | awk -F ',' '{print $4}')
	#发布实例的实例名
	instance=$(echo ${LINE} | awk -F ',' '{print $5}')
	#发布实例所需要的差异的zip包路径
	release_file_path=$(echo ${LINE} | awk -F ',' '{print $6}')
	#发布实例所需的source的zip包名
	release_file_zip=$(echo ${LINE} | awk -F ',' '{print $7}')
	#发布实例所需的配置文件的zip包名
	release_config_file=$(echo ${LINE} | awk -F ',' '{print $8}')
	#发布实例的实例的父路径
	parentPath=$(echo ${LINE} | awk -F ',' '{print $9}')
	#发布实例的实例绝对路径
	path=$(echo ${LINE} | awk -F ',' '{print $10}')
	#发布实例所需文件所在的服务器的IP
	fetch_file_service_ip=$(echo ${LINE} | awk -F ',' '{print $11}')
	#发布实例所需文件所在的服务器的路径
	fetch_file_service_path=$(echo ${LINE} | awk -F ',' '{print $12}')
	#发布实例所需文件所在的服务器的密码
	fetch_file_service_pwd=$(echo ${LINE} | awk -F ',' '{print $13}')
	#创建实例父路径是否从跟路径创建
	createParentDirectoryFromRootDirectoryFlag=$(echo ${LINE} | awk -F ',' '{print $14}')
	#启动实例
	if [ $? -eq 0 ]; then
	echo "正在启动${ip}服务器的${path}实例" >>  ${log_file}
	fi
	#非交互式远程执行脚本AutoDeploy.sh
	echo "当前配置的参数是：" >>  ${log_file}
	echo "ip=${ip} " >>  ${log_file}
	echo "shell_deploy_script_path=${shell_deploy_script_path} " >>  ${log_file}
	echo "shell_fetch_file_script_path=${shell_fetch_file_script_path} " >>  ${log_file}
	echo "log_file_name=${log_file_name} " >>  ${log_file}
	echo "release_file_path=${release_file_path} " >>  ${log_file}
	echo "release_file_zip=${release_file_zip} " >>  ${log_file}
	echo "release_config_file=${release_config_file} " >>  ${log_file}
	echo "parentPath=${parentPath} " >>  ${log_file}
	echo "path=${path} " >>  ${log_file}
	echo "instance=${instance} " >>  ${log_file}
	echo "fetch_file_service_ip=${fetch_file_service_ip} " >>  ${log_file}
	echo "fetch_file_service_path=${fetch_file_service_path} " >>  ${log_file}
	echo "fetch_file_service_pwd=${fetch_file_service_pwd} " >>  ${log_file}
	echo "createParentDirectoryFromRootDirectoryFlag=${createParentDirectoryFromRootDirectoryFlag} " >>  ${log_file}
	setsid ssh ${user}@${ip} ". /etc/profile; ${shell_deploy_script_path}/AutoDeploy.sh ${shell_fetch_file_script_path} ${release_file_path} ${release_file_zip} ${release_config_file} ${log_file_name} ${instance} ${parentPath} ${path} ${fetch_file_service_ip} ${fetch_file_service_path} ${fetch_file_service_pwd} ${createParentDirectoryFromRootDirectoryFlag} & " &
	if [ $? -eq 0 ]; then
		echo "启动${ip}服务器的${instance}实例成功" >>  ${log_file}
	else
		echo "启动${ip}服务器的${instance}实例失败" >>  ${log_file}
		exit 1
	fi

done

echo "------------------------ReleaseControlCenter.sh---${time}----END---------------------------------" >>  ${log_file}
exit 0
