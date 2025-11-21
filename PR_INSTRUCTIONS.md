# left_4_ai — Integration into L4D2_Rage (dev)

This PR renames **new_left_4_chat_2** → **left_4_ai** and integrates it into the Rage repo layout without changing HUD assets.

## What’s included
- `addons/sourcemod/plugins/left_4_ai.smx`
- `addons/sourcemod/scripting/left_4_ai.sp`
- `addons/sourcemod/scripting/include/left_4_ai.inc`
- `addons/sourcemod/translations/left_4_ai.phrases.txt` (English only; Chinese removed)
- `addons/sourcemod/configs/left_4_ai_system_prompt.txt`
- `addons/sourcemod/configs/left_4_ai_message_prompt.txt`

## Not included
- HUD/VPK files remain untouched as requested.

## Setup (server)
1. Upload `addons/` to your server.
2. Restart server or run `sm plugins load left_4_ai`.

### First run
The plugin will generate `cfg/sourcemod/left_4_ai.cfg` with cvars like:
```
l4ai_api_key            ""     // REQUIRED
l4ai_api_type           "openai" // openai|gemini
l4ai_api_host           ""     // optional override
l4ai_api_endpoint       ""     // optional override
l4ai_model              "gpt-4o-mini"
l4ai_max_tokens         256
l4ai_cooldown           5.0
```
> Names were migrated from `l4c2_*` to `l4ai_*` in source.

### Prompts
- Edit `addons/sourcemod/configs/left_4_ai_system_prompt.txt`
- Edit `addons/sourcemod/configs/left_4_ai_message_prompt.txt`

## Usage
- Players type `/ai <message>` or use the existing chat triggers from the plugin.
- AI replies appear in the standard in-game chat overlay.

## Notes
- All Chinese strings removed; English phrases kept in `left_4_ai.phrases.txt`.
- If you compile from source, ensure `scripting/include/left_4_ai.inc` is present.
- If other plugins used `nl4c2.inc`, update them to `left_4_ai.inc` and prefix `L4AI_` / `l4ai_`.
