local bint = require('.bint')(256)
local Config = {}
local ConfigMethods = {}

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',                      -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',                -- Code version
    incentives = '',                  -- Incentives process Id
    configurator = '',                -- Configurator process Id
    collateralToken = ''              -- Approved Collateral Token
  }
  -- Add CPMM
  local cpmm = {
    marketFactory = '',       -- Market Factory process Id
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
  obj.cpmm = cpmm
  -- Add LP Token
  local token = {
    name = '',                -- LP Token Name
    ticker = '',              -- LP Token Ticker
    logo = '',                -- LP Token Logo
    balances = {},            -- LP Token Balances
    totalSupply = '0',        -- LP Token Total Supply
    denomination = 12         -- LP Token Denomination
  }
  obj.token = token
  -- Add Conditional Tokens
  local tokens = {
    name = 'Outcome DAI Conditional Tokens',  -- Collateral-specific Name
    ticker = 'CDAI',                          -- Collateral-specific Ticker
    logo = '',                                -- Logo
    balancesById = {},                        -- Balances by id 
    totalSupplyById = {},                     -- TotalSupply by id
    denomination = 12                         -- Denomination
  }
  obj.tokens = tokens
  -- Add LP Fee
  local lpFee = {
    Percentage = tostring(bint(bint.__div(bint.__pow(10, obj.token.denomination), 100))), -- Fee Percentage, i.e. 1%
    ONE = tostring(bint(bint.__pow(10, obj.token.denomination)))
  }
  obj.lpFee = lpFee
  -- Add Take fee
  local takeFee = {
    percentage = tostring(bint(bint.__div(bint.__mul(bint.__pow(10, obj.tokens.denomination), 2.5), 100))), -- Fee Percentage, i.e. 2.5%
    target = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',                                          -- Fee Target
    ONE = tostring(bint(bint.__pow(10, obj.tokens.denomination)))
  }
  obj.takeFee = takeFee
  -- Add derived metadata
  obj.resetState = obj.env == 'DEV' or false
  -- Set metatable for method lookups
  setmetatable(obj, { __index = ConfigMethods })
  return obj
end

-- Update Methods
function ConfigMethods:updateTakeFeePercentage(percentage)
  self.takeFee.percentage = percentage
end

function ConfigMethods:updateTakeFeeTarget(target)
  self.takeFee.target = target
end

function ConfigMethods:updateName(name)
  self.name = name
end

function ConfigMethods:updateTicker(ticker)
  self.ticker = ticker
end

function ConfigMethods:updateLogo(logo)
  self.logo = logo
end

function ConfigMethods:updateIncentives(incentives)
  self.incentives = incentives
end

function ConfigMethods:updateConfigurator(configurator)
  self.configurator = configurator
end

return Config
