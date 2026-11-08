<div align="center">

# AutoBuffer

A World of Warcraft addon that buffs nearby players who are missing your buff, one key press at a time.

· [Changelog](./CHANGELOG.md) ·

[![Version 0.1.0][github-release-shield]][github-release-link]

</div>

## 👋🏻 Welcome

Buffing every player you meet is a nice thing to do, but targeting each of them by hand gets tedious. AutoBuffer finds
the next player in range who is missing your buff. You only press one key.

## ✨ Features

- Finds the next friendly player in range who is missing the selected buff
- One key press or click casts exactly one buff (no automation)
- Buff presets for Priest, Mage, Druid, Paladin, Warlock and Shaman, or any other spell by name or ID
- Group versions (e.g. Prayer of Fortitude) count as "already buffed"
- Buffs other players via their nameplates
- Optionally includes yourself and your group/raid
- Shows how many players in range still need the buff
- Optional chat report of each buff, with player names in class colors
- Statistics per character and for all characters: buffs per spell, different players, top players, classes, levels,
  zones, streaks and records
- 25 account-wide achievements, from your first buff to 10,000 buffs
- A window with tabs for statistics and achievements

## 📦 Download & Installation

[Download the current version][github-release-link] from GitHub and drop the contents of the folder into your WoW
addons folder.

## 🔨 Usage

### Button

- Left click: buff the next player
- Right click: switch to the next buff of your class
- [Alt] + click: open the window with statistics and achievements (out of combat)
- [Shift] + drag: move the button

### Key binding

Options > Keybindings > AddOns > AutoBuffer > "Buff next player"

### Slash commands

- Use `/autobuff` to show the help and the buffs available to your class
- Use `/autobuff <number>` to pick a buff from that list
- Use `/autobuff spell <name or ID>` to pick any spell
- Use `/autobuff others` to toggle buffing other players (requires friendly nameplates, [Shift] + V)
- Use `/autobuff group` to toggle yourself and your group/raid (buffing and report)
- Use `/autobuff report` to toggle the chat report
- Use `/autobuff window` to open the window with statistics and achievements
- Use `/autobuff stats` to show the statistics of this character in the chat
- Use `/autobuff stats account` to show the statistics of all characters
- Use `/autobuff stats reset` to delete the statistics of this character (the account totals are kept)
- Use `/autobuff achievements` to show your achievements and the next goal of each category
- Use `/autobuff achievements all` to show all achievements with their progress
- Use `/autobuff hide` to hide the button (the key binding still works)
- Use `/autobuff show` to show the button after you have hidden it
- Use `/autobuff reset` to move the button back to its initial position

`/abuff` works as a short alias.

### Statistics

Every successful buff on a friendly player is counted, whether the report is on or off. The same rules as for the
button apply: yourself and your group/raid only count when `/autobuff group` is on. Buffs on NPCs are never counted.

The names of buffed players are saved locally in your SavedVariables to count different players and to show your top
players.

### Achievements

Achievements are shared by all your characters and are checked against the account-wide statistics. When you unlock
one, it is announced in the chat with a sound. Achievements your existing statistics already fulfil are unlocked at
login without a separate announcement.

| Category | Achievements                                                          |
| -------- | --------------------------------------------------------------------- |
| Buffs    | 1, 10, 100, 500, 1,000, 5,000 and 10,000 buffs                        |
| Players  | 10, 50, 100, 500 and 1,000 different players                          |
| Loyalty  | The same player 10 and 25 times                                       |
| Classes  | A player of every class                                               |
| Zones    | 10 and 25 different zones                                             |
| Speed    | 10 and 20 buffs within one minute, 100 buffs in one session           |
| Streaks  | 7 and 30 days in a row                                                |
| Special  | 50 buffs on players below level 10, a buff between midnight and 4 a.m., every buff of your class |

### Limitations

- Addons can't change the target while you are in combat. The button then buffs the last player it picked.
- WoW Forever does not let addons cast directly on nameplates. Other players are therefore targeted by their full name
  for the cast, then your previous target is restored.

## License

MIT

<!-- Links -->

[github-release-shield]: https://img.shields.io/badge/version-0.1.0-blue?color=369eff&labelColor=black&logo=github
[github-release-link]: https://github.com/hjenneberg/wow-auto-buffer/releases
