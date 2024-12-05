local Config = {}
local ConfigMethods = {}

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',                                                  -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',                                            -- Code version
    admin = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',        -- Admin process Id
    delay = 5000, -- 1000 * 60 * 60 * 24 * 3                      -- Delay between update staging and action, in milliseconds, e.g. 5 seconds / days
    staged = {}
  }
  -- Add derived metadata
  obj.resetState = obj.env == 'DEV' or false
  -- Set metatable for method lookups
  setmetatable(obj, { __index = ConfigMethods })
  return obj
end

return Config
