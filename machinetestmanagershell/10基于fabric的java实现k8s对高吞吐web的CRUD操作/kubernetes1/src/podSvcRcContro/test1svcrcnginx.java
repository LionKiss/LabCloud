package podSvcRcContro;

import podSvcRcService.rcservice;
import podSvcRcService.svcservice;
import io.fabric8.kubernetes.api.model.ReplicationController;
import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.client.KubernetesClient;
import kubernetesUtil.kubernetesUtil;

public class test1svcrcnginx {

	public static void main(String[] args) {
		// TODO Auto-generated method stub

		KubernetesClient client = new kubernetesUtil().getK8Sclient();
		//调用 service 实现相关任务
		rcservice nginx_rc = new rcservice();
		nginx_rc.deleteRC(client, "web-loadbalance", "ntnginxwm");
		ReplicationController nginrc = nginx_rc.createRC(client, "ntnginxwm", "web-loadbalance", "redis", "ntnginxwm", 1, "ntnginxwm", "node0:5000/nginx:latest", 80);
		//创建对应的service
		svcservice nginx_svc = new svcservice();
		nginx_svc.deleteService(client, "web-loadbalance", "ntnginxwm");
		Service createService = nginx_svc.createService(client, "ntnginxwm", "web-loadbalance", "redis", "ntnginxwm", 80, 30603);
	}

}
