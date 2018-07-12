# !/bin/bash

hostname=
registryHostname=
apiserverHostname=
etcdHostname=

chmod +x common_init_MsaterSalve_tmp*
#这里准备写个脚本文件，
function connect(){
  #connect internet
}
function disconnect(){
  #disconnect internet
}


#更新yum源 
function yumupdate(){
disconnect
connect
yum clean all
yum --enablerepo=extras clean metadata
yum -y update
yum install -y deltarpm
yum provides '*/applydeltarpm'
disconnect
}
#一般yum源在基础镜像中已经更新好了的最新版本，这里就不更新了
#yumupdate


#install etcd
function init_edit_etcd.conf(){
connect
yum install -y etcd 
disconnect
sed -i 's/ETCD_NAME=default/ETCD_NAME='$hostname'/' /etc/etcd/etcd.conf
sed -i 's/ETCD_LISTEN_CLIENT_URLS="http:\/\/.*:2379"/ETCD_LISTEN_CLIENT_URLS="http:\/\/0.0.0.0:2379"/;s/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/.*:2379"/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/0.0.0.0:2379"/' /etc/etcd/etcd.conf
}
#install Docker
function init_edit_docker(){
#配置镜像路径
cat > /etc/yum.repos.d/virt7-docker-common-release.repo << EOF
[virt7-docker-common-release]
name=virt7-docker-common-release
baseurl=http://cbs.centos.org/repos/virt7-docker-common-release/x86_64/os/
gpgcheck=0
EOF
connect
#Docker安装
yum -y install --enablerepo=virt7-docker-common-release kubernetes flannel
disconnect
#配置registry镜像库，表示可以从节点上拉取镜像 即为registry节点
#编辑/etc/sysconfig/docker文件 
sed -i 's/OPTIONS=\x27--selinux-enabled --log-driver=journald --signature-verification=false.*\x27/OPTIONS=\x27--selinux-enabled --log-driver=journald --signature-verification=false --registry-mirror=https:\/\/wzmto2ol.mirror.aliyuncs.com --insecure-registry '$registryHostname':5000 --add-registry '$registryHostname':5000\x27/' /etc/sysconfig/docker
#设置开机自启动并开启服务
systemctl enable docker
systemctl start docker
}
#install kubernetes
#配置 /etc/kubernetes/kubelet文件
function init_edit_kubernetes(){
connect
#yum -y install kubernetes
disconnect
#注意：主节点也要编辑 /etc/kubernetes/kubelet 不然启动的时候是 127.0.0.1 不是主节点的名称
sed -i 's/KUBELET_ADDRESS="--address=.*"/KUBELET_ADDRESS="--address=0.0.0.0"/;s/KUBELET_HOSTNAME="--hostname-override=.*"/KUBELET_HOSTNAME="--hostname-override='$hostname'"/;s/KUBELET_API_SERVER="--api-servers=http:\/\/.*:8080"/KUBELET_API_SERVER="--api-servers=http:\/\/'$apiserverHostname':8080"/;s/KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=.*"/KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image='$registryHostname':5000\/pod-infrastructure"/;s/KUBELET_ARGS=.*/KUBELET_ARGS="--cluster-dns=10.254.10.2 --cluster-domain=hi --allow-privileged=true"/' /etc/kubernetes/kubelet
}
#install Flannel
#Flannel一个网络管理工具，在master节点与slave节点中都需安装
function init_edit_flannel(){
#yum install -y flannel
#master、node上均编辑/etc/sysconfig/flanneld
#这里的docker1为etcd服务的节点的主机名
sed -i 's/FLANNEL_ETCD_ENDPOINTS="http:\/\/.*:2379"/FLANNEL_ETCD_ENDPOINTS="http:\/\/'$etcdHostname':2379"/;s/FLANNEL_ETCD_PREFIX=".*"/FLANNEL_ETCD_PREFIX="\/kube-centos\/network"/' /etc/sysconfig/flanneld
#在master节点中配置上文FLANNEL_ETCD_PREFIX对应文件/kube-centos/network的值 见下文
#注意  这一句经过了本人一个月的实践与磨练
#原理是： 0.7版本的flannel在启动之前或者说集群部署之后都会将路由转发规则写入iptables，利用iptables -L命令可查看。
#192.168.0.0/16 是我们设置的etcd网络段
iptables -I FORWARD -s 192.168.0.0/16 -j ACCEPT 
}
init_edit_etcd.conf
init_edit_docker
init_edit_kubernetes
init_edit_flannel