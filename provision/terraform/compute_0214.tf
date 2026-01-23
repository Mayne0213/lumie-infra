# ============================================
# Availability Domain 조회 - 0214
# ============================================
data "oci_identity_availability_domains" "ads_0214" {
  provider       = oci.account_0214
  compartment_id = var.tenancy_0214_ocid
}

# ============================================
# Ubuntu 24.04 ARM64 이미지 조회 - 0214
# ============================================
data "oci_core_images" "ubuntu_arm64_0214" {
  provider                 = oci.account_0214
  compartment_id           = var.compartment_0214_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ============================================
# K3s 노드 인스턴스 - 0214 (Master + Workers)
# ============================================
resource "oci_core_instance" "nodes_0214" {
  provider    = oci.account_0214
  for_each    = var.nodes_0214

  compartment_id      = var.compartment_0214_ocid
  availability_domain = data.oci_identity_availability_domains.ads_0214.availability_domains[0].name
  display_name        = "k3s-${each.key}"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm64_0214.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet_0214.id
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
}

# ============================================
# Worker 노드 필터링 - 0214
# ============================================
locals {
  worker_nodes_0214 = {
    for name, config in var.nodes_0214 :
    name => config if config.role == "worker"
  }
}

# ============================================
# 블록 볼륨 (50GB MinIO) - 0214 Worker 노드용
# ============================================
resource "oci_core_volume" "volumes_0214" {
  provider    = oci.account_0214
  for_each    = local.worker_nodes_0214

  compartment_id      = var.compartment_0214_ocid
  availability_domain = data.oci_identity_availability_domains.ads_0214.availability_domains[0].name
  display_name        = "k3s-${each.key}-minio"
  size_in_gbs         = 50
  vpus_per_gb         = 10

  freeform_tags = {
    "role" = "minio"
    "node" = "k3s-${each.key}"
  }
}

# ============================================
# 블록 볼륨 Attachment - 0214
# ============================================
resource "oci_core_volume_attachment" "attachments_0214" {
  provider    = oci.account_0214
  for_each    = local.worker_nodes_0214

  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.nodes_0214[each.key].id
  volume_id       = oci_core_volume.volumes_0214[each.key].id
  display_name    = "k3s-${each.key}-minio-attachment"
  is_read_only    = false
  is_shareable    = false
}
