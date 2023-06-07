variable "hosted_zone" {
  description = "Hosted zone name"
  default     = "astest.online"
}

variable "hosted_zone_id" {
  description = "Hosted zone ID"
  default     = "Z0866284667T45VZU8A0"
}

variable "cluster_name" {
  description = "Cluster name"
  default     = "as-cluster"
}
variable "deployment_region"{
    description = "Region to deploy the cluster to"
    default = "us-east-2"
}

variable "operator_ssh_pub_key_path"{
    description = "ssh public key path of the controlling key"
#   default = file("${path.module}/.txt")
    default = "~/.ssh/id_rsa.pub"
}

#variable "aws_cred_file"{
#    description = "path of credentials for aws"
#    default = "../aws_creds"
#}

variable "controller_count"{
    description = "Type of ec2 to be used for the controller nodes."
    default     = 2
}

variable "controller_type"{
    description = "Type of ec2 to be used for the controller nodes."
    default     = "m5.large"
}

variable "worker_count"{
    description = "Type of ec2 to be used for the worker nodes."
    default     = 2
}

variable "worker_type"{
    description = "Type of ec2 to be used for the worker nodes."
    default     = "m5.large"
}
