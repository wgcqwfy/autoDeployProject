#!/usr/bin/expect
if {$argc<5} {
    echo "fetchZipFile.sh脚本缺少参数，执行fetchZipFile.sh脚本失败。"
}
set file [lindex $argv 0]
set path [lindex $argv 1]
set ip [lindex $argv 2]
#scp -r root@${ip}:/opt/release/${file} /opt/release/${path}
set fetch_file_service_path [lindex $argv 3]
set password [lindex $argv 4]
spawn scp -r root@${ip}:${fetch_file_service_path}/${file} ${path}
set timeout 200
expect "*password:"
send "$password\r"
send "exit\r"
expect eof