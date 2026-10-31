---- [ SERVER: PLAYER HANDS SAFETY NET ] ----
-- The arms on every UseHands weapon are one entity, made by the gamemode's
-- PlayerSpawn. A PlayerSpawn hook that throws or returns a value (ours or any
-- other addon's) skips it, and those weapons float with no arms for that whole
-- life while weapons with arms built into the model look fine. This is a timer
-- and not another PlayerSpawn hook because a hook would be skipped the same way.

timer.Create("KC_HandsSafetyNet", 1, 0, function()
    for _, ply in ipairs(player.GetHumans()) do
        if ply:Alive() and not IsValid(ply:GetHands()) then
            ply:SetupHands()
        end
    end
end)
