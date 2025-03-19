variable "hcp_client_secret" {}

variable "region" {
  default = "us-east-2"
  type    = string
}

variable "cidr-vpc" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az" {
  type        = list(string)
  description = "availability zones"
  default     = ["us-east-2a", "us-east-2b"]
}

variable "cidr-rt" {
  type    = string
  default = "0.0.0.0/0"
}

variable "ami" {
  type    = string
  default = "ami-0cb91c7de36eed2cb"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
