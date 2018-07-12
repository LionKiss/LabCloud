package kubernetesUtil;

import java.util.List;

import io.fabric8.kubernetes.api.model.Event;
import io.fabric8.kubernetes.api.model.Namespace;
import io.fabric8.kubernetes.api.model.Node;
import io.fabric8.kubernetes.api.model.ObjectMeta;
import io.fabric8.kubernetes.api.model.Pod;
import io.fabric8.kubernetes.api.model.ReplicationController;
import io.fabric8.kubernetes.api.model.ResourceQuota;
import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.api.model.ServiceAccount;
import io.fabric8.kubernetes.client.Config;
import io.fabric8.kubernetes.client.ConfigBuilder;
import io.fabric8.kubernetes.client.DefaultKubernetesClient;
import io.fabric8.kubernetes.client.KubernetesClient;



public class kubernetesUtil {
	public static KubernetesClient client=null;
	public static KubernetesClient getK8Sclient() {
		Config config = new ConfigBuilder().withMasterUrl("http://172.16.2.123:8080/").build();
		client = new DefaultKubernetesClient(config); 
		return client;
	}
	public static void createNSname(String createNameSpace){
		//String createNameSpace = "web-loadbalance";
		//Namespace namespace = client.namespaces().withName(createNameSpace).get();
		if(null!=client.namespaces().withName(createNameSpace).get()){
			client.namespaces().withName(createNameSpace).delete();
		}else{
			//创建命名空间Namespace为web_loadBalance
			Namespace namespace = new Namespace();
			ObjectMeta objectMeta = new ObjectMeta();
			objectMeta.setName(createNameSpace);
			namespace.setMetadata(objectMeta);
			client.namespaces().create(namespace);
		}
	}
}
