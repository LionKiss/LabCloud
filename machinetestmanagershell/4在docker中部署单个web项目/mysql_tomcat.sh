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

docker build -t taxisql:1 $files_Dir

docker run -d -p 13306:3306 -e MYSQL_ROOT_PASSWORD=123 --name sqlone taxisql:1

}
init_mysql

function init_tomcat(){

cd $files_Dir
rm -rf Dockerfile
connect

cat > Dockerfile << EOF
FROM docker.io/tomcat
MAINTAINER zqq/819789214@qq.com
#ADD  cyclingbgtv1  /usr/local/tomcat/webapps/cyclingbgtv1
COPY  cyclingbgtv1.war  /usr/local/tomcat/webapps/
EXPOSE 8080
EOF

docker build -t taxitomcat:1 $files_Dir

docker run -d -p 8090:8080 --name taxitomcatone taxitomcat:1


}
init_tomcat
