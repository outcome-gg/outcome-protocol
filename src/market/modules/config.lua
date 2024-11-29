local bint = require('.bint')(256)
local Config = {}
local ConfigMethods = {}

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',                      -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',                -- Code version
    incentives = '',                  -- Process ID of Incentives
    configurator = '',                -- Process ID of Configurator 
    marketFactory = '',               -- Process ID of Market Factory
    marketId = '',                    -- Market ID
    initialized = false               -- Initialized
  }
  -- Add CPMM
  local cpmm = {
    poolBalances = {},        -- Pool Balances
    withdrawnFees = {},       -- Withdrawn Fees
    totalWithdrawnFees = '0', -- Total Withdrawn Fees
    feePoolWeight = '0',      -- Fee Pool Weight
  }
  obj.cpmm = cpmm
  -- add CTF
  local ctf = {
    collateralToken = '',     -- Process ID of Collateral Tokens
    conditionId = '',         -- Condition ID
    outomeSlotCount = nil,    -- Outcome Slot Count
    positionIds = {},         -- Position IDs
    payoutNumerators = {},    -- Payout Numerators, indexded by conditionalId to ensure payouts reported by resolution agent    
    payoutDenominator = {}    -- Payout Denominator, indexded by conditionalId to ensure payouts reported by resolution agent 
  }
  obj.ctf = ctf
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
    percentage = tostring(bint(bint.__div(bint.__pow(10, obj.token.denomination), 100))), -- Fee Percentage, i.e. 1%
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
