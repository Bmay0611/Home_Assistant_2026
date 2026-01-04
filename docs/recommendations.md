# packages/30_recommendations.yaml
# Purpose: small collection of helpers and commented integration templates
# for voice / media / keypad / Zigbee / Z-Wave that match the plan you asked for.
# Replace secrets and follow the Integrations UI where indicated. Do not paste long-lived secrets into this file.

select:
  voice_pe_assistant:
    name: Voice assistant backend
    options:
      - Home Assistant
      - Home Assistant Cloud
      - Rhasspy
      - Mycroft
      - Local LLM
    initial: Home Assistant Cloud

input_select:
  music_provider:
    name: Music provider
    options:
      - Default
      - Spotify
      - Apple Music
      - Sonos
    initial: Default

  music_zone:
    name: Music zone
    options:
      - Living Room
      - Bedroom
      - Kitchen
      - Patio
    initial: Living Room

input_text:
  music_search:
    name: Music search
    max: 255

# --- Integration templates & notes (commented guidance) ---
# Spotify
# Recommended: Enable via Configuration -> Integrations -> + -> Spotify
# If you prefer YAML (UI is recommended), the template would be:
# spotify:
#   client_id: !secret spotify_client_id
#   client_secret: !secret spotify_client_secret
# Impact: Enables Spotify Connect speakers and control via media_player services.

# Lutron Caseta
# Recommended: Configure via Integrations UI -> Lutron Caseta. Use the Smart Bridge IP for pairing.
# Impact: Adds lights & switches as native entities. No cloud required. Do the pairing through UI for reliability.

# Schlage Z-Wave (J-Series)
# Recommended: Use Z-Wave JS (install the Z-Wave JS add-on) and add integration via UI.
# Example if using USB stick (managed via add-on):
# zwave_js:
#   usb_path: /dev/ttyUSB0
#   network_key: !secret zwave_network_key
# Impact: Brings your Schlage lock(s) as lock.* entities. Keep device firmware up-to-date.

# Zigbee (e.g., Zigbee devices)
# Recommended: ZHA or Zigbee2MQTT via Integrations / HACS. Example (ZHA usb path):
# zha:
#   usb_path: /dev/ttyUSB1
#   database_path: /config/zigbee.db
# Impact: Native Zigbee control and entity creation. May require a dedicated USB stick (ConBeeII/CC2652).

# Govee
# Govee devices typically use the Govee cloud or the HACS custom integration. You will need an API key.
# Example (HACS/custom):
# govee:
#   api_key: !secret govee_api_key
# Impact: Enables control of Govee lights/LEDs. Cloud-based unless using alternative local methods.

# Fire TV / Android TV
# Use the Android TV / ADB integration (Integrations -> + -> Android TV) or the ADB Server add-on.
# Example (UI recommended). For Fire TV 2021+, enable ADB debugging in Developer options.
# Impact: Allows launching apps, sending key events, and turning screens on/off.

# Apple Music
# Best practical approach: use Sonos or AirPlay 2 capable speakers to play Apple Music. Home Assistant does not
# provide a direct universal Apple Music integration for credential-based playback the same way Spotify works.
# Impact: Use Sonos account linking (Sonos -> Services) or AirPlay 2 targets for Apple Music playback.

# Voice & Conversation (options and recommendation)
# You already have assist_pipeline.yaml and an esphome device for Home Assistant Voice PE.
# Recommendations that match "money no option" and self-installed:
# 1) For best out-of-the-box experience: Use Home Assistant Cloud (Nabu Casa) + Home Assistant Voice PE
#    - Pros: integrated, lower setup complexity, mobile/tablet support via browser/app and Home Assistant Cloud.
#    - Cons: cloud-assisted for some features and requires Nabu Casa subscription for Voice PE full features.
# 2) For local/offline high-quality: Run Rhasspy for wake-word + Whisper/WhisperX (STT) + Coqui / ElevenLabs for TTS,
#    and connect a conversational LLM via either a local GPU server (Llama 2 / Mistral variants) or OpenAI for best results.
#    - Pros: Full local control, privacy, custom wake words per room, multi-room routing.
#    - Cons: More hardware complexity (server with GPU recommended for local LLM conversational quality).
# 3) Hybrid approach: Use Rhasspy or Home Assistant Voice for wake-word and STT locally, and forward text to OpenAI
#    (or local LLM) for conversation / context. Use high-quality TTS for voice replies (ElevenLabs, Google WaveNet, Polly).
#    - This yields ChatGPT-like conversational replies while keeping wake-word and microphone handling local.
# Impact: Choosing Rhasspy/Local LLM requires additional servers and will create new entities/automations. Home Assistant
# Voice PE + Nabu Casa is the easiest path to conversational voice with existing setup.

# Tablet recommendations (wall-mounted & mobile)
# - Android: Fully Kiosk Browser or Home Assistant Companion App in kiosk mode. Grant microphone permission to capture voice.
# - iPad: Home Assistant Companion App is supported but kiosk/always-on multi-app microphone access is more limited.
# - Register each tablet via Mobile App integration so you can target them individually for TTS, notifications, and presence.
# Impact: Fully Kiosk + Android allows reliable full-screen dashboards, motion/light control, and microphone use (with proper setup).

# Post-setup checklist (safe/required steps):
# 1) Install Spotify integration and link account. Update any speaker mapping tables in packages/20_media_control.yaml to match
#    the real entity_ids (e.g., replace media_player.livingroom_show if different from your environment). Right now you have
#    media_player.living_room per your note — verify and update UI mappings.
# 2) Install Z-Wave JS and ZHA (as needed). Ensure Schlage lock appears as lock.<whatever> and update group.all_locks if different.
# 3) Set up Lutron Caseta via UI and confirm light/switch entities. Update group.all_dimmable_lights / group.all_light_switches lists
#    as necessary to reflect actual entity_ids.
# 4) Configure Fire TV via Android TV/ADB so automations in packages that reference media_player.bedroom_tv_2 / living_room_tv_2
#    point to the correct entities.
# 5) If you want ChatGPT conversational replies, confirm rest_command.call_openai has a working secret (openai_api_key) and webhook
#    endpoint to receive responses (scripts currently use a webhook 'chatgpt_response'). Test carefully.

# Testing & rollback:
# - These helpers are non-destructive. After adding, restart Home Assistant and check Configuration -> Devices & Services for integrations.
# - If you prefer, test in a development instance first for major changes (Z-Wave / Zigbee / Lutron pairing can affect physical devices).

# End of package
