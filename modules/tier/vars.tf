variable "vpc_id" {
	description = "The VPC ID to launch the tiered architecture into"
}

variable "cidr_block" {
	description = "The CIDR block of the tier subnet"
}

variable "map_public_ip_on_launch" {
  default = false
}

variable "name" {
	description = "name to be used for tggin instances"
}

variable "user_data" {
	description = "user data to supply to the instance"
}

variable "route_table_id" {
	description = "id of route table to associate "
}

variable "ami_id" {
	description = "ithe id of the ami to spin up in the subnet"
}

variable "ingress" {
  type = "list"
}

variable "machine_count" {
  description = "The number of machines to create"
}