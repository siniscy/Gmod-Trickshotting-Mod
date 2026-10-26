-- Run "kc_debug_map_textures" in console (while standing on the map you're
-- having trouble with) to find out which textures aren't loading and why.
-- Checks every material used by the map's own world brushes AND every
-- currently-spawned entity's model (props, statics, everything) via
-- Material():IsError() -- true means that material failed to load and is
-- rendering as the pink/black checkerboard, exactly like it would in-game.
-- This is per-client (it's your own installed content being checked), so it
-- has to run on the client, not the server.

local function CheckMaterial(matName, seen, missing)
    if not matName or matName == "" then return end
    if seen[matName] then return end
    seen[matName] = true

    local mat = Material(matName)
    if not mat or mat:IsError() then
        table.insert(missing, matName)
    end
end

concommand.Add("kc_debug_map_textures", function()
    local seen, missing = {}, {}

    -- The map's own world brushes (walls, floors, displacements, etc.)
    local worldMats = game.GetWorld():GetMaterials() or {}
    for _, m in ipairs(worldMats) do
        CheckMaterial(m, seen, missing)
    end

    -- Every currently-spawned entity's model materials (props, statics,
    -- weapons, NPCs, everything with a model) -- this is where a missing
    -- content pack usually shows up, more often than the map's own brushes.
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then
            local mats = ent:GetMaterials()
            if mats then
                for _, m in ipairs(mats) do
                    CheckMaterial(m, seen, missing)
                end
            end
        end
    end

    table.sort(missing)

    print(string.format("[KC Debug] Checked %d unique materials on %s -- %d missing/broken:",
        table.Count(seen), game.GetMap(), #missing))

    if #missing == 0 then
        print("[KC Debug] No missing/error materials found among what's currently loaded.")
        print("[KC Debug] If you're still seeing checkerboard textures, they may belong to")
        print("[KC Debug] a prop that hasn't spawned/streamed in yet -- move closer and rerun.")
    else
        for _, m in ipairs(missing) do
            print("[KC Debug]   MISSING: materials/" .. m .. ".vmt")
        end
    end

    -- Also written to a file, since console scrollback can drop lines on a
    -- long list and this needs to be copy-pasted somewhere to actually fix.
    local lines = {
        string.format("Missing/error materials on %s (%d of %d checked):", game.GetMap(), #missing, table.Count(seen)),
    }
    for _, m in ipairs(missing) do
        table.insert(lines, "materials/" .. m .. ".vmt")
    end
    file.Write("kc_missing_textures.txt", table.concat(lines, "\n"))
    print("[KC Debug] Full list also written to garrysmod/data/kc_missing_textures.txt")
end)

print("[KC Debug] kc_debug_map_textures loaded -- run it in console on the map you're having trouble with.")
