# =========   Global Variables  =========

variable "agency_code" {
  type     = string
  nullable = false
}
variable "terraform" {
  type     = bool
  nullable = false
}
variable "project_code" {
  type     = string
  nullable = false
}
variable "division" {
  type     = string
  nullable = false
}
variable "env" {
  type     = string
  nullable = false
}
# variable "tier" {
#   type     = string
#   nullable = false
# }
variable "purpose" {
  type     = string
  nullable = false
}
variable "requestor" {
  type     = string
  nullable = false
}
variable "creator" {
  type     = string
  nullable = false
}
variable "repo_name" {
  type     = string
  nullable = false
}
# =========   Local Variables  =========
variable "instance_type" {
  type     = string
  nullable = false
}
variable "vpc_id" {
  type     = string
  nullable = false
}
variable "subnet_id" {
  type     = string
  nullable = false
}
variable "ebs_volume" {
  type     = string
  nullable = false
}