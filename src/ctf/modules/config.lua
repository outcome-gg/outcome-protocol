local bint = require('.bint')(256)
local Config = {}
local ConfigMethods = {}

-- Constructor for Config 
function Config:new()
  -- Create a new config object
  local obj = {
    env = 'DEV',                      -- Set to "PROD" for production, "DEV" to Reset State on each run
    version = '1.0.1',                -- Code version
    configurator = '',                -- Configurator process Id
    collateralToken = ''              -- Approved Collateral Token
  }
  -- Add Tokens
  local tokens = {
    name = 'Outcome DAI Conditional Tokens',  -- Collateral-specific Name
    ticker = 'CDAI',                          -- Collateral-specific Ticker
    logo = '',                                -- Logo
    balances = {},                            -- Balances by id 
    totalSupply = {},                         -- TotalSupply by id
    denomination = 12                         -- Denomination
  }
  obj.tokens = tokens
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

return Config
