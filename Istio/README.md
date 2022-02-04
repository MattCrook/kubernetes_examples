# Istio Examples

##### Egress
If you want traffic destined to an external source to bypass the egress gateway, you can provide configuration to the ConfigMap of the istio-sidecar-injector. Set the following configuration in the sidecar injector, which will identify cluster-local networks and keep traffic destined locally within the mesh while forwarding traffic for all other destinations externally:
```
--set global.proxy.includeIPRanges="10.0.0.1/24”
```


```
helm template install/kubernetes/helm/istio --name istio --namespace istio-system --set pilot.resources.requests.memory="512Mi" | kubectl apply -f -
```

The easiest and most common way to access the cluster is through kubectl proxy, which creates a local web server that securely proxies data to Dashboard through the Kubernetes API Server. Deploy the Kubernetes Dashboard by running the following command:
```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml

kubectl proxy

To protect your cluster data, Dashboard deploys with a minimal role-based access control (RBAC) configuration by default. Currently, Dashboard only supports logging in with a bearer token. You can either create a sample user and use its token or use an existing token provided by your Docker Desktop deployment, as shown here:

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | awk '/default-token/ {print $1}')”

Copy the token and use it to authenticate in Dashboard.

```

##### Installing Istio

https://istio.io/latest/docs/setup/getting-started/


```
curl -L https://git.io/getLatestIstio | sh -

This script fetches the latest Istio release candidate and untars it.

To fetch a particular version of Istio, specify the desired version number, as shown here:
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.1.0 sh -

istioctl version

Add to PATH
export PATH=$PWD/bin:$PATH
```
Or if on Mac just `brew install istioctl`

```
for i in install/kubernetes/helm/istio-init/files/crd*yaml;
      do kubectl apply -f $i; done
```
As an alternative to looping through the install/kubernetes/helm/istio-init/files/crd*yaml manifests, we could apply istio-demo.yaml, which has these same CRD manifests included. The istio-demo.yaml file also includes all of Istio’s control-plane components (not just the CRDs). Within the install/ folder of your release distribution folder, you’ll find installation files for different supported platforms to run Istio. Given that Kubernetes is the platform we’ve chosen to work with in this book, open the install/kubernetes/ folder. There, you’ll find the istio-demo.yaml file, which contains all necessary Istio components (in the form of CRDs, clusteroles, configmaps, services, HPAs, deployments, services, and so on) and a few helpful adapters like Grafana and Prometheus.
Once you register Istio’s custom resources with Kubernetes, you can install Istio’s control-plane components.


##### Installing Istio Control-Plane Components
We use the istio-demo.yaml specification file, which contains Istio configurations that enable services to operate in mTLS permissive mode. Use of mTLS permissive mode is recommended if you have existing services or applications in your Kubernetes cluster. However, if you’re starting with a fresh cluster, security best practices suggest switching to istio-demo-auth.yaml to enforce encryption of service traffic between sidecars.
```
kubectl apply -f install/kubernetes/istio-demo.yaml
```

https://istio.io/latest/docs/setup/getting-started/

Using the istioctl proxy-status command allows you to get an overview of your mesh
```
istioctl proxy-status
```


Verifying the presence of the Istio sidecar injector
```
kubectl get svc -n istio-system

kubectl -n istio-system get deployment -l istio=sidecar-injector
```

The `NamespaceSelector` decides whether to run the webhook on an object based on whether the namespace for that object matches the selector.
Label the default namespace with istio-injection=enabled:
```
kubectl label namespace default istio-injection=enabled

Then confirm which namespaces have the istio-injection label:
kubectl get namespace -L istio-injection”
```

Identifying the IP address and port number of the exposed sample application on Istio ingress gateway
```
echo "http://$(kubectl get nodes -o template --template='{{range.items}}
     {{range.status.addresses}}{{if eq .type "InternalIP"}}{{.address}}{{end}}{{end}}
     {{end}}'):$(kubectl get svc istio-ingressgateway \
     -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')/
     productpage"
```


You can use istioctl as a tool to manually inject the Envoy sidecar definition into Kubernetes manifests. To do so, use istioctl’s kube-inject capability to manually inject the sidecar into deployment manifests by manipulating the YAML file:
```
istioctl kube-inject -f samples/sleep/sleep.yaml | kubectl apply -f -
```
You can update Kubernetes specifications on the fly at the time of applying them to Kubernetes for scheduling. Alternatively, you might use the istioctl kube-inject utility, like so:
```
kubectl apply -f <(istioctl kube-inject -f <resource.yaml>)
```

If you don’t have the source manifests available, you can update an existing Kubernetes deployment to bring its services onto the mesh:
```
kubectl get deployment -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```

----

## Istioctl

##### Get overview of mesh

https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/

The proxy-status command allows you to get an overview of your mesh. If you suspect one of your sidecars isn’t receiving configuration or is out of sync then proxy-status will tell you this.

- SYNCED means that Envoy has acknowledged the last configuration Istiod has sent to it.
- NOT SENT means that Istiod hasn’t sent anything to Envoy. This usually is because Istiod has nothing to send.
- STALE means that Istiod has sent an update to Envoy but has not received an acknowledgement. This usually indicates a networking issue between Envoy and Istiod or a bug with Istio itself.

```
istioctl proxy-status
istioctl proxy-status <PROXY_NAME>
```


##### See how a given Envoy instance is configured

https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration

The proxy-config command can be used to see how a given Envoy instance is configured. This can then be used to pinpoint any issues you are unable to detect by just looking through your Istio configuration and custom resources. To get a basic summary of clusters, listeners or routes for a given pod use the command as follows (changing clusters for listeners or routes when required):



```
istioctl proxy-config <clusters|listeners|routes|endpoints|bootstrap|log|secret> <pod-name> -n <namsespoce>


Examples:
- istioctl proxy-config cluster -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
- istioctl proxy-config listeners <pod | proxy> -n <NAMESPACE>
- istioctl proxy-config routes <pod | proxy> -n <NAMESPACE>
- istioctl proxy-config listeners shipt-test-app-webserver-65cf6c695f-hj8w4 -n istio-poc
- istioctl proxy-config listeners shipt-test-app-webserver-65cf6c695f-hj8w4 -n istio-poc -o json

```


##### Proxy config diff/ JSON output

```
istioctl proxy-config <clusters|listeners|routes|endpoints|bootstrap|log|secret> <POD> --port <PORT> -n <NAMESPACE> -o json


Examples:
- istioctl proxy-config listeners istio-ingressgateway-747c547894-mldlq --port 8443 -o json -n istio-system
- istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs --port 15001 -o json -n default
```

##### Routes and Endpoints

```
Find the route from the listener routeConfigName or virtualHoost that Envoy tells Envoy to send the request:
- istioctl proxy-config routes <pod> --name 9080 -o json


To see the endpoints currently available for this cluster use the proxy-config endpoints command:
- istioctl proxy-config cluster productpage-v1-6c886ff494-7vxhs --fqdn reviews.default.svc.cluster.local -o json


- istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster "outbound|9080||reviews.default.svc.cluster.local"

```

##### Detect potential issues with your Istio configuration

https://istio.io/latest/docs/ops/diagnostic-tools/istioctl-analyze/

```
istioctl analyze
```

-----

### Example

```
istioctl proxy-status
istioctl proxy-status istioctl proxy-status istio-ingressgateway-747c547894-mldlq.istio-system
istioctl proxy-config cluster istio-ingressgateway-747c547894-mldlq.istio-system -n istio-system
istioctl proxy-config cluster istio-ingressgateway-747c547894-mldlq.istio-system -n istio-system -o json

kubectl get pods -n istio-poc

istioctl proxy-config listeners shipt-test-app-webserver-65cf6c695f-hj8w4 -n istio-poc
istioctl proxy-config listeners shipt-test-app-webserver-65cf6c695f-hj8w4 -n istio-poc -o json
istioctl proxy-config listeners shipt-test-app-webserver-65cf6c695f-hj8w4 -n istio-poc --port 15001
istioctl proxy-config listeners shipt-test-app-webserver-65cf6c695f-hj8w4 -n istio-poc --port 15001 -o json
```

```
istioctl proxy-config listeners shipt-test-app-webserver-65cf6c695f-hj8w4 -n istio-poc -o json
```

- From the above summary you can see that every sidecar has a listener bound to 0.0.0.0:15006 which is where IP tables routes all inbound pod traffic to and a listener bound to 0.0.0.0:15001 which is where IP tables routes all outbound pod traffic to. The 0.0.0.0:15001 listener hands the request over to the virtual listener that best matches the original destination of the request, if it can find a matching one. Otherwise, it sends the request to the PassthroughCluster which connects to the destination directly.


```
istioctl proxy-config listeners shipt-test-platform-webserver-7fb65bf747-b6xqn -n istio-poc -o json
istioctl proxy-config listeners shipt-test-platform-webserver-7fb65bf747-b6xqn -n istio-poc -o json --port 9080
```
- Our request is an outbound HTTP request to port 9080 this means it gets handed off to the 0.0.0.0:9080 virtual listener. This listener then looks up the route configuration in its configured RDS. In this case it will be looking up route 9080 in RDS configured by Istiod (via ADS).

- The 9080 route configuration only has a virtual host for each service. Our request is heading to the reviews service so Envoy will select the virtual host to which our request matches a domain. Once matched on domain Envoy looks for the first route that matches the request. In this case we don’t have any advanced routing so there is only one route that matches on everything. This route tells Envoy to send the request to the `outbound|9080||reviews.default.svc.cluster.local cluster`.

```
outbound|9080||details.bookinfo.svc.cluster.local
outbound|9080||productpage.bookinfo.svc.cluster.local
outbound|9080||ratings.bookinfo.svc.cluster.local
outbound|9080||reviews.bookinfo.svc.cluster.local
```

```
istioctl proxy-config routes shipt-test-platform-webserver-7fb65bf747-b6xqn -n istio-poc --name 9080 -o json
```


- This cluster is configured to retrieve the associated endpoints from Istiod (via ADS). So Envoy will then use the serviceName field as a key to look up the list of Endpoints and proxy the request to one of them.

```
istioctl proxy-config cluster shipt-test-platform-webserver-7fb65bf747-b6xqn --fqdn reviews.default.svc.cluster.local -o json
```

##### To see the endpoints currently available for this cluster use the proxy-config endpoints command.
```
- istioctl proxy-config endpoints shipt-test-platform-webserver-7fb65bf747-b6xqn --cluster "outbound|9080||details.bookinfo.svc.cluster.local" -n istio-poc
- istioctl proxy-config endpoints shipt-test-platform-webserver-7fb65bf747-b6xqn --cluster "outbound|9080||reviews.default.svc.cluster.local" -n istio-poc
- istioctl proxy-config endpoints shipt-test-platform-webserver-7fb65bf747-b6xqn --cluster "outbound|9080||productpage.bookinfo.svc.cluster.local" -n istio-poc
- istioctl proxy-config endpoints shipt-test-platform-webserver-7fb65bf747-b6xqn --cluster "outbound|9080||ratings.default.svc.cluster.local" -n istio-poc
```



## Verify Istiod

https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/#verifying-connectivity-to-istiod

##### Create sleep Pod
```
kubectl create namespace foo
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo



Test connectivity to Istiod using curl. The following example invokes the v1 registration API using default Istiod configuration parameters and mutual TLS enabled:

kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl -sS istiod.istio-system:15014/version

```


### Find out Envoy Version Istio is Using:

To find out the Envoy version used in deployment, you can exec into the container and query the server_info endpoint:
```
kubectl exec -it productpage-v1-6b746f74dc-9stvs -c istio-proxy -n default  -- pilot-agent request GET server_info --log_as_json | jq {version}
```
