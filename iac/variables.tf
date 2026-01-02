variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "git_repository" {
  type        = string
  description = "git repository from which this resource is from"
}

variable "git_branch" {
  type        = string
  description = "git branch from which this resource is from"
  default     = ""
}

variable "private_subnet" {
  type    = list(string)
  default = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
}

variable "public_subnet" {
  type    = list(string)
  default = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
}

variable "intra_subnet" {
  type    = list(string)
  default = ["10.0.96.0/20", "10.0.112.0/20", "10.0.128.0/20"]
}

variable "nat_gateways_count" {
  type        = number
  default     = 1
  description = "Number of NAT Gateway to deploy, should be inferior or equal to public subnet counts"
}
