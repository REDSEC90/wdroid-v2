#!/bin/bash
# tests/test_launch.sh — Verifica comando wdroid launch

suite "Comando launch (bin/wdroid)"

_launch_content=$(cat "$BASE_DIR/commands/launch.sh")
_bin_content=$(cat "$BASE_DIR/bin/wdroid")

# Verifica que launch tiktok-lite delega para plugin tiktok open
assert_contains "launch tiktok-lite presente no comando" \
    "tiktok-lite" "$_launch_content"
assert_contains "launch tiktok-lite chama plugin tiktok open" \
    "plugin_cmd run tiktok open" "$_launch_content"

# Verifica que launch whatsapp delega para plugin whatsapp open
assert_contains "launch whatsapp presente no comando" \
    "whatsapp" "$_launch_content"
assert_contains "launch whatsapp chama plugin whatsapp open" \
    "plugin_cmd run whatsapp open" "$_launch_content"

# Verifica que launch sem argumento usa APP_PACKAGE (fallback)
assert_contains "launch fallback usa APP_PACKAGE" \
    'launch_app "${1:-$APP_PACKAGE}"' \
    "$_launch_content"

assert_contains "bin roteia launch para commands/launch.sh" \
    '_run_command launch "$@"' \
    "$_bin_content"

suite "Help do bin/wdroid"

# Verifica que o help menciona tiktok-lite
assert_contains "help menciona launch tiktok-lite" \
    "tiktok-lite" \
    "$(cat "$BASE_DIR/commands/help.sh")"

# Verifica que o help menciona TikTok Lite na descrição
assert_contains "help descreve TikTok Lite" \
    "TikTok Lite" \
    "$(cat "$BASE_DIR/commands/help.sh")"
