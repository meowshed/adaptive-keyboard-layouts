# adaptive-keyboard-layouts

A [meowctl](https://github.com/meowshed/meowctl) registry module — Hammerspoon Spoon that automatically switches macOS keyboard layouts based on the connected keyboard.

## What it does

- Detects USB keyboards (e.g., Das Keyboard) and switches to Dvorak
- Detects Bluetooth keyboards (e.g., Nuphy Air75) and switches to Dvorak
- Falls back to ABC layout when no external keyboard is connected
- Uses macOS Input Sources API via Hammerspoon

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) (installed via meowctl stdlib)

## Usage

In your `init.star`:

```python
component("@adaptive-keyboard-layouts//adaptive-keyboard-layouts")
```

Or:

```sh
meowctl dep add adaptive-keyboard-layouts
meowctl apply
```

## Files

| File | Destination |
|------|-------------|
| `AdaptiveKeyboardLayouts.spoon/init.lua` | `~/.hammerspoon/Spoons/AdaptiveKeyboardLayouts.spoon/init.lua` |

## Dependencies

- `@stdlib//components/hammerspoon`

## License

MIT
