variable access_cidr {
  description = "IP range which may access resources like rds instance"
}

variable "default_vpc_sg_id" {
  default = "sg-730f900a"
  description = "The SG Id of the default VPC in the region where this should be deployed."
}