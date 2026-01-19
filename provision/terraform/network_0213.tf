# ============================================
# VCN - 0213 Account (Workers)
# ============================================
resource "oci_core_vcn" "vcn_0213" {
  provider       = oci.account_0213
  compartment_id = var.compartment_0213_ocid
  cidr_blocks    = [var.vcn_0213_cidr]
  display_name   = "k3s-vcn-0213"
  dns_label      = "k3svcn0213"
}

# ============================================
# Internet Gateway - 0213
# ============================================
resource "oci_core_internet_gateway" "igw_0213" {
  provider       = oci.account_0213
  compartment_id = var.compartment_0213_ocid
  vcn_id         = oci_core_vcn.vcn_0213.id
  display_name   = "k3s-internet-gateway"
  enabled        = true
}

# ============================================
# Route Table - 0213
# ============================================
resource "oci_core_route_table" "rt_0213" {
  provider       = oci.account_0213
  compartment_id = var.compartment_0213_ocid
  vcn_id         = oci_core_vcn.vcn_0213.id
  display_name   = "k3s-route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.igw_0213.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  # Route to 0214 VCN via LPG
  route_rules {
    network_entity_id = oci_core_local_peering_gateway.lpg_0213.id
    destination       = var.vcn_0214_cidr
    destination_type  = "CIDR_BLOCK"
    description       = "Route to 0214 VCN via LPG"
  }
}

# ============================================
# Security List - 0213
# ============================================
resource "oci_core_security_list" "sl_0213" {
  provider       = oci.account_0213
  compartment_id = var.compartment_0213_ocid
  vcn_id         = oci_core_vcn.vcn_0213.id
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

  # Ingress: Kubelet (10250)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "Kubelet API"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  # Ingress: HTTP (80)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "HTTP"
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
    source      = var.vcn_0213_cidr
    stateless   = false
    description = "VCN internal"
  }

  # Ingress: 0214 VCN via peering
  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_0214_cidr
    stateless   = false
    description = "0214 VCN via peering"
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

  # Ingress: Flannel VXLAN (8472 UDP)
  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "Flannel VXLAN"
    udp_options {
      min = 8472
      max = 8472
    }
  }

  # Ingress: WireGuard (51820 UDP)
  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "WireGuard"
    udp_options {
      min = 51820
      max = 51820
    }
  }

}

# ============================================
# Public Subnet - 0213
# ============================================
resource "oci_core_subnet" "subnet_0213" {
  provider                   = oci.account_0213
  compartment_id             = var.compartment_0213_ocid
  vcn_id                     = oci_core_vcn.vcn_0213.id
  cidr_block                 = var.subnet_0213_cidr
  display_name               = "k3s-public-subnet"
  dns_label                  = "k3ssubnet"
  route_table_id             = oci_core_route_table.rt_0213.id
  security_list_ids          = [oci_core_security_list.sl_0213.id]
  prohibit_public_ip_on_vnic = false
}
