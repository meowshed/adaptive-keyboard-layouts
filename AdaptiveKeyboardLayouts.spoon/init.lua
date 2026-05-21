--- AdaptiveKeyboardLayouts.spoon
-- Switches macOS keyboard layouts based on connected keyboard.
-- Supports USB (Das Keyboard) and Bluetooth (Nuphy Air75) external keyboards.
-- Falls back to MacBook Pro built-in layout when no external keyboard detected.
--
-- Usage:
--   hs.loadSpoon("AdaptiveKeyboardLayouts")
--   spoon.AdaptiveKeyboardLayouts:start()

local obj = {}
obj.__index = obj

obj.name = "AdaptiveKeyboardLayouts"
obj.version = "1.0"
obj.author = "Andrew Vasilyev"
obj.license = "MIT"

-- Known external keyboards
obj.keyboards = {
  {
    name       = "Das Keyboard",
    vendorID   = 0x24f0,
    productID  = 0x0140,
    layoutID   = 19458,
    layoutName = "RussianWin",
  },
  {
    name       = "Nuphy Air75",
    vendorID   = 0x05AC,  -- reported as Apple HID over BT; detected via ioreg name
    productID  = nil,     -- matched by name instead
    layoutID   = 19458,
    layoutName = "RussianWin",
  },
}

-- Layout used when no external keyboard is connected (MacBook Pro built-in)
obj.builtinLayout = {
  layoutID   = 19456,
  layoutName = "Russian",
}

-- ABC layout — always included alongside the Russian layout
obj.abcLayout = {
  layoutID   = 252,
  layoutName = "ABC",
}

obj._usbWatcher      = nil
obj._bluetoothTimer  = nil
obj._lastState       = nil

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function buildLayoutDict(layoutID, layoutName)
  return string.format(
    '<dict><key>InputSourceKind</key><string>Keyboard Layout</string>' ..
    '<key>KeyboardLayout ID</key><integer>%d</integer>' ..
    '<key>KeyboardLayout Name</key><string>%s</string></dict>',
    layoutID, layoutName
  )
end

local function applyLayouts(russian)
  -- Write enabled input sources: ABC + chosen Russian variant
  local abc     = buildLayoutDict(obj.abcLayout.layoutID, obj.abcLayout.layoutName)
  local russian = buildLayoutDict(russian.layoutID, russian.layoutName)
  os.execute(string.format(
    "defaults write com.apple.HIToolbox AppleEnabledInputSources -array '%s' '%s'",
    abc, russian
  ))
  -- Restart input menu agent to apply changes
  os.execute("pkill TextInputMenuAgent 2>/dev/null; true")
end

local function isExternalConnected()
  -- USB: check attached devices
  for _, dev in ipairs(hs.usb.attachedDevices()) do
    for _, kb in ipairs(obj.keyboards) do
      if kb.productID and dev.vendorID == kb.vendorID and dev.productID == kb.productID then
        return true, kb
      end
    end
  end
  -- HID/Bluetooth: check ioreg for known names
  local output = hs.execute("ioreg -c IOHIDDevice -r -l | grep '\"Product\"' | grep -v 'Apple Internal' | grep -v Backlight | grep -v BTM")
  if output then
    for _, kb in ipairs(obj.keyboards) do
      if not kb.productID and output:find(kb.name) then
        return true, kb
      end
    end
  end
  return false, nil
end

-- ── Core ─────────────────────────────────────────────────────────────────────

function obj:_apply(showAlert)
  local connected, kb = isExternalConnected()
  local layout = connected and { layoutID = kb.layoutID, layoutName = kb.layoutName }
                            or obj.builtinLayout
  applyLayouts(layout)
  if showAlert then
    local msg = connected
      and ("⌨ " .. kb.name .. " → " .. layout.layoutName)
      or  "⌨ Built-in → " .. layout.layoutName
    hs.notify.new({ title = "Keyboard Layout", informativeText = msg }):send()
  end
  return connected
end

function obj:_onUSBEvent(event)
  for _, kb in ipairs(obj.keyboards) do
    if kb.productID
      and event.vendorID == kb.vendorID
      and event.productID == kb.productID then
      self:_apply(true)
      return
    end
  end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function obj:start()
  -- Apply immediately
  self._lastState = self:_apply(true)

  -- Double-check after short delays (Bluetooth can be slow to report)
  hs.timer.doAfter(2, function() self:_apply(false) end)
  hs.timer.doAfter(5, function() self:_apply(false) end)

  -- Watch USB events
  self._usbWatcher = hs.usb.watcher.new(function(event)
    self:_onUSBEvent(event)
  end)
  self._usbWatcher:start()

  -- Poll Bluetooth every 2 s
  self._bluetoothTimer = hs.timer.doEvery(2, function()
    local current = isExternalConnected()
    if current ~= self._lastState then
      self:_apply(true)
      self._lastState = current
    end
  end)

  hs.notify.new({ title = "Keyboard Layout", informativeText = "AdaptiveKeyboardLayouts ready" }):send()
  return self
end

function obj:stop()
  if self._usbWatcher     then self._usbWatcher:stop();     self._usbWatcher     = nil end
  if self._bluetoothTimer then self._bluetoothTimer:stop(); self._bluetoothTimer = nil end
end

return obj
