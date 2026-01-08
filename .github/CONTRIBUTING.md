# Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/).

## Format

```
<TYPE>(<scope>): <description>

- <bullet point 1>
- <bullet point 2>
```

**IMPORTANT:** Body with bullet points is **REQUIRED**, not optional.

## Rules

### Subject Line (First Line)

1. **50 characters or less** - If longer, shorten the description
2. **Uppercase TYPE** - Use `FEAT`, not `feat`
3. **No period at the end** - `Add feature` not `Add feature.`
4. **Imperative mood** - `Add`, `Fix`, `Update` (not `Added`, `Fixed`, `Updated`)
5. **Descriptive scope** - Use component name in parentheses

### Body (Required)

6. **Blank line** between subject and body
7. **Bullet points required** - Start each line with `-`
8. **Explain what changed** - Be specific about the changes
9. **72 characters per line** - Wrap long lines
10. **No Claude Code references** - Never mention AI-generated content

## Types

| Type | Description | When to Use |
|------|-------------|-------------|
| `INIT` | Initial setup | First commit, project initialization |
| `FEAT` | New feature | Adding new functionality |
| `FIX` | Bug fix | Fixing broken functionality |
| `CHORE` | Maintenance | Dependency updates, config changes, CI updates |
| `REFACTOR` | Code refactoring | Restructuring without changing behavior |
| `PERF` | Performance | Optimization, resource reduction |
| `REVERT` | Revert changes | Undoing previous commits |
| `DOCS` | Documentation | README, comments, docs |

## Scopes

Use component names as scope:

| Repository | Components |
|------------|------------|
| **applications** | code-server, crafty, docusaurus, headlamp, homer, immich, mas, umami |
| **observability** | alertmanager, goldilocks, grafana, karma, loki, prometheus, promtail, thanos |
| **platform** | argocd, cert-manager, coredns, descheduler, traefik |
| **security** | authelia, external-secrets, falco, trivy, vault |
| **storage** | cnpg, minio, pgweb, postgresql, velero, zot |
| **web-apps** | jaejadle, joossam, jotion, jovies, mas, portfolio, todo |

Special scopes:
- `deps` - Dependency updates
- `repo` - Repository-wide changes
- `app` - Application deployment/image updates (for web-apps)
- `ci` - CI/CD workflow changes
- `docker` - Dockerfile changes
- `db` - Database changes
- `auth` - Authentication changes
- `deploy` - Deployment configuration

## Examples

### Good Examples

```
FEAT(authelia): add OIDC provider configuration

- Enable OIDC identity provider
- Add Vault as OIDC client
- Configure client secrets from ExternalSecret
```

```
FIX(traefik): resolve ingress routing issue

- Update ingressClassName to traefik
- Fix service backend reference
- Add TLS configuration
```

```
CHORE(deps): update Helm release grafana to v10.4.3

- Upgrade Grafana chart version
- Apply security patches
```

```
REFACTOR(storage): migrate from Longhorn to local-path

- Change storageClassName to local-path-retain
- Update PVC configurations
- Remove Longhorn-specific annotations
```

```
PERF(prometheus): reduce CPU request from 200m to 100m

- Reduce based on actual usage (avg: 80m)
- Update ResourceQuota accordingly
```

```
REVERT(traefik): revert node affinity changes

- Revert due to CRD upgrade issues
- Restore original scheduling configuration
```

### Bad Examples (Don't Do This)

```
❌ FEAT(authelia): add OIDC provider configuration
   (Missing body - no bullet points)

❌ feat(authelia): add oidc provider configuration
   (Lowercase TYPE)

❌ FEAT(authelia): Add OIDC provider configuration.
   (Period at the end)

❌ FEAT(authelia): Added OIDC provider configuration
   (Past tense instead of imperative)

❌ FEAT(authelia): add OIDC provider configuration for Vault and Headlamp with client secrets
   (Subject too long - over 50 characters)

❌ FEAT(authelia): add OIDC

- Add OIDC configuration

🤖 Generated with Claude Code
   (Contains AI reference - NEVER do this)
```

## Automated Image Updates

For CI-generated image update commits, use this format:

```
CHORE(app): update prod image to <tag>

- Update container image reference
- Trigger deployment
```

These commits may skip the body requirement as they are auto-generated.

## Commit Message Template

Copy this template for new commits:

```
TYPE(scope): short description (max 50 chars)

- What was changed
- Why it was changed (if not obvious)
- Any important details
```

## Quick Reference

| Element | Rule | Example |
|---------|------|---------|
| TYPE | Uppercase | `FEAT`, `FIX`, `CHORE` |
| scope | lowercase | `authelia`, `grafana` |
| description | Imperative, no period | `add feature`, `fix bug` |
| body | Required, bullet points | `- Add X`<br>`- Update Y` |
| length | Subject ≤50, body ≤72/line | Keep it concise |

## Common Mistakes to Avoid

1. **Missing body** - Every commit needs `-` bullet points
2. **Subject too long** - Shorten to 50 chars, put details in body
3. **Truncated subject** - Don't let subject get cut off with `...`
4. **Past tense** - Use `Add` not `Added`
5. **Vague descriptions** - Be specific: `fix auth bug` → `fix OIDC token validation`
6. **Missing scope** - Always include component name in parentheses
