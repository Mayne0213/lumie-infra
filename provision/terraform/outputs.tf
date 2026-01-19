# ============================================
# 0214 Account Outputs (Master + Workers)
# ============================================
output "nodes_0214_public_ips" {
  description = "0214 Account - Node Public IPs"
  value = {
    for name, instance in oci_core_instance.nodes_0214 :
    name => instance.public_ip
  }
}

output "nodes_0214_private_ips" {
  description = "0214 Account - Node Private IPs"
  value = {
    for name, instance in oci_core_instance.nodes_0214 :
    name => instance.private_ip
  }
}

output "ssh_commands_0214" {
  description = "0214 Account - SSH Commands"
  value = {
    for name, instance in oci_core_instance.nodes_0214 :
    name => "ssh ubuntu@${instance.public_ip}"
  }
}

# ============================================
# 0213 Account Outputs (Workers)
# ============================================
output "nodes_0213_public_ips" {
  description = "0213 Account - Node Public IPs"
  value = {
    for name, instance in oci_core_instance.nodes_0213 :
    name => instance.public_ip
  }
}

output "nodes_0213_private_ips" {
  description = "0213 Account - Node Private IPs"
  value = {
    for name, instance in oci_core_instance.nodes_0213 :
    name => instance.private_ip
  }
}

output "ssh_commands_0213" {
  description = "0213 Account - SSH Commands"
  value = {
    for name, instance in oci_core_instance.nodes_0213 :
    name => "ssh ubuntu@${instance.public_ip}"
  }
}

# ============================================
# VCN 정보
# ============================================
output "vcn_0214_id" {
  description = "0214 VCN OCID"
  value       = oci_core_vcn.vcn_0214.id
}

output "vcn_0213_id" {
  description = "0213 VCN OCID"
  value       = oci_core_vcn.vcn_0213.id
}

# ============================================
# K3s 설치 가이드
# ============================================
output "k3s_install_guide" {
  description = "K3s installation commands"
  value = <<-EOF

    ========================================
    K3s 클러스터 설정 가이드
    ========================================

    1. Master 노드 (0214 계정)에서 K3s 설치:
       ssh ubuntu@${try(oci_core_instance.nodes_0214["master"].public_ip, "MASTER_IP")}

       curl -sfL https://get.k3s.io | sh -s - server \
         --disable traefik \
         --write-kubeconfig-mode 644

    2. Master에서 토큰 확인:
       sudo cat /var/lib/rancher/k3s/server/node-token

    3. Worker 노드 (0214 계정)에서 조인:
       curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_PRIVATE_IP>:6443 \
         K3S_TOKEN=<TOKEN> sh -

    4. Worker 노드 (0213 계정)에서 조인:
       curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_PUBLIC_IP>:6443 \
         K3S_TOKEN=<TOKEN> sh -

    ========================================
  EOF
}
