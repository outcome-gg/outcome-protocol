Scenarios = { _version = "0.0.1"}

local Outcome = require("outcome")  -- Import the Outcome module
local json = require("json")

--[[
=============
LOG FUNCTIONS
=============
]]

-- Utility function for logging scenario execution
local function logScenarios(isStart, isSuccess)
  local border = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if isStart then
    print("\n" .. border)
    print("🚀 [EXECUTING ALL SCENARIOS]")
    print(border)
  else
    local msg = isSuccess and "✅ [ALL SCENARIOS COMPLETED]" or "❌ [ONE OR MORE SCENARIOS FAILED]"
    print(msg)
    print("\n" .. border)
  end
end

-- Utility function for logging scenario execution
local function logScenario(name, isStart, isSuccess)
  local border = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if isStart then
    print("\n" .. border)
    print("🚀 [SCENARIO START] " .. name)
    print(border)
  else
    local statusIcon = isSuccess and "🏁 ✅" or "🏁 ❌"
      print(statusIcon .. " [SCENARIO COMPLETE] " .. name)
      print(border .. "\n")
  end
end

-- Utility function for logging actions within scenarios
local function logAction(name, details)
  print("  ▶️ [ACTION] " .. name .. ": " .. (details or ""))
end

-- Utility function for logging results of actions
local function logResult(name, details, isSuccess)
  local status = isSuccess and "✅" or "❌"
  local output = details and details ~= "" and details or "N/A"
  print("    " .. status .. " [RESULT] " .. name .. ": 📌 " .. output .. "\n")
end

--[[
==============
HELPERS: ASYNC
==============
]]

--- Retry helper function
local function retry(fn, retries)
  local lastError = nil
  for attempt = 1, retries do
    local result, errorMsg = fn()
    if result then return result end
    lastError = errorMsg or "Unknown error"
    logAction("🔄 Retry", "Attempt " .. tostring(attempt) .. " failed.")
  end
  return nil, lastError
end

-- Tries to get process ID
--- @notice ProcessId is expected to be a non-empty string
local function tryGetProcessId(originalMsgId)
  local res = Outcome.marketFactoryGetProcessId(originalMsgId)
  -- Check if ProcessId is nil or an empty string
  if not res or res.ProcessId:match("^%s*$") or not res.ProcessId then
    return nil, "ProcessId is nil"
  end
  return res
end

--- Tries to init market
--- @notice tries to get process ID first, then initializes the market
local function tryInitMarket(originalMsgId)
  retry(tryGetProcessId, 100)
  local res = Outcome.marketFactoryInitMarket()
  if not res or not res.MarketProcessIds or #res.MarketProcessIds == 0 then
    return nil, "MarketProcessIds is nil or empty"
  end
  return res
end

--[[
==================
HELPERS: SCENARIOS
==================
]]

--- Create a market with the specified number of outcome slots
--- @warning The outcomeSlotCount must be between 2 and 256, inclusive
--- @param outcomeSlotCount number The number of outcome slots
local function createMarket(outcomeSlotCount)
  -- Step 1: Spawn Market
  logAction("Spawn Market", "`outcomeSlotCount` is 2 for binary market")
  local res1 = Outcome.marketFactorySpawnMarket(
    ao.id, -- Resolution Agent
    Outcome.testCollateral, -- Collateral Token
    "What will happen?", -- Question
    outcomeSlotCount, -- Outcome Slot Count
    "Category", -- Category
    "Subcategory", -- Subcategory
    "Logo_TxID", -- Logo
    "Rules", -- Rules
    250, -- Creator Fee
    ao.id -- Creator Fee Target
  )
  local originalMsgId = res1["Original-Msg-Id"]
  -- Error handling
  if originalMsgId == nil then
    logResult("Spawn Market", "Original-Msg-Id is nil", false)
    return
  end
  -- Success
  logResult("Spawn Market", "Original-Msg-Id: " .. originalMsgId, true)

  -- Step 2: Initialize Market
  logAction("Init Market", "Initializing pending markets")
  local res2, error2 = retry(tryInitMarket, 25)
  -- Error handling
  if not res2 or error2 then
    logResult("Init Market", error2, false)
    return
  end
  -- Success
  logResult("Init Market", "MarketProcessIds: " .. json.encode(res2.MarketProcessIds), true)

  -- Step 3: Retrieve Market Process ID
  logAction("Get Market ID", "Get Process ID using Original-Msg-Id")
  local res3, error3 = tryGetProcessId(originalMsgId)
  -- Error handling
  if not res3 or error3 then
    logResult("Get Market ID", error3, false)
    return
  end
  -- Success
  local marketId = res3.ProcessId
  logResult("Get Market ID", "Market ID: " .. marketId, true)

  -- Return the Market ID
  return marketId
end

-- Mint test collateral
--- @note `quantity` is set to 1000, with 12 decimal places
local function mintTestCollateral()
  -- Step 1: Spawn Market
  logAction("Mint Test Collateral", "Mint 100 test collateral tokens, with 12 decimal places")
  local res = Outcome.tokenMint(Outcome.testCollateral, "1000000000000000")
  local quantity = res.Quantity or nil
  -- Error handling
  if not quantity then
    logResult("Mint Test Collateral", "Quantity is nil", false)
    return
  end
  -- Success
  logResult("Mint Test Collateral", "Quantity: " .. quantity, true)
  return quantity
end

--[[
===============================
SCENARIOS: CREATE BINARY MARKET
===============================
]]

-- Create a binary market
--- @note `outcomeSlotCount` is set to 2
function Scenarios.createBinaryMarket()
  logScenario("Create Binary Market", true)
  local marketId = createMarket(2)
  logScenario("Create Binary Market", false, marketId)
  return marketId
end

--[[
====================================
SCENARIOS: CREATE CATEGORICAL MARKET
====================================
]]

-- Create a categorical market
--- @note `outcomeSlotCount` is set to 3
function Scenarios.createCategoricalMarket()
  logScenario("Create Categorical Market", true)
  local marketId = createMarket(3)
  logScenario("Create Categorical Market", false, marketId)
  return marketId
end

--[[
==========================================
SCENARIOS: CREATE LARGE CATEGORICAL MARKET
==========================================
]]

--- Create a large categorical market
--- @note `outcomeSlotCount` is set to 256
function Scenarios.createLargeCategoricalMarket()
  logScenario("Create Large Categorical Market", true)
  local marketId = createMarket(256)
  logScenario("Create Large Categorical Market", false, marketId)
  return marketId
end

--[[
===============================
SCENARIOS: MINT TEST COLLATERAL
===============================
]]

-- Mint test collateral
--- @note `quantity` is set to 1000, with 12 decimal places
function Scenarios.mintTestCollateral()
  logScenario("Mint Test Collateral", true)
  local quantity = mintTestCollateral()
  logScenario("Mint Test Collateral", false, quantity)
  return quantity
end

--[[
=========================================================
SCENARIOS: SET PROBABILITY DISTRIBUITON FOR BINARY MARKET
=========================================================
]]

-- -- Create a binary market
-- --- @note `outcomeSlotCount` is set to 2
-- function Scenarios.setProbabilityDistributionForBinaryMarket()
--   local marketId = Scenarios.createBinaryMarket()
--   local res = Outcome.marketAddFunding(market, )
--   return marketId
-- end

--[[
==============================
SCENARIO REGISTRY: IDENTIFIERS
==============================
]]

-- Enum-like table for scenario identifiers
Scenarios.ScenarioIDs = {
  CREATE_BINARY_MARKET = 1,
  CREATE_CATEGORICAL_MARKET = 2,
  CREATE_LARGE_CATEGORICAL_MARKET = 3,
  MINT_TEST_COLLATERAL = 4,
}

--[[
==================================
SCENARIO REGISTRY: EXECUTION TABLE
==================================
]]

-- Register scenarios for easy execution
Scenarios.scenarios = {
  [Scenarios.ScenarioIDs.CREATE_BINARY_MARKET] = { name = "Create Binary Market", func = Scenarios.createBinaryMarket },
  [Scenarios.ScenarioIDs.CREATE_CATEGORICAL_MARKET] = { name = "Create Categorical Market", func = Scenarios.createCategoricalMarket },
  [Scenarios.ScenarioIDs.CREATE_LARGE_CATEGORICAL_MARKET] = { name = "Create Large Categorical Market", func = Scenarios.createLargeCategoricalMarket },
  [Scenarios.ScenarioIDs.MINT_TEST_COLLATERAL] = { name = "Mint Test Collateral", func = Scenarios.mintTestCollateral },
}

--[[
==========
MAIN: HELP
==========
]]

-- Function to list available scenarios
function Scenarios.help()
  print("\n📖 Available Scenarios:")
  for id, scenario in pairs(Scenarios.scenarios) do
    print("- " .. id .. ": " .. scenario.name)
  end
end

--[[
==============
MAIN: RUN(...)
==============
]]

--- Run one or more scenarios by ID
--- @param ... number|number[] The scenario ID or IDs to run
function Scenarios.run(...)
  local ids = {...}
  local results = {}
  for i = 1, #ids do
    local id = tonumber(ids[i])
    local scenario = Scenarios.scenarios[id]
    if scenario then
      local result = scenario.func()
      results[i] = result
    else
      print("[ERROR] Scenario ID '" .. tostring(id) .. "' not found.")
      Scenarios.help()
    end
  end
  return results
end

--[[
=============
MAIN: RUN ALL
=============
]]

-- Function to run all scenarios
function Scenarios.runAll()
  logScenarios(true)
  local allSuccess = true
  for _, scenario in pairs(Scenarios.scenarios) do
    local success = scenario.func()
    if not success then
      allSuccess = false
      logScenarios(false, false)
      return
    end
  end
  logScenarios(false, allSuccess)
end

return Scenarios
