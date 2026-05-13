# FreeMyBag

**Delete items from your bags with one right-click.**

You're out farming. Your bags are filling up with gray junk. You can't sell because there's no vendor nearby — or you just don't want to waste time running back.

Turn on **Delete Mode**, right-click each junk item once, and it's gone. Turn it off and keep playing.

## How it works

Toggle Delete Mode on (via the red button in your backpack or the slash command). While Delete Mode is active, **right-clicking** any item in your bags destroys it immediately. Left-click still works normally (pick up, move, equip, split stacks). When you're done, toggle it off and go back to normal gameplay.

No dialogs, no confirmation spam. One right-click, gone.

## Features

- **Delete Mode** — right-click any bag item to destroy it instantly (left-click works normally)
- **Auto-Accept** — automatically confirms the Blizzard deletion popup so you never have to click a second time (optional, ON by default)
- **Screen Border Pulse** — a pulsing red border around your screen while Delete Mode is active, so you always know the mode is on
- **Bag Borders** — red outline on every bag frame (backpack, bags, bank) while Delete Mode is active
- **Button Pulse** — the Delete Mode button pulses while active for extra visibility
- All visual feedback can be toggled on/off individually in settings

## Why right-click?

Blizzard's default bag UI only passes **LeftButton** and **RightButton** events through. Modifier keys (ALT, CTRL, SHIFT) are consumed by the game engine before they reach any addon hook, and MiddleButton is not passed to bag item click handlers. Right-click is the only reliable way to trigger deletion that doesn't interfere with normal bag operations (pick up, move, split stacks).

## Commands

| Command | Description |
|---------|-------------|
| `/fmb` | Toggle the settings window |
| `/freemybag` | Same as above |

## Settings

Open the settings window with `/fmb`. You can configure:

- **Delete Mode** — toggle on/off
- **Auto-Accept** — skip the Blizzard confirmation popup
- **Visual Feedback** — individual toggles for Screen Border, Bag Border, and Button Pulse

All settings save automatically per character.

## Why not just vendor?

When you're deep in a dungeon, in the middle of a farming route, or doing content where you can't mount up and fly back to town, vendor trash is useless. FreeMyBag lets you clear space instantly and keep going without interrupting your flow.

It's also useful for:
- Clearing soulbound quest items you no longer need
- Getting rid of grey items during leveling when you don't want to run back
- Deleting unwanted BoP items that you'd otherwise need to destroy via the default UI (which takes multiple clicks)

## Requirements

World of Warcraft Wrath of the Lich King 3.3.5 (or any client using the 3.3.5 API).

## License

MIT
