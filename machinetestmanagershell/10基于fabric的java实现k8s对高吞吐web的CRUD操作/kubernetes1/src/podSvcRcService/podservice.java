package podSvcRcService;

import io.fabric8.kubernetes.api.model.Container;
import io.fabric8.kubernetes.api.model.ContainerBuilder;
import io.fabric8.kubernetes.api.model.ContainerPort;
import io.fabric8.kubernetes.api.model.ContainerPortBuilder;
import io.fabric8.kubernetes.api.model.ObjectMeta;
import io.fabric8.kubernetes.api.model.ObjectMetaBuilder;
import io.fabric8.kubernetes.api.model.Pod;
import io.fabric8.kubernetes.api.model.PodBuilder;
import io.fabric8.kubernetes.api.model.PodSpec;
import io.fabric8.kubernetes.api.model.PodSpecBuilder;
import io.fabric8.kubernetes.client.KubernetesClient;

public class podservice {

	//创建Pod
	public static Pod createPod(KubernetesClient client,String nameSpace, String podName, String containerName, String imageName, int cnPort, int htPort){
	    //ObjectMeta 配置
	    ObjectMeta objectMeta = new ObjectMetaBuilder().
	            withName(podName).
	            withNamespace(nameSpace).
	            build();
	    //Container 端口配置
	    ContainerPort containerPort = new ContainerPortBuilder().
	            withContainerPort(cnPort).
	            withHostPort(htPort).
	            build();
	    //Container 配置
	    Container container = new ContainerBuilder().
	            withName(containerName).
	            withImage(imageName).
	            withPorts(containerPort).
	            build();
	    //Spec 配置
	    PodSpec podSpec = new PodSpecBuilder().
	            withContainers(container).
	            build();
	    //Pod 配置
	    Pod pod = new PodBuilder().
	            withApiVersion("v1").
	            withKind("Pod").
	            withMetadata(objectMeta).
	            withSpec(podSpec).
	            build();
	    try {
	        //Pod 创建
	        client.pods().create(pod);
	        System.out.println("pod create success");
	    }catch (Exception e) {
	        System.out.println("pod create failed");
	    }
	    return pod;
	}
	 
	//删除pod
	public static Pod deletePod(KubernetesClient client,String namespaceName, String podName){
	    Pod pod = new Pod();
	    try {
	        //获取要删除的pod
	        pod = client.pods().inNamespace(namespaceName).withName(podName).get();
	        //Pod 删除
	        client.pods().inNamespace(namespaceName).withName(podName).delete();
	        System.out.println("pod delete success");
	    }catch (Exception e){
	        System.out.println("pod create failed");
	    }
	    return pod;
	}
}
