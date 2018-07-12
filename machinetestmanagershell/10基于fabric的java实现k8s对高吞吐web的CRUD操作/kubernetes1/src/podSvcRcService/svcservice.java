package podSvcRcService;

import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.api.model.ServiceBuilder;
import io.fabric8.kubernetes.client.KubernetesClient;

public class svcservice {

	//创建Service
    public static Service createService(KubernetesClient client,String seriveName, String nsName, String labelkey, String labelvalue, int cnPort, int nodePort){
        Service service = new ServiceBuilder()
                .withApiVersion("v1")
                .withKind("Service")
                .withNewMetadata()
                    .withName(seriveName)
                    .withNamespace(nsName)
                    .addToLabels(labelkey, labelvalue)
                .endMetadata()
                .withNewSpec()
                    .addNewPort()
                        .withPort(cnPort)
                        .withNodePort(nodePort)
                        .withProtocol("TCP")
                        .withName("http")
                    .endPort()
                    .withType("NodePort")
                    .addToSelector(labelkey,labelvalue)
                .endSpec()
                .build();
        try {
            client.services().create(service);
            System.out.println("service create success");
        }catch (Exception e){
        	e.printStackTrace();	
            System.out.println("service create failed");
        }
        return service;
    }
 
    //删除Service
    public static Service deleteService(KubernetesClient client,String namespaceName, String serviceName){
        Service service = new Service();
        try {
            service = client.services().inNamespace(namespaceName).withName(serviceName).get();
            client.services().inNamespace(namespaceName).withName(serviceName).delete();
            System.out.println("service delete success");
        }catch (Exception e){
            System.out.println("service delete failed");
        }
        return service;
    }
 
    //查询Service
    public static Service readService(KubernetesClient client,String namespaceName, String serviceName){
        Service service = new Service();
        try {
            service = client.services().inNamespace(namespaceName).withName(serviceName).get();
            System.out.println("service read success");
        }catch (Exception e){
            System.out.println("service read failed");
        }
        return service;
    }
}
