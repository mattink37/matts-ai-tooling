#!/usr/bin/env bash
# install-rules.sh — Merge shared Claude rules from this repo into ~/.claude/CLAUDE.md
#
# Cross-platform: works on macOS, Linux, and Windows (Git Bash / WSL).
# Safe to re-run: updates existing rule sections in place rather than duplicating.
# Run this from the repo root, or pass --repo <path> to point at the repo.
#
# Usage:
#   ./install-rules.sh              # Use the repo this script lives in
#   ./install-rules.sh --repo /path/to/matts-ai-tooling
#   ./install-rules.sh --dry-run    # Show what would change without writing
#   ./install-rules.sh --help

set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

progname="$(basename "$0")"
dry_run=false
repo_dir=""

usage() {
    cat <<EOF
Usage: $progname [OPTIONS]

Merge shared Claude rules from the repo into your global ~/.claude/CLAUDE.md.

Options:
  --repo PATH     Path to the matts-ai-tooling repo (default: script location)
  --dry-run       Print the resulting CLAUDE.md instead of writing it
  -h, --help      Show this help message

The script wraps each rule in delimited markers so re-runs update in place.
Rules you've deleted from the repo are removed from CLAUDE.md on the next run.
EOF
    exit 0
}

die() {
    echo "$progname: $*" >&2
    exit 1
}

warn() {
    echo "$progname: $*" >&2
}

info() {
    echo "  → $*"
}

# ── Parse arguments ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            repo_dir="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            die "Unknown option: $1 (use --help)"
            ;;
    esac
done

# ── Locate repo and rules ────────────────────────────────────────────────────

if [[ -z "$repo_dir" ]]; then
    repo_dir="$(cd "$(dirname "$0")" && pwd)"
fi

rules_dir="$repo_dir/rules"

if [[ ! -d "$rules_dir" ]]; then
    die "Rules directory not found: $rules_dir"
fi

# Gather rule files (skip README.md and hidden files)
# Rule filenames are simple kebab-case — newline-delimited sort is safe here.
rule_files=()
while IFS= read -r f; do
    [[ -n "$f" ]] && rule_files+=("$f")
done < <(find "$rules_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' ! -name '.*' | sort)

if [[ ${#rule_files[@]} -eq 0 ]]; then
    warn "No .md rule files found in $rules_dir (excluding README.md). Nothing to install."
    exit 0
fi

# ── Marker format ────────────────────────────────────────────────────────────

MARKER_PREFIX="<!-- BEGIN_SHARED_RULES:matts-ai-tooling:"
# MARKER_END_PREFIX is composed in the loop

# ── Build arrays of rule names and paths (bash 3.2 compatible) ──────────────

rule_names=()
rule_paths=()
for f in "${rule_files[@]}"; do
    name="$(basename "$f" .md)"
    rule_names+=("$name")
    rule_paths+=("$f")
done

# ── Process the current CLAUDE.md into a temp file ───────────────────────────

target="$HOME/.claude/CLAUDE.md"
tmpfile="${target}.tmp.$$"

# Clean up temp file on exit
cleanup() { rm -f "$tmpfile" "${tmpfile}.stripped" "${tmpfile}.final" 2>/dev/null; }
trap cleanup EXIT

inside_block=false
current_block_name=""

{
    if [[ -f "$target" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == "$MARKER_PREFIX"*" -->" ]]; then
                inside_block=true
                current_block_name="${line#"$MARKER_PREFIX"}"
                current_block_name="${current_block_name% -->}"
                continue
            fi

            if $inside_block; then
                if [[ "$line" == "<!-- END_SHARED_RULES:matts-ai-tooling:"*" -->" ]]; then
                    inside_block=false
                    current_block_name=""
                fi
                continue
            fi

            # Not inside a block — pass through
            echo "$line"
        done < "$target"
    fi
} > "$tmpfile"

# ── Append fresh rule blocks ─────────────────────────────────────────────────

# Ensure we start on a fresh line if the file has content
if [[ -s "$tmpfile" ]]; then
    # Remove trailing blank lines from tmpfile
    # Cross-platform: use awk to strip trailing empty lines
    awk 'BEGIN { last=0 } { lines[NR]=$0; if ($0 != "") last=NR } END { for (i=1; i<=last; i++) print lines[i] }' "$tmpfile" > "${tmpfile}.stripped"
    mv "${tmpfile}.stripped" "$tmpfile"

    # If the file doesn't end with a blank line before our block, add one
    if [[ -s "$tmpfile" ]]; then
        last_char=$(tail -c 1 "$tmpfile" 2>/dev/null || true)
        if [[ "$last_char" != "" && "$last_char" != $'\n' ]]; then
            echo "" >> "$tmpfile"
        fi
        echo "" >> "$tmpfile"
    fi
fi

first_block=true
for (( i=0; i < ${#rule_names[@]}; i++ )); do
    name="${rule_names[$i]}"
    path="${rule_paths[$i]}"

    if ! $first_block; then
        echo "" >> "$tmpfile"
    fi
    first_block=false

    echo "${MARKER_PREFIX}${name} -->" >> "$tmpfile"
    # Read rule content — normalize trailing newlines
    # Use cat and trim any trailing blank lines from the rule file
    awk 'BEGIN { last=0 } { lines[NR]=$0; if ($0 != "") last=NR } END { for (i=1; i<=last; i++) print lines[i] }' "$path" >> "$tmpfile"
    echo "<!-- END_SHARED_RULES:matts-ai-tooling:${name} -->" >> "$tmpfile"

    info "Merged rule: $name"
done

# Ensure the file ends with exactly one newline (cross-platform)
awk 'BEGIN { last=0 } { lines[NR]=$0; if ($0 != "") last=NR } END { for (i=1; i<=last; i++) print lines[i] }' "$tmpfile" > "${tmpfile}.final"
mv "${tmpfile}.final" "$tmpfile"

# ── Write ────────────────────────────────────────────────────────────────────

if $dry_run; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  DRY RUN — ~/.claude/CLAUDE.md would look like this:"
    echo "═══════════════════════════════════════════════════════════"
    cat "$tmpfile"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
else
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Back up existing file if it exists
    if [[ -f "$target" ]]; then
        backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$target" "$backup"
        info "Backed up existing CLAUDE.md to $(basename "$backup")"
    fi

    mv "$tmpfile" "$target"
    info "Wrote $target with ${#rule_names[@]} shared rule(s)"
fi
