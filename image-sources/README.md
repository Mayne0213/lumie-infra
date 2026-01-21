# Image Sources

Container image sources for Zot registry mirroring.

Renovate tracks these images and creates PRs when new versions are available.

## Images

### Storage

| Image | Source | Tag |
|-------|--------|-----|
| minio | quay.io/minio/minio | RELEASE.2025-09-07T16-13-09Z |
| cnpg | ghcr.io/cloudnative-pg/cloudnative-pg | 1.25.1 |
| pgweb | docker.io/sosedoff/pgweb | 0.17.0 |
| velero | docker.io/velero/velero | v1.17.1 |
| velero-plugin-aws | docker.io/velero/velero-plugin-for-aws | v1.13.1 |
| velero-ui | docker.io/otwld/velero-ui | 0.10.1 |
| minio-console | ghcr.io/georgmangold/console | v1.9.1 |

### Applications

| Image | Source | Tag |
|-------|--------|-----|
| homer | docker.io/b4bz/homer | v25.11.1 |
| alpine-git | docker.io/alpine/git | v2.47.1 |
| code-server | docker.io/codercom/code-server | 4.104.2 |
| headlamp | ghcr.io/headlamp-k8s/headlamp | v0.39.0 |
| umami | ghcr.io/umami-software/umami | postgresql-latest |
| kubectl | docker.io/bitnami/kubectl | latest |
| kaniko | gcr.io/kaniko-project/executor | debug |

### Observability

| Image | Source | Tag |
|-------|--------|-----|
| thanos | quay.io/thanos/thanos | v0.37.2 |
| opentelemetry-collector-contrib | docker.io/otel/opentelemetry-collector-contrib | 0.119.0 |
| karma | ghcr.io/prymitive/karma | v0.122 |
| grafana | docker.io/grafana/grafana | 12.3.1 |
| loki | docker.io/grafana/loki | 3.3.2 |
| k8s-sidecar | docker.io/kiwigrid/k8s-sidecar | 1.28.0 |
| tempo | docker.io/grafana/tempo | 2.6.1 |
| alertmanager | quay.io/prometheus/alertmanager | v0.30.0 |
| node-exporter | quay.io/prometheus/node-exporter | v1.8.2 |
| blackbox-exporter | quay.io/prometheus/blackbox-exporter | v0.25.0 |
| kube-state-metrics | registry.k8s.io/kube-state-metrics/kube-state-metrics | v2.13.0 |
| vpa-recommender | registry.k8s.io/autoscaling/vpa-recommender | 1.0.0 |
| goldilocks | us-docker.pkg.dev/fairwinds-ops/oss/goldilocks | v4.10.0 |

### Platform

| Image | Source | Tag |
|-------|--------|-----|
| haproxy | docker.io/library/haproxy | 3.0-alpine |
| buildah | quay.io/buildah/stable | v1.33 |
| nginx | docker.io/library/nginx | alpine |
| gitea | docker.gitea.com/gitea | 1.24.6-rootless |

### Security

| Image | Source | Tag |
|-------|--------|-----|
| falco | docker.io/falcosecurity/falco | 0.40.0 |
| authelia | ghcr.io/authelia/authelia | 4.39.13 |
| redis | docker.io/bitnami/redis | latest |
| external-secrets | ghcr.io/external-secrets/external-secrets | v1.2.1 |

## Usage

When Renovate creates a PR for a new version:

1. Review the PR
2. Mirror the image to Zot:
   ```bash
   skopeo copy --dest-creds "admin:PASSWORD" \
     docker://SOURCE:TAG \
     docker://zot0213.kro.kr/DEST:TAG
   ```
3. Update the actual K8s manifests in the corresponding repo
4. Merge the PR
