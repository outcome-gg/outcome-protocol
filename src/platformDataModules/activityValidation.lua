--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See activity.lua for full license details.
=========================================================
]]

local ActivityValidation = {}
local sharedValidation = require('platformDataModules.sharedValidation')
local sharedUtils = require('platformDataModules.sharedUtils')
local utils = require('platformDataModules.utils')
local json = require('json')

--- Validate log market
--- @param msg Message The message received
function ActivityValidation.validateLogMarket(msg)
  sharedValidation.validateAddress(msg.Tags.Market, "Market")
  sharedValidation.validateAddress(msg.Tags.Creator, "Creator")
  sharedValidation.validatePositiveIntegerOrZero(msg.Tags.CreatorFee, "CreatorFee")
  sharedValidation.validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
  sharedValidation.validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
  sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral")
  sharedValidation.validateAddress(msg.Tags.ResolutionAgent, "ResolutionAgent")
  assert(type(msg.Tags.Category) == "string", "Category is required!")
  assert(type(msg.Tags.Subcategory) == "string", "Subcategory is required!")
  assert(type(msg.Tags.Logo) == "string", "Logo is required!")
end

--- Validate log funding
--- @param msg Message The message received
function ActivityValidation.validateLogFunding(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
  sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral")
  assert(type(msg.Tags.Operation) == "string", "Operation is required!")
  assert(msg.Tags.Operation == "add" or msg.Tags.Operation == "remove", "Operation must be 'add' or 'remove'!")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
end

--- Validate log prediction
--- @param msg Message The message received
function ActivityValidation.validateLogPrediction(msg)
  sharedValidation.validateAddress(msg.Tags.User, "User")
  sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral")
  assert(type(msg.Tags.Operation) == "string", "Operation is required!")
  assert(msg.Tags.Operation == "buy" or msg.Tags.Operation == "sell", "Operation must be 'buy' or 'sell'!")
  sharedValidation.validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  sharedValidation.validatePositiveInteger(msg.Tags.Outcome, "Outcome")
  sharedValidation.validatePositiveNumber(msg.Tags.Price, "Price")
end

--- Validate log probabilities
--- @param msg Message The message received
function ActivityValidation.validateLogProbabilities(msg)
  assert(type(msg.Tags.Probabilities) == "string", "Probabilities is required!")
  assert(sharedUtils.isValidKeyValueJSON(msg.Tags.Probabilities), "Probabilities must be valid JSON!")
end

local function normalize_query(query)
  -- Remove comments (both single-line -- and multi-line /* */)
  query = query:gsub("%-%-.-\n", "")  -- Remove single-line comments
  query = query:gsub("/%*.-%*/", "")  -- Remove multi-line comments
  -- Collapse multiple spaces into one
  query = query:gsub("%s+", " ")
  -- Trim leading and trailing spaces
  query = query:match("^%s*(.-)%s*$")
  -- Convert to lowercase
  query = query:lower()
  return query
end

--- Validate query
--- @param msg Message The message received
--- @param readers table<string> The list of approved readers
--- @return string The normalized SQL query
function ActivityValidation.validateQuery(readers, msg)
  assert(utils.includes(msg.From, readers), "Sender must be reader!")
  local sql = tostring(msg.Data)
  assert(sql and type(sql) == "string", "SQL query is required!")
  -- normalize query to remove comments and spaces
  sql = normalize_query(sql)
  -- check for forbidden keywords
  local forbiddenKeywords = {"DELETE", "DROP", "TRUNCATE", "ALTER", "CREATE", "INSERT", "UPDATE"}
  for _, keyword in ipairs(forbiddenKeywords) do
    assert(not sql:upper():match(keyword), "Forbidden keyword found in query!")
  end
  return sql
end

return ActivityValidation