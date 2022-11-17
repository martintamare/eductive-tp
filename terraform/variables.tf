variable "student_id" {
  default = "eductive27"
  type    = string
}

variable "gra_backends" {
  default = 1
  type    = number
}

variable "sbg_backends" {
  default = 1
  type    = number
}

variable "vlan_id" {
  default = 27
  type    = number
}

variable "service_name" {
  type    = string
}

variable "vlan_dhcp_start" {
  type    = string
  default = "192.168.27.100"
}
variable "vlan_dhcp_end" {
  type    = string
  default = "192.168.27.200"
}
variable "vlan_dhcp_network" {
  type    = string
  default = "192.168.27.0/24"
}
