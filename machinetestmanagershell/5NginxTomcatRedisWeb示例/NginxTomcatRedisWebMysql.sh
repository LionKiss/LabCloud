function connect(){
  #connect internet
}
function disconnect(){
  #disconnect internet
}

files_Dir=


function ready(){
connect
docker pull docker.io/mysql
docker pull docker.io/tomcat
docker pull docker.io/redis
docker pull docker.io/nginx
}
ready

function init_mysql(){

cd $files_Dir

cat > Dockerfile <<EOF
FROM docker.io/mysql

ENV MYSQL_ALLOW_EMPTY_PASSWORD yes

COPY setup.sh /mysql/setup.sh
COPY schema.sql /mysql/schema.sql
COPY privileges.sql /mysql/privileges.sql
COPY my.cnf /etc/mysql/my.cnf
CMD ["sh", "/mysql/setup.sh"]
EOF

docker build -t ntrwmysql:1 $files_Dir
docker stop ntrwmysql
docker rm ntrwmysql
docker run -d -p 13306:3306 -e MYSQL_ROOT_PASSWORD=123 --name ntrwmysql ntrwmysql:1

}
init_mysql

function init_Redis(){
docker stop ntrediswm
docker rm ntrediswm
docker run -d -p 16379:6379  --name ntrediswm docker.io/redis
}
init_Redis




function init_tomcat(){

cd $files_Dir
rm -rf Dockerfile
connect

cat > Dockerfile << EOF
FROM docker.io/tomcat
MAINTAINER zqq/819789214@qq.com
#ADD cyclingbgtv1  /usr/local/tomcat/webapps/cyclingbgtv1
COPY cyclingbgtv1.war  /usr/local/tomcat/webapps/
COPY context.xml /usr/local/tomcat/conf/
COPY commons-pool2-2.4.2.jar /usr/local/tomcat/lib/
COPY jedis-2.9.0.jar /usr/local/tomcat/lib/
COPY tomcat-juli-8.5.21.jar /usr/local/tomcat/lib/
COPY tomcat85-session-redis-1.0.jar /usr/local/tomcat/lib/
EXPOSE 8080
EOF

docker build -t ntomcatrwm:1 $files_Dir
docker stop ntomcatrwm1
docker rm ntomcatrwm1
docker run -d -p 8180:8080 --name ntomcatrwm1 ntomcatrwm:1
docker stop ntomcatrwm2
docker rm ntomcatrwm2
docker run -d -p 8280:8080 --name ntomcatrwm2 ntomcatrwm:1

}

init_tomcat


function init_Nginx(){
cd $files_Dir
rm -rf Dockerfile

cat  > Dockerfile <<EOF
FROM nginx
MAINTAINER zqq/819789214@qq.com
COPY  nginx.conf  /etc/nginx/
EXPOSE 8080
EOF

docker build -t nginxtrwm:1 $files_Dir
docker stop nginxtrwm
docker rm nginxtrwm
docker run -d -p 800:80 --name nginxtrwm nginxtrwm:1
}
init_Nginx

function chongqi_tomcat(){
docker stop ntomcatrwm1
docker rm ntomcatrwm1
docker run -d -p 8180:8080 --name ntomcatrwm1 ntomcatrwm:1
docker stop ntomcatrwm2
docker rm ntomcatrwm2
docker run -d -p 8280:8080 --name ntomcatrwm2 ntomcatrwm:1
}
chongqi_tomcat

