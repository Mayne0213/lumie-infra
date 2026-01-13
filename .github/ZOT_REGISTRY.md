# Zot Registry Image Management Guide

This document describes how to manage container images in the K3S-HOME cluster. All container images should be mirrored to the internal Zot registry.

## Registry Information

| Type | URL | Usage |
|------|-----|-------|
| External | `zot0213.kro.kr` | Push images from local Docker |
| Internal | `zot.zot.svc.cluster.local:5000` | Pull images from within cluster |

## Folder Structure

Images are organized by category:

```
zot.zot.svc.cluster.local:5000/
├── applications/    # User-facing apps (homer, headlamp, code-server)
├── observability/   # Monitoring stack (thanos, karma, otel)
├── platform/        # Infrastructure (haproxy, nginx, argocd)
├── security/        # Security tools (falco, authelia)
├── storage/         # Data services (minio, postgresql, cnpg)
└── web-apps/        # Custom web applications
```

## When Installing New Helm Charts

### Step 1: Identify Required Images

Check the Helm chart's `values.yaml` for image references:
```bash
helm show values <repo>/<chart> | grep -A5 "image:"
```

### Step 2: Pull and Push to Zot

```bash
# Pull from source registry
docker pull <source-registry>/<image>:<tag>

# Tag for Zot registry
docker tag <source-registry>/<image>:<tag> zot0213.kro.kr/<category>/<image-name>:<tag>

# Push to Zot
docker push zot0213.kro.kr/<category>/<image-name>:<tag>
```

### Step 3: Update image-sources/images.yaml

Add entry to `/Users/bluemayne/Projects/K3S-HOME/image-sources/images.yaml`:

```yaml
- name: <image-name>
  source: <source-registry>/<image>
  tag: "<tag>"
  dest: <category>/<image-name>
```

This enables Renovate to track version updates.

### Step 4: Configure Helm Values

In the application's `helm-values.yaml`, set image to use internal registry:

```yaml
image:
  repository: zot.zot.svc.cluster.local:5000/<category>/<image-name>
  tag: "<tag>"
```

Or if the chart uses separate registry/repository fields:

```yaml
image:
  registry: zot.zot.svc.cluster.local:5000
  repository: <category>/<image-name>
  tag: "<tag>"
```

### Step 5: Add ImagePullSecret (if needed)

Most namespaces have `zot-registry-credentials` available via ClusterExternalSecret.

```yaml
imagePullSecrets:
  - name: zot-registry-credentials
```

## Exceptions

| Image | Reason |
|-------|--------|
| `ghcr.io/project-zot/zot-*` | Circular dependency - Zot cannot pull its own image |

## Example: Adding a New Application

```bash
# 1. Pull image
docker pull docker.io/example/myapp:v1.0.0

# 2. Tag for Zot
docker tag docker.io/example/myapp:v1.0.0 zot0213.kro.kr/applications/myapp:v1.0.0

# 3. Push to Zot
docker push zot0213.kro.kr/applications/myapp:v1.0.0

# 4. Add to image-sources/images.yaml
# - name: myapp
#   source: docker.io/example/myapp
#   tag: "v1.0.0"
#   dest: applications/myapp

# 5. Configure helm-values.yaml
# image:
#   repository: zot.zot.svc.cluster.local:5000/applications/myapp
#   tag: "v1.0.0"
```

## Category Guidelines

| Category | Use For |
|----------|---------|
| `applications/` | User-facing applications, dashboards, tools |
| `observability/` | Prometheus, Grafana, Loki, Thanos, etc. |
| `platform/` | ArgoCD, Traefik, HAProxy, cert-manager, etc. |
| `security/` | Authelia, Vault, Falco, Trivy, etc. |
| `storage/` | MinIO, PostgreSQL, CNPG, Velero, Zot, etc. |
| `web-apps/` | Custom-built web applications |

## Commit Convention

When adding new images:

```
FEAT(<category>): add <image-name> image for Zot mirroring

- Add <source-registry>/<image>:<tag> to image sources
- Enable Renovate tracking for version updates
```

When updating Helm values to use Zot:

```
CHORE(<app>): use Zot registry for <image-name> image

- Change image from <source> to zot.zot.svc.cluster.local
- Image mirrored to <category>/<image-name>:<tag>
```
