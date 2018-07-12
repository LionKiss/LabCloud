rm -rf /root/tensorflowyaml
mkdir -p /root/tensorflowyaml
cat > ps.yaml <<EOF
piVersion: v1
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
          image: $registryHostname:5000/tensorflow/tensorflow
          ports:
           - containerPort: 2222
EOF

cat > ps-srv.yaml <<EOF
piVersion: v1
kind: Service
metadata:
  labels:
    name: tensorflow-ps
    role: service
  name: tensorflow-ps-service
spec:
  ports:
    - port: 2222
      targetPort: 2222
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
          image: $registryHostname:5000/tensorflow/tensorflow
          ports:
           - containerPort: 2222
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
    - port: 2222
      targetPort: 2222
  selector:
    name: tensorflow-worker
EOF
for ss in `ll /root/tensorflowyaml | awk '{print $9}'`;
do
echo $ss;
kubectl delete -f $ss
done
kubectl create -f ps.yaml
kubectl create -f ps-srv.yaml
kubectl create -f worker.yaml
kubectl create -f worker-srv.yaml
#查看service来查看对应的容器的ip
kubectl describe service tensorflow-ps-service
kubectl describe service tensorflow-wk-service

docker run -d -p 8888:8888 -p 6006:6006 --name=tensorflow1 docker.io/tensorflow/tensorflow

docker run -it -p 8888:8888 -p 6006:6006 --name=tensorflow1 docker.io/tensorflow/tensorflow

docker exec -it tensorflow1 /bin/bash

docker stop tensorflow1
docker rm tensorflow1

docker stop 130ab4624f92
docker rm 130ab4624f92


#根据官方镜像将jupyter的密码以及工作目录修改
python
from notebook.auth import passwd 
passwd()
exit()
ss='sha1:dd739cb8ee1b:9dc2d55ab877911dc845db0d800315e5cbd93d29'
mkdir /opt/pydev
sed -i '$a\falge' /root/.jupyter/jupyter_notebook_config.py
sed -i "s/falge/c\.NotebookApp\.notebook_dir = u'\/opt\/pydev'/g" /root/.jupyter/jupyter_notebook_config.py
sed -i '$a\falge' /root/.jupyter/jupyter_notebook_config.py
sed -i "s/falge/c\.NotebookApp\.password = u'$ss'/g" /root/.jupyter/jupyter_notebook_config.py
cat /root/.jupyter/jupyter_notebook_config.py
docker commit tensorflow1 tensorflow-jupyter
 
docker run -it -p 8888:8888 -p 6006:6006 --name=tensorflow1 tensorflow-jupyter
 
#根据修改后的镜像将mnist数据加入
mnist_data_dir=/root/dataset/mnist_data
cd $mnist_data_dir
cat > Dockerfile <<EOF
FROM tensorflow-jupyter
RUN mkdir -p /opt/pydev/mnist_data
COPY t10k-images-idx3-ubyte.gz /opt/pydev/mnist_data/
COPY t10k-labels-idx1-ubyte.gz /opt/pydev/mnist_data/
COPY train-images-idx3-ubyte.gz /opt/pydev/mnist_data/
COPY train-labels-idx1-ubyte.gz /opt/pydev/mnist_data/
ADD CNNtestpy2.py /opt/pydev/
EOF
#docker build -t tensorflow-jupyter-mnist $mnist_data_dir
#docker run -it -p 8888:8888 -p 6006:6006 --name=tensorflow1 tensorflow-jupyter-mnist

docker build -t tensorflow-jupyter-mnist-cnn $mnist_data_dir
docker stop tensorflow1
docker rm tensorflow1
docker run -it -p 8888:8888 -p 6006:6006 --name=tensorflow1 tensorflow-jupyter-mnist-cnn

docker run -d -p 8888:8888 -p 6006:6006 --name=tensorflow1 tensorflow-jupyter-mnist-cnn
docker exec -it tensorflow1 /bin/bash

#将加入mnist数据集的镜像提交到本地镜像仓库中
docker push tensorflow-jupyter-mnist-cnn:latest
#根据镜像将其部署到kubernetes中
rm -rf /root/tensorflowyaml
mkdir -p /root/tensorflowyaml
cd /root/tensorflowyaml
image_url=node2:5000/tensorflow-jupyter-mnist-cnn
image_url=node2:5000/tensorflow/tensorflow1.2.0:latest
cat > ps.yaml <<EOF
piVersion: v1
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
           - containerPort: 2222
EOF

cat > ps-srv.yaml <<EOF
piVersion: v1
kind: Service
metadata:
  labels:
    name: tensorflow-ps
    role: service
  name: tensorflow-ps-service
spec:
  ports:
    - port: 2222
      targetPort: 2222
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
           - containerPort: 2222
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
    - port: 2222
      targetPort: 2222
  selector:
    name: tensorflow-worker
EOF

for ss in `ll /root/tensorflowyaml | awk '{print $9}'`;
do
echo $ss;
kubectl delete -f $ss
done

for ss in `docker ps -a | grep Exited | awk '{print $1}'`; do docker rm $ss ; done

kubectl create -f ps.yaml
kubectl create -f ps-srv.yaml
kubectl create -f worker.yaml
kubectl create -f worker-srv.yaml
#查看service来查看对应的容器的ip
kubectl describe service tensorflow-ps-service
kubectl describe service tensorflow-wk-service

docker ps -a | grep ten

docker exec -it `docker ps -a | grep ten | grep k8s_ps | awk '{print $1}'` /bin/bash

docker exec -it `docker ps -a | grep ten | grep k8s_work | awk '{print $1}'` /bin/bash

