#!/usr/bin/env bash

set -Eeuo pipefail

readonly MODEL_CACHE_ROOT="/runpod-volume/huggingface-cache/hub/models--OpenMOSS-Team--MOSS-Image-SFT/snapshots"
readonly MODEL_LINK="/models/MOSS-Image-SFT"
readonly REQUIRED_COMPONENTS=(transformer text_encoder tokenizer vae)

die() {
    echo "moss-image startup: ERROR: $*" >&2
    exit 1
}

if [[ ! -d "$MODEL_CACHE_ROOT" ]]; then
    die "RunPod Serverless cached model was not found at $MODEL_CACHE_ROOT. Configure the endpoint with the Hugging Face cached model OpenMOSS-Team/MOSS-Image-SFT; do not use a user-managed Network Volume."
fi

shopt -s nullglob
snapshots=("$MODEL_CACHE_ROOT"/*)
selected_snapshot=""

for snapshot in "${snapshots[@]}"; do
    [[ -d "$snapshot" ]] || continue

    missing_components=()
    for component in "${REQUIRED_COMPONENTS[@]}"; do
        [[ -d "$snapshot/$component" ]] || missing_components+=("$component")
    done

    if ((${#missing_components[@]} > 0)); then
        echo "moss-image startup: skipping incomplete snapshot $snapshot (missing: ${missing_components[*]})" >&2
        continue
    fi

    if [[ -z "$selected_snapshot" || "$snapshot" -nt "$selected_snapshot" ]]; then
        selected_snapshot="$snapshot"
    fi
done

if [[ -z "$selected_snapshot" ]]; then
    die "No complete MOSS-Image-SFT snapshot was found under $MODEL_CACHE_ROOT. Each snapshot must contain transformer, text_encoder, tokenizer, and vae directories."
fi

if [[ -e "$MODEL_LINK" && ! -L "$MODEL_LINK" ]]; then
    die "$MODEL_LINK already exists and is not a symlink; refusing to replace it."
fi

mkdir -p "$(dirname "$MODEL_LINK")"
ln -sfn "$selected_snapshot" "$MODEL_LINK"

for component in "${REQUIRED_COMPONENTS[@]}"; do
    [[ -d "$MODEL_LINK/$component" ]] || die "Created model link is missing required component: $component"
done

export MOSS_IMAGE_MODEL_PATH="$MODEL_LINK"
echo "moss-image startup: using cached snapshot $selected_snapshot"
echo "moss-image startup: model available at $MODEL_LINK"

exec /start.sh "$@"
