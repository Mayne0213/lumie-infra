# K3S-HOME

![K3s](https://img.shields.io/badge/K3s-v1.34-blue?logo=k3s)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-orange?logo=argo)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)
![Ansible](https://img.shields.io/badge/Ansible-Automation-red?logo=ansible)
![OCI](https://img.shields.io/badge/OCI-Cloud-red?logo=oracle)

## Overview

A production-grade, GitOps-driven home lab Kubernetes cluster running on Oracle Cloud Infrastructure (OCI).

## Key Features

- **GitOps workflow** - Git is the single source of truth; ArgoCD auto-syncs all changes
- **App-of-Apps pattern** - 7 application categories with hierarchical deployment
- **Air-gapped private registry** - Zot container registry for all workload images
- **Full observability stack** - Prometheus, Grafana, Loki, Tempo, OpenTelemetry
- **Secret management** - HashiCorp Vault with External Secrets Operator
- **Infrastructure as Code** - Terraform for cloud resources, Ansible for cluster provisioning

## Infrastructure

- **5-node cluster**: 1 master + 4 worker nodes
- **Multi-OCI account** with VCN peering for network isolation
- **Private registry**: All container images mirrored to internal Zot registry

## Component Categories

| Category | Purpose | Key Components |
|----------|---------|----------------|
| **bootstrap** | Foundation services | MinIO, Zot, Vault, Forgejo |
| **platform** | Platform services | Traefik, Cert-Manager, CoreDNS |
| **security** | Security & compliance | Authelia, Falco, Kyverno, Trivy |
| **storage** | Storage & database | CNPG, Velero |
| **observability** | Monitoring/logging/tracing | Prometheus, Grafana, Loki, Tempo, OTel |
| **applications** | Core applications | ArgoCD, Homer, Tekton, Code-Server |
| **web-apps** | Dynamic web applications | ApplicationSet-based deployment |

## Directory Structure

```
K3S-HOME/
├── provision/          # Terraform + Ansible (Infrastructure as Code)
├── bootstrap/          # Foundation services (Sync Wave -1)
├── platform/           # Platform services
├── security/           # Security components
├── storage/            # Storage and databases
├── observability/      # Monitoring, logging, tracing
├── applications/       # Core applications
├── web-apps/           # Dynamic web applications
└── charts/             # Shared Helm charts
```

## Documentation

For detailed architecture and setup guides, see the [documentation site](https://docs.k3s0213.kro.kr) (coming soon).
