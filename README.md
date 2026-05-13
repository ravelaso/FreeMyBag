# FreeMyBag

**Delete items from your bags with Alt+LeftClick — fast, safe, and without leaving the game.**

You're out farming. Your bags are full of gray junk, soulbound quest items you no longer need, or BoP gear you want to get rid of. There's no vendor nearby — and you don't want to waste time running back.

Turn on **Delete Mode**, hold **Alt** and **LeftClick** each item. It's gone. Turn Delete Mode off and keep playing normally.

## How it works

1. Enable **Delete Mode**
   - Click the red button in your backpack, or type `/fmb on`

2. **Alt+LeftClick** any item to destroy it
   - Alt is required — prevents accidental clicks from deleting something valuable
   - RightClick always works normally (equip, use, learn)

3. Disable Delete Mode when you're done
   - Click the button again, or type `/fmb off`

### Safety by quality

| Item quality | Auto-Delete OFF (default) | Auto-Delete ON |
|---|---|---|
| Poor / Common | Deleted instantly, no popup | Deleted instantly |
| Uncommon (green) | Blizzard popup — type DELETE to confirm | Auto-confirmed |
| Rare+ (blue, purple, orange) | Custom confirm dialog (Delete / Cancel) | Auto-confirmed |

Auto-Delete is OFF by default so you always have a chance to review before anything valuable is destroyed.

## Commands

| Command | Description |
|---------|-------------|
| `/fmb` | Open settings window |
| `/fmb on` | Enable Delete Mode |
| `/fmb off` | Disable Delete Mode |

## Settings

Open the window with `/fmb`. All settings save per character.

- **Delete Mode** — enable/disable
- **Auto-Delete** — skips the "type DELETE" confirmation for Rare+ and Uncommon items
- **Screen Border** — pulsing red border around your screen while in Delete Mode
- **Bag Border** — red outline on every bag frame
- **Button Pulse** — the Delete Mode button pulses when active

## Requirements

World of Warcraft Wrath of the Lich King 3.3.5 

## License

MIT
