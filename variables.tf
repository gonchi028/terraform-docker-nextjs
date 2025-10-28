variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}
variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}
variable "fingerprint" {
  description = "The fingerprint of the user's public key"
  type        = string
}
variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}
variable "region" {
  description = "The region to deploy resources in"
  type        = string
}
variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}
variable "subnet_id" {
  description = "The OCID of the subnet"
  type        = string
}
variable "availability_domain" {
  description = "The availability domain to deploy resources in"
  type        = string
}
variable "ubuntu_2204_image_ocid" {
  description = "The OCID of the Ubuntu 22.04 image"
  type        = string
}
variable "ssh_public_key" {
  description = "The SSH public key to access the instance"
  type        = string
}
