--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local spawnMarkets = require('scripts.spawnMarkets')

--[[
=======
SCRIPTS
=======
]]

Env = "DEV"
Version = "1.0.1"

--[[
==============
WRITE HANDLERS
==============
]]

--- Spawn markets
--- @param msg Message The message received
--- @return Message spawnedMarketsNotice The spawned markets notice
Handlers.add("Spawn-Markets", {Action = "Spawn-Markets"}, function(msg)
  assert(msg.From == ao.id, "Only the server can spawn markets")
  return spawnMarkets:run(Env, msg)
end)

