# Moonloader Script Development — AI Guide

You are an expert assistant for writing **Moonloader Lua scripts** for **GTA San Andreas**.
Your authoritative source for all functions, opcodes, and constants is **`references.txt`** in this repository.

---

## Critical Rules (MUST follow every time)

1. **NEVER guess opcodes or function names.**
   Always look up the exact signature from `references.txt`.
   If a function exists in MoonAdditions or MoonPlus but not base Moonloader, use the version from those libraries.

2. **Every loop MUST contain `wait(0)` or higher.**
   A loop without a wait call will freeze or crash the game permanently.
   ```lua
   while true do
       -- your code
       wait(0)
   end
   ```

3. **Model loading:** After `requestModel()`, always call `loadAllModelsNow()` before spawning.
   After you're done with the model, always call `markModelAsNoLongerNeeded(model)`.
   ```lua
   requestModel(modelId)
   loadAllModelsNow()
   -- use the model
   markModelAsNoLongerNeeded(modelId)
   ```

4. **Never request or remove the "ped" animation library.**
   It is always loaded by the game. Touching it will cause a game freeze.

5. **Animation loading:** After `requestAnimation(animLib)`, always call `removeAnimation(animLib)` when done.

6. **Always unload what you load.**
   Audio, TXD, models, and textures loaded by the script must be unloaded when no longer needed.
   Scripts that hold memory indefinitely are broken scripts.

7. **Prefer readable code over compact one-liners.**
   Use temporary variables and split complex expressions across multiple lines.
   This reduces parser errors and makes debugging easier.

8. **Use `script.use_cleo_functions()` if CLEO compatibility is needed**, but prefer native Moonloader functions.

9. **Thread safety:** Use `createThread(function() ... end)` for separate coroutines.
   Never block the main script thread with heavy logic — put it in a thread.

10. **Return value handling:** Many opcodes return multiple values. Always capture them:
    ```lua
    local result, x, y, z = getCharCoordinates(playerPed)
    ```

---

## Script Boilerplate

Every Moonloader script must start with:

```lua
script_name("My Script")       -- Required: sets the script name
script_description("Does X")  -- Optional but recommended
script_author("YourName")      -- Optional
script_version("1.0")          -- Optional

require "moonloader"           -- Always include
-- require "moonadditions"     -- Include if using MoonAdditions functions
-- require "moonplus"          -- Include if using MoonPlus functions

local imgui = require "imgui"  -- Include only if using ImGui

function main()
    -- Wait for game to fully load
    while not isSampLoaded() and not isGameStarted() do
        wait(100)
    end
    wait(1000) -- Extra safety wait

    -- Your main logic here
    while true do
        wait(0)
    end
end
```

---

## How to Look Things Up

### Finding a function:
1. Open `references.txt`
2. Search for a keyword (e.g. "vehicle", "char", "weapon")
3. Read the signature: `function_name(<param_type param_name>)` → `return_type`
4. Use exactly that signature — no improvisation

### Function signature format in references.txt:
```
- `functionName(<int handle>, <float x>)` → `bool result` — Short description
```
- Parameters in `<>` show the type and name
- `→ return_type` shows what the function returns
- Multiple return values: `→ bool result, float x, float y`

### Library priority:
1. **Moonloader** — base game opcodes (Section 1 of references.txt)
2. **MoonAdditions** — extended functions (Section 2)
3. **MoonPlus** — additional utilities (Section 3)
4. **ImGui** — UI windows and widgets (Section 4)
5. **Lua stdlib** — standard Lua functions (Section 5)
6. **Enums** — named constants (Section 6)

---

## Common Patterns

### Getting the player ped and position:
```lua
local playerId = getPlayerId()
local playerPed = getPlayerChar(playerId)
local result, x, y, z = getCharCoordinates(playerPed)
```

### Spawning a vehicle:
```lua
local model = 411 -- Infernus
requestModel(model)
loadAllModelsNow()
local result, x, y, z = getCharCoordinates(playerPed)
local car = createCar(model, x + 3.0, y, z)
markModelAsNoLongerNeeded(model)
```

### Spawning a ped:
```lua
local model = 287
requestModel(model)
loadAllModelsNow()
local result, x, y, z = getCharCoordinates(playerPed)
local ped = createChar(4, model, x + 1.0, y, z)
markModelAsNoLongerNeeded(model)
```

### Playing an animation on a ped:
```lua
requestAnimation("fight_b")
loadAllModelsNow()
taskPlayAnim(ped, "punch_r", "fight_b", 4.0, false, false, false, false, -1)
wait(1000)
removeAnimation("fight_b")
```

### ImGui window example:
```lua
local imgui = require "imgui"
local showWindow = imgui.ImBool(false)

function main()
    -- ...
    createThread(function()
        while true do
            imgui.Process = showWindow.v
            wait(0)
        end
    end)
end

function imgui.OnDrawFrame()
    if showWindow.v then
        imgui.SetNextWindowSize(imgui.ImVec2(300, 200), imgui.Cond.FirstUseEver)
        imgui.Begin("My Window", showWindow)
        imgui.Text("Hello World!")
        if imgui.Button("Click Me") then
            -- do something
        end
        imgui.End()
    end
end
```

### Blip on a position:
```lua
local blip = addBlipForCoord(x, y, z)
changeBlipDisplay(blip, 2)
changeBlipColour(blip, 0)
```

### Checking if player is in a vehicle:
```lua
if isCharInAnyCar(playerPed) then
    local result, car = storeCarPlayerIsIn(playerId)
    -- use car
end
```

### Weapons:
```lua
giveWeapon(playerPed, 31, 500) -- Weapon ID 31 = M4, 500 ammo
setCurrentCharWeapon(playerPed, 31)
```

---

## Enums Quick Reference

Instead of raw integers, use named constants from Section 6 of references.txt.
Common examples:
- Weapon IDs: `WEAPON_AK47`, `WEAPON_M4`, `WEAPON_SNIPER`, etc.
- Ped types: use integer type `4` for civilian, `5` for criminal, etc.
- Vehicle colors: integer 0–126
- Blip colors: 0 = red, 1 = green, 2 = blue, 3 = white, 4 = yellow
- `component_state` enum for vehicle components: `DISABLED`, `ENABLED`, `DAMAGED`

---

## What NOT to do

| ❌ Wrong | ✅ Correct |
|---|---|
| Guess an opcode name from memory | Look it up in references.txt |
| `while true do end` | `while true do wait(0) end` |
| Leave models loaded forever | `markModelAsNoLongerNeeded(model)` |
| `requestAnimation("ped")` | Never touch the ped library |
| Dense one-line expressions | Break into clear steps with temps |
| Use `require "cleo"` unless needed | Prefer native Moonloader APIs |

---

## Debugging Tips

- Use `print(value)` — output appears in Moonloader log (`moonloader.log` in GTA SA root)
- Use `sampAddChatMessage("debug: " .. tostring(val), -1)` for in-game visible debug if SAMP is loaded
- Check `moonloader.log` for runtime errors with line numbers
- Script crashes often mean: missing `wait()`, wrong opcode params, or unloaded model access

---

*Reference: `references.txt` in this repo — generated from the GTA SA Moonloader VSCode extension snippets.*
