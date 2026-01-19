# K3s Ansible Deployment

Ansible playbooks for deploying K3s cluster on OCI infrastructure.

## Architecture

```
Account 0214 (DEFAULT):
  - master (10.0.0.241) - K3s server
  - worker-1 (10.0.0.124) - K3s agent
  - worker-2 (10.0.0.2) - K3s agent

Account 0213 (SECOND):
  - worker-3 (10.1.0.148) - K3s agent (VCN Peering)
  - worker-4 (10.1.0.9) - K3s agent (VCN Peering)
```

## Prerequisites

- Ansible 2.14+
- Python 3.8+
- SSH access to all nodes
- Terraform (for dynamic inventory)

### Install Ansible Collections

```bash
ansible-galaxy collection install ansible.posix community.general
```

## Quick Start

### With Terraform (Recommended)

```bash
# 1. Deploy infrastructure
cd ..
terraform apply

# 2. Deploy K3s cluster
cd ansible
ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml

# 3. Fetch kubeconfig to local machine
ansible-playbook -i inventory/terraform_inventory.py playbooks/fetch-kubeconfig.yml

# 4. Use kubectl
export KUBECONFIG=./kubeconfig/config
kubectl get nodes
```

### Without Terraform

```bash
# 1. Copy example inventory
cp inventory/hosts.yml.example inventory/hosts.yml

# 2. Edit IP addresses
vim inventory/hosts.yml

# 3. Deploy K3s cluster
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

## Playbooks

| Playbook | Description |
|----------|-------------|
| `site.yml` | Full cluster deployment (common + master + workers) |
| `k3s-master.yml` | Master node only |
| `k3s-workers.yml` | Worker nodes only (requires master) |
| `k3s-reset.yml` | Remove K3s from all nodes |
| `fetch-kubeconfig.yml` | Download kubeconfig to local machine |

## Usage Examples

### Full Deployment

```bash
ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml
```

### Dry Run (Check Mode)

```bash
ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml --check
```

### Deploy Only Workers

```bash
ansible-playbook -i inventory/terraform_inventory.py playbooks/k3s-workers.yml
```

### Deploy Specific Worker Group

```bash
# Only 0214 workers
ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml --tags workers_0214

# Only 0213 workers
ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml --tags workers_0213
```

### Skip Common Tasks (Faster Redeploy)

```bash
ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml --skip-tags common
```

### Verbose Output

```bash
ansible-playbook -i inventory/terraform_inventory.py playbooks/site.yml -v
```

## Directory Structure

```
ansible/
├── ansible.cfg                    # Ansible configuration
├── inventory/
│   ├── hosts.yml.example          # Static inventory example
│   └── terraform_inventory.py     # Dynamic inventory from Terraform
├── group_vars/
│   ├── all.yml                    # Variables for all hosts
│   ├── masters.yml                # Variables for master nodes
│   ├── workers_0214.yml           # Variables for 0214 workers
│   └── workers_0213.yml           # Variables for 0213 workers
├── roles/
│   ├── common/                    # OS preparation role
│   ├── k3s-master/                # K3s server installation
│   └── k3s-worker/                # K3s agent installation
├── playbooks/
│   ├── site.yml                   # Full deployment
│   ├── k3s-master.yml             # Master only
│   ├── k3s-workers.yml            # Workers only
│   ├── k3s-reset.yml              # Cluster reset
│   └── fetch-kubeconfig.yml       # Get kubeconfig
└── README.md
```

## Token Management

**No hardcoded tokens!** The token flow:

1. Master installation generates token at `/var/lib/rancher/k3s/server/node-token`
2. Ansible reads token from master using `slurp` module
3. Token is passed to workers via `delegate_to` and `set_fact`
4. Workers join cluster using the token

## K3s Configuration

Current configuration matches existing cluster:

| Setting | Value |
|---------|-------|
| K3s Version | v1.34.3+k3s1 |
| Container Runtime | containerd |
| Traefik | Disabled |
| Kubeconfig Mode | 644 |
| Pod CIDR | 10.42.0.0/16 |
| Service CIDR | 10.43.0.0/16 |

## Networking

- All workers connect to master via **private IP** (10.0.0.241)
- VCN Peering allows 0213 workers to reach master
- Tested latency: ~0.4ms

## Troubleshooting

### Check Inventory

```bash
./inventory/terraform_inventory.py --list | jq .
```

### Test SSH Connectivity

```bash
ansible all -i inventory/terraform_inventory.py -m ping
```

### Check K3s Status on Nodes

```bash
ansible all -i inventory/terraform_inventory.py -m shell -a "systemctl status k3s* || true"
```

### View K3s Logs

```bash
# Master
ansible masters -i inventory/terraform_inventory.py -m shell -a "journalctl -u k3s -n 50"

# Workers
ansible workers -i inventory/terraform_inventory.py -m shell -a "journalctl -u k3s-agent -n 50"
```

## Idempotency

All playbooks are idempotent:
- Running multiple times is safe
- Already installed components are skipped
- Configuration is verified each run

## Security Notes

- No sensitive data in version control
- Tokens retrieved dynamically
- SSH keys managed separately
- kubeconfig/ directory is gitignored
