# Wick's Quest Key — Changelog

## 1.0.0 — 2026-05-03

### Initial release

Retail-style ExtraActionButton for TBC Classic. One bind cycles through every active quest item, auto-detected from your quest log. Brand-consistent with the rest of the [Wick suite](https://github.com/Wicksmods/WickSuite).

- Single 52x52 secure-action button with the Wick chrome (flat purple-black panel, 1px border, fel-green L-bracket corners)
- Auto-detects quest items via `GetQuestLogSpecialItemInfo`
- Left-click or binding fires the armed item; cycles to the next on each press
- Right-click cycles without firing (skip the current item)
- Keybind label shown in the top-right corner of the button, updates on `UPDATE_BINDINGS`
- Stack count rendered bottom-right when count > 1
- Hides when no usable quest items are loaded; reappears on `QUEST_LOG_UPDATE` / `BAG_UPDATE_DELAYED`
- Slash commands: `/wqk`, `/wqk unlock`, `/wqk lock`, `/wqk reset`
- Position saved to `WicksQuestKeyDB`
