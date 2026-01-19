#!/usr/bin/env python3
"""
Dynamic Ansible Inventory from Terraform Output

Parses terraform output -json and generates Ansible inventory.
Supports both 0214 (master account) and 0213 (worker account) nodes.

Usage:
  ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml
  ./terraform_inventory.py --list
  ./terraform_inventory.py --host <hostname>
"""

import json
import subprocess
import sys
import os
from pathlib import Path


def get_terraform_output():
    """Get terraform output as JSON."""
    # Find terraform directory (sibling of ansible directory)
    # Structure: provision/ansible/inventory/terraform_inventory.py
    #            provision/terraform/
    script_dir = Path(__file__).parent
    terraform_dir = script_dir.parent.parent / "terraform"

    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f"Error running terraform output: {e.stderr}\n")
        sys.exit(1)
    except json.JSONDecodeError as e:
        sys.stderr.write(f"Error parsing terraform output: {e}\n")
        sys.exit(1)


def build_inventory(tf_output):
    """Build Ansible inventory from Terraform output."""
    inventory = {
        "_meta": {
            "hostvars": {}
        },
        "all": {
            "children": ["masters", "workers"]
        },
        "masters": {
            "hosts": []
        },
        "workers": {
            "children": ["workers_0214", "workers_0213"]
        },
        "workers_0214": {
            "hosts": []
        },
        "workers_0213": {
            "hosts": []
        }
    }

    master_private_ip = None

    # Process 0214 nodes (master account - has master and workers)
    public_ips_0214 = tf_output.get("nodes_0214_public_ips", {}).get("value", {})
    private_ips_0214 = tf_output.get("nodes_0214_private_ips", {}).get("value", {})

    for node_name, public_ip in public_ips_0214.items():
        private_ip = private_ips_0214.get(node_name, "")

        inventory["_meta"]["hostvars"][node_name] = {
            "ansible_host": public_ip,
            "private_ip": private_ip,
            "ansible_user": "ubuntu",
            "ansible_python_interpreter": "/usr/bin/python3"
        }

        if node_name == "master":
            inventory["masters"]["hosts"].append(node_name)
            master_private_ip = private_ip
            inventory["_meta"]["hostvars"][node_name]["k3s_role"] = "server"
        else:
            inventory["workers_0214"]["hosts"].append(node_name)
            inventory["_meta"]["hostvars"][node_name]["k3s_role"] = "agent"

    # Process 0213 nodes (worker account - workers only)
    public_ips_0213 = tf_output.get("nodes_0213_public_ips", {}).get("value", {})
    private_ips_0213 = tf_output.get("nodes_0213_private_ips", {}).get("value", {})

    for node_name, public_ip in public_ips_0213.items():
        private_ip = private_ips_0213.get(node_name, "")

        inventory["_meta"]["hostvars"][node_name] = {
            "ansible_host": public_ip,
            "private_ip": private_ip,
            "ansible_user": "ubuntu",
            "ansible_python_interpreter": "/usr/bin/python3",
            "k3s_role": "agent"
        }

        inventory["workers_0213"]["hosts"].append(node_name)

    # Set k3s_master_url for all workers (using master's private IP)
    if master_private_ip:
        k3s_master_url = f"https://{master_private_ip}:6443"

        for node_name in inventory["workers_0214"]["hosts"] + inventory["workers_0213"]["hosts"]:
            inventory["_meta"]["hostvars"][node_name]["k3s_master_url"] = k3s_master_url
            inventory["_meta"]["hostvars"][node_name]["k3s_master_private_ip"] = master_private_ip

        # Also set for master
        if inventory["masters"]["hosts"]:
            master_name = inventory["masters"]["hosts"][0]
            inventory["_meta"]["hostvars"][master_name]["k3s_master_url"] = k3s_master_url
            inventory["_meta"]["hostvars"][master_name]["k3s_master_private_ip"] = master_private_ip

    return inventory


def main():
    """Main entry point."""
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        tf_output = get_terraform_output()
        inventory = build_inventory(tf_output)
        print(json.dumps(inventory, indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == "--host":
        # Return empty dict for host-specific vars (all vars are in _meta)
        print(json.dumps({}))
    else:
        sys.stderr.write("Usage: {} --list | --host <hostname>\n".format(sys.argv[0]))
        sys.exit(1)


if __name__ == "__main__":
    main()
