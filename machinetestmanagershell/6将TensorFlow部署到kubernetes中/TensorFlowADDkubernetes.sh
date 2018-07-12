# !bin/bash

function connect(){
  #connect internet
}
function disconnect(){
  #disconnect internet
}

registryHostname=node2

#参考链接：http://www.cnblogs.com/xuxinkun/p/5983633.html
connect
#搜索TensorFlow
docker search tensorflow
#注意变量声明赋值不能有空格
nic=`docker search tensorflow | awk '{print $2}' | sed -n '2p;2q'`
docker pull $nic
docker stop registry
docker rm registry
#浏览器访问http://172.16.2.14:5000/v2/_catalog 显示的自己私有镜像库的列表，又可能是空，但只要不报错就行
docker run -d -p 5000:5000 --restart=always --name registry  registry:2
docker tag $nic node2:5000/tensorflow/tensorflow:latest
docker push node2:5000/tensorflow/tensorflow

做一个带有ifconfig telnet netstat
cat > Dockerfile <<EOF
FROM node2:5000/tensorflow/tensorflow:1.2.0
RUN curl "http://202.193.80.124/" -H "Pragma: no-cache" -H "Origin: http://202.193.80.124" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --data "DDDDD=g102016452&upass=03141b2b5032ba8c682103364b93ce2a123456781&R1=0&R2=1&para=00&0MKKey=123456" --compressed | grep "Please don't forget to log out after you have finished."
RUN apt-get update 
RUN apt-get install -y iputils-ping
RUN apt-get install -y net-tools 
EOF
docker build -t tensorflow/tensorflow1.2.0 .
docker run -d -p 8888:8888 -p 6006:6006 --name=tensorflow1 node2:5000/tensorflow/tensorflow1.2.0:latest


创建挂载卷及数据集存储目录与运行程序，将数据集传至mnist_data，程序文件传至/root/dataset/
mkdir -p /root/dataset/mnist_data
rm -rf /root/dataset/SimpleDistribut.py
scp -r /root/dataset/ root@node2:/root/
scp -r /root/dataset/ root@node3:/root/
scp -r /root/dataset/ root@node4:/root/
#workingDir: /root/dataset/
编写四个yaml文件 使用vlume方式

Node添加label标记
kubectl label nodes node1 nodelist=distribute
kubectl label nodes node0 nodelist=distribute
#将节点的label标记删除
kubectl label nodes node2 foo nodelist-
#nodeSelector: nodelist:distribute
kubectl get nodes --show-labels

image_url=node0:5000/tensorflow/tensorflow:1.3.0
cat > ps.yaml <<EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: tensorflow-ps-rc
spec:
  replicas: 2
  selector:
    name: tensorflow-ps
  template:
    metadata:
      labels:
        name: tensorflow-ps
        role: ps
    spec:
      containers:
        - name: ps
          image: $image_url
          ports:
           - containerPort: 32222
          workingDir: /root/dataset/
          volumeMounts:
          - name: dataset
            mountPath: /root/dataset/
      nodeSelector: 
        nodelist: distribute
      volumes:
      - name: dataset
        hostPath:
          path: /root/dataset/
EOF

cat > ps-srv.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    name: tensorflow-ps
    role: service
  name: tensorflow-ps-service
spec:
  ports:
    - port: 32222
      targetPort: 32222
  selector:
    name: tensorflow-ps
EOF

cat > worker.yaml <<EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: tensorflow-worker-rc
spec:
  replicas: 2
  selector:
    name: tensorflow-worker
  template:
    metadata:
      labels:
        name: tensorflow-worker
        role: worker
    spec:
      containers:
        - name: worker
          image: $image_url
          ports:
           - containerPort: 32222
          workingDir: /root/dataset/
          volumeMounts:
          - name: dataset
            mountPath: /root/dataset/
      nodeSelector: 
        nodelist: distribute
      volumes:
      - name: dataset
        hostPath:
          path: /root/dataset/
EOF

cat > worker-srv.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    name: tensorflow-worker
    role: service
  name: tensorflow-wk-service
spec:
  ports:
    targetPort: 32222
  selector:
    name: tensorflow-worker
EOF

cat > ps-pssvc-wk-wksvc.yaml <<EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: tensorflow-ps-rc
spec:
  replicas: 2
  selector:
    name: tensorflow-ps
  template:
    metadata:
      labels:
        name: tensorflow-ps
        role: ps
    spec:
      containers:
        - name: ps
          image: $image_url
          ports:
           - containerPort: 32222
          workingDir: /root/dataset/
          volumeMounts:
          - name: dataset
            mountPath: /root/dataset/
      nodeSelector: 
        nodelist: distribute
      volumes:
      - name: dataset
        hostPath:
          path: /root/dataset/
---
apiVersion: v1
kind: Service
metadata:
  labels:
    name: tensorflow-ps
    role: service
  name: tensorflow-ps-service
spec:
  ports:
    - port: 32222
      targetPort: 32222
  selector:
    name: tensorflow-ps
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: tensorflow-worker-rc
spec:
  replicas: 2
  selector:
    name: tensorflow-worker
  template:
    metadata:
      labels:
        name: tensorflow-worker
        role: worker
    spec:
      containers:
        - name: worker
          image: $image_url
          ports:
           - containerPort: 32222
          workingDir: /root/dataset/
          volumeMounts:
          - name: dataset
            mountPath: /root/dataset/
      nodeSelector: 
        nodelist: distribute
      volumes:
      - name: dataset
        hostPath:
          path: /root/dataset/
---
apiVersion: v1
kind: Service
metadata:
  labels:
    name: tensorflow-worker
    role: service
  name: tensorflow-wk-service
spec:
  ports:
    - port: 32222
      targetPort: 32222
  selector:
    name: tensorflow-worker
EOF
for ss in `ll /root/dataset | grep yaml | awk '{print $9}'`;
do
echo $ss;
kubectl delete -f $ss
done

for ss in 1 2 3 4;
do
docker run -itd --name c$ss busybox
done

docker run -itd --name c1 busybox
docker exec -it c1 sh

docker run -itd --name c2 busybox
docker exec -it c2 sh

docker run -itd --name c3 busybox
docker exec -it c3 sh

for ss in 1 2 3;
do
docker stop c$ss 
docker rm c$ss 
done


for ss in `docker ps -a | grep Exited | awk '{print $1}'`; do docker rm $ss ; done

kubectl create -f ps1.yaml
kubectl create -f ps2.yaml
kubectl create -f worker1.yaml
kubectl create -f worker2.yaml
kubectl create -f ps-srv.yaml
kubectl create -f worker-srv.yaml


kubectl create -f ps-pssvc-wk-wksvc.yaml
#查看service来查看对应的容器的ip
kubectl describe service tensorflow-ps-service
kubectl describe service tensorflow-wk-service

docker ps -a | grep ten

docker exec -it `docker ps -a | grep ten | grep k8s_ps | awk '{print $1}'` /bin/bash

docker exec -it `docker ps -a | grep ten | grep k8s_work | awk '{print $1}'` /bin/bash

docker inspect `docker ps -a | grep ten | grep k8s_ps | awk '{print $1}'` | grep IPAddress
docker inspect `docker ps -a | grep ten | grep k8s_work | awk '{print $1}'` | grep IPAddress


kubectl create -f monitoring-namespase.yaml 
#现下载部署node-exporter
#http://www.do1618.com/wp-content/uploads/2016/08/node-exporter.zip
#在修改镜像下载
#启动
cd /root/prometheus/node-exporter
unzip node-exporter.zip
kubectl delete -f node-exporter.yaml
kubectl create -f node-exporter.yaml

#参考链接 https://prometheus.io/docs/introduction/getting_started/
#下载prometheus  https://github.com/prometheus/prometheus/releases/download/v1.8.2/prometheus-1.8.2.linux-amd64.tar.gz
wget https://github.com/prometheus/prometheus/releases/download/v1.8.2/prometheus-1.8.2.linux-amd64.tar.gz
tar -zxvf prometheus-*.tar.gz
cd prometheus-*
#备份
cp prometheus.yml prometheus.yml.back

cat > prometheus.yml <<EOF
global:
  scrape_interval: 20s
  scrape_timeout: 10s
  evaluation_interval: 20s

scrape_configs:
- job_name: 'kubernetes-nodes-cadvisor'
  kubernetes_sd_configs:
  - api_server: 'http://172.16.2.123:8080'
    role: node
  relabel_configs:
  - action: labelmap
    regex: __meta_kubernetes_node_label_(.+)
  - source_labels: [__meta_kubernetes_role]
    action: replace
    target_label: kubernetes_role
    #将默认10250端口改成10255端口
  - source_labels: [__address__]
    regex: '(.*):10250'
    replacement: '${1}:10255'
    target_label: __address__
#以下是监控每个宿主机，需要安装node-exporter    
- job_name: 'kubernetes_node'
  kubernetes_sd_configs:
  - role: node
    api_server: 'http://172.16.2.123:8080'
  relabel_configs:
  - source_labels: [__address__]
    regex: '(.*):10250'
    replacement: '${1}:9100'
    target_label: __address__

EOF
#执行
./prometheus --config.file=prometheus.yml
#关闭Prometheus
kill -SIGTERM $(pidof prometheus)


# #安装go语言golang
yum install -y wget
#通常yum上的文件版本比较低 所以使用链接下载go,如果链接不成，可使用迅雷下载
wget https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.9.linux-amd64.tar.gz
vi ~/.profile
export PATH=$PATH:/usr/local/go/bin
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$HOME/go/bin
source ~/.profile
mkdir /root/go
# yum install -y golang
# mkdir /root/Goworkspace
# echo 'export GOPATH="root/Goworkspace"' >> ~/.bashrc
# source ~/.bashrc
# #检查go版本
# go version

# #测试案例
# yum install -y git
# # Fetch the client library code and compile example.
# git clone https://github.com/prometheus/client_golang.git
# cd client_golang/examples/random
# #get         download and install packages and dependencies
# #The -d flag instructs get to stop after downloading the packages; that is,it instructs get not to install the packages.
# go get -d
# go build
# # Start 3 example targets in separate terminals:
# ./random -listen-address=:8091
# ./random -listen-address=:8092
# ./random -listen-address=:8093
# #没成功先跳过 往下看看吧，这里就不记录了

#使用promtool来检测规则文件
./promtool check-rules prometheus.rules


#安装Grafana 官网http://docs.grafana.org/installation/rpm/
#下载，如果比较慢的话，可以从迅雷中下载
wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.6.1-1.x86_64.rpm
yum install -y initscripts fontconfig urw-fonts
rpm -Uvh grafana-4.6.1-1.x86_64.rpm
#启动
/bin/systemctl daemon-reload
/bin/systemctl enable grafana-server.service
/bin/systemctl start grafana-server.service
service grafana-server start
service grafana-server stop

#http://172.16.2.144:3000/ admin admin

# #To configure the Grafana server to start at boot time:
# /sbin/chkconfig --add grafana-server
# #Start the server (via systemd)
# systemctl daemon-reload
# systemctl start grafana-server
# systemctl status grafana-server
# #Enable the systemd service to start at boot
# sudo systemctl enable grafana-server.service


#以集群的方式运行容器



#能看到内存
sum(process_resident_memory_bytes{job="apiserver"})
#启动前杀死
netstat -nlp |grep 9090
kill -9
./prometheus -config.file=prometheus.yml -web.listen-address ":9090" -log.level=debug 2>&1 >> run.log &


rate(process_cpu_seconds_total{job=~"apiserver|etcd-server-v2"}[20s])
rate(http_request_duration_microseconds_count{job="apiserver"}[5m])
rate(http_request_duration_microseconds_count{job="etcd-server-v2"}[5m])
#{job=~".*"} 模糊匹配 
rate(container_cpu_usage_seconds_total{pod_name=~"tensorflow.*"}[5m])
#多样匹配
rate(container_cpu_usage_seconds_total{container_name=~"ps|worker"}[5m])
#s - seconds，m - minutes ，h - hours，d - days，w - weeks，y - years
#返回了一个星期前http_requests_total的5分钟速率:
rate(http_requests_total[5m] offset 1w)

#Arithmetic binary operators
#+ (addition)，- (subtraction)，* (multiplication)，/ (division)， % (modulo)，^ (power/exponentiation)

#Comparison binary operators
# == (equal)， != (not-equal)，> (greater-than)， < (less-than)， >= (greater-or-equal)，  <= (less-or-equal)
#Logical/set binary operators
#  and (intersection)，or (union)， unless (complement)

# Aggregation operators 聚合操作符
    # sum (calculate sum over dimensions)
    # min (select minimum over dimensions)
    # max (select maximum over dimensions)
    # avg (calculate the average over dimensions)
    # stddev (calculate population standard deviation over dimensions)
    # stdvar (calculate population standard variance over dimensions)
    # count (count number of elements in the vector)
    # count_values (count number of elements with the same value)
    # bottomk (smallest k elements by sample value)
    # topk (largest k elements by sample value)
    # quantile (calculate φ-quantile (0 ≤ φ ≤ 1) over dimensions)
	
#这些运算符可以用于聚合所有标签维度，也可以通过包含一个无或子句来保留不同的维度。
#<aggr-op>([parameter,] <vector expression>) [without|by (<label list>)]
#parameter is only required for count_values, quantile, topk and bottomk
#without removes the listed labels from the result vector, while all other labels are preserved the output.
#从结果向量中删除列出的标签，而所有其他标签则保留输出。

# 优先级
    # ^
    # *, /, %
    # +, -
    # ==, !=, <=, <, >=, >
    # and, unless
    # or

#将prometheus加入到kubernetes中
kubectl --namespace=monitoring apply -f node-exporter-ds.yaml

kubectl --namespace=monitoring apply -f prometheus-svc.yaml
kubectl --namespace=monitoring apply -f prometheus-env.yaml
kubectl --namespace=monitoring apply -f prometheus-configmap.yaml
kubectl --namespace=monitoring apply -f prometheus-deployment.yaml

kubectl create secret generic --from-file=ca.pem=/path/to/ca.pem --from-file=client.pem=/path/to/client.pem --from-file=client-key.pem=/path/to/client-key.pem etcd-tls-client-certs

kubectl apply -f node-exporter-ds.yaml

kubectl apply -f prometheus-svc.yaml
kubectl apply -f prometheus-env.yaml
kubectl apply -f prometheus-configmap.yaml
kubectl apply -f prometheus-deployment.yaml

#看下是不是有开启 replicasets 或者 replicationcontrollers 
kubectl get rc prometheus-deployment-448714976-w3r1w
kubectl get rs prometheus-deployment-448714976-w3r1w
kubectl delete pods prometheus-deployment-448714976-w3r1w


rm -rf prometheus-deployment.yaml
kubectl delete -f prometheus-deployment.yaml


kubectl describe pods/`kubectl get pods --all-namespaces | awk '{print $2}'` --namespace="monitoring"




















