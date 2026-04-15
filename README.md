# WorldBossLockouts

A TurtleWoW addon that tracks your weekly world boss loot lockouts. Opens automatically alongside the Raid Info window and shows at a glance which bosses you can still loot this week.

## Features

- Tracks all TurtleWoW world bosses in one panel
- Automatically detects lockouts from system messages when you kill a boss
- Shows time remaining until the weekly reset
- Hover over any boss for zone, group size, natural respawn window, and summoning item details
- Lockouts persist across sessions and clear automatically on weekly reset
- No dependencies

## Installation

1. Download and extract the folder
2. Place the `WorldBossLockouts` folder in `World of Warcraft/Interface/AddOns/`
3. Restart the game or reload your UI

## Usage

Open your **Raid** panel and click the **Raid Info** button. The WorldBossLockouts panel appears directly below it.

- **Green** means you can loot this boss this week
- **Red** means you are locked out until the weekly reset
- Hover over any boss row for full details

Lockouts are detected automatically when you receive the system message after killing a world boss. No manual input needed.

## Bosses Tracked

Azuregos, Dark Reaver, Nerubian Overseer, Concavius, Ostarius, Kazzak, Ysondre, Taerar, Emeriss, Lethon, Cla'ckora, Moo

## Notes

- Ostarius has a 14-day respawn rather than the standard weekly lockout window
- The four Dragons of Nightmare share a respawn timer that starts only after all four are dead
- Cla'ckora and Moo have no loot lockout and will always show as available
