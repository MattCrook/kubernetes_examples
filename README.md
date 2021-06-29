# Kubernetes

This repository consists of a collection of Kubernetes examples with config files for many Kubernetes resources, services, and components.

## Set up a quick Kubernetes Cluster on AWS

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

## Set up a quick Kubernetes Cluster on GCP

#### Set up cluster with gcloud

You can configure your default region/zone for your project, so that omitting those in the script below will use them, or just define them in the `gcloud` command.

To see what is currently set as default region/zone:
* `gcloud config get-value compute/region`
* `gcloud config get-value compute/zone`

Or to get a full description of your configurations:
* `gcloud config configurations list`


```sh
gcloud container clusters create <cluster_name> \
    --num-nodes=2 \
    --project=<project_in_GCP> \
    --region=us-central1
    --zone=us-central1-c
    --machine-type f1-micro
```


After creating your cluster, get authentication credentials to interact and connect with the cluster:
* `gcloud container clusters get-credentials <cluster_name>`


Delete cluster:
* `gcloud container clusters delete <cluster_name>`


### Set up with Minikube (on Mac)

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
