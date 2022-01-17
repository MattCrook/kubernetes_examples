## Bookinfo Sample Istio Set up and Extra Commands

https://istio.io/latest/docs/setup/getting-started/

```
curl -L https://istio.io/downloadIstio | sh -
```


Using demo configuration file (https://istio.io/latest/docs/setup/additional-setup/config-profiles/)
It’s selected to have a good set of defaults for testing, but there are other profiles for production or performance testing.
```
istioctl install --set profile=demo -y
```


##### Add a namespace label to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later:
```
kubectl label namespace default istio-injection=enabled
```

```
kubectl apply -f bookinfo.yaml
```

Verify everything is working correctly up to this point. Run this command to see if the app is running inside the cluster and serving HTML pages by checking for the page title in the response:
```
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
```

##### Ensure that there are no issues with the configuration:
```
istioctl analyze
```


##### Determining the ingress IP and ports
https://istio.io/latest/docs/setup/getting-started/#determining-the-ingress-ip-and-ports

```
kubectl get svc istio-ingressgateway -n istio-system


export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
```

##### Follow these instructions if your environment does not have an external load balancer and choose a node port instead.
```
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
```

##### GKE:
```
export INGRESS_HOST=workerNodeAddress

Ex:
export INGRESS_HOST=34.135.32.125

gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"

```
Other:
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')



##### Set GATEWAY_URL:
```
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```
##### Ensure an IP address and port were successfully assigned to the environment variable:
```
echo "$GATEWAY_URL"
192.168.99.100:32194
```


##### Run the following command to retrieve the external address of the Bookinfo application:
```
echo "http://$GATEWAY_URL/productpage"

```

Istio integrates with several different telemetry applications. These can help you gain an understanding of the structure of your service mesh, display the topology of the mesh, and analyze the health of your mesh.

Use the following instructions to deploy the Kiali dashboard, along with Prometheus, Grafana, and Jaeger.

Install Kiali and the other addons and wait for them to be deployed.
```
kubectl apply -f addons
kubectl rollout status deployment/kiali -n istio-system
```


###### Access the Kiali dashboard
```
istioctl dashboard kiali
```

In the left navigation menu, select Graph and in the Namespace drop down, select default.

To see trace data, you must send requests to your service. The number of requests depends on Istio’s sampling rate. You set this rate when you install Istio. The default sampling rate is 1%. You need to send at least 100 requests before the first trace is visible. To send a 100 requests to the productpage service, use the following command:
```
for i in $(seq 1 100); do curl -s -o /dev/null "http://$GATEWAY_URL/productpage"; done
```

##### Kubernetes Dashboard
```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml”
kubectl proxy

Get the access Token:
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | awk '/default-token/ {print $1}')”
```

##### Use kube-inject to manually add Envoy side car
```
You can use istioctl as a tool to manually inject the Envoy sidecar definition into Kubernetes manifests. To do so, use istioctl’s kube-inject capability to manually inject the sidecar into deployment manifests by manipulating the YAML file:
- istioctl kube-inject -f samples/sleep/sleep.yaml | kubectl apply -f -


You can update Kubernetes specifications on the fly at the time of applying them to Kubernetes for scheduling. Alternatively, you might use the istioctl kube-inject utility, like so:
- kubectl apply -f <(istioctl kube-inject -f <resource.yaml>)


If you don’t have the source manifests available, you can update an existing Kubernetes deployment to bring its services onto the mesh:
kubectl get deployment -o yaml | istioctl kube-inject -f - | kubectl apply -f -


Update deployment:
kubectl get deployment productpage-v1 -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```

Instead of ad hoc onboarding of a running application, you might prefer to perform this manual injection operation once and save the new manifest file with istio-proxy (Envoy) inserted. You can create a persistent version of the sidecar-injected deployment by outputting the results of istioctl kube-inject to a file:
```
istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml

Or, like so:
istioctl kube-inject -f deployment.yaml > deployment-injected.yaml
```

##### Create a persistent version of the deployment with Envoy sidecar injected configuration from Kubernetes configmap 'istio-inject'
```
istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigMapName istio-inject”

```


##### Remove deployment from the mesh
```
- kubectl patch deployment nginx --type=json --patch='[{"op": "add", "path": "/spec/template/metadata/annotations", "value": {"sidecar.istio.io/inject": "false"}}]'
```



##### See iptable rule chains in container running envoy proxy
```
- iptables -t nat --list
```

##### Mutating Webhook
```
kubectl get mutatingwebhookconfigurations

kubectl get mutatingwebhookconfigurations istio-sidecar-injector -o yaml

```

##### istio-proxy is a multiprocess container with pilot-agent running alongside Envoy
```
kubectl exec ratings-v1-7665579b75-2qcsb -c istio-proxy
```

##### Verifying that productpage’s certificate is valid
```
kubectl exec -it $(kubectl get pod | grep productpage | awk '{ print $1 }') -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout
```

##### Showing the filename of the Envoy configuration file within the istio-proxy container
```
kubectl exec ratings-v1-7665579b75-2qcsb -c istio-proxy ls /etc/istio/proxy
```

## Admin Console

##### Envoy’s administrative console outside of an Istio service mesh deployment, the simplest way to do so might be to use Docker:
```
docker run --name=proxy -d -p 80:10000 -v $(pwd)/envoy/envoy.yaml:/etc/envoy/envoy.yaml envoyproxy/envoy:latest
```

##### After opening your browser to http://localhost:15000, you will be presented with a list of endpoints to explore, like the following:
```
/certs
Certificates within the Envoy instance

/clusters
Clusters with which Envoy is configured

/config_dump
Dumps the actual Envoy configuration

/listeners
Listeners with which Envoy is configured

/logging
View and change logging settings

/stats
Envoy statistics

/stats/prometheus
Envoy statistics as Prometheus records
```

##### Verifying that the key and certificate are correctly mounted in productpage’s service proxy
```
kubectl exec -it $(kubectl get pod | grep productpage | awk '{ print $1 }') -c istio-proxy -- ls /etc/certs
```




#### Cleanup
```
kubectl delete -f samples/addons
istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
istioctl tag remove default
kubectl delete namespace istio-system
kubectl label namespace default istio-injection-
```





## With Helm
Create a namespace for Istio’s control-plane components and then install all of Istio’s CRDs. Render Istio’s core components to a Kubernetes manifest called istio.yaml using the following command from the Istio release directory:
```
kubectl create namespace istio-system

helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -

```

Part of the benefit of using a Helm-based method of deployment is that you can relatively easily customize your Istio configuration by adding one or more --set <key>=<value> installation options to the Helm command, like so:
```
helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set global.controlPlaneSecurityEnabled=true \
  --set mixer.adapters.useAdapterCRDs=false \
  --set grafana.enabled=true --set grafana.security.enabled=true \
  --set tracing.enabled=true \
  --set kiali.enabled=true
```


##### Delete Helm Installation
```
helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl delete -f -

kubectl delete namespace istio-system
```
