package kubernetestest01;
import io.fabric8.kubernetes.api.model.*;
import io.fabric8.kubernetes.api.model.extensions.*;
import io.fabric8.kubernetes.api.model.extensions.Deployment;
import io.fabric8.kubernetes.client.Config;
import io.fabric8.kubernetes.client.ConfigBuilder;
import io.fabric8.kubernetes.client.*;
import okhttp3.TlsVersion;
import org.apache.log4j.Logger;

import java.io.Closeable;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

//public class Fabric8KubeUtils implements KubeUtils<KubernetesClient> {
//    private KubernetesClient client;
//    private static final int CONNECTION_TIMEOUT = 3 * 1000;
//    private static final int REQUEST_TIMEOUT = 3 * 1000;
//
//    private static Logger logger = Logger.getLogger(Fabric8KubeUtils.class);
//
//
//    @Override
//    public KubernetesClient getClient() {
//        return client;
//    }
//
//    @Override
//    public void setClient(KubernetesClient client) {
//        this.client = client;
//    }
//
//
//    private Fabric8KubeUtils(KubernetesClient client) {
//        this.client = client;
//    }
//
//
//    /**传入参数，连接k8s的api server**/
//    public static KubeUtils buildKubeUtils(Cluster cluster, String namespace) throws K8sDriverException {
//        if (cluster == null) {
//            throw new K8sDriverException("cluster is null");
//        }
//        String key = cluster.md5Key(namespace);
//        if (KUBEUTILSMAP.containsKey(key)) {
//            return KUBEUTILSMAP.get(key);
//        }
//        String master = cluster.getApi();
//        master = CommonUtil.fullUrl(master);
//        if (StringUtils.isBlank(master)) {
//            throw new K8sDriverException("master api is null, cluster id=" + cluster.getId() + ", cluster name=" + cluster.getName());
//        }
//
//        Config config;
//        if (master.toLowerCase().startsWith("https://")) {
//            config = new ConfigBuilder().withMasterUrl(master)
//                    .withTrustCerts(true)
//                    .withNamespace(namespace)
//                    .withOauthToken(cluster.getOauthToken())
//                    .withUsername(cluster.getUsername())
//                    .withPassword(cluster.getPassword())
//                    .removeFromTlsVersions(TlsVersion.TLS_1_0)
//                    .removeFromTlsVersions(TlsVersion.TLS_1_1)
//                    .removeFromTlsVersions(TlsVersion.TLS_1_2)
//                    .withRequestTimeout(REQUEST_TIMEOUT)
//                    .withConnectionTimeout(CONNECTION_TIMEOUT)
//                    .build();
//        } else {
//            config = new ConfigBuilder().withMasterUrl(master)
//                    .withNamespace(namespace)
//                    .withOauthToken(cluster.getOauthToken())
//                    .withUsername(cluster.getUsername())
//                    .withPassword(cluster.getPassword())
//                    .removeFromTlsVersions(TlsVersion.TLS_1_0)
//                    .removeFromTlsVersions(TlsVersion.TLS_1_1)
//                    .removeFromTlsVersions(TlsVersion.TLS_1_2)
//                    .withTrustCerts(true)
//                    .withRequestTimeout(REQUEST_TIMEOUT)
//                    .withConnectionTimeout(CONNECTION_TIMEOUT)
//                    .build();
//        }
//        KubeUtils kubeUtils = buildKubeUtils(config);
//        KUBEUTILSMAP.putIfAbsent(key, kubeUtils);
//        return kubeUtils;
//    }
//
//    /**创建client**/
//    public static KubeUtils buildKubeUtils(Config config) throws K8sDriverException {
//        KubernetesClient client;
//        try {
//            client = new DefaultKubernetesClient(config);
//        } catch (Exception e) {
//            throw new K8sDriverException("instantialize kubernetes client error");
//        }
//        return new Fabric8KubeUtils(client);
//    }
//
//
//}