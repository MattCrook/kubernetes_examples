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
