package podSvcRcContro;

import java.util.List;


import io.fabric8.kubernetes.api.model.ReplicationController;
import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.client.KubernetesClient;
import kubernetesUtil.kubernetesUtil;
import podSvcRcService.rcservice;
import podSvcRcService.svcservice;

public class test1svcrcredis {

	public static void main(String[] args) {
		KubernetesClient client = new kubernetesUtil().getK8Sclient();
		//调用 service 实现相关任务
		//创建rc
		rcservice redis_rc = new rcservice();
		redis_rc.deleteRC(client, "web-loadbalance", "ntrediswm");
		ReplicationController createRC = redis_rc.createRC(client, "ntrediswm", "web-loadbalance", "redis", "ntrediswm", 1, "ntrediswm", "node0:5000/redis:latest", 6379);
		//创建对应的service
		svcservice redis_svc = new svcservice();
		redis_svc.deleteService(client, "web-loadbalance", "ntrediswm");
		Service createService = redis_svc.createService(client, "ntrediswm", "web-loadbalance", "redis", "ntrediswm", 6379, 30601);
		

	}
}
