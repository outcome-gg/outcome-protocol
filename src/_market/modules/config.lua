local config = {}

-- General
config.Env = "DEV"                    -- Set to "PROD" for production, "DEV" to Reset State on each run
config.Version = "1.0.1"              -- Update on each code change
config.DataIndex = ""                 -- Set to Process ID of Data Index

-- Order Book
config.DLOB = {
  Name = "DLOB-v" .. config.Version,   -- DLOB versioned name
}

-- Derived
config.ResetState = config.Env == "DEV" or false

return config
