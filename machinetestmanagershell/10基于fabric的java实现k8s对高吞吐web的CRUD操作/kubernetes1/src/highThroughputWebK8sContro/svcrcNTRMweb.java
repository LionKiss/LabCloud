package highThroughputWebK8sContro;

import podSvcRcService.rc_ENVservice;
import podSvcRcService.rcservice;
import podSvcRcService.svcservice;
import io.fabric8.kubernetes.api.model.ReplicationController;
import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.client.KubernetesClient;
import kubernetesUtil.kubernetesUtil;

public class svcrcNTRMweb {

	public static void main(String[] args) {
		
		KubernetesClient client = new kubernetesUtil().getK8Sclient();
		//调用 service 实现相关任务
		rcservice ntrw_rc = new rcservice();
		svcservice ntrw_svc = new svcservice();
		//1,创建mysql，服务并测试ntrmmysql：30610
//		rc_ENVservice mysql_rc_ENV = new rc_ENVservice();
//		mysql_rc_ENV.deleteRC(client, "default", "ntrmmysql");
//		mysql_rc_ENV.createRC(client, "ntrmmysql", "default", "mysql", "ntrmmysql", 1, "ntrmmysql", "node0:5000/ntrmmysql:1", 3306,"MYSQL_ROOT_PASSWORD","123");
//		
//		ntrw_svc.deleteService(client, "default", "ntrmmysql");
//		ntrw_svc.createService(client, "ntrmmysql", "default", "mysql", "ntrmmysql", 3306, 30610);
		
		//创建redis ntrmredis：30611
//		ntrw_rc.deleteRC(client, "default", "ntrmredis");
//		ntrw_rc.createRC(client, "ntrmredis", "default", "redis", "ntrmredis", 1, "ntrmredis", "node0:5000/redis:latest", 6379);
//		ntrw_svc.deleteService(client, "default", "ntrmredis");
//		ntrw_svc.createService(client, "ntrmredis", "default", "redis", "ntrmredis", 6379, 30611);
		
		//创建Tomcat1 ntrmtomcat1:30612 和Tomcat2 ntrmtomcat2:30613,注意修改context.xml文件中的host="ntrmredis" port="30611"
//		ntrw_rc.deleteRC(client, "default", "ntrmtomcat1");
//		ntrw_svc.deleteService(client, "default", "ntrmtomcat1");
//		ntrw_rc.deleteRC(client, "default", "ntrmtomcat2");
//		ntrw_svc.deleteService(client, "default", "ntrmtomcat2");
//		
//		ntrw_rc.deleteRC(client, "default", "ntrmnginx");
//		ntrw_svc.deleteService(client, "default", "ntrmnginx");
//		
//		
//		ntrw_rc.createRC(client, "ntrmtomcat1", "default", "tomcat", "ntrmtomcat1", 1, "ntrmtomcat1", "node0:5000/ntrmtomcat:1", 8080);
//		//创建对应的service
//		ntrw_svc.createService(client, "ntrmtomcat1", "default", "tomcat", "ntrmtomcat1", 8080, 30612);
//		
//		
//		ntrw_rc.createRC(client, "ntrmtomcat2", "default", "tomcat", "ntrmtomcat2", 1, "ntrmtomcat2", "node0:5000/ntrmtomcat:1", 8080);
//		//创建对应的service
//		ntrw_svc.createService(client, "ntrmtomcat2", "default", "tomcat", "ntrmtomcat2", 8080, 30613);
//		
//		
//		ntrw_rc.createRC(client, "ntrmnginx", "default", "redis", "ntrmnginx", 1, "ntrmnginx", "node0:5000/ntrmnginx:1", 80);
//		//创建对应的service
//		ntrw_svc.createService(client, "ntrmnginx", "default", "redis", "ntrmnginx", 80, 30614);
//	
//		ntrw_rc.deleteRC(client, "default", "ntrmtomcat1");
//		ntrw_svc.deleteService(client, "default", "ntrmtomcat1");
//		ntrw_rc.deleteRC(client, "default", "ntrmtomcat2");
//		ntrw_svc.deleteService(client, "default", "ntrmtomcat2");
//		
//		ntrw_rc.deleteRC(client, "default", "ntrmnginx");
//		ntrw_svc.deleteService(client, "default", "ntrmnginx");
		
		ntrw_rc.deleteRC(client, "default", "ntrmtomcat1");
		ntrw_svc.deleteService(client, "default", "ntrmtomcat1");
		ntrw_rc.deleteRC(client, "default", "ntrmtomcat2");
		ntrw_svc.deleteService(client, "default", "ntrmtomcat2");
		ntrw_rc.createRC(client, "ntrmtomcat1", "default", "tomcat", "ntrmtomcat1", 1, "ntrmtomcat1", "node0:5000/ntrmtomcat:1", 8080);
		//创建对应的service
		ntrw_svc.createService(client, "ntrmtomcat1", "default", "tomcat", "ntrmtomcat1", 8080, 30612);
		ntrw_rc.createRC(client, "ntrmtomcat2", "default", "tomcat", "ntrmtomcat2", 1, "ntrmtomcat2", "node0:5000/ntrmtomcat:1", 8080);
		//创建对应的service
		ntrw_svc.createService(client, "ntrmtomcat2", "default", "tomcat", "ntrmtomcat2", 8080, 30613);
		
		
		

	}
}
