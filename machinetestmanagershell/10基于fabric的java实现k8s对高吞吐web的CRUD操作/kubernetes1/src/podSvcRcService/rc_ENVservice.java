package podSvcRcService;

import io.fabric8.kubernetes.api.model.ReplicationController;
import io.fabric8.kubernetes.api.model.ReplicationControllerBuilder;
import io.fabric8.kubernetes.client.KubernetesClient;

public class rc_ENVservice {

	//创建Replication Controller
	public static ReplicationController createRC(KubernetesClient client,String rcName, String nsName, String lbkey, String lbvalue, int replicas, String ctName, String imName, int cnPort,String envname,String envvalue){
	    ReplicationController rc = new ReplicationControllerBuilder()
	            .withApiVersion("v1")
	            .withKind("ReplicationController")
	            .withNewMetadata()
	                .withName(rcName)
	                .withNamespace(nsName)
	                .addToLabels(lbkey, lbvalue)
	            .endMetadata()
	            .withNewSpec()
	                .withReplicas(replicas)
	                .addToSelector(lbkey, lbvalue)
	                .withNewTemplate()
	                    .withNewMetadata()
	                        .addToLabels(lbkey, lbvalue)
	                    .endMetadata()
	                    .withNewSpec()
	                        .addNewContainer()
	                            .withName(ctName)
	                            .withImage(imName)
	                            .addNewPort()
	                                .withContainerPort(cnPort)
	                            .endPort()
	                            .addNewEnv()
	                                .withName(envname)
	                                .withValue(envvalue)
	                            .endEnv()
	                        .endContainer()
	                    .endSpec()
	                .endTemplate()
	            .endSpec()
	            .build();
	    try {
	    	client.replicationControllers().create(rc);
	        System.out.println("replication controller create success");
	    }catch (Exception e) {
	        System.out.println("replication controller create failed");
	    }
	    return rc;
	}
	 
	//删除Replication Controller
	public static ReplicationController deleteRC(KubernetesClient client, String nsName, String rcName){
	    ReplicationController rc = new ReplicationController();
	    try {
	        rc = client.replicationControllers().inNamespace(nsName).withName(rcName).get();
	        client.replicationControllers().inNamespace(nsName).withName(rcName).delete();
	        System.out.println("replication controller delete success");
	    }catch (Exception e){
	        System.out.println("replication controller delete failed");
	    }
	    return rc;
	}
	 
	//查询Replication Controller
	public static ReplicationController readRC(KubernetesClient client, String nsName, String rcName){
	    ReplicationController rc = new ReplicationController();
	    try {
	        rc = client.replicationControllers().inNamespace(nsName).withName(rcName).get();
	        System.out.println("replication controller read success");
	    }catch (Exception e){
	        System.out.println("replication controller read failed");
	    }
	    return rc;
	}
}
