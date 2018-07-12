package podSvcRcContro;

import io.fabric8.kubernetes.api.model.ReplicationController;
import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.client.KubernetesClient;
import kubernetesUtil.kubernetesUtil;
import podSvcRcService.rcservice;
import podSvcRcService.svcservice;

public class test1svcrcmysql {

	public static void main(String[] args) {
		// TODO Auto-generated method stub

		KubernetesClient client = new kubernetesUtil().getK8Sclient();
		//调用 service 实现相关任务  mysql这里源镜像的密码是随机的还是特定设定的？这里不知道源密码。故无法测试，需改动
		rcservice mysql_rc = new rcservice();
		mysql_rc.deleteRC(client, "web-loadbalance", "ntmysqlwm");
		//ReplicationController nginrc = mysql_rc.createRC(client, "ntmysqlwm", "web-loadbalance", "redis", "ntmysqlwm", 1, "ntmysqlwm", "node0:5000/mysql:latest", 3306);
		//创建对应的service
		svcservice mysql_svc = new svcservice();
		mysql_svc.deleteService(client, "web-loadbalance", "ntmysqlwm");
		//Service createService = mysql_svc.createService(client, "ntmysqlwm", "web-loadbalance", "redis", "ntmysqlwm", 3306, 30604);

	}

}
