# Kubernetes

This repository consists of a collection of Kubernetes examples with config files for many Kubernetes resources, services, and components.

## Set up a quick Kubernetes Cluster on AWS

If you want to quickly provision a Kubernetes cluster to play around with, and don't want/ need to deal with the configuration in Terraform, you can use the `eksctl` command line tool to do so.

##### Install EKSCTL
* `brew tap weaveworks/tap`
* `brew install weaveworks/tap/eksctl`

Create a 2048-bit RSA key pair with the specified name. Amazon EC2 stores the public key and displays the private key for you to save to a file. The private key is returned as an unencrypted PEM encoded PKCS#1 private key.

`aws ec2 create-key-pair --region us-west-2 --key-name <myKeyPair>`

Set up the cluster using eksctl:

```sh
eksctl create cluster \
    --name <Name_Your_Cluster>
    --version 1.17 \
    --region us-east-2 \
    --with-oidc \
    --ssh-access \
    --ssh-public-key <your-key> \
    --nodegroup-name linux-nodes \
    --node-type t2-medium \
    --nodes 2
    --managed
```

Delete cluster when done:
* `eksctl delete cluster --name <cluster_name> --region us-east-2`

#### Amazon EKS Managed Node Groups

Amazon EKS managed node groups automate the provisioning and lifecycle management of nodes (Amazon EC2 instances) for Amazon EKS Kubernetes clusters.

With Amazon EKS managed node groups, you don’t need to separately provision or register the Amazon EC2 instances that provide compute capacity to run your Kubernetes applications.

You can create, automatically update, or terminate nodes for your cluster with a single operation.

```sh
eksctl create nodegroup \
  --cluster <my-cluster> \
  --region <us-east-2> \
  --name <my-mng> \
  --node-type <t2-medium> \
  --nodes <3> \
  --nodes-min <2> \
  --nodes-max <4> \
  --ssh-access \
  --ssh-public-key <my-key> \
  --managed
```

Delete cluster when done:
* `eksctl delete cluster --name <cluster_name> --region us-east-2`


## Set up a quick Kubernetes Cluster on GCP

Same as with AWS, if you want to quickly provision a Kubernetes cluster to play around with, and don't want/ need to deal with the configuration in Terraform, you can use the `gcloud` command line tool to do so.

#### Set up cluster with gcloud

If not done so, install the `gcloud` SDK:
* https://cloud.google.com/sdk/docs/install

You can configure your default region/zone for your project, so that omitting those in the script below will use them, or just define them in the `gcloud` command.

To see what is currently set as default region/zone:
* `gcloud config get-value compute/region`
* `gcloud config get-value compute/zone`

Or to get a full description of your configurations:
* `gcloud config configurations list`


```sh
gcloud container clusters create <cluster_name> \
    --num-nodes=2 \
    --project=<project_name-in_GCP> \
    --region=us-central1
    --zone=us-central1-c
    --machine-type f1-micro
    --enable-stackdriver-kubernetes
```

Get Kubernetes Master Public IP address:
* `gcloud container clusters describe mycluster --format='get(endpoint)'`

Create cluster with Labels:

* `gcloud container clusters create example-cluster --labels env=dev`
* `gcloud container clusters list --filter resourceLabels.env=dev`

After creating your cluster, get authentication credentials to interact and connect with the cluster:

* `gcloud container clusters get-credentials <cluster_name>`

Delete cluster:

* `gcloud container clusters delete <cluster_name>`

## Set up with Minikube (on Mac)

**Install hypervisor**
* `brew update`
* `brew install hyperkit`

**Install Minikube**
* `brew install minikube`

**Start Minikube**
* `minikube start --vm-driver=hyperkit`

**Start with certain version and in debug mode:**
* `minikube start --vm-driver=hyperkit --v=7 --alsologtostderr`

**Stop/ Delete Running Cluster in Minikube**
* `minikube delete`


#### Ingress and Other Add Ons

Enabling the Ingress add-on in Minikube. You can check whether it is by listing all the add-ons:

* `minikube addons list`
* `minikube addons enable <addon>`

*Example - adding ingress*:
* `minikube addons enable ingress`
