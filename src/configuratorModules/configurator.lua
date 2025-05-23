--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

local Configurator = {}
local ConfiguratorMethods = {}
local ConfiguratorNotices = require('configuratorModules.configuratorNotices')
local sharedUtils = require('configuratorModules.sharedUtils')
local json = require('json')
local crypto = require('.crypto')

-- Default Configurator delay
ConfiguratorDelay = {
  DEV = 3 * 1000,                 -- 3 seconds in milliseconds
  PROD = 3 * 24 * 60 * 60 * 1000, -- 3 days in milliseconds
  MAX = 365 * 24 * 60 * 60 * 1000 -- 365 days in milliseconds
}

--- Represents a Configurator
--- @class Configurator
--- @field admin string The admin process ID
--- @field delay number The update delay in seconds
--- @field Staged table<string, number> A mapping of update hashes to their staged timestamps

--- Creates a new Constructor instance
--- @param admin string The admin process ID
--- @param env string The environment
--- @return Configurator configurator The new Configurator instance
function Configurator.new(admin, env)
  assert(type(admin) == "string", 'Admin process ID is required!')
  assert(sharedUtils.isValidArweaveAddress(admin), 'Admin must be a valid Arweave address!')
  assert(env == "DEV" or env == "PROD", 'Invalid environment! Must be "DEV" or "PROD".')

  local configurator = {
    admin = admin,
    delay = ConfiguratorDelay[env],
    maxDelay = ConfiguratorDelay.MAX,
    staged = {},
  }
  setmetatable(configurator, {
    __index = function(_, k)
      if ConfiguratorMethods[k] then
        return ConfiguratorMethods[k]
      elseif ConfiguratorNotices[k] then
        return ConfiguratorNotices[k]
      end
    end
  })
  return configurator
end

--- Stages an update
--- @param process string The process ID
--- @param action string The action name
--- @param tags string The JSON string of tags
--- @param data string The JSON string of data
--- @param msg Message The message received
--- @return Message The stage update notice
function ConfiguratorMethods:stageUpdate(process, action, tags, data, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(process .. action .. tags .. data).asHex()
  hash = "update" .. hash
  -- stage
  self.staged[hash] = os.time()
  -- stage notice
  return self.stageUpdateNotice(process, action, tags, data, hash, msg)
end

--- Unstages an update
--- @param process string The process ID
--- @param action string The action name
--- @param tags string The JSON string of tags
--- @param data string The JSON string of data
--- @param msg Message The message received
--- @return Message The unstage update notice
function ConfiguratorMethods:unstageUpdate(process, action, tags, data, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(process .. action .. tags.. data).asHex()
  hash = "update" .. hash
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage
  self.staged[hash] = nil
  -- unstage notice
  return self.unstageUpdateNotice(hash, msg)
end

--- Actions an update
--- @param process string The process ID
--- @param action string The action name
--- @param tags string The JSON string of tags
--- @param data string The JSON string of data
--- @param msg Message The message received
--- @return Message The action update notice
function ConfiguratorMethods:actionUpdate(process, action, tags, data, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(process .. action .. tags .. data).asHex()
  hash = "update" .. hash
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining <= 0, 'Update not staged long enough! Remaining: ' .. remaining .. 's.')
  -- action update
  local message = {
    Target = process,
    Action = action,
    Data = data ~= '' and json.decode(data) or nil
  }
  if tags ~= '' then
    for tagName, tagValue in pairs(json.decode(tags)) do
      message[tostring(tagName)] = tostring(tagValue)
    end
  end
  ao.send(message)
  -- unstage
  self.staged[hash] = nil
  -- action notice
  return self.actionUpdateNotice(hash, msg)
end

--- Stages an update for the admin
--- @param updateAdmin string The new admin process ID
--- @param msg Message The message received
--- @return Message The stage update admin notice
function ConfiguratorMethods:stageUpdateAdmin(updateAdmin, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  hash = "updateAdmin" .. hash
  -- stage
  self.staged[hash] = os.time()
  -- stage notice
  return self.stageUpdateAdminNotice(updateAdmin, hash, msg)
end

--- Unstages an update for the admin
--- @param updateAdmin string The new admin process ID
--- @param msg string The message received
--- @return Message The unstage update admin notice
function ConfiguratorMethods:unstageUpdateAdmin(updateAdmin, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  hash = "updateAdmin" .. hash
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage
  self.staged[hash] = nil
  -- unstage notice
  return self.unstageUpdateAdminNotice(hash, msg)
end

--- Actions an update for the admin
--- @param updateAdmin string The new admin process ID
--- @param msg string The message received
--- @return Message The action update admin notice
function ConfiguratorMethods:actionUpdateAdmin(updateAdmin, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  hash = "updateAdmin" .. hash
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining <= 0, 'Update not staged long enough! Remaining: ' .. remaining .. 's.')
  -- action update
  self.admin = updateAdmin
  -- unstage
  self.staged[hash] = nil
  -- action notice
  return self.actionUpdateAdminNotice(hash, msg)
end

--- Stages an update for the delay time
--- @param delayInSeconds number The new delay time in seconds
--- @param msg string The message received
--- @return Message The stage update delay notice
function ConfiguratorMethods:stageUpdateDelay(delayInSeconds, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(tostring(delayInSeconds)).asHex()
  hash = "updateDelay" .. hash
  self.staged[hash] = os.time()
  -- stage notice
  return self.stageUpdateDelayNotice(delayInSeconds, hash, msg)
end

--- Unstages an update for the delay time
--- @param delayInSeconds number The new delay time in seconds
--- @param msg string The message received
--- @return Message The unstage update delay notice
function ConfiguratorMethods:unstageUpdateDelay(delayInSeconds, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(tostring(delayInSeconds)).asHex()
  hash = "updateDelay" .. hash
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage
  self.staged[hash] = nil
  -- unstage notice
  return self.unstageUpdateDelayNotice(hash, msg)
end

--- Actions an update for the delay time
--- @param delayInSeconds number The new delay time in seconds
--- @param msg string The message received
--- @return Message The action update delay notice
function ConfiguratorMethods:actionUpdateDelay(delayInSeconds, msg)
  -- hash with descriminator to prevent collisions
  local hash = crypto.digest.keccak256(tostring(delayInSeconds)).asHex()
  hash = "updateDelay" .. hash
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining <= 0, 'Update not staged long enough! Remaining: ' .. remaining .. 's.')
  -- action update
  self.delay = tonumber(delayInSeconds)
  -- unstage
  self.staged[hash] = nil
  -- action notice
  return self.actionUpdateDelayNotice(hash, msg)
end

return Configurator