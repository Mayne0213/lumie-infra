# Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/).

## 7 Rules

1. Separate subject from body with a blank line
2. Limit the subject line to 50 characters
3. Use uppercase for Type (FEAT, FIX, CHORE, etc.)
4. Do not end the subject line with a period
5. Use imperative mood, not past tense (Added → Add)
6. Wrap the body at 72 characters
7. Use the body to explain what and why, not how

## Format

```
<TYPE>(<scope>): <description>

<body>
```

## Types

| Type | Description |
|------|-------------|
| `INIT` | Initial setup |
| `FEAT` | New feature |
| `FIX` | Bug fix |
| `CHORE` | Maintenance (deps, configs) |
| `REFACTOR` | Code refactoring |
| `PERF` | Performance improvement |
| `REVERT` | Revert previous changes |
| `DOCS` | Documentation |

## Scopes

Use component names as scope:

- **applications:** code-server, crafty, docusaurus, gitea, headlamp, homer, immich, umami
- **observability:** alertmanager, goldilocks, grafana, kube-state-metrics, loki, node-exporter, prometheus, promtail, uptime-kuma, vpa
- **platform:** argocd, cert-manager, traefik
- **security:** authelia, external-secrets, falco, trivy, vault
- **storage:** cnpg, longhorn, minio, pgweb, postgresql, velero

For dependency updates: `deps`
For repo-wide changes: `repo` or omit scope

## Examples

```
INIT(repo): initial setup

FEAT(authelia): add OIDC provider configuration

FIX(traefik): resolve ingress routing issue

CHORE(deps): update Helm release grafana to v10.4.3

REFACTOR(storage): migrate from Longhorn to local-path

PERF(prometheus): reduce memory usage

REVERT(traefik): revert node affinity changes
```

## Commit Message Template

```
FEAT(component): short description

Why:
- Reason for this change

What:
- What was changed
- Another change

Refs: #123
```
