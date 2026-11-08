# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added statistics per character and for all characters (`/autobuff stats`, `/autobuff stats account`)
- Added buffs per spell, different players, top players, classes, levels and top zones to the statistics
- Added active days, streaks and records (per minute, per session) to the statistics
- Added today's and total buffs to the button tooltip
- Added `/autobuff stats reset` to delete the statistics of the current character

## [0.1.0] - 2026-11-08

### Added

- Added a button that buffs the next player in range who is missing the selected buff
- Added buff presets for Priest, Mage, Druid, Paladin, Warlock and Shaman
- Added support for any spell via slash command
- Added buffing of other players via nameplates
- Added an option to include or exclude yourself and your group/raid
- Added a key binding
- Added a counter showing how many players in range still need the buff
- Added a chat report of each buff, with player names in class colors
