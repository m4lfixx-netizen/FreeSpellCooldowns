# Free Spell Cooldowns

Track spell cooldowns, buffs, and procs with freely positioned icons,
customizable visual alerts, stack tracking, and separate settings for each
specialization.

This addon targets **World of Warcraft Forever 1.60.1 (Interface 16001)**.
This repository contains version **1.12.0**. Its configuration interface is in Czech. Compatibility with other WoW
clients is not verified.

## Features

- Place and resize each cooldown icon independently; enter exact pixel positions.
- Customize opacity, combat visibility, range and mana colors, and ready flashes.
- Track buffs and procs using an icon, a left/right pair, or a top motif.
- Choose lightning, fire, frost, nature, or paladin artwork.
- Show optional stack numbers, progressive intensity, or cumulative artwork pieces.
- Set a separate stack threshold for the timed color fade with a gray underlay.
- Configure maximum-stack glow, flashing, pulsing, and supported sound alerts.
- Keep buff previews and cooldown icons locked independently.
- Save settings separately for both talent specializations and each character.
- Open settings from the minimap button or `/fsc`.

## Installation

Install a packaged release into `Interface/AddOns/FreeSpellCooldowns`.
Close WoW completely before replacing the addon folder. Keep the `WTF`
folder to preserve your saved settings.

The repository root contains the addon files directly. CurseForge's packager
uses `.pkgmeta` to put them inside the correctly named addon folder.

## Sound and client restrictions

Exact stack-triggered audio depends on information the client makes available.
For Maelstrom Weapon at five stacks, the addon also supports a public signal
based on Lightning Bolt being both instant and free of mana, provided competing
instant-cast talents do not make that signal ambiguous. Other thresholds and
buffs can require readable aura stacks. The sound preview tests playback only.

See `README_CS.txt` for the detailed Czech guide.

Bundled Noto Sans uses the SIL Open Font License; see `Fonts/OFL.txt`.
