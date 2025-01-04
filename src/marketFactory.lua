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

local marketFactory = require('modules.factory')

--[[
==============
MARKET FACTORY
==============
]]

Name = "Outcome Market Factory"
Version = '1.0.1'
Env = 'DEV'

-- @dev Reset state while in DEV mode
if not MarketFactory or Env == 'DEV' then MarketFactory = marketFactory:new() end

--[[
========
MATCHING
========
]]

--- Match on spawn market
--- @param msg Message The message to match
--- @return boolean True if the message is to add funding, false otherwise
local function isSpawnMarket(msg)
  if (
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Spawn-Market"
  ) then
    return true
  else
    return false
  end
end

--[[
============
INFO HANDLER
============
]]

--- Info handler
Handlers.add("Info", {Action = "Info"}, function(msg)
  msg.reply({
    Name = Name,
    Version = Version,
    Env = Env
  })
end)

--[[
=============================
MARKET FACTORY WRITE HANDLERS
=============================
]]

--- Spawn market handler
--- @param msg Message The message to handle
--- @return Message spawnedMarketNotice The spawned market notice
--- @dev replace matching with isSpawnMarket
Handlers.add("Spawn-Market", {Action = "Spawn-Market"}, function(msg)
  -- TODO: Add validation
  local question = msg.Tags.Question
  local resolutionAgent = msg.Tags.ResolutionAgent
  local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
  local creatorFee = tonumber(msg.Tags.CreatorFee)
  local creatorFeeTarget = msg.Tags.CreatorFeeTarget

  return MarketFactory:spawnMarket(question, resolutionAgent, outcomeSlotCount, creatorFee, creatorFeeTarget, msg)
end)

--- Spawned market handler
--- @param msg Message The message to handle
--- @return boolean success True if successful, false otherwise
Handlers.add("Market-Spawned", {Action = "Spawned", From = ao.id}, function(msg)
  return MarketFactory:spawnedMarket(msg)
end)

--- Init market handler
--- @param msg Message The message to handle
--- @return Message marketInitNotice The market init notice
Handlers.add("Init-Market", {Action = "Init-Market"}, function(msg)
  return MarketFactory:initMarket(msg)
end)

--- Markets pending handler
--- @param msg Message The message to handle
--- @return Message marketsPending The markets pending
Handlers.add("Markets-Pending", {Action = "Markets-Pending"}, function(msg)
  return MarketFactory:marketsPending(msg)
end)

--- Markets initialized handler
--- @param msg Message The message to handle
--- @return Message marketsInitialized The markets initialized
Handlers.add("Markets-Init", {Action = "Markets-Init"}, function(msg)
  return MarketFactory:marketsInitialized(msg)
end)

--- Markets initialized by creator handler
--- @param msg Message The message to handle
--- @return Message marketsInitializedByCreator The markets initialized by creator
Handlers.add("Markets-Init-By-Creator", {Action = "Markets-Init-By-Creator"}, function(msg)
  return MarketFactory:marketsInitializedByCreator(msg)
end)

--- Get process ID handler
--- @param msg Message The message to handle
--- @return Message processId The process ID
Handlers.add("Get-Process-Id", {Action = "Get-Process-Id"}, function(msg)
  return MarketFactory:getProcessId(msg)
end)

--- Get latest process ID for creator handler
--- @param msg Message The message to handle
--- @return Message processId The process ID
Handlers.add("Get-Latest-Process-Id-For-Creator", {Action = "Get-Latest-Process-Id-For-Creator"}, function(msg)
  return MarketFactory:getLatestProcessIdForCreator(msg.Tags.Creator, msg)
end)