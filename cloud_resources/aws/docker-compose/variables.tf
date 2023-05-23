variable "deployment_region"{
    description = "Region to deploy."
    type = string
    default = "us-east-2"
}

variable "operator_ssh_pub_key"{
    description = "SSH public key to access the EC2 instance."
    type = string
    default = null
}


variable "tendermint_ingress_port" {
  description = "Tendermint port to expose for the deployment."
  default = 26656
}
