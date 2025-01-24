
--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See platformData.lua for full license details.
=========================================================
]]

local PlatformDataValidation = {}
local sharedValidation = require('platformDataModules.sharedValidation')
local utils = require('platformDataModules.utils')
local json = require('json')


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
function PlatformDataValidation.validateQuery(readers, msg)
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

--- Validate get market
--- @param msg Message The message received
function PlatformDataValidation.validateGetMarket(msg)
  sharedValidation.validateAddress(msg.Tags.Market, "Market")
end

--- Validate get markets
--- @param msg Message The message received
function PlatformDataValidation.validateGetMarkets(msg)
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

--- Validate updateConfigurator
--- @param msg Message The message received
function PlatformDataValidation.validateUpdateConfigurator(configurator, msg)
  assert(msg.From == configurator, "Sender must be the configurator!")
  sharedValidation.validateAddress(msg.Tags.Configurator, "Configurator")
end

--- Validate updateModerators
--- @param msg Message The message received
function PlatformDataValidation.validateUpdateModerators(configurator, msg)
  assert(msg.From == configurator, "Sender must be the configurator!")
  assert(type(msg.Tags.Moderators) == 'table', "Moderators is required!")
  local moderators = json.decode(msg.tags.Moderators)
  for _, moderator in ipairs(moderators) do
    sharedValidation.validateAddress(moderator, "Moderator")
  end
end

--- Validate updateReaders
--- @param msg Message The message received
function PlatformDataValidation.validateUpdateReaders(configurator, msg)
  assert(msg.From == configurator, "Sender must be the configurator!")
  local readers = json.decode(msg.tags.Readers)
  for _, reader in ipairs(readers) do
    sharedValidation.validateAddress(reader, "Reader")
  end
end

return PlatformDataValidation