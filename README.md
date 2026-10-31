# deskpaper

Stickers on your Wayland desktop: die-cut and holographic pictures, stamps, polaroids, tickets, post-its and a torn-paper calendar that sit above the wallpaper and below every window. You place them in an editor, so you can't move them by accident on the desktop.

## Requirements

Quickshell, Python 3, Pillow and PyYAML. awww or swww is optional; the editor uses it to show each screen's wallpaper behind the stickers.

```bash
sudo pacman -S quickshell python-pillow python-yaml
```

## Install

Clone the repository and run it. There is nothing to build:

```bash
git clone https://github.com/AlejandroMinor/deskpaper.git
cd deskpaper
./deskpaper
```

`deskpaper` opens the editor and puts the stickers on the desktop. `deskpaper start` puts only the stickers.

To run it from anywhere as `deskpaper`, link it into a folder in your `PATH`:

```bash
ln -s "$PWD/deskpaper" ~/.local/bin/deskpaper
```

To find the editor in your app launcher, link its desktop file and icon too:

```bash
ln -s "$PWD/data/io.github.AlejandroMinor.deskpaper.desktop" ~/.local/share/applications/
mkdir -p ~/.local/share/icons/hicolor/scalable/apps
ln -s "$PWD"/src/deskpaper/icons/hicolor/scalable/apps/*.svg ~/.local/share/icons/hicolor/scalable/apps/
```

### Start with the session

To have the stickers on the desktop when you log in, start them with your compositor. Hyprland:

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("deskpaper start")
end)
```

sway:

```
exec deskpaper start
```

### Open the editor as a floating window

The editor is a Quickshell window: its app ID is `org.quickshell` and its title `deskpaper`.

Hyprland:

```lua
hl.window_rule({
    name   = "deskpaper",
    match  = { class = "^(org.quickshell)$", title = "^(deskpaper)$" },
    float  = true,
    center = true,
})
```

sway:

```
for_window [app_id="org.quickshell" title="^deskpaper$"] floating enable
```

## The editor

On the left is a canvas with your screens and their wallpapers. On the right are the things you can add:

- **Stickers.** Your imported pictures. **+ Image…** imports a new one.
- **Widgets.** Stickers that show data or need no picture: the post-it with upcoming events, the calendar, clocks, washi tape, a ransom note.
- **Off screen.** Stickers whose screen is not connected or whose picture is gone. Drag one onto a screen to place it again.

Drag a sticker or widget onto a screen to place it as it is. Or click it first: it stays in the preview, with its controls below (skin, text, look, shadow), and dragging it, from its tile or the preview, or **Add** places it with those settings.

How to change a sticker on the canvas:

- Drag it to move it.
- Drag the blue corner to resize it.
- Drag the orange knob to turn it.
- The red × on its corner, Remove under the canvas, or `Del` removes it.
- `[` and `]` (or `PgDn` and `PgUp`) move it one place down or up in the pile of its screen; `End` and `Home` send it to the back or the front. The Arrange buttons under the canvas do the same.
- `Ctrl+D` duplicates it; `Ctrl+Z` and `Ctrl+Shift+Z` (or `Ctrl+Y`) undo and redo.
- Under the canvas, the selected sticker's controls, in groups: **Skin**; its caption, title or text; **Look**, the skin's own options; **Effects**, its shadow and a lifted or peeled corner; **Arrange**, its place in the pile, Duplicate and Remove.
- Pictures have **outline** (the die-cut border: white, black or none) and **backing** (a black or white card behind the picture, for art that needs a dark or light background). The picture itself is not changed.

**Apply** saves the board, and the desktop updates right away. `Esc` closes the editor; if there are unsaved changes, press it twice.

## Skins

| Skin | Shows | Text | Extras |
|---|---|---|---|
| diecut | a picture with a die-cut border | | gloss, peeled corner, outline, backing |
| holo | the same, with a rainbow that now and then sweeps across | | animated, peeled corner, outline, backing |
| news | a newspaper clipping: masthead, black-and-white photo, text columns | headline | torn edges, backing |
| clock | the time: hands on a paper disc, or the digits on a label-maker strip, cut from magazines, in marker or typed (kind `widget`) | | style |
| tape | a strip of washi tape (kind `widget`) | | pattern, color |
| ransom | a ransom note, every letter cut from a different magazine (kind `text`) | the message | |
| stamp | a picture on perforated paper | caption | gloss, backing |
| polaroid | a square photo | caption | lifted corner, backing |
| ticket | a picture on the stub of an admission ticket | caption | gloss, backing |
| postit | upcoming events (`events` source) | title | lifted corner |
| calendar | this month on torn paper (`month` source) | | event days marked |

Every sticker has a shadow that can be soft, normal, strong or none. Stickers bounce in when the desktop layer loads them. The fonts (Permanent Marker, Caveat, Special Elite, UnifrakturMaguntia) ship in `qml/fonts/` with their licenses.

## Files

Everything lives in `~/.config/deskpaper/`. Set `DESKPAPER_DIR` to use another folder.

- `board.json`: the stickers. Each one has `id`, `kind` (`image`, `data`, `text` or `widget`), `skin`, `monitor` (output name, such as `DP-2`), `x` and `y` (the center, as a fraction from 0 to 1 of the screen), `scale`, `rotation` (degrees), `z` and `props`.
- `assets/`: imported pictures (`<id>.png`), their die-cut silhouettes (`<id>.cut.png`) and the rounded card used with a backing (`<id>.card.png`). A light, flat background (a PNG on white) is made transparent on import, so the die-cut follows the drawing; `--keep-background` skips that, and `deskpaper recut <id>.png` (the scissors on a picture in the editor) does it for a picture imported before. Dark backgrounds are left alone: dark art often touches them.
- `data/events.json` (or `.yml`): events for the post-it and the calendar, if you want some besides HyprFlow's:

  ```json
  [{"when": "2026-10-30T10:00", "title": "Meeting"}, {"when": "2026-10-31", "title": "All day"}]
  ```

To move everything to another machine, run `deskpaper export file.tar.gz`, then on the other machine run `deskpaper restore file.tar.gz`. Add `--replace` to restore over an existing board; the old board is kept aside as `deskpaper.old-<date>`. The editor has buttons for both.

## Extending

- **A skin** is one QML file, `qml/skins/<Name>.qml`, where the file name is the skin id with its first letter in upper case. It declares `property var sticker` and `property var payload` and sets its own `implicitWidth` and `implicitHeight`. Visual values go in `qml/services/Look.qml`.
- **Sources included:** `events` (the post-it) and `month` (the calendar) read `data/events.json` and HyprFlow's calendar (`~/.local/share/hyprflow/calendar/`, or `HYPRFLOW_CALENDAR_DIR`) together; either one may be missing.
- **A data source** is a Python module in `src/deskpaper/sources/` with a function that returns a dict, plus one line in `REGISTRY`. `deskpaper source <name>` prints it, and the skin reads it as `payload`.

Python fetches the data and QML only draws it, so neither one needs to know about the other.

## Tests

They need pytest (`sudo pacman -S python-pytest`). The QML is checked with Qt 6's `qmllint` when it is installed.

```bash
python -m pytest -q
```
