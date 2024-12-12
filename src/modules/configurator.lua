local json = require('json')
local crypto = require('.crypto')
local configuratorNotices = require('modules.configuratorNotices')

local Configurator = {}

-- Add configurator notices
local configuratorMethods = configuratorNotices

-- Constructor for ProcessProvider 
function Configurator:new(env)
  -- Create a new configurator object
  local obj = {
    admin = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',  -- Initial Admin Address
    delay = env == "DEV" and 1 or 3*24*60*60,               -- Initial Update Delay in Seconds (i.e. 1 second or 3 days)
    staged = {},                                            -- Staged Update Timestamps
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
  local hash = crypto.digest.keccak256(process .. action .. tags .. data).asHex()
  -- stage
  self.staged[hash] = os.time()
  -- stage notice
  return self.stageUpdateNotice(process, action, tags, data, hash, self.staged[hash], msg)
end

--[[
    Unstage Update
]]
function configuratorMethods:unstageUpdate(process, action, tags, data, msg)
  local hash = crypto.digest.keccak256(process .. action .. tags.. data).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage
  self.staged[hash] = nil
  -- unstage notice
  return self.unstageUpdateNotice(hash, msg)
end

--[[
    Action Update
]]
function configuratorMethods:actionUpdate(process, action, tags, data, msg)
  local hash = crypto.digest.keccak256(process .. action .. tags .. data).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining <= 0, 'Update not staged long enough! Remaining: ' .. remaining .. 's.')
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
  return self.actionUpdateNotice(hash, msg)
end

--[[
    ADMIN ----------------------------------------------------------------
]]

--[[
    Stage Update: Admin
]]
function configuratorMethods:stageUpdateAdmin(updateAdmin, msg)
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  -- stage
  self.staged[hash] = os.time()
  -- stage notice
  return self.stageUpdateAdminNotice(updateAdmin, hash, self.staged[hash], msg)
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
  return self.unstageUpdateAdminNotice(hash, msg)
end

--[[
    Action Update: Admin
]]
function configuratorMethods:actionUpdateAdmin(updateAdmin, msg)
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
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

--[[
    DELAY TIME ----------------------------------------------------------------
]]

--[[
    Stage Update: DelayTime
]]
function configuratorMethods:stageUpdateDelay(delayInSeconds, msg)
  local hash = crypto.digest.keccak256(tostring(delayInSeconds)).asHex()
  self.staged[hash] = os.time()
  -- stage notice
  return self.stageUpdateDelayNotice(delayInSeconds, hash, self.staged[hash], msg)
end

--[[
    Unstage Update: Delay
]]
function configuratorMethods:unstageUpdateDelay(delayInSeconds, msg)
  local hash = crypto.digest.keccak256(tostring(delayInSeconds)).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  -- unstage
  self.staged[hash] = nil
  -- unstage notice
  return self.unstageUpdateDelayNotice(hash, msg)
end

--[[
    Action Update: Delay
]]
function configuratorMethods:actionUpdateDelay(delayInSeconds, msg)
  local hash = crypto.digest.keccak256(tostring(delayInSeconds)).asHex()
  assert(self.staged[hash], 'Update not staged! Hash: ' .. hash)
  local remaining = self.staged[hash] + self.delay - os.time()
  assert(remaining <= 0, 'Update not staged long enough! Remaining: ' .. remaining .. 's.')
  -- action update
  self.delay = delayInSeconds
  -- unstage
  self.staged[hash] = nil
  -- action notice
  return self.actionUpdateDelayNotice(hash, msg)
end

return Configurator