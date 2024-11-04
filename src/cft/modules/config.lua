local bint = require('.bint')(256)
local config = {}

-- General
config.Env = 'DEV'                    -- Set to "PROD" for production, "DEV" to Reset State on each run
config.Version = '1.0.1'              -- Update on each code change
config.DataIndex = ''                 -- Set to Process ID of Data Index

-- CFT
config.CFT = {
  Name = 'CFT-v' .. config.Version,   -- Conditional Framework Tokens versioned name
  Ticker = 'CFT',                     -- Ticker symbol
  Denomination = 12,                  -- Default denomination
  Logo = '',                          -- Logo (optional, default to empty string)       
}

-- Take Fee
config.TakeFee = {
  Percentage = tostring(bint(bint.__div(bint.__mul(bint.__pow(10, config.CFT.Denomination), 2.5), 100))), -- Fee Percentage, i.e. 2.5%
  Target = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',                                                 -- Fee Target
  ONE = tostring(bint(bint.__pow(10, config.CFT.Denomination)))                                           -- E.g. 1e12
}

-- Derived
config.ResetState = config.Env == 'DEV' or false

return config
