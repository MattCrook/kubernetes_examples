# Commands

Below is just a collection of commands that I ran when playing around with various clusters. More or less here to have a reference for myself. The commands are not in any particular order or organized in any specific way.


###### Create a cluster using CLI tools
```
aws ec2 create-key-pair --region us-west-2 --key-name <myKeyPair>
eksctl create cluster \
    --name test-cluster \
    --version 1.20 \
    --region us-east-2 \
    --with-oidc \
    --ssh-access \
    --ssh-public-key <your-key> \
    --nodegroup-name linux-nodes \
    --node-type t2.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 3 \
    --managed


aws ec2 create-key-pair --region us-west-2 --key-name demoClusterKey
eksctl create cluster \
    --name test-cluster \
    --version 1.20 \
    --region us-east-2 \
    --with-oidc \
    --ssh-access \
    --ssh-public-key demoClusterKey \
    --nodegroup-name linux-nodes \
    --node-type t2.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 3 \
    --managed
```

###### Cluster info
```
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'
eksctl delete cluster --name test-cluster --region us-east-2
kubectl describe service demo -n default
kubectl get endpoints
```
##### Exec into pod
```
kubectl exec -it node-app-8649b55857-zds5t /bin/bash/
kubectl exec -it node-app-8649b55857-zds5t /bin/sh
```

##### Install curl in pod (or on node)
```
*apt update
*apt upgrade
apt add curl or apt install curl
```

##### Use DNS to hit cluster 
```
curl http://kubernetes.default.svc.cluster.local
curl http://kubernetes.default
ping demo.default.svc.cluster.local
```

##### Minikube Addons
```
minikube addons list
minikube addons enable <addon>
```

Once you know the IP (of Ingress), you can then either configure your DNS servers to resolve kubia.example.com
to that IP or you can add the following line to /etc/hosts
(orC:\windows\system32\drivers\etc\hosts on Windows):
```

192.168.99.100    kubia.example.com

```

ACCESSING PODS THROUGH THE INGRESS

Everything is now set up, so you can access the service at http://kubia.example.com(using a browser or curl):
```
$ curl http://kubia.example.com
```

For now, you’ll create theSecret without paying too much attention to it.
First, you need to create the private key and certificate:

```
openssl genrsa -out tls.key 2048
openssl req -new -x509 -key tls.key -out tls.cert -days 360 -subj /CN=demo.example.com
kubectl create secret tls tls-secret --cert=tls.cert --key=tls.key
```

And instead of signing certs ourselves, you can get the certificate signed by creating a CertificateSigningRequest resource.
```
kubectl certificate approve <name_of_the_CSR>
```
```
curl -k -v https://demo.example.com/kubia
* About to connect() to kubia.example.com port 443 (#0)
...
* Server certificate:
*   subject: CN=demo.example.com.
..
> GET /kubia HTTP/1.1
>

```

##### Exec into deployment pod and create file to make readiness probe pass

```
kubectl exec demo-deployment-pod-559cbd5846-5fvn7 -- touch /var/ready
```

Run a pod pod based on an image that contains the binaries you need?
To perform DNS-related actions, you can use the tutum/dnsutils containerimage,
which is available on Docker Hub and contains both the `nslookup` and the `dig` binaries.
```
$ kubectl run dnsutils --image=tutum/dnsutils --generator=run-pod/v1 --command -- sleep infinity
```
Perform DNS lookup inside the Pod.
```
$ kubectl exec dnsutils nslookup demo-headless
```

The DNS server returns two different IPs for the kubia-headless.default.svc.cluster.local FQDN.
Those are the IPs of the two pods that are reporting being ready. You can confirm this by listing pods with kubectl get pods -o wide, which shows the pods’ IPs.

Look up clusterIP. Headless is different from what DNS returns for regular services such as for clusterIP service, where the returned IP is the service's clusterIP.
```
$ kubectl exec dnsutils nslookup demo-clusterIP

name:    kubia.default.svc.cluster.local
Address: 10.111.249.153

kubectl get pods -o yaml | grep -i podip
curl -k https://172.17.0.3

kubectl port-forward fortune 8080:80
curl http://localhost:8080
```

##### Look at volumes of pods
```
kubectl get pods -n kube-system
kubectl describe pod kube-controller-manager-minikube -n kube-system
```

##### Create GCE Persistant Disk
``` 
$ gcloud container cluster list
$ gcloud compute disks create --size=1GiB --zone=us-east1-c mongodb
```

WRITING DATA TO THE PERSISTENT STORAGE BY ADDING DOCUMENTS TO YOUR MONGODB DATABASE
```
$ kubectl exec -it mongodb mongo
or
$ kubectl exec -it mongodb -- mongo
> use mystore
> db.foo.insert({name: 'foo'})
> db.foo.find()

See docker processes runnning in container"
$ docker exec 4675d ps
$ docker exec -it e4bad ps x

ConfigMaps
$ kubectl create configmap fortune-config --from-literal=sleep-interval=25

From file:
$ kubectl create configmap my-config --from-file=config-fil.conf
```

When you run the previous command, kubectl looks for the file `config-file.conf` in the directory you run kubectl in.
It will then store the contents of the file under the key `config-file.conf` in the ConfigMap (the filename is used as the map key),
but you can also specify a key manually like this:
```
$ kubectl create configmap my-config --from-file=customkey=config-file.conf
```
This command will store the file’s contents under the key customkey.
As with literals,you can add multiple files by using the --from-file argument multiple times.

------------------------------------------------------------------------

Youtube GKE cluster video:

https://www.youtube.com/watch?v=Vcv6GapxUCI&t=35s

```
gcloud organizations list
gcloud beta billing accounts list
export TF_VAR_org_id=YOUR_ORG_ID
export TF_VAR_billing_account=YOUR_BILLING_ACCOUNT_ID
export TF_ADMIN=${USER}-terraform-admin
export TF_CREDS=~/.config/gcloud/${USER}-terraform-admin.json
```

Connect cluster to local machine
```
$ gcloud container clusters get-credentials k8-cluster-project-gke-cluster-default --zone us-central1-c --project k8-cluster-project
```

List clusters and info (to find info, like zone etc...)
```
$ gcloud container clusters list
```
Create a GCE PersistantDisk. This is Provisioning the storge manually.
```
$ gcloud compute disks create --size=10GB --zone=us-central1-c mongodb
```

Authenticating and OAuth with service account:
If you're running Terraform from a GCE instance, default credentials are automatically available. See Creating and Enabling Service Accounts for Instances for more details.
On your computer, you can make your Google identity available by running gcloud auth application-default login.
```
kubectl config view -o jsonpath='{.users[*].name}'
kubectl config view -o jsonpath='{.users[?(@.name == "gke_k8-cluster-project_us-central1-c_kubia")].user.password}'
kubectl config view -o jsonpath='{.users[?(@.name == gke_k8-cluster-project_us-central1-c_kubia)].user.password}'
kubectl config view -o jsonpath='{.users[?(@.name == "gke_k8-cluster-project_us-central1-c_kubia")].user.password}'
kubectl config view
```
##### Kubernetes Dashboard
```
kubectl get secrets
Kubernetes Dashboard
kubectl proxy http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
kubectl cluster-info
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml\n
kubectl proxy http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
kubectl proxy http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/\#/login
kubectl describe secrets
kubectl proxy http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/\#/login
```

##### Minikuke Addons - Kubernetes Dashboard

```
minikube addons list
minikube addons enable <addon>
minikube kubernetes Dashboard
minikube dashboard
minikube dashboard --url
```

##### Useful commands
```
kubectl get pods --all-namespaces
kubectl get secret -n kubernetes-dashboard -o yaml

kubectl describe pod kubernetes-dashboard-9f9799597-vmdm7 -n kubernetes-dashboard
kubectl cluster-info

kubectl get pods --show-labels
kubectl get jobs
kubectl api-resources -o name
kubectl api-resources --namespaced=true

kubectl get events --sort-by=.metadata.creationTimestamp

kubectl config view -o jsonpath='{.users[*].name}'
kubectl config current-context

kubectl cluster-info
kubectl cluster-info dum
kubectl cluster-info dump
kubectl cluster-info dump > cluster.txt
```

##### Configmaps
```
$ kubectl create configmap fortune-config --from-file=configmap-files
$ kubectl get configmap fortune-config -o yaml


$ kubectl port-forward fortune-configmap-volume 8080:80 &
$ curl -H "Accept-Encoding: gzip" -I localhost:8080
$ kubectl exec fortune-nginx-configmap-volume -c web-server ls /etc/nginx/conf.d
$ kubectl edit configmap fortune-config
$ kubectl exec fortune-configmap-volume -c web-server -- cat /etc/nginx/conf.d/my-nginx-config.conf
$ kubectl exec fortune-configmap-volume -c web-server -- nginx -s reload
$ kubectl exec -it fortune-configmap-volume -c web-server -- ls -lA
$ kubectl exec -it fortune-configmap-volume -c web-server -- ls -lA /etc/nginx/conf.d
```

##### Secrets
```
$ kubectl exec demo-deployment-pod-559cbd5846-gth6v ls  /var/run/secrets/kubernetes.io/serviceaccount
Create secret for https traffic

$ openssl genrsa -out https.key 2048
$ openssl req -new -x509 -key https.key -out https.cert -days 3650 -subj /CN=demo.example.com
$ echo bar > foo

Now you can use kubectl create secret to create a Secret from the three files:
$ kubectl create secret generic fortune-https --from-file=https.key --from-file=https.cert --from-file=foo

kubectl exec fortune-https -c web-server -- mount | grep certs
```

##### Creating Secret for Private Docker image
```
Pull image from docker from private repository
$ kubectl create secret docker-registry mydockerhubsecret \
    --docker-username=myusername \
    --docker-password=mypassword \
    --docker-email=my.email@provider.com
```

<!-- $ kubectl create secret docker-registry flaskappdockerhubsecret --docker-server=https://index.docker.io/v2/ --docker-username=mgcrook11 --docker-password='' --docker-email=matt.crook11@gmail.com -->


##### Create secret from Existing docker config file if alredy ran docker login:
```
$ kubectl create secret generic flaskappdockerhubsecret \
    --from-file=.dockerconfigjson=/Users/matt.crook/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson


$ kubectl create secret docker-registry myregistrykey \
    --docker-server=DUMMY_SERVER \
    --docker-username=DUMMY_USERNAME --docker-password=DUMMY_DOCKER_PASSWORD \
    --docker-email=DUMMY_DOCKER_EMAIL
```

##### To create a secret from yaml config file:

turn into base64 encoded:
```
$ echo -n 'admin' | base64
$ echo -n '1f2d1e2e67df' | base64
```

Decoding the secret:
```
$ kubectl get secret db-user-pass -o jsonpath='{.data}'
    {"password":"MWYyZDFlMmU2N2Rm","username":"YWRtaW4="}

$ echo 'MWYyZDFlMmU2N2Rm' | base64 --decode
```

##### Downward API
```
Looking at volumes in container of downward api volume
$ kubectl exec downward -- ls -alh /etc/downward
$ kubectl exec downward -- cat /etc/downward/labels
$ kubectl exec downward -- cat /etc/downward/annotations


$ kubectl cluster-info
-k option is curl's insecure option
$ curl https://192.168.64.4:8443 -k
```

##### Running curl-pod:
```
$ kubectl exec -it curl -- sh
env | grep KUBERNETES_SERVICE

$ ls var/run/secrets/kubernetes.io/serviceaccount/
$ curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.cert https://kubernetes
```

##### Setting CURL_CA_BUNDLE Environment Variable
```
Be kubectl exec into pod, and run:
export CURL_CA_BUNDLE=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

To authenticate, you need an authentication token.
Luckily, the token is provided through the default-token Secret mentioned previously, and is stored in the token file in the secret volume.
As the Secret’s name suggests, that’s the primary purpose of the Secret.
You’re going to use the token to access the API server.

First, load the token into an environment variable.
* `TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)`

  * Set namespace as environment variable:
    * `NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)`

      * Get all pods in pods namespace:
        * `curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/$NS/pods`


##### Rolling updates
```
kubectl rolling-update kubia-v1 kubia-v2 --image=luksa/kubia:v2 --v 6
Using the --v 6 option increases the logging level enough to let you seethe requests kubectl is sending to the API server

Using this option, kubectl will print out each HTTP request it sends to the Kubernetes API server.
You’ll see PUT requests to
/api/v1/namespaces/default/replicationcontrollers/kubia-v1
which is the RESTful URL representing your kubia-v1 resource.
```

##### Deployments
```
Check Deployment's status:

$ kubectl rollout status deployment <deployment>
$ kubectl patch deployment kubia -p '{"spec": {"minReadySeconds": 10}

$ while true; do curl http://130.211.109.222; done

Set image changes the container image defined in a pod:

$ kubectl set image deployment kubia nodejs=luksa/kubia:v2
$ kubectl rollout undo deployment <deployment>
kubectl rollout history deployment kubia

Rollback to specific version:

$ kubectl rollout undo deployment kubia --to-revision=1
kubectl rollout pause deployment <deployment>
kubectl rollout resume deployment <deployment>
```

##### StatefulSets
```
if using GKE, need to create actual GCE PersistantDisks
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b pv-a
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b pv-b
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b pv-c

Hit stateful pod using kubectl proxy through the API server using that as a proxy
$ curl localhost:8001/api/v1/namespaces/default/pods/stateful-pod-0/proxy/

Send POST 
$ curl -X POST -d "Hey there! This greeting was submitted to kubia-0." localhost:8001/api/v1/namespaces/default/pods/stateful-pod-0/proxy/

Look at other pod (node) to see if data there - should not be bc each should have its own state and own PVC and PV
$ curl localhost:8001/api/v1/namespaces/default/pods/stateful-pod-1/proxy/
```

##### Deleting pods
```
Deleting a pod should make the pod scale down then scale back up again, if using the PVCs correctly, should
see the same pod with same host and same data.

kubectl get pods
kubectl proxy
curl localhost:8001/api/v1/namespaces/default/pods/stateful-pod-1/proxy/
kubectl delete pod stateful-pod-1
kubectl get pods
```

##### Connecting to Cluster-Internal Services Through the API Server
```
Instead of using a piggyback pod to access the service from inside the cluster, you can use  the  same  proxy  feature  provided  by  the  API  server  to access the service the way you’ve accessed individual pods. The URI path for proxy-ing requests to Services is formed like this:

/api/v1/namespaces/<namespace>/services/<service name>/proxy/<path>

Therefore, you can run curl on your local machine and access the service through the kubectl proxy like this (you ran kubectl proxy earlier and it should still be running):

curl localhost:8001/api/v1/namespaces/default/services/kubia-public/proxy/
You’ve hit kubia-1
Data stored on this pod: No data pod
```
##### Hitting an Internal Service From Outside the Cluster
Say we have a ClusterIP, Because this isn’t an externally exposed Service (it’s a regular ClusterIP Service, not a NodePort or a LoadBalancer-type  Service), you can only access it from inside the cluster. You’ll need a pod to access it from, right? Not necessarily.

```
kubectl proxy

URI:
/api/v1/namespaces/<namespace>/services/<service name>/proxy/<path>

Ex:
curl localhost:8001/api/v1/namespaces/default/services/stateful-public/proxy/
```

##### List SRV Records For Stateful pods

You’re going to list the SRV records for your stateful pods by running the `dig` DNSlookup tool inside a new temporary pod. This is the command you’ll use:
```
kubectl run -it srvlookup --image=tutum/dnsutils --rm --restart=Never -- dig SRV kubia.default.svc.cluster.local
```

* The command runs a one-off pod `(--restart=Never)` called `srvlookup`, which is attached to the console `(-it)` and is deleted as soon as it terminates `(--rm)`.
* The pod runs a single container from the `tutum/dnsutils` image and runs the following command:
  * `dig SRV kubia.default.svc.cluster.local`

```
The ANSWER SECTION shows two SRV records pointing to the two pods backing your head-less service. Each pod also gets its own A record, as shown in ADDITIONAL SECTION.
For a pod to get a list of all the other pods of a StatefulSet, all you need to do is perform an SRV DNS lookup.

In Node.js, for example, the lookup is performed like this:
dns.resolveSrv("kubia.default.svc.cluster.local", callBackFunction)
```

##### Trying Out Clustered Data Store (Stateful pod peers)

```
Writing to clustered data store through service:

curl -X POST -d "The sun is shining" localhost:8001/api/v1/namespaces/default/services/stateful-public/proxy/
Data stored on pod stateful-pod-peers-1

curl -X POST -d "The weather is sweet"localhost:8001/api/v1/namespaces/default/services/stateful-public/proxy/
Data stored on pod stateful-pod-peers-2

Reading from the data store:
curl localhost:8001/api/v1/namespaces/default/services/stateful-public/proxy/
You’ve hit kubia-2Data stored on each cluster node:
- kubia-0.kubia.default.svc.cluster.local: The weather is sweet
- kubia-1.kubia.default.svc.cluster.local: The sun is shining
- kubia-2.kubia.default.svc.cluster.local: No data posted yet

When a client request reaches one of your cluster nodes, it discovers all its peers, gathers data from them, and sends all the data back to the client. Even if you scale the StatefulSet up or down, the pod servicing the client’s request can always find all the peers running at that
```

##### Shutting Down a Node's `eth0` Interface (Shutting down a node)

To shut down a node’s eth0 interface, you need to ssh into one of the nodes like this:
```
gcloud compute ssh <NODE_NAME>
gcloud compute ssh gke-kubia-default-pool-32a2cac8-m0

Then, inside the node, run the following command:
sudo ifconfig eth0 down

Your ssh session will stop working, so you’ll need to open another terminal to continue
```

##### Forcibly Deleting Pod

```
The only thing you can do is tell the API server to delete the pod without waiting for the Kubelet to confirm that the pod is no longer running. 
You do that like this:

kubectl delete po kubia-0 --force --grace-period 0
warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "kubia-0" delete
```

##### Bring Disconnected Node back Online
```
gloud compute instances reset <node_name>
```
##### Check Control Plane Status

```
kubectl get componentstatuses
```
##### Kubernetes components running as pods
```
kubectl get pods -o custom-columns=POD:metadata.name,NODE:spec.nodeName --sort-by spec.nodeName -n kube-system
```

##### Control Plane Etcd
```
etcdctl ls /registry

If you’re using v3 of the etcd API, you can’t use the ls command to seethe contents of a directory. Instead, you can list all keys that start with a givenprefix with etcdctl get /registry --prefix=true

etcdctl ls /registry/pods

As you can infer from the names, these two entries correspond to the default and thekube-system  namespaces,  which  means  pods  are  stored  per  namespace.

etcdctl ls /registry/pods/default

etcd representing a pod:
etcdctl get /registry/pods/default/kubia-159041347-wt6g
```

##### Create pod Nginx and ssh onto node to investigate Docker containers, To see pod Infrastructure Container
```
kubectl run nginx --image=nginx
minikube ssh
or 
gcloud compute ssh <NODE_NAME>
docker ps
```

###### the kube-scheduler Endpoints resources used for leader-election
```
kubectl get endpoints kube-scheduler -n kube-system -o yaml
```
