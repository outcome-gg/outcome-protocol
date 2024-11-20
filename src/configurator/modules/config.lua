local Config = {}
local ConfigMethods = {}

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',                    -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',              -- Code version
    configurator = '',              -- Configurator process Id
    delay = 1000 * 60 * 60 * 24 * 3 -- Delay between update staging and action, in milliseconds, e.g. 3 days
  }
  -- Add derived metadata
  obj.resetState = obj.env == 'DEV' or false
  -- Set metatable for method lookups
  setmetatable(obj, { __index = ConfigMethods })
  return obj
end

-- Update Methods
function ConfigMethods:updateDelay(delayInMilliseconds)
  self.Configurator.Delay = delayInMilliseconds
end

return Config
