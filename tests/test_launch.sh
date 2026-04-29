#!/bin/bash
# tests/test_launch.sh — Verifica comando wdroid launch

suite "Comando launch (bin/wdroid)"

# Verifica que launch tiktok-lite delega para plugin tiktok open
_launch_block=$(grep -A 15 'launch)' "$BASE_DIR/bin/wdroid" | head -20)
assert_contains "launch tiktok-lite presente no bin/wdroid" \
    "tiktok-lite" "$_launch_block"
assert_contains "launch tiktok-lite chama plugin tiktok open" \
    "plugin_cmd run tiktok open" "$_launch_block"

# Verifica que launch whatsapp delega para plugin whatsapp open
assert_contains "launch whatsapp presente no bin/wdroid" \
    "whatsapp" "$_launch_block"
assert_contains "launch whatsapp chama plugin whatsapp open" \
    "plugin_cmd run whatsapp open" "$_launch_block"

# Verifica que launch sem argumento usa APP_PACKAGE (fallback)
assert_contains "launch fallback usa APP_PACKAGE" \
    'launch_app "${1:-$APP_PACKAGE}"' \
    "$(cat "$BASE_DIR/bin/wdroid")"

suite "Help do bin/wdroid"

# Verifica que o help menciona tiktok-lite
_help_block=$(grep -A 5 'launch tiktok' "$BASE_DIR/bin/wdroid" || true)
assert_contains "help menciona launch tiktok-lite" \
    "tiktok-lite" \
    "$(cat "$BASE_DIR/bin/wdroid")"

# Verifica que o help menciona TikTok Lite na descrição
assert_contains "help descreve TikTok Lite" \
    "TikTok Lite" \
    "$(cat "$BASE_DIR/bin/wdroid")"
