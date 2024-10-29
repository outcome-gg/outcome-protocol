local bint = require('.bint')(256)

local config = {}

-- General
config.Env = "DEV"                    -- Set to "PROD" for production, "DEV" to Reset State on each run
config.Version = "1.0.1"              -- Update on each code change
config.DataIndex = ""                 -- Set to Process ID of Data Index

-- Market
config.Creator = ''                   -- Process ID of the Market Creator

-- LP Token
config.LPToken = {
  Name = 'AMM-v' .. config.Version,                     -- LPToken versioned name
  Ticker = 'OUTCOME-LP-v' .. config.Version,            -- LPToken Ticker
  Logo = 'SBCCXwwecBlDqRLUjb8dYABExTJXLieawf7m2aBJ-KY', -- LPToken Logo
  Balances = {},                                        -- LPToken Balances
  TotalSupply = '0',                                    -- LPToken Total Supply
  Denomination = 12                                     -- LPToken Denomination
}

-- AMM
config.AMM = {
  Initialized = false,                                                                -- AMM Initialization Status
  CollateralToken = '',                                                               -- Process ID of Collateral Token 
  ConditionalTokens = '',                                                             -- Process ID of Conditional Tokens
  ConditionId = '',                                                                   -- Condition ID
  Fee = tostring(bint(bint.__div(bint.__pow(10, config.LPToken.Denomination), 100))), -- Fee Percentage, i.e. 1%
  FeePoolWeight = '0',                                                                  -- Fee Pool Weight
  TotalWithdrawnFees = '0',                                                             -- Total Withdrawn Fees
  WithdrawnFees = {},                                                                 -- Withdrawn Fees
  OutomeSlotCounts = {},                                                              -- Outcome Slot Counts
  CollectionIds = {},                                                                 -- Collection IDs
  PositionIds = {},                                                                   -- Position IDs
  PoolBalances = {},                                                                  -- Pool Balances
  ONE = tostring(bint.__pow(10, config.LPToken.Denomination))                         -- E.g. 1e12
}

-- Derived
config.ResetState = config.Env == "DEV" or false -- Used to reset state for integration tests

return config
