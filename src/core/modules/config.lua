local config = {}

-- General
config.Env = "DEV"                    -- Set to "PROD" for production, "DEV" to Reset State on each run
config.Version = "1.0.1"              -- Update on each code change
config.DataIndex = ""                 -- Set to Process ID of Data Index

-- Token
config.CFT = {
  Name = "CFT-v" .. config.Version,   -- Conditional Framework Tokens versioned name
  Ticker = "CFT",                     -- Ticker symbol
  Denomination = 12,                  -- Default denomination
  Logo = "",                          -- Logo (optional, default to empty string)
}

-- Derived
config.ResetState = config.Env == "DEV" or false

return config
