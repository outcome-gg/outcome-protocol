local json = require('json')
local crypto = require('.crypto')
local config = require('modules.config')
local configuratorNotices = require('modules.configuratorNotices')

local Configurator = {}

-- Add configurator notices
local configuratorMethods = configuratorNotices

-- Constructor for ProcessProvider 
function Configurator:new()
  local Config = config:new()
  -- Create a new configurator object
  local obj = {
    admin = Config.admin,     -- Admin Address
    delay = Config.delay,     -- Update Delay
    staged = Config.staged,    -- Staged Timestamps
    foo = 12
  }
  -- Set metatable for method lookups
  setmetatable(obj, { __index = configuratorMethods })
  return obj
end

--[[
    PROTOCOL ----------------------------------------------------------------
]]

--[[
    Stage Update
]]
function configuratorMethods:stageUpdate(process, action, tags, data, msg)
  local hash = tostring(crypto.digest.keccak256(process .. action .. tags .. data).asHex())
  -- stage
  self.staged[hash] = os.time()
  -- stage notice
  self.stageUpdateNotice(process, action, tags, data, hash, self.staged[hash], msg)
end

--[[
    Unstage Update
]]
function configuratorMethods:unstageUpdate(process, action, tags, data, msg)
  local hash = tostring(crypto.digest.keccak256(process .. action .. tags.. data).asHex())
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage
  self.staged[hash] = nil
  -- unstage notice
  self.unstageUpdateNotice(hash, msg)
end

--[[
    Action Update
]]
function configuratorMethods:actionUpdate(process, action, tags, data, msg)
  local hash = crypto.digest.keccak256(process .. action .. tags .. data).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining < 0, 'Update not staged long enough! Remaining: ' .. remaining .. ' ms')
  -- action update
  local message = {
    Target = process,
    Action = action,
    Data = data ~= '' and json.decode(data) or nil
  }
  for tagName, tagValue in pairs(json.decode(tags)) do
    message[tagName] = tagValue
  end
  ao.send(message)
  -- unstage
  self.staged[hash] = nil
  -- action notice
  self.actionUpdateNotice(hash, msg)
end

--[[
    ADMIN ----------------------------------------------------------------
]]

--[[
    Stage Update: Admin
]]
function configuratorMethods:stageUpdateAdmin(updateAdmin, msg)
  local hash = tostring(crypto.digest.keccak256(updateAdmin).asHex())
  -- stage
  self.staged[hash] = os.time()
  -- stage notice
  self.stageUpdateAdminNotice(updateAdmin, hash, self.staged[hash], msg)
end

--[[
    Unstage Update: Admin
]]
function configuratorMethods:unstageUpdateAdmin(updateAdmin, msg)
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage 
  self.staged[hash] = nil
  -- unstage notice
  self.unstageUpdateAdminNotice(hash, msg)
end

--[[
    Action Update: Admin
]]
function configuratorMethods:actionUpdateAdmin(updateAdmin, msg)
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining < 0, 'Update not staged long enough! Remaining: ' .. remaining .. ' ms')
  -- action update
  self.admin = updateAdmin
  -- unstage
  self.staged[hash] = nil
  -- action notice
  self.actionUpdateAdminNotice(hash, msg)
end

--[[
    DELAY TIME ----------------------------------------------------------------
]]

--[[
    Stage Update: DelayTime
]]
function configuratorMethods:stageUpdateDelay(delayInMilliseconds, msg)
  local hash = crypto.digest.keccak256(tostring(delayInMilliseconds)).asHex()
  self.staged[hash] = os.time()
  -- stage notice
  self.stageUpdateDelayNotice(delayInMilliseconds, hash, self.staged[hash], msg)
end

--[[
    Unstage Update: Delay
]]
function configuratorMethods:unstageUpdateDelay(delayInMilliseconds, msg)
  local hash = crypto.digest.keccak256(tostring(delayInMilliseconds)).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage
  self.staged[hash] = nil
  -- unstage notice
  self.unstageUpdateDelayNotice(hash, msg)
end

--[[
    Action Update: Delay
]]
function configuratorMethods:actionUpdateDelay(delayInMilliseconds, msg)
  local hash = crypto.digest.keccak256(tostring(delayInMilliseconds)).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining < 0, 'Update not staged long enough! Remaining: ' .. remaining .. ' ms')
  -- action update
  self.delay = delayInMilliseconds
  -- unstage
  self.staged[hash] = nil
  -- action notice
  self.actionUpdateDelayNotice(hash, msg)
end

return Configurator