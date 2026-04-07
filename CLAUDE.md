# Moonloader Script Development Workspace

You are assisting with writing Moonloader scripts for GTA San Andreas using LUA.

## Critical Rules

1. **NEVER guess opcodes.** Before using ANY opcode, always use correct opcodes from "references.txt". Some opcodes might not be in Base Moonloader there are MoonAdditions and MoonPlus for that job. For imgui there are no references but an example use that to get an idea of how that works.
2. **Every loop MUST contain `wait {time} 0`** (or higher). Loops without wait will freeze the game.
3. **If the script needs it's models or animations in the instance use loadAllModelsNow after requesting them. Else wait for the models or animations to be loaded
4. **Never request or remove "Ped" animation library it's always loaded by the game requesting or removing it will cause the game to freeze
5. **Always clean up models.** After `requestModel` + `loadAllModelsNow`, always call `markModelAsNoLongerNeeded` when done.
6. **Always clean up animations.** After "requestAnimation" always call "removeAnimation"
7. **If something else like audio or txd or anything are loaded by the script after the need for them are done make sure the loaded once get unloaded. We don't need bad scripts taking memory.
8. **Prefer parser-safe syntax over compact syntax.** If an expression can be written either as one dense line or as 2-4 simple lines with temporaries, prefer the simpler form.

## How to Look Things Up

Just use the "references.txt" it includes all the references you'll need
If Imgui is needed use "examples\paintjob-loader.lua" as an example of how it's done