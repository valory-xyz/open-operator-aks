provider "ct" {}

terraform {
  required_providers {
    ct = {
      source = "poseidon/ct"
      #version = "0.9.0"
      version = "0.11.0"
    }
    aws = {
      source = "hashicorp/aws"
      #version = "3.48.0"
      version = "4.61.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.10.0"
    }    
  }

  backend "s3" {
    bucket = "open-operator-aks-kube"
    key    = "terraform.tfstate"
    region = "us-east-2"
    #dynamodb_table = "open_operator_terraform_state_lock"
    #encrypt        = true
  }
}

provider "kubernetes" {
    config_path = "kubefiles/kubeconfig"
}

provider "helm" {
    kubernetes {
        config_path = "kubefiles/kubeconfig"
    }
}


module "aws_cluster" {
  #source = "git::https://github.com/poseidon/typhoon//aws/flatcar-linux/kubernetes?ref=v1.22.4"
  source = "git::https://github.com/poseidon/typhoon//aws/flatcar-linux/kubernetes?ref=v1.24.1"
  #source = "git::https://github.com/poseidon/typhoon//aws/flatcar-linux/kubernetes?ref=v1.27.2"

  # AWS
  cluster_name = var.cluster_name
  dns_zone     = var.hosted_zone
  dns_zone_id  = var.hosted_zone_id

  # configuration
  #ssh_authorized_key = file(var.operator_ssh_pub_key_path)
  ssh_authorized_key = chomp(file(var.operator_ssh_pub_key_path))

  # optional
  worker_count = var.worker_count
  worker_type  = var.worker_type
  controller_count = var.controller_count
  controller_type  = var.controller_type
}


resource "aws_route53_record" "app-1" {
  zone_id = var.hosted_zone_id

  name = format("*.%s.%s", var.cluster_name, var.hosted_zone)
  type = "A"
  alias {
    name                   = module.aws_cluster.ingress_dns_name
    zone_id                = module.aws_cluster.ingress_zone_id
    evaluate_target_health = false
  }  # DNS zone name
  # DNS record
}

resource "local_file" "kubeconfig" {
  content  = module.aws_cluster.kubeconfig-admin
  filename = "kubefiles/kubeconfig"
}


/*
resource "kubernetes_storage_class" "nfs-ephemeral" {
  depends_on = [
      local_file.kubeconfig,
    ]

  metadata {
    name = "nfs-ephemeral"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    
    fileSystemId   = aws_efs_file_system.efs_ephemeral.id
    directoryPerms = "755"
    uid            = "1000"
    gid            = "1000"
  }
}
*/

#output "efs_file_system_id" {
#  value = aws_efs_file_system.efs.id
#}

/*
resource "helm_release" "nfs-ephemeral" {
    name         = "nfs-ephemeral"
    chart        = "https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/releases/download/nfs-subdir-external-provisioner-4.0.18/nfs-subdir-external-provisioner-4.0.18.tgz"
    namespace    = "nfs-ephemeral"
    create_namespace = true
    depends_on = [
      local_file.kubeconfig,
    ]

    values = [
        <<EOF
        # this is a shame, this is a helpful image which allows an nfs server to be used as a storage class
        # image:
        #     tag: v2.3.0
        #     repository: quay.io/kubernetes_incubator/nfs-provisioner
        storageClass:
            name: "nfs-ephemeral"
            archiveOnDelete: false
        resources:
            requests:
                memory: "128Mi"
                cpu: "100m"
            limits:
                memory: "256Mi"
                cpu: "200m"
        nfs:
            server: ${aws_efs_mount_target.efs-ephemeral-mt["subnet_1"].ip_address}
            path: "/dynamic_provisioning"
        EOF
    ]
}
*/
