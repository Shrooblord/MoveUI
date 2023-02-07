--MoveUI Copyright (C) 2017-2023 Dirtyredz, Shrooblord
--Initialisation script.

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MoveUI
MoveUI = {}

function MoveUI.onPlayerLogIn(playerIndex)
  -- Adding script to player when they log in
  local player = Player(playerIndex)
  if player then
    print("Hi " .. player.name .. "!")
    player:addScriptOnce("data/scripts/player/MoveUI.lua")
  end
end

Server():registerCallback("onPlayerLogIn", "onPlayerLogIn")
