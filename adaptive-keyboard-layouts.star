# adaptive-keyboard-layouts.star
#
# platforms: ["macos"]
# after:     ["@stdlib//components/hammerspoon"]
#
# Hammerspoon Spoon: switches macOS keyboard layouts based on connected keyboard.
# Supports USB (Das Keyboard) and Bluetooth (Nuphy Air75) external keyboards.
# Falls back to MacBook Pro built-in layout when no external keyboard detected.

platforms = ["macos"]
after = ["@stdlib//components/hammerspoon"]

def install(ctx):
    home = ctx.env("HOME")
    ctx.link_file(
        src = "AdaptiveKeyboardLayouts.spoon/init.lua",
        dst = home + "/.hammerspoon/Spoons/AdaptiveKeyboardLayouts.spoon/init.lua",
    )

def verify(ctx):
    home = ctx.env("HOME")
    if not ctx.file_exists(home + "/.hammerspoon/Spoons/AdaptiveKeyboardLayouts.spoon/init.lua"):
        ctx.log("adaptive-keyboard-layouts: Spoon not found")

def uninstall(ctx):
    home = ctx.env("HOME")
    ctx.remove_symlink(home + "/.hammerspoon/Spoons/AdaptiveKeyboardLayouts.spoon/init.lua")
