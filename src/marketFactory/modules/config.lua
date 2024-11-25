local Config = {}
local ConfigMethods = {}

local json = require('json')

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',                      -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',                -- Code version
    configurator = '',                -- Configurator process Id
    incentives = '',                  -- Incentives process Id
    lookup = {},                      -- Lookup Table: { [CollateralToken Process Id] = { Name = [CollateralToken Name], Logo = [Collateral LP Token Logo] } }
    counters = {},                    -- Counters Table for TokenIds: { [CollateralToken Process Id] = [Counter Value] }
    delay = 1000 * 60 * 60 * 24 * 3,  -- Delay between update staging and action, in milliseconds, e.g. 3 days
    payoutNumerators = {},            -- Payout Numerators for each outcomeSlot
    payoutDenominator = {}            -- Payout Denominator
  }
  -- Add derived metadata
  obj.resetState = obj.env == 'DEV' or false
  obj.name = 'MarketFactory-v' .. obj.version
  -- Set metatable for method lookups
  setmetatable(obj, { __index = ConfigMethods })
  return obj
end

-- Update Methods
function ConfigMethods:updateLookup(collateralToken, collateralTokenTicker, lpTokenLogo)
  local lookupItem = {
    ticker = collateralTokenTicker,
    logo = lpTokenLogo
  }
  self.lookup[collateralToken] = lookupItem
  return self.lookup[collateralToken]
end

function ConfigMethods:removeLookup(collateralToken)
  assert(self.lookup[collateralToken], 'Collateral Token not found!')
  self.lookup[collateralToken] = nil
end

function ConfigMethods:updateIncentives(incentives)
  self.incentives = incentives
end

function ConfigMethods:updateConfigurator(configurator)
  self.configurator = configurator
end

return Config
