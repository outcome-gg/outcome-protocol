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
  sharedValidation.validatePositiveInteger(msg.Tags.Shares, "Shares")
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

--- Validate get markets
--- @param msg Message The message received
function ActivityValidation.validateGetMarkets(msg)
  if msg.Tags.Status then 
    assert(type(msg.Tags.Status) == "string", "Status must be a string!")
    assert(utils.includes(msg.Tags.Status, {"open", "closed", "resolved"}), "Status must be 'open', 'closed', or 'resolved'!")
  end
  if msg.Tags.Collateral then sharedValidation.validateAddress(msg.Tags.Collateral, "Collateral") end
  if msg.Tags.MinFunding then sharedValidation.validatePositiveInteger(msg.Tags.MinFunding, "MinFunding") end
  if msg.Tags.Creator then sharedValidation.validateAddress(msg.Tags.Creator, "Creator") end
  if msg.Tags.Category then assert(type(msg.Tags.Category) == "string", "Category must be a string!") end
  if msg.Tags.Subcategory then assert(type(msg.Tags.Subcategory) == "string", "Subcategory must be a string!") end
  if msg.Tags.Keyword then assert(type(msg.Tags.Keyword) == "string", "Keyword must be a string!") end
  if msg.Tags.Limit then sharedValidation.validatePositiveInteger(msg.Tags.Limit, "Limit") end
  if msg.Tags.Offset then sharedValidation.validatePositiveInteger(msg.Tags.Offset, "Offset") end
  if msg.Tags.OrderBy then
    assert(type(msg.Tags.OrderBy) == "string", "OrderBy must be a string!")
    assert(utils.includes(msg.Tags.OrderBy, {"question", "creator_fee", "funding_amount", "bet_volume", "timestamp"}), "OrderBy must be 'created', 'funding', 'outcomes', or 'volume'!")
  end
  if msg.Tags.OrderDirection then
    assert(type(msg.Tags.OrderDirection) == "string", "OrderDirection must be a string!")
    assert(msg.Tags.OrderDirection == "ASC" or msg.Tags.OrderDirection == "DESC", "OrderDirection must be 'ASC' or 'DESC'!")
  end
end

return ActivityValidation