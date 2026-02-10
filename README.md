# lumie-infra

GitOps-driven Kubernetes infrastructure on Oracle Cloud. A 5-node K3s cluster managed entirely through ArgoCD with an app-of-apps pattern.

## Stack

| Layer | Components |
|-------|------------|
| Cloud | OCI (multi-account, VCN peering) |
| Cluster | K3s v1.34 (1 master + 4 workers) |
| GitOps | ArgoCD (self-managed, auto-sync) |
| Ingress | Kong API Gateway |
| TLS | Cert-Manager (Vault-backed) |
| Registry | Zot (air-gapped, on-demand sync from upstream) |
| Secrets | HashiCorp Vault + External Secrets Operator |
| Database | CloudNativePG (PostgreSQL 18.1) + PgBouncer |
| Monitoring | Prometheus, Thanos, Grafana, Loki, Tempo, OpenTelemetry |
| Security | Authelia, Keycloak, Falco, Kyverno, Trivy |
| CI/CD | Tekton Pipelines (Kaniko builds → Zot) |
| IaC | Terraform + Ansible |

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           Oracle Cloud (2 accounts)      │
                    │    VCN Peering for network isolation      │
                    └────────────────┬────────────────────────┘
                                     │
                    ┌────────────────┴────────────────────────┐
                    │         K3s Cluster (5 nodes)            │
                    │                                          │
   Git Push ──► ArgoCD ──► Auto-sync all applications          │
                    │                                          │
                    │  ┌──────────┐  ┌──────────┐  ┌────────┐ │
                    │  │ Kong     │  │ Zot      │  │ Vault  │ │
                    │  │ Ingress  │  │ Registry │  │ Secrets│ │
                    │  └──────────┘  └──────────┘  └────────┘ │
                    │                                          │
                    │  ┌──────────────────────────────────────┐│
                    │  │ Observability                        ││
                    │  │ Prometheus → Thanos → Grafana        ││
                    │  │ OTel → Loki (logs) / Tempo (traces)  ││
                    │  └──────────────────────────────────────┘│
                    │                                          │
                    │  ┌──────────────────────────────────────┐│
                    │  │ LUMIE Platform (multi-tenant)        ││
                    │  │ 12 microservices + CNPG + PgBouncer  ││
                    │  │ RabbitMQ event bus                   ││
                    │  └──────────────────────────────────────┘│
                    └──────────────────────────────────────────┘
```

## Repository Structure

```
lumie-infra/
├── provision/                # Infrastructure as Code
│   ├── terraform/            #   OCI compute, networking, VCN peering
│   └── ansible/              #   K3s install, storage setup, ArgoCD bootstrap
│
├── bootstrap/                # Foundation services (Sync Wave -1)
│   ├── minio/                #   Object storage (backups)
│   ├── zot/                  #   Private container registry
│   ├── vault/                #   Secrets management + VSO
│   └── kong/                 #   API gateway & ingress controller
│
├── platform/                 # Platform infrastructure
│   ├── priority-classes/     #   Pod QoS priority tiers
│   ├── coredns-config/       #   Cluster DNS configuration
│   ├── cert-manager/         #   TLS certificate management
│   ├── rabbitmq-operator/    #   RabbitMQ operator
│   └── rabbitmq/             #   Event bus for microservices
│
├── security/                 # Security & compliance
│   ├── authelia/             #   Authentication gateway
│   ├── keycloak/             #   OIDC identity provider
│   ├── falco/                #   Runtime threat detection
│   ├── kyverno/              #   Policy enforcement (4 policies)
│   ├── trivy/                #   Vulnerability scanning
│   └── teleport/             #   SSH & Kubernetes access
│
├── storage/                  # Data persistence
│   ├── cnpg/                 #   CloudNativePG operator
│   ├── infra-db/             #   Shared PostgreSQL (Teleport, Grafana, Umami, Keycloak)
│   ├── pgbouncer/            #   Connection pooling (LUMIE tenants)
│   ├── pgweb/                #   PostgreSQL web UI
│   ├── redis/                #   In-memory cache
│   └── velero/               #   Backup & disaster recovery (→ MinIO)
│
├── observability/            # Monitoring, logging, tracing
│   ├── prometheus/           #   Metrics collection
│   ├── thanos/               #   Long-term metrics storage
│   ├── alertmanager/         #   Alert routing
│   ├── grafana/              #   Dashboards (14 pre-built)
│   ├── loki/                 #   Log aggregation
│   ├── tempo/                #   Distributed tracing
│   ├── opentelemetry-operator/
│   ├── opentelemetry/        #   OTel Collector (metrics, logs, traces)
│   ├── node-exporter/        #   Host metrics
│   ├── kube-state-metrics/   #   Kubernetes object metrics
│   ├── blackbox-exporter/    #   Endpoint probing
│   ├── goldilocks/           #   VPA recommendation dashboard
│   └── vpa/                  #   Vertical Pod Autoscaler
│
├── applications/             # Business applications
│   ├── argocd/               #   GitOps controller (self-managed)
│   ├── tekton/               #   CI/CD pipelines, triggers, dashboard
│   │   └── ci-cd/            #     6 pipeline templates (Spring Boot, Next.js, Python, React, FastAPI, LUMIE)
│   ├── lumie/                #   Multi-tenant academy platform
│   │   ├── tenant-svc/       #     Tenant management
│   │   ├── auth-svc/         #     Authentication
│   │   ├── billing-svc/      #     Billing & payments
│   │   ├── academy-svc/      #     LMS functionality
│   │   ├── exam-svc/         #     Exam management
│   │   ├── content-svc/      #     Course content
│   │   ├── file-svc/         #     File storage
│   │   ├── grading-svc/      #     Grading engine
│   │   ├── admin-svc/        #     Admin operations
│   │   ├── attendance-svc/   #     Attendance tracking
│   │   ├── spreadsheet-svc/  #     Real-time collaborative spreadsheets
│   │   └── lumie-frontend/   #     Web frontend
│   ├── umami/                #   Web analytics
│   ├── code-server/          #   Web IDE
│   ├── headlamp/             #   Kubernetes dashboard
│   ├── docusaurus/           #   Documentation site
│   ├── mas/                  #   Multi-Account System
│   ├── joossam/              #   LMS component
│   └── lumie-dev/            #   Development environment
│
├── web-apps/                 # Dynamic web apps (ApplicationSet)
│
├── charts/
│   └── common/               # Shared Helm chart (15 templates)
│                              #   Deployment, Service, Ingress, CNPG,
│                              #   Vault secrets, ServiceMonitor, RBAC, etc.
│
├── upstream-versions.json    # Image versions (Renovate-managed)
└── renovate.json             # Automated dependency updates
```

## App-of-Apps Hierarchy

ArgoCD manages 44+ applications across 7 categories:

```
bootstrap (sync-wave: -1)
├── minio → zot → vault → kong
│
platform
├── priority-classes, coredns-config, cert-manager, rabbitmq-operator, rabbitmq
│
security
├── authelia, keycloak, falco, kyverno, trivy, teleport
│
storage
├── cnpg, infra-db, pgbouncer, pgweb, redis, velero
│
observability
├── prometheus, thanos, alertmanager, grafana, loki, tempo
├── otel-operator, otel-collector, node-exporter, kube-state-metrics
├── blackbox-exporter, goldilocks, vpa
│
applications
├── argocd, tekton, umami, code-server, headlamp, docusaurus, mas, joossam
├── lumie (12 microservices), lumie-dev
│
web-apps
└── ApplicationSet-based dynamic deployment
```

## Key Design Decisions

**Shared Helm Chart** - All applications use `charts/common/` for consistent deployment patterns (Deployment, Service, Ingress, CNPG, Vault secrets, ServiceMonitor).

**Air-Gapped Registry** - Zot syncs images on-demand from upstream registries. Kyverno policy enforces all pods use `zot.lumie-infra.com`. Renovate automates version tracking in `upstream-versions.json`.

**Multi-Tenant Database** - CNPG clusters with PgBouncer for connection pooling. `infra-db` serves shared infrastructure; per-app clusters for isolation.

**Secrets via Vault** - All credentials stored in Vault. Vault Secrets Operator syncs to Kubernetes Secrets. No secrets in Git.

**CI/CD Pipeline** - Tekton builds images with Kaniko → pushes to Zot → updates Helm values in Git → ArgoCD auto-syncs.

## Provisioning

```bash
# 1. Terraform: Create OCI infrastructure
cd provision/terraform && terraform apply

# 2. Ansible: Install K3s + bootstrap ArgoCD
cd provision/ansible && ansible-playbook site.yml

# 3. ArgoCD takes over: All remaining apps deployed via GitOps
```
