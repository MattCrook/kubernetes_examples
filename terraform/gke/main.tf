module "gke-cluster-1" {
  source                    = "./modules/gke-cluster"
  project_id                = "myproject"
  name                      = "cluster-1"
  location                  = "us-central1-a"
  network                   = "default"
  subnetwork                = "default"
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32
  master_authorized_ranges = {
    internal-vms = "10.0.0.0/8"
  }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "192.168.0.0/28"
    master_global_access    = false
  }
  labels = {
    environment = "dev"
  }
}

module "cluster-1-nodepool-1" {
  source                      = "./modules/nodepool"
  project_id                  = "myproject"
  cluster_name                = "cluster-1"
  location                    = "us-central1-a"
  name                        = "nodepool-1"
}

######################################
# GKE Cluster with Dataplane V2 enabled
#######################################
module "gke-cluster-1" {
  source                    = "./modules/gke-cluster"
  project_id                = "myproject"
  name                      = "cluster-1"
  location                  = "us-central1-a"
  network                   = "default"
  subnetwork                = "default"
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32
  enable_dataplane_v2       = true
  master_authorized_ranges = {
    internal-vms = "10.0.0.0/8"
  }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "192.168.0.0/28"
    master_global_access    = false
  }
  labels = {
    environment = "dev"
  }
}

#######################################
# Internally managed service account
#######################################
module "cluster-1-nodepool-1" {
  source                      = "./modules/nodepool"
  project_id                  = "myproject"
  cluster_name                = "cluster-1"
  location                    = "us-central1-a"
  name                        = "nodepool-1"
  node_service_account_create = true
}
