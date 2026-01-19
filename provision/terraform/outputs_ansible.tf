# Ansible-specific outputs
# These outputs are used by the dynamic inventory script

output "ansible_inventory_hint" {
  description = "Hint for using Ansible with this infrastructure"
  value       = <<-EOT
    Ansible Deployment:

    1. Navigate to ansible directory:
       cd ansible

    2. Test inventory:
       ./inventory/terraform_inventory.py --list | jq .

    3. Test connectivity:
       ansible all -i inventory/terraform_inventory.py -m ping

    4. Deploy K3s cluster:
       ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml

    5. Fetch kubeconfig:
       ansible-playbook -i inventory/terraform_inventory.py playbooks/fetch-kubeconfig.yml
  EOT
}

output "master_info" {
  description = "K3s master node information"
  value = {
    name       = "master"
    public_ip  = oci_core_instance.nodes_0214["master"].public_ip
    private_ip = oci_core_instance.nodes_0214["master"].private_ip
    k3s_url    = "https://${oci_core_instance.nodes_0214["master"].private_ip}:6443"
  }
}

output "workers_info" {
  description = "K3s worker nodes information"
  value = merge(
    {
      for name, instance in oci_core_instance.nodes_0214 :
      name => {
        account    = "0214"
        public_ip  = instance.public_ip
        private_ip = instance.private_ip
      }
      if name != "master"
    },
    {
      for name, instance in oci_core_instance.nodes_0213 :
      name => {
        account    = "0213"
        public_ip  = instance.public_ip
        private_ip = instance.private_ip
      }
    }
  )
}
