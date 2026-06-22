#!/bin/bash
# tests/test_docs.sh — Verifica documentação textual

suite "Documentação"

_markdown_files=(
    "$BASE_DIR/README.md"
    "$BASE_DIR/CHANGELOG.md"
    "$BASE_DIR/CONTRIBUTING.md"
    "$BASE_DIR/docs/architecture.md"
    "$BASE_DIR/docs/overview.md"
    "$BASE_DIR/docs/security.md"
    "$BASE_DIR/docs/troubleshooting.md"
    "$BASE_DIR/docs/usage.md"
)

for _doc in "${_markdown_files[@]}"; do
    _name="${_doc#$BASE_DIR/}"
    _fences=$(grep -c '^```' "$_doc" 2>/dev/null || true)
    if (( _fences % 2 == 0 )); then
        pass "fences markdown balanceadas: $_name"
    else
        fail "fences markdown desbalanceadas: $_name" "$_fences delimitadores"
    fi

    if [ -s "$_doc" ]; then
        pass "documento não vazio: $_name"
    else
        fail "documento vazio: $_name"
    fi
done
