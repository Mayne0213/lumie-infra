# ============================================
# Availability Domain 조회 - 0213
# ============================================
data "oci_identity_availability_domains" "ads_0213" {
  provider       = oci.account_0213
  compartment_id = var.tenancy_0213_ocid
}

# ============================================
# Ubuntu 24.04 ARM64 이미지 조회 - 0213
# ============================================
data "oci_core_images" "ubuntu_arm64_0213" {
  provider                 = oci.account_0213
  compartment_id           = var.compartment_0213_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ============================================
# K3s Worker 노드 인스턴스 - 0213
# ============================================
resource "oci_core_instance" "nodes_0213" {
  provider    = oci.account_0213
  for_each    = var.nodes_0213

  compartment_id      = var.compartment_0213_ocid
  availability_domain = data.oci_identity_availability_domains.ads_0213.availability_domains[0].name
  display_name        = "k3s-${each.key}"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm64_0213.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet_0213.id
    assign_public_ip = true
    display_name     = "k3s-${each.key}-vnic"
    hostname_label   = "k3s-${each.key}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    # Minimal user_data: only set hostname
    # All other configuration (packages, iptables, kernel modules) handled by Ansible
    user_data = base64encode(<<-EOF
      #!/bin/bash
      hostnamectl set-hostname k3s-${each.key}
    EOF
    )
  }

  agent_config {
    is_monitoring_disabled = false
    is_management_disabled = false
  }

  freeform_tags = {
    "role" = each.value.role
    "name" = "k3s-${each.key}"
  }

  lifecycle {
    ignore_changes = [metadata]
  }

  depends_on = [oci_core_instance.nodes_0214]
}

# ============================================
# 블록 볼륨 (50GB MinIO) - 0213 Worker 노드용
# ============================================
resource "oci_core_volume" "volumes_0213" {
  provider    = oci.account_0213
  for_each    = var.nodes_0213

  compartment_id      = var.compartment_0213_ocid
  availability_domain = data.oci_identity_availability_domains.ads_0213.availability_domains[0].name
  display_name        = "k3s-${each.key}-minio"
  size_in_gbs         = 50
  vpus_per_gb         = 10

  freeform_tags = {
    "role" = "minio"
    "node" = "k3s-${each.key}"
  }
}

# ============================================
# 블록 볼륨 Attachment - 0213
# ============================================
resource "oci_core_volume_attachment" "attachments_0213" {
  provider    = oci.account_0213
  for_each    = var.nodes_0213

  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.nodes_0213[each.key].id
  volume_id       = oci_core_volume.volumes_0213[each.key].id
  display_name    = "k3s-${each.key}-minio-attachment"
  is_read_only    = false
  is_shareable    = false
}
