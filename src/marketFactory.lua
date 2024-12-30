---------------------------------------------------------------------------------
-- All Rights Reserved © Outcome
---------------------------------------------------------------------------------

local marketFactory = require('modules.factory')

Name = "Outcome Market Factory"
Version = '1.0.1'
Env = 'DEV'

-- @dev Reset state while in DEV mode
if not MarketFactory or Env == 'DEV' then MarketFactory = marketFactory:new() end

-- Info
Handlers.add("Info", {Action = "Info"}, function(msg)
  msg.reply({
    Name = Name,
    Version = Version,
    Env = Env
  })
end)

-- Spawn Market
Handlers.add("Spawn-Market", {Action = "Spawn-Market"}, function(msg)
  MarketFactory:spawnMarket(msg)
end)

Handlers.add("Market-Spawned", {Action = "Spawned", From = ao.id}, function(msg)
  MarketFactory:spawnedMarket(msg)
end)

-- Init Market
Handlers.add("Init-Market", {Action = "Init-Market"}, function(msg)
  MarketFactory:initMarket(msg)
end)

-- Markets Pending
Handlers.add("Markets-Pending", {Action = "Markets-Pending"}, function(msg)
  MarketFactory:marketsPending(msg)
end)

-- Markets Initialized
Handlers.add("Markets-Initialized", {Action = "Markets-Initialized"}, function(msg)
  MarketFactory:marketsInitialized(msg)
end)

-- Markets Initialized by Creator
Handlers.add("Markets-Initialized-By-Creator", {Action = "Markets-Initialized-By-Creator"}, function(msg)
  MarketFactory:marketsInitializedByCreator(msg)
end)
