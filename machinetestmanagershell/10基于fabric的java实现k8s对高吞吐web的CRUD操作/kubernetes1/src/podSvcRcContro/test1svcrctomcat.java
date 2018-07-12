package podSvcRcContro;

import io.fabric8.kubernetes.api.model.ReplicationController;
import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.client.KubernetesClient;
import kubernetesUtil.kubernetesUtil;
import podSvcRcService.rcservice;
import podSvcRcService.svcservice;

public class test1svcrctomcat {

	public static void main(String[] args) {
		// TODO Auto-generated method stub

		KubernetesClient client = new kubernetesUtil().getK8Sclient();
		//调用 service 实现相关任务
		//创建rc
		rcservice tomcat_rc = new rcservice();
		tomcat_rc.deleteRC(client, "web-loadbalance", "ntomcatrwm");
		ReplicationController createRC = tomcat_rc.createRC(client, "ntomcatrwm", "web-loadbalance", "tomcat", "ntomcatrwm", 1, "ntomcatrwm", "node0:5000/tomcat:latest", 8080);
		//创建对应的service
		svcservice tomcat_svc = new svcservice();
		tomcat_svc.deleteService(client, "web-loadbalance", "ntomcatrwm");
		Service createService = tomcat_svc.createService(client, "ntomcatrwm", "web-loadbalance", "tomcat", "ntomcatrwm", 8080, 30602);
		
	}

}
