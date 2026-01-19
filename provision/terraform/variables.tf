# ============================================
# OCI 기본 설정
# ============================================
variable "region" {
  description = "OCI Region"
  type        = string
  default     = "ap-chuncheon-1"
}

# ============================================
# 0214 계정 설정 (Master Account)
# ============================================
variable "tenancy_0214_ocid" {
  description = "0214 Account Tenancy OCID"
  type        = string
}

variable "compartment_0214_ocid" {
  description = "0214 Account Compartment OCID"
  type        = string
}

variable "vcn_0214_cidr" {
  description = "0214 VCN CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_0214_cidr" {
  description = "0214 Subnet CIDR block"
  type        = string
  default     = "10.0.0.0/24"
}

variable "nodes_0214" {
  description = "0214 Account nodes (master + workers)"
  type = map(object({
    ocpus         = number
    memory_in_gbs = number
    role          = string
  }))
}

# ============================================
# 0213 계정 설정 (Worker Account)
# ============================================
variable "tenancy_0213_ocid" {
  description = "0213 Account Tenancy OCID"
  type        = string
}

variable "compartment_0213_ocid" {
  description = "0213 Account Compartment OCID"
  type        = string
}

variable "vcn_0213_cidr" {
  description = "0213 VCN CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_0213_cidr" {
  description = "0213 Subnet CIDR block"
  type        = string
  default     = "10.1.0.0/24"
}

variable "nodes_0213" {
  description = "0213 Account nodes (workers only)"
  type = map(object({
    ocpus         = number
    memory_in_gbs = number
    role          = string
  }))
}

# ============================================
# SSH 키
# ============================================
variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

