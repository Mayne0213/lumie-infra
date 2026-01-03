# K3S-HOME

Home Kubernetes cluster infrastructure managed with GitOps (ArgoCD).

## Repositories

| Repository | Description |
|------------|-------------|
| [cluster-infrastructure](https://github.com/K3S-HOME/cluster-infrastructure) | Core infrastructure: Traefik, Cert-Manager, Vault, Authelia, Velero, VPA, Falco |
| [applications](https://github.com/K3S-HOME/applications) | User applications: Gitea, Homer, Docusaurus, Immich, Code-Server, Headlamp |
| [monitoring](https://github.com/K3S-HOME/monitoring) | Observability stack: Prometheus, Grafana, Loki, Alertmanager, Goldilocks |
| [databases](https://github.com/K3S-HOME/databases) | Data services: PostgreSQL (CNPG), Longhorn, MinIO, PgWeb |

## Tech Stack

- **Kubernetes**: K3s on Oracle Cloud (ARM64)
- **GitOps**: ArgoCD
- **Ingress**: Traefik
- **TLS**: Cert-Manager + Let's Encrypt
- **Auth**: Authelia SSO
- **Secrets**: HashiCorp Vault + External Secrets
- **Storage**: Longhorn, MinIO
- **Backup**: Velero
