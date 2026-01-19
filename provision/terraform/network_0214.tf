# ============================================
# VCN - 0214 Account (Master)
# ============================================
resource "oci_core_vcn" "vcn_0214" {
  provider       = oci.account_0214
  compartment_id = var.compartment_0214_ocid
  cidr_blocks    = [var.vcn_0214_cidr]
  display_name   = "k3s-vcn"
  dns_label      = "k3svcn"
}

# ============================================
# Internet Gateway - 0214
# ============================================
resource "oci_core_internet_gateway" "igw_0214" {
  provider       = oci.account_0214
  compartment_id = var.compartment_0214_ocid
  vcn_id         = oci_core_vcn.vcn_0214.id
  display_name   = "k3s-internet-gateway"
  enabled        = true
}

# ============================================
# Route Table - 0214
# ============================================
resource "oci_core_route_table" "rt_0214" {
  provider       = oci.account_0214
  compartment_id = var.compartment_0214_ocid
  vcn_id         = oci_core_vcn.vcn_0214.id
  display_name   = "k3s-route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.igw_0214.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  # Route to 0213 VCN via LPG
  route_rules {
    network_entity_id = oci_core_local_peering_gateway.lpg_0214.id
    destination       = var.vcn_0213_cidr
    destination_type  = "CIDR_BLOCK"
    description       = "Route to 0213 VCN via LPG"
  }
}

# ============================================
# Security List - 0214
# ============================================
resource "oci_core_security_list" "sl_0214" {
  provider       = oci.account_0214
  compartment_id = var.compartment_0214_ocid
  vcn_id         = oci_core_vcn.vcn_0214.id
  display_name   = "k3s-security-list"

  # Egress: 모든 트래픽 허용
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress: SSH (22)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "SSH"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: HTTP (80)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "HTTP/Lets Encrypt"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress: HTTPS (443)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "HTTPS"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Ingress: K3s API Server (6443)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "K3s API Server"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Ingress: ICMP
  ingress_security_rules {
    protocol    = "1"
    source      = "0.0.0.0/0"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Ingress: VCN 내부 통신
  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_0214_cidr
    stateless   = false
    description = "VCN internal"
  }

  # Ingress: 0213 VCN via peering
  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_0213_cidr
    stateless   = false
    description = "0213 VCN via peering"
  }

  # Ingress: K3s Pod Network
  ingress_security_rules {
    protocol    = "all"
    source      = "10.42.0.0/16"
    stateless   = false
    description = "K3s Pod Network"
  }

  # Ingress: K3s Service Network
  ingress_security_rules {
    protocol    = "all"
    source      = "10.43.0.0/16"
    stateless   = false
    description = "K3s Service Network"
  }

}

# ============================================
# Public Subnet - 0214
# ============================================
resource "oci_core_subnet" "subnet_0214" {
  provider                   = oci.account_0214
  compartment_id             = var.compartment_0214_ocid
  vcn_id                     = oci_core_vcn.vcn_0214.id
  cidr_block                 = var.subnet_0214_cidr
  display_name               = "k3s-public-subnet"
  dns_label                  = "k3ssubnet"
  route_table_id             = oci_core_route_table.rt_0214.id
  security_list_ids          = [oci_core_security_list.sl_0214.id]
  prohibit_public_ip_on_vnic = false
}
