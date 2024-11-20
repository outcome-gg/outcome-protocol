local crypto = require('.crypto')

Configurator = {}
ConfiguratorMethods = {}

-- Constructor for ProcessProvider 
function Configurator:new(config)
  -- Create a new configurator object
  local obj = {
    admin = '',             -- Admin Address
    delay = config.Delay,   -- Update Delay
    staged = {}             -- Staged Timestamps
  }
  -- Set metatable for method lookups
  setmetatable(obj, { __index = ConfiguratorMethods })
  return obj
end

--[[
    PROTOCOL ----------------------------------------------------------------
]]

--[[
    Stage Update
]]
function Configurator:stageUpdate(process, action, tagName, tagValue)
  local hash = crypto.digest.keccak256(process .. action .. tagName.. tagValue).asHex()
  self.staged[hash] = os.time()
end

--[[
    Unstage Update
]]
function Configurator:unstageUpdate(process, action, tagName, tagValue)
  local hash = crypto.digest.keccak256(process .. action .. tagName.. tagValue).asHex()
  self.staged[hash] = nil
end

--[[
    Action Update
]]
function Configurator:actionUpdate(process, action, tagName, tagValue)
  local hash = crypto.digest.keccak256(process .. action .. tagName .. tagValue).asHex()
  -- check if hash exists
  if not self.staged[hash] then
    return false, 'Update not staged'
  end
  -- check if staged for long enough
  if self.staged[hash] + self.delay < os.time() then
    return false, 'Update not staged long enough'
  end
  -- action update
  ao.send({ Target = process, Action = action, Tags = { tagName = tagValue } }).receive()
  -- unstage
  self.staged[hash] = nil
  return true, ''
end

--[[
    ADMIN ----------------------------------------------------------------
]]

--[[
    Stage Update: Admin
]]
function Configurator:stageUpdateAdmin(updateAdmin)
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  self.staged[hash] = os.time()
end

--[[
    Unstage Update: Admin
]]
function Configurator:unstageUpdateAdmin(updateAdmin)
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  self.staged[hash] = nil
end

--[[
    Action Update: Admin
]]
function Configurator:actionUpdateAdmin(updateAdmin)
  local hash = crypto.digest.keccak256(updateAdmin).asHex()
  -- check if hash exists
  if not self.staged[hash] then
    return false, 'Update not staged'
  end
  -- check if staged for long enough
  if self.staged[hash] + self.delay < os.time() then
    return false, 'Update not staged long enough'
  end
  -- action update
  self.admin = updateAdmin
  -- unstage
  self.staged[hash] = nil
  return true, ''
end

--[[
    DELAY TIME ----------------------------------------------------------------
]]

--[[
    Stage Update: DelayTime
]]
function Configurator:stageUpdateDelayTime(delayInMilliseconds)
  local hash = crypto.digest.keccak256(tostring(delayInMilliseconds)).asHex()
  self.staged[hash] = os.time()
end

--[[
    Unstage Update: DelayTime
]]
function Configurator:unstageUpdateDelayTime(delayInMilliseconds)
  local hash = crypto.digest.keccak256(tostring(delayInMilliseconds)).asHex()
  self.staged[hash] = nil
end

--[[
    Action Update: DelayTime
]]
function Configurator:actionUpdateDelayTime(delayInMilliseconds)
  local hash = crypto.digest.keccak256(tostring(delayInMilliseconds)).asHex()
  -- check if hash exists
  if not self.staged[hash] then
    return false, 'Update not staged'
  end
  -- check if staged for long enough
  if self.staged[hash] + self.delay < os.time() then
    return false, 'Update not staged long enough'
  end
  -- action update
  self.delay = delayInMilliseconds
  -- unstage
  self.staged[hash] = nil
  return true, ''
end

return Configurator