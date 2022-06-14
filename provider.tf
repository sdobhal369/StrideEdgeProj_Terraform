provider "aws" {

  
  region     = "us-west-1"
  access_key = "var.accesskey"
  secret_key = "var.secretkey"
}



# Parameters of kubernetes provider

provider "kubectl" {
  load_config_file       = false
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = "${data.google_container_cluster.my_cluster.access_token}"
  cluster_ca_certificate = "${base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)}"
}



provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


