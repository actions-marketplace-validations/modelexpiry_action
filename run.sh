#!/usr/bin/env bash
# The ModelExpiry GitHub Action (action.yml, PRD FR-4): `modelexpiry ci` with the
# Action's inputs. `ci` writes the annotations and the job summary itself.
set -euo pipefail

directory="${MODELEXPIRY_INPUT_DIRECTORY:-.}"
args=(ci "$directory" --fail-on "${MODELEXPIRY_INPUT_FAIL_ON:-retiring}")

if [[ -n "${MODELEXPIRY_INPUT_WARN_DAYS:-}" ]]; then
  args+=(--warn-days "$MODELEXPIRY_INPUT_WARN_DAYS")
fi
if [[ -n "${MODELEXPIRY_INPUT_CONFIG:-}" ]]; then
  args+=(--config "$MODELEXPIRY_INPUT_CONFIG")
fi
if [[ -n "${MODELEXPIRY_INPUT_SARIF_FILE:-}" ]]; then
  args+=(--sarif "$MODELEXPIRY_INPUT_SARIF_FILE")
fi
if [[ -n "${MODELEXPIRY_INPUT_REGISTRY:-}" ]]; then
  args+=(--registry "$MODELEXPIRY_INPUT_REGISTRY")
fi

base="${MODELEXPIRY_INPUT_BASE:-}"
if [[ "${MODELEXPIRY_INPUT_DIFF_ONLY:-true}" == "true" && -n "$base" ]]; then
  # actions/checkout fetches one commit by default: bring the base too, to diff against it.
  if ! git -C "$directory" cat-file -e "${base}^{commit}" 2>/dev/null; then
    git -C "$directory" fetch --no-tags --quiet --depth=1 origin "$base"
  fi
  args+=(--diff-base "$base")
fi

if [[ -n "${MODELEXPIRY_CLI:-}" ]]; then
  # A local build of the CLI, for this Action's own tests.
  exec node "$MODELEXPIRY_CLI" "${args[@]}"
fi
exec npx --yes "modelexpiry@${MODELEXPIRY_INPUT_VERSION:?the version input is required}" "${args[@]}"
