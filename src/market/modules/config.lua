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
    collateralToken = '',               -- Collateral Token Process ID
    conditionId = '',                   -- Condition ID
    outomeSlotCount = nil,              -- Outcome Slot Count
    positionIds = {},                   -- Position IDs
    payoutNumerators = {},              -- Payout Numerators, indexded by conditionalId to ensure payouts reported by resolution agent    
    payoutDenominator = {}              -- Payout Denominator, indexded by conditionalId to ensure payouts reported by resolution agent 
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
    name = '',                           -- Conditional Token Name
    ticker = '',                         -- Conditional Token Ticker
    logo = '',                           -- Conditional Token Logo
    balancesById = {},                   -- Conditional Token Balances by ID 
    totalSupplyById = {},                -- Conditional Token TotalSupply by ID
  }
  obj.tokens = tokens
  -- Add LP Fee
  obj.lpFee = 0           -- LP Fee in basis points, e.g. 100 for 1%
  -- Add Take fee
  local takeFee = {
    creatorFee = 0,         -- Creator Fee in basis points, where Max Take Fee (Creator + Protocol) is 1000, i.e. 10%
    creatorFeeTarget = '',  -- Creator Fee Target
    protocolFee = 0,        -- Protocol Fee in basis points, where Max Take Fee (Creator + Protocol) is 1000, i.e. 10%
    protocolFeeTarget = ''  -- Protocol Fee Target
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
