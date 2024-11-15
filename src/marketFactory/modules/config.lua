local bint = require('.bint')(256)
local config = {}

-- General
config.Env = 'DEV'                    -- Set to "PROD" for production, "DEV" to Reset State on each run
config.Version = '1.0.1'              -- Update on each code change
config.DataIndex = ''                 -- Set to Process ID of Data Index

-- Market Factory
config.MarketFactory = {
  Name = 'MarketFoundry-v' .. config.Version,                       -- Market Factory versioned name   
  Admin = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I',            -- Admin
  ConditionalTokens = 'T34FwrFFGf9HjWT4pGx7VPJkQQqAAQ2m2s1VV3Znvys' -- Conditional Tokens
}

-- Derived
config.ResetState = config.Env == 'DEV' or false

return config
