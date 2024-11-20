local bint = require('.bint')(256)
local Config = {}
local ConfigMethods = {}

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',              -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',        -- Code version
    initialized = false,      -- CPMM Initialization Status
    configurator = '',        -- Configurator process Id
    marketFactory = '',       -- Market Factory process Id
    collateralToken = '',     -- Process ID of Collateral Token 
    conditionalTokens = '',   -- Process ID of Conditional Tokens
    marketId = '',            -- Market ID
    conditionId = '',         -- Condition ID
    feePoolWeight = '0',      -- Fee Pool Weight
    totalWithdrawnFees = '0', -- Total Withdrawn Fees
    withdrawnFees = {},       -- Withdrawn Fees
    collectionIds = {},       -- Collection IDs
    positionIds = {},         -- Position IDs   
    poolBalances = {},        -- Pool Balances
    outomeSlotCount = 2,      -- Outcome Slot Count
  }
  -- Add Token
  local token = {
    name = 'Outcome DAI LP Token 1',  -- LP Token Name
    ticker = 'ODAI-LP-1',             -- LP Token Ticker
    logo = '',                        -- LP Token Logo
    balances = {},                    -- LP Token Balances
    totalSupply = '0',                -- LP Token Total Supply
    denomination = 12                 -- LP Token Denomination
  }
  obj.token = token
  -- Add LP Fee
  local lpFee = {
    Percentage = tostring(bint(bint.__div(bint.__pow(10, obj.token.denomination), 100))), -- Fee Percentage, i.e. 1%
    ONE = tostring(bint(bint.__pow(10, obj.token.denomination)))
  }
  obj.lpFee = lpFee
  -- Add derived metadata
  obj.resetState = obj.env == 'DEV' or false
  -- Set metatable for method lookups
  setmetatable(obj, { __index = ConfigMethods })
  return obj
end

-- Update Methods
function ConfigMethods:updateLpFeePercentage(percentage)
  self.lpFee.percentage = percentage
end

function ConfigMethods:updateLogo(logo)
  self.logo = logo
end

return Config
