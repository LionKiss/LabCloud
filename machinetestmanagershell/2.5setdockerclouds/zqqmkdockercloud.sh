# !/bin/bash
#校园网登陆，敏感信息
function connect(){
  #connect internet
}
function disconnect(){
  #disconnect internet
}

# 基于裸机的准备工作
function readyBaseOnBare(){
    connect
    #关闭SELinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    #关闭防火墙
    firewall-cmd --state #查看默认防火墙状态（关闭后显示notrunning，开启后显示running）
    systemctl stop firewalld.service #停止firewall
    systemctl disable firewalld.service #禁止firewall开机启动
    #设置开机等待时间
    sed -i 's/set timeout=5/set timeout=1/g' /boot/grub2/grub.cfg
    #设置阿里云yum 源 参考链接https://blog.csdn.net/kangvcar/article/details/73477730
    #设置yum等待时间  避免网速过慢 导致失败
    sed -i '$a\timeout=120' /etc/yum.conf
    #安装wget
    yum --enablerepo=extras clean metadata
    yum install -y wget
    ll /etc/yum.repos.d/
    mkdir /opt/centos-yum.bak
    mv -f /etc/yum.repos.d/* /opt/centos-yum.bak/
    cd /etc/yum.repos.d/
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    yum clean all
    yum --enablerepo=extras clean metadata
    yum makecache 
    yum install -y deltarpm
    yum provides '*/applydeltarpm'
    #解决错误：open /etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt: no such file or directory
    yum install -y *rhsm*
    #使用yum源更新
    yum -y update

    #更新内核
    uname -sr
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
    yum --enablerepo=elrepo-kernel install -y kernel-ml
    #设置 GRUB 默认的内核版本
    sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    #接下来运行下面的命令来重新创建内核配置
    grub2-set-default 0
    grub2-mkconfig -o /boot/grub2/grub.cfg
    #重启
    reboot
    uname -sr

    #虚拟机的可进行快照（关机halt后快照占用的空间少）
}

#设置各个主机名以及ip和hostname映射
function host_hostname(){

cat > /etc/hostname <<EOF
$hostname
EOF

cat > /etc/hosts <<EOF
$IP_hostname
EOF

}
hostname=
IP_hostname=

function common_init_MsaterSalve(){
#配置镜像路径
cat > /etc/yum.repos.d/virt7-docker-common-release.repo << EOF
[virt7-docker-common-release]
name=virt7-docker-common-release
baseurl=http://cbs.centos.org/repos/virt7-docker-common-release/x86_64/os/
gpgcheck=0
EOF
connect
#Docker安装
yum -y install --enablerepo=virt7-docker-common-release kubernetes flannel etcd
#安装两次 确保软件都安装上，防止因网络慢而停下
connect
yum -y install --enablerepo=virt7-docker-common-release kubernetes flannel etcd
#配置etcd
#sed -i 's/ETCD_NAME=default/ETCD_NAME='$hostname'/' /etc/etcd/etcd.conf
sed -i 's/ETCD_LISTEN_CLIENT_URLS="http:\/\/.*:2379"/ETCD_LISTEN_CLIENT_URLS="http:\/\/0.0.0.0:2379"/;s/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/.*:2379"/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/0.0.0.0:2379"/' /etc/etcd/etcd.conf

#配置docker
#配置registry镜像库，表示可以从节点上拉取镜像 即为registry节点
#编辑/etc/sysconfig/docker文件 
sed -i 's/OPTIONS=\x27--selinux-enabled --log-driver=journald --signature-verification=false.*\x27/OPTIONS=\x27--selinux-enabled --log-driver=journald --signature-verification=false --registry-mirror=https:\/\/wzmto2ol.mirror.aliyuncs.com --insecure-registry '$registryHostname':5000 --add-registry '$registryHostname':5000\x27/' /etc/sysconfig/docker
#设置开机自启动并开启服务


#配置 /etc/kubernetes/kubelet文件
#注意：主节点也要编辑 /etc/kubernetes/kubelet 不然启动的时候是 127.0.0.1 不是主节点的名称
sed -i 's/KUBELET_ADDRESS="--address=.*"/KUBELET_ADDRESS="--address=0.0.0.0"/;s/KUBELET_HOSTNAME="--hostname-override=.*"/KUBELET_HOSTNAME="--hostname-override='$hostname'"/;s/KUBELET_API_SERVER="--api-servers=http:\/\/.*:8080"/KUBELET_API_SERVER="--api-servers=http:\/\/'$apiserverHostname':8080"/;s/KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=.*"/KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image='$registryHostname':5000\/pod-infrastructure"/;s/KUBELET_ARGS=.*/KUBELET_ARGS="--cluster-dns=10.254.10.2 --cluster-domain=hi --allow-privileged=true"/' /etc/kubernetes/kubelet

#Flannel一个网络管理工具，在master节点与slave节点中都需配置
#master、node上均编辑/etc/sysconfig/flanneld
#这里的docker1为etcd服务的节点的主机名
sed -i 's/FLANNEL_ETCD_ENDPOINTS="http:\/\/.*:2379"/FLANNEL_ETCD_ENDPOINTS="http:\/\/'$etcdHostname':2379"/;s/FLANNEL_ETCD_PREFIX=".*"/FLANNEL_ETCD_PREFIX="\/kube-centos\/network"/' /etc/sysconfig/flanneld
#在master节点中配置上文FLANNEL_ETCD_PREFIX对应文件/kube-centos/network的值 见下文

}
#配置dockercloud 所需的参数及执行函数common_init_MsaterSalve
hostname=
registryHostname=
apiserverHostname=
etcdHostname=

#单独配置master节点的脚本
#关于kubernetes：有五个组件 主节点需要配置apiserver config kubelet
function only_init_master(){

#配置Kubernets API Server
#编辑/etc/kubernetes/apiserver
sed -i 's/KUBE_API_ADDRESS="--insecure-bind-address=.*"/KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"/;s/KUBE_ETCD_SERVERS="--etcd-servers=http:\/\/.*:2379"/KUBE_ETCD_SERVERS="--etcd-servers=http:\/\/'$master_hostname':2379"/' /etc/kubernetes/apiserver
#去掉权限检查以免unable to create pods: No API token found for service account "default"
sed -i 's/KUBE_ADMISSION_CONTROL=.*/KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"/' /etc/kubernetes/apiserver
#编辑 /etc/kubernetes/config
sed -i 's/KUBE_MASTER="--master=http:\/\/.*:8080"/KUBE_MASTER="--master=http:\/\/'$master_hostname':8080"/' /etc/kubernetes/config
#/etc/kubernetes/kubelet 这个文件主从节点都要配置，所以抽象出来，放到公共的配置脚本中

#这里要启动etcd
systemctl start etcd
#在master节点中配置上文FLANNEL_ETCD_PREFIX对应文件/kube-centos/network的值
etcdctl mkdir /kube-centos/network
etcdctl mk /kube-centos/network/config "{ \"Network\": \"192.168.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"

}
master_hostname=

#单独配置salve节点的脚本
#配置Kubernets的组件Kubernets Proxy
#编辑 /etc/kubernetes/config
function only_init_salve(){
sed -i 's/KUBE_MASTER="--master=http:\/\/.*:8080"/KUBE_MASTER="--master=http:\/\/'$KUBE_master_hostname':8080"/' /etc/kubernetes/config
}
KUBE_master_hostname=

function registry_init_update(){
    connect
    #解决错误：open /etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt: no such file or directory
    yum install -y *rhsm*
	#部署kubernetes-dashboard.yaml：一个容器里面的是一个网站，用来显示集群部署环境，也是使用的集群的ui接口
	#http://172.16.2.14:5000/v2/_catalog 显示的自己私有镜像库的列表，即配置的registry节点地址
	#六个镜像下载地址
	#registry:2
	#直接pull下来，运行
	docker pull registry:2
	
	docker stop registry
	docker rm registry
	#浏览器访问http://172.16.2.14:5000/v2/_catalog 显示的自己私有镜像库的列表，又可能是空，但只要不报错就行
	docker run -d -p 5000:5000 --restart=always --name registry  registry:2
	
	#部署dashboard，将下面的两个链接直接pull下来
	#registry.access.redhat.com/rhel7/pod-infrastructure
	#docker.io/mritd/kubernetes-dashboard-amd64 
	
	connect
	docker pull docker.io/mritd/kubernetes-dashboard-amd64 
	docker pull registry.access.redhat.com/rhel7/pod-infrastructure
	#使用tag创建新的名称并上传到自己的镜像库，便于kubernetes-dashboard.yaml下载
	docker tag registry.access.redhat.com/rhel7/pod-infrastructure  node2:5000/pod-infrastructure:latest
	docker tag  docker.io/mritd/kubernetes-dashboard-amd64  node2:5000/kubernetes-dashboard-amd64:latest
	docker push node2:5000/pod-infrastructure
	docker push node2:5000/kubernetes-dashboard-amd64

	#部署dns方式重复部署dashboard的pull 、tag、push 步骤
	connect
	#docker.io/ist0ne/kubedns-amd64 
	docker pull docker.io/ist0ne/kubedns-amd64 
	docker tag  docker.io/ist0ne/kubedns-amd64 node2:5000/kubedns-amd64:latest
	docker push node2:5000/kubedns-amd64
    connect
	#docker.io/ist0ne/kube-dnsmasq-amd64 
	docker pull docker.io/ist0ne/kube-dnsmasq-amd64
	docker tag docker.io/ist0ne/kube-dnsmasq-amd64 node2:5000/kube-dnsmasq-amd64:latest
	docker push node2:5000/kube-dnsmasq-amd64
	connect
	#docker.io/ist0ne/exechealthz-amd64 
	docker pull docker.io/ist0ne/exechealthz-amd64 
	docker tag docker.io/ist0ne/exechealthz-amd64 node2:5000/exechealthz-amd64:latest
	docker push node2:5000/exechealthz-amd64
	#浏览器访问http://172.16.2.14:5000/v2/_catalog 这时就应该显示留个镜像了
    
	disconnect
}

registryinitupdate



#注意：这里的IP地址（172.16.2.14）和主机名（docker1）更换为自己的IP与主机名  还要主要image的镜像地址值
function dashboard_skydns_kubedns(){
  #dashboard
  cat > kubernetes-dashboard.yaml << EOF
# Configuration to deploy release version of the Dashboard UI.  
#  
# Example usage: kubectl create -f <this_file>  
  
kind: Deployment  
apiVersion: extensions/v1beta1  
metadata:  
  labels:  
    app: kubernetes-dashboard  
    version: v1.1.0  
  name: kubernetes-dashboard  
  namespace: kube-system
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: kubernetes-dashboard  
  template:  
    metadata:  
      labels:  
        app: kubernetes-dashboard  
    spec:  
      containers:  
      - name: kubernetes-dashboard  
        image: $registryHostname:5000/kubernetes-dashboard-amd64  
        imagePullPolicy: Always  
        ports:  
        - containerPort: 9090  
          protocol: TCP  
        args:  
          # Uncomment the following line to manually specify Kubernetes API server Host  
          # If not specified, Dashboard will attempt to auto discover the API server and connect  
          # to it. Uncomment only if the default does not work.  
          - --apiserver-host=http://$apiserver_host:8080
        livenessProbe:  
          httpGet:  
            path: /  
            port: 9090  
          initialDelaySeconds: 30  
          timeoutSeconds: 30  
---  
kind: Service  
apiVersion: v1  
metadata:  
  labels:  
    app: kubernetes-dashboard  
  name: kubernetes-dashboard  
  namespace: kube-system  
spec:  
  type: NodePort  
  ports:  
  - port: 80  
    targetPort: 9090  
  selector:  
    app: kubernetes-dashboard
EOF
  kubectl delete -f kubernetes-dashboard.yaml
  kubectl create -f kubernetes-dashboard.yaml
  kubectl get pods --all-namespaces
  kubectl describe pods/`kubectl get pods --all-namespaces | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl logs `kubectl get pods --all-namespaces | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl describe service/kubernetes-dashboard --namespace="kube-system"

  kubectl describe pods/`kubectl get pods --all-namespaces | grep 'kube-dns-v9' | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl logs `kubectl get pods --all-namespaces | grep 'kube-dns-v9' | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  
  cat > kube-dns_14.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-dns-v20
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    version: v20
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: kube-dns
    version: v20
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        version: v20
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
        scheduler.alpha.kubernetes.io/tolerations: '[{"key":"CriticalAddonsOnly", "operator":"Exists"}]'
    spec:
      containers:
      - name: kubedns
        image: kubedns-amd64
        imagePullPolicy: IfNotPresent
        resources:
          # TODO: Set memory limits when we've profiled the container for large
          # clusters, then set request = limit to keep this container in
          # guaranteed class. Currently, this container falls into the
          # "burstable" category so the kubelet doesn't backoff from restarting it.
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        livenessProbe:
          httpGet:
            path: /healthz-kubedns
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /readiness
            port: 8081
            scheme: HTTP
          # we poll on pod startup for the Kubernetes master service and
          # only setup the /readiness HTTP server once that's available.
          initialDelaySeconds: 3
          timeoutSeconds: 5
        args:
        # command = "/kube-dns"
        - --domain=hi
        - --dns-port=10053
        - --kube-master-url=http://$kube_master_url:8080
        ports:
        - containerPort: 10053
          name: dns-local
          protocol: UDP
        - containerPort: 10053
          name: dns-tcp-local
          protocol: TCP
      - name: dnsmasq
        image: kube-dnsmasq-amd64
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /healthz-dnsmasq
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        args:
        - --cache-size=1000
        - --no-resolv
        - --server=127.0.0.1#10053
        - --log-facility=-
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      - name: healthz
        image: exechealthz-amd64
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 50Mi
          requests:
            cpu: 10m
            # Note that this container shouldn't really need 50Mi of memory. The
            # limits are set higher than expected pending investigation on #29688.
            # The extra memory was stolen from the kubedns container to keep the
            # net memory requested by the pod constant.
            memory: 50Mi
        args:
        - --cmd=nslookup kubernetes.default.svc.hi 127.0.0.1 >/dev/null
        - --url=/healthz-dnsmasq
        - --cmd=nslookup kubernetes.default.svc.hi 127.0.0.1:10053 >/dev/null
        - --url=/healthz-kubedns
        - --port=8080
        - --quiet
        ports:
        - containerPort: 8080
          protocol: TCP
      dnsPolicy: Default  # Don't use cluster DNS.
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeDNS"
spec:
  type: NodePort  
  selector:
    k8s-app: kube-dns
  clusterIP: 10.254.10.2
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF

  #skydns-rc skydns-svc
  for SERVICES in kube-dns_14; do
    kubectl delete -f $SERVICES.yaml
    kubectl create -f $SERVICES.yaml  
    #kubectl apply -f nginx.yaml
    #kubectl describe pods/nginx
  done


}

registryHostname=
apiserver_host=
kube_master_url=
#dashboard_skydns_kubedns

# 主节点启动
function startMasterSoftware(){
  for SERVICES in etcd docker kube-apiserver kube-controller-manager kube-scheduler flanneld  kubelet kube-proxy; do
      systemctl restart $SERVICES
      systemctl enable $SERVICES
      systemctl status $SERVICES
  done
}
function startSlaveSoftware(){
  for SERVICES in kube-proxy kubelet flanneld docker; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
  done
}
start_docker_cloud





