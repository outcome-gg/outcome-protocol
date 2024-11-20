local bint = require('.bint')(256)
local config = {}

-- General
config.Env = 'DEV'                    -- Set to "PROD" for production, "DEV" to Reset State on each run
config.Version = '1.0.1'              -- Update on each code change
config.Configurator = ''              -- Set to Process ID of Configurator

-- Market Factory
config.MarketFactory = {
  Name = 'MarketFactory-v' .. config.Version,       -- Market Factory versioned name   
  ConditionalTokens = {}                            -- Testing: T34FwrFFGf9HjWT4pGx7VPJkQQqAAQ2m2s1VV3Znvys
}

-- Derived
config.ResetState = config.Env == 'DEV' or false

-- Update Methods
function config.updateConditionalTokens(collateralToken, conditionalTokens)
  config.ConditionalTokens[collateralToken] = conditionalTokens
end

return config
