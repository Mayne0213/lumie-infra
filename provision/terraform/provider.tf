# ============================================
# Terraform 설정
# ============================================
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# ============================================
# OCI Provider - 0214 Account (DEFAULT profile)
# Master + Worker-1 + Worker-2
# ============================================
provider "oci" {
  alias               = "account_0214"
  region              = var.region
  config_file_profile = "DEFAULT"
}

# ============================================
# OCI Provider - 0213 Account (SECOND profile)
# Worker-3 + Worker-4
# ============================================
provider "oci" {
  alias               = "account_0213"
  region              = var.region
  config_file_profile = "SECOND"
}
