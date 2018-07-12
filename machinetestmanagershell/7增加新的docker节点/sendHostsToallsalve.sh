# !/bin/bash
#校园网登陆，敏感信息
function connect(){
  #connect internet
}
function disconnect(){
  #disconnect internet
}
#将主节点/etc/hsots文件中的主机名与IP映射重新发至所有从节点

hostpwdIP_hostname=

#将新增的IP与主机名映射添加/etc/hosts文件
function AddNewSlaveHosts(){
cat >> /etc/hosts <<EOF
$IP_hostname
EOF
}
AddNewSlaveHosts

#重新发至所有从节点
function sendHostsToallsalve(){
    connect
    yum install -y expect
    for ss in `cat /etc/hosts | awk '{print $1}'`;
	do 
    expect -c "set timeout -1;
        spawn scp /etc/hosts root@$ss:/etc/hosts;
        expect {
            *(yes/no)* {send -- yes\r;exp_continue;}
            *assword:* {send -- $hostpwd\r;exp_continue;}
            eof        {exit 0;}
        }";
	done
}
sendHostsToallsalve