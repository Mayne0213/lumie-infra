#!/bin/bash
# Zot Registry Image Mirroring Script
# This script mirrors external images to the internal Zot registry
# using skopeo with custom path structure: {repo-folder}/{image-name}
#
# Prerequisites:
#   - skopeo installed
#   - Access to source registries (Docker Hub, Quay.io, GHCR)
#   - Credentials for Zot registry
#
# Usage:
#   ./mirror-images.sh [--dry-run]

set -uo pipefail

# Configuration
ZOT_REGISTRY="${ZOT_REGISTRY:-zot0213.kro.kr}"
ZOT_USERNAME="${ZOT_USERNAME:-admin}"
ZOT_PASSWORD="${ZOT_PASSWORD:-}"
DRY_RUN="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Image list: SOURCE_IMAGE DEST_PATH TAG
# Format: "source_registry/source_repo dest_folder/dest_name tag"
IMAGES=(
    # Storage
    "quay.io/minio/minio storage/minio RELEASE.2025-09-07T16-13-09Z"
    "ghcr.io/cloudnative-pg/cloudnative-pg storage/cnpg 1.25.1"
    "docker.io/sosedoff/pgweb storage/pgweb 0.17.0"
    "docker.io/velero/velero storage/velero v1.17.1"
    "docker.io/velero/velero-plugin-for-aws storage/velero-plugin-aws v1.13.1"
    "docker.io/otwld/velero-ui storage/velero-ui 0.10.1"
    "ghcr.io/georgmangold/console storage/minio-console v1.9.1"

    # Applications
    "docker.io/b4bz/homer applications/homer v25.11.1"
    "docker.io/alpine/git applications/alpine-git v2.47.1"
    "docker.io/codercom/code-server applications/code-server 4.104.2"
    "ghcr.io/headlamp-k8s/headlamp applications/headlamp v0.27.0"

    # Observability
    "quay.io/thanos/thanos observability/thanos v0.37.2"
    "docker.io/otel/opentelemetry-collector-contrib observability/opentelemetry-collector-contrib 0.119.0"
    "ghcr.io/prymitive/karma observability/karma v0.122"

    # Platform
    "docker.io/library/haproxy platform/haproxy 3.0-alpine"
    "quay.io/buildah/stable platform/buildah v1.33"
    "docker.io/alpine/git platform/alpine-git v2.47.1"

    # Security
    "docker.io/falcosecurity/falco security/falco 0.40.0"
)

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    if ! command -v skopeo &> /dev/null; then
        log_error "skopeo is not installed. Please install it first."
        echo "  macOS: brew install skopeo"
        echo "  Ubuntu: sudo apt-get install skopeo"
        exit 1
    fi
    log_info "skopeo found: $(skopeo --version)"

    if [[ -z "${ZOT_PASSWORD}" ]]; then
        log_error "ZOT_PASSWORD environment variable is required."
        echo "  export ZOT_PASSWORD='your-password'"
        exit 1
    fi
}

mirror_image() {
    local source="$1"
    local dest_path="$2"
    local tag="$3"

    local dest="${ZOT_REGISTRY}/${dest_path}:${tag}"

    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        log_info "[DRY-RUN] Would copy: ${source}:${tag} -> ${dest}"
        return 0
    fi

    log_info "Mirroring: ${source}:${tag} -> ${dest}"

    if skopeo copy --all \
        --dest-creds "${ZOT_USERNAME}:${ZOT_PASSWORD}" \
        "docker://${source}:${tag}" \
        "docker://${dest}" 2>&1; then
        log_info "Successfully mirrored: ${dest_path}:${tag}"
    else
        log_error "Failed to mirror: ${source}:${tag}"
        return 1
    fi
}

main() {
    log_info "Zot Registry Image Mirroring Script"
    log_info "Target registry: ${ZOT_REGISTRY}"
    echo ""

    check_prerequisites

    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        log_warn "Running in dry-run mode. No images will be copied."
        echo ""
    fi

    local success_count=0
    local fail_count=0
    local total=${#IMAGES[@]}

    for image_spec in "${IMAGES[@]}"; do
        read -r source dest_path tag <<< "$image_spec"

        if mirror_image "$source" "$dest_path" "$tag"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done

    echo "========================================"
    log_info "Mirroring complete!"
    log_info "Total: ${total}, Success: ${success_count}, Failed: ${fail_count}"

    if [[ $fail_count -gt 0 ]]; then
        log_warn "Some images failed to mirror. Check the logs above."
        exit 1
    fi
}

main "$@"
