# ============================================
# VCN Peering - Cross-Tenancy (0213 <-> 0214)
# ============================================

# Local Peering Gateway - 0214 VCN (Requestor)
resource "oci_core_local_peering_gateway" "lpg_0214" {
  provider       = oci.account_0214
  compartment_id = var.compartment_0214_ocid
  vcn_id         = oci_core_vcn.vcn_0214.id
  display_name   = "lpg-to-0213"
  peer_id        = oci_core_local_peering_gateway.lpg_0213.id
}

# Local Peering Gateway - 0213 VCN
resource "oci_core_local_peering_gateway" "lpg_0213" {
  provider       = oci.account_0213
  compartment_id = var.compartment_0213_ocid
  vcn_id         = oci_core_vcn.vcn_0213.id
  display_name   = "lpg-to-0214"
}

# ============================================
# Peering 연결 상태 출력
# ============================================
output "peering_status" {
  description = "VCN Peering Gateway Status"
  value = {
    lpg_0214_id     = oci_core_local_peering_gateway.lpg_0214.id
    lpg_0213_id     = oci_core_local_peering_gateway.lpg_0213.id
    peering_status  = "Auto-connected via Terraform (peer_id)"
  }
}
