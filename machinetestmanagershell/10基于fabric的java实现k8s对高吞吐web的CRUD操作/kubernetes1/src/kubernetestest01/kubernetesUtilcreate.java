package kubernetestest01;

import java.util.List;

import com.sun.xml.internal.ws.api.addressing.WSEndpointReference.Metadata;

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

/**
 * 操作kubernates的各项资源
常用的资源   创建
Nodes
Namespaces
Services
Replicationcontrollers
Pods
Events
Resourcequotas
可以通过api对以上资源做增删改查各种操作。
 * @author Administrator
 *
 */

public class kubernetesUtilcreate {

	public static void main(String[] args) {
		// TODO Auto-generated method stub

		Config config = new ConfigBuilder().withMasterUrl("http://172.16.2.123:8080/").build();
		KubernetesClient client = new DefaultKubernetesClient(config); 
		
		String createNameSpace = "web-loadbalance";
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
		List<Namespace> nameSpaceList =client.namespaces().list().getItems();
		for (Namespace ss : nameSpaceList) {
			System.out.println(ss);
		}
		
		
		
//		List<ServiceAccount> serviceAccountsList = client.serviceAccounts().list().getItems();
//		for (ServiceAccount serviceAccount : serviceAccountsList) {
//			System.out.println(serviceAccount);
//		}
//		List<Node> nodeList = client.nodes().list().getItems();
//		for (Node node : nodeList) {
//			System.out.println(node);
//		}
//		
//		List<Service> serviceList = client.services().list().getItems();
//		for (Service service : serviceList) {
//			System.out.println(service);
//		}
//		List<ReplicationController> replicationControllerList = client.replicationControllers().list().getItems();
//		for (ReplicationController replicationController : replicationControllerList) {
//			System.out.println(replicationController);
//		}
//		
//		List<Pod> podlist = client.pods().list().getItems();
//		for (Pod pod : podlist) {
//			System.out.println(pod);
//		}
//		
//		List<Event> eventlist = client.events().list().getItems();
//		for (Event event : eventlist) {
//			System.out.println(event);
//		}
//		
//	    List<ResourceQuota> resourcequotaslist = client.resourceQuotas().list().getItems();
//		for (ResourceQuota resourceQuota : resourcequotaslist) {
//			System.out.println(resourceQuota);
//		}
		
		
	}

}
