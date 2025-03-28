--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and exclusively controlled by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, reproduction, modification, or distribution of this code is strictly
prohibited without explicit written permission from Outcome.

By using this software, you agree to the Outcome Terms of Service:
https://outcome.gg/tos
======================================================================================
]]

Outcome = { _version = "0.0.1"}
Outcome.__index = Outcome
Outcome.configurator = "XZrrfWA17ljL8msjXvG3kYx2mo5odhlgJJ8bWo6lxwo"
Outcome.marketFactory = "l9l7DorUAeRQ5KYmg1Kh3ZfBwQBIqVHbVl2hnBGG9Tc"
Outcome.token = "haUOiKKmYMGum59nWZx5TVFEkDgI5LakIEY7jgfQgAI"
Outcome.testCollateral = "jAyJBNpuSXmhn9lMMfwDR60TfIPANXI6r-f3n9zucYU"

local sharedUtils = require('configuratorModules.sharedUtils')
local json = require('json')

--- @class Outcome
--- @field _version string The Outcome package version
--- @field configurator string The Outcome configurator process ID
--- @field marketFactory string The Outcome market factory process ID
--- @field token string The Outcome utility token process ID
--- @field testCollateral string Outcome test collateral token process ID

--- @class BaseMessage
--- @field MessageId string The message ID
--- @field Timestamp number The timestamp of the message
--- @field Block-Height number The block height of the message

--- @class BaseNotice: BaseMessage
--- @field Action string The action name

--[[
================
INPUT VALIDATION
================
]]

--- Validates a valid Arweave address
--- @param value string The value to validate
--- @param name string The name of the value
local function validateValidArweaveAddress(value, name)
  assert(value, string.format("`%s` is required.", name))
  assert(sharedUtils.isValidArweaveAddress(value), string.format("`%s` must be a valid Arweave address (43-character base64url string).", name))
end

--- Validates a positive number or zero
--- @param value string The value to validate
--- @param name string The name of the value
local function validatePositiveNumberOrZero(value, name)
  assert(type(value) == "string", string.format("`%s` must be a string.", name))
  assert(tonumber(value), string.format("`%s` must be a number.", name))
  assert(tonumber(value) >= 0, string.format("`%s` must be greater than or equal to zero.", name))
end

--- Validates a positive number greater than zero
--- @param value string The value to validate
--- @param name string The name of the value
local function validatePositiveNumberGreaterThanZero(value, name)
  validatePositiveNumberOrZero(value, name)
  assert(tonumber(value) > 0, string.format("`%s` must be greater than zero.", name))
end

--- Validates a positive integer or zero
--- @param value string The value to validate
--- @param name string The name of the value
local function validatePositiveIntegerOrZero(value, name)
  validatePositiveNumberOrZero(value, name)
  assert(tonumber(value) % 1 == 0, string.format("`%s` must be an integer.", name))
end

--- Validates a positive integer greater than zero
--- @param value string The value to validate
--- @param name string The name of the value
local function validatePositiveIntegerGreaterThanZero(value, name)
  validatePositiveNumberGreaterThanZero(value, name)
  assert(tonumber(value) % 1 == 0, string.format("`%s` must be an integer.", name))
end

--- Validates a non-empty numeric table
--- @note The table must have a total sum greater than zero
--- @param value table The value to validate
--- @param name string The name of the table
local function validateNonEmptyNumericTable(value, name)
  assert(type(value) == "table", string.format("`%s` must be a table.", name))
  local sum = 0
  for _, v in pairs(value) do
    assert(tonumber(v), string.format("`%s` values must be numbers.", name))
    assert(tonumber(v) >= 0, string.format("`%s`values must be greater than or equal to zero.", name))
    sum = sum + tonumber(v)
  end
  assert(sum > 0, string.format("`%s` must have a total sum greater than zero.", name))
end

--- Validates a non-empty positive integer table
--- @param value table The value to validate
--- @param name string The name of the table
local function validatePositiveIntegerTable(value, name)
  assert(type(value) == "table", string.format("`%s` must be a table.", name))
  for _, v in pairs(value) do
    assert(tonumber(v), string.format("`%s` values must be numbers.", name))
    assert(tonumber(v) % 1 == 0, string.format("`%s` values must be integers.", name))
    assert(tonumber(v) > 0, string.format("`%s`values must be greater than to zero.", name))
  end
end

--- Validates a table of valid Arweave addresses
--- @param value table The value to validate
--- @param name string The name of the table
local function validateArweaveAddressTable(value, name)
  assert(type(value) == "table", string.format("`%s` must be a table.", name))
  for _, v in pairs(value) do
    assert(sharedUtils.isValidArweaveAddress(v), string.format("`%s` values must be valid Arweave addresses.", name))
  end
end

--- Validates a table of valid Arweave addresses to numbers
--- @param value table The table to validate
--- @param name string The name of the table
local function validateArweaveToNumberMap(value, name)
  assert(type(value) == "table", string.format("`%s` must be a table.", name))
  for k, v in pairs(value) do
    assert(sharedUtils.isValidArweaveAddress(k), string.format("`%s` keys must be valid Arweave addresses.", name))
    assert(tonumber(v), string.format("`%s` values must be numbers.", name))
  end
end

--- Validates a table of valid Arweave addresses to positive numbers
--- @param value table The table to validate
--- @param name string The name of the table
local function validateArweaveToPositiveNumberMap(value, name)
  assert(type(value) == "table", string.format("`%s` must be a table.", name))
  for k, v in pairs(value) do
    assert(sharedUtils.isValidArweaveAddress(k), string.format("`%s` keys must be valid Arweave addresses.", name))
    assert(tonumber(v), string.format("`%s` values must be numbers.", name))
    assert(tonumber(v) > 0, string.format("`%s` values must be greater than zero.", name))
  end
end

--- Validates a table of valid Arweave addresses to positive integers
--- @param value table The value to validate
--- @param name string The name of the table
local function validateArweaveToPositiveIntegerMap(value, name)
  assert(type(value) == "table", string.format("`%s` must be a table.", name))
  for k, v in pairs(value) do
    assert(sharedUtils.isValidArweaveAddress(k), string.format("`%s` keys must be valid Arweave addresses.", name))
    assert(tonumber(v), string.format("`%s` values must be numbers.", name))
    assert(tonumber(v) % 1 == 0, string.format("`%s` values must be integers.", name))
    assert(tonumber(v) > 0, string.format("`%s` values must be greater than zero.", name))
  end
end

--- Validates a table of strings to non-nil values
--- @param value table The table to validate
--- @param name string The name of the table
local function validateKeyValueTable(value, name)
  assert(value, string.format("`%s` is required.", name))
  assert(type(value) == "table", string.format("`%s` must be a table.", name))
  assert(next(value), string.format("`%s` must not be empty.", name))

  for k, v in pairs(value) do
    assert(type(k) == "string", string.format("All keys in `%s` must be strings.", name))
    assert(v ~= nil, string.format("All values in `%s` must not be nil.", name))
  end
end

--[[
====
INFO
====
]]

--- @class OutcomeInfo
--- @field Version string The Outcome package version
--- @field Configurator string The Outcome configurator process ID
--- @field MarketFactory string The Outcome market factory process ID
--- @field Token string The Outcome utility token process ID
--- @field TestCollateral string The Outcome test collateral process ID

--- Info
--- @return OutcomeInfo The Outcome package info
function Outcome.info()
  return {
    Version = Outcome._version,
    Configurator = Outcome.configurator,
    MarketFactory = Outcome.marketFactory,
    Token = Outcome.token,
    TestCollateral = Outcome.testCollateral
  }
end

--[[
==================
CONFIGURATOR: INFO
==================
]]

---@class ConfiguratorInfo: BaseMessage
---@field Admin string The configurator admin process ID
---@field Delay number The update delay in seconds
---@field Staged table<string, number> A mapping of update hashes to their staged timestamps

--- Configurator info
--- @return ConfiguratorInfo The configurator info
function Outcome.configuratorInfo()
  -- Send and receive response
  local info = ao.send({
    Target = Outcome.configurator,
    Action = "Info"
  }).receive()
  -- Return formatted response
  return {
    Admin = info.Tags.Admin,
    Delay = tonumber(info.Tags.Delay),
    Staged = json.decode(info.Tags.Staged),
    MessageId = info.Id,
    Timestamp = info.Timestamp,
    ["Block-Height"] = info["Block-Height"]
  }
end

--[[
===================
CONFIGURATOR: WRITE
===================
]]

--- @class ConfiguratorStageUpdateNotice: BaseNotice
--- @field Discriminator string The discriminator
--- @field UpdateProcess string The process to update
--- @field UpdateAction string The update message action
--- @field UpdateTags string The update message tags
--- @field UpdateData string The update message data
--- @field Hash string The hash of the staged update

--- Configurator stage update
--- @warning Only callable by the configurator admin, else the transaction will fail
--- @param discriminator string The discriminator
--- @param updateProcess string The process to update
--- @param updateAction string The update message action
--- @param updateTags table|nil The update message tags or `nil`
--- @param updateData table|nil The update message data or `nil`
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Stage-Update-Notice`: **configurator → ao.id** -- Logs the stage update action
--- @return ConfiguratorStageUpdateNotice The configurator stage update notice
function Outcome.configuratorStageUpdate(discriminator, updateProcess, updateAction, updateTags, updateData)
  -- Validate input
  assert(discriminator, "`discriminator` is required.")
  assert(type(discriminator) == "string", "`discriminator` must be a string.")
  assert(updateProcess, "`updateProcess` is required.")
  assert(sharedUtils.isValidArweaveAddress(updateProcess), "`updateProcess` must be a valid Arweave address.")
  assert(updateAction, "`updateAction` is required.")
  assert(type(updateAction) == "string", "`updateAction` must be a string.")
  if updateTags then validateKeyValueTable(updateTags, "updateTags") end
  if updateData then validateKeyValueTable(updateData, "updateData") end
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Stage-Update",
    Discriminator = discriminator,
    UpdateProcess = updateProcess,
    UpdateAction = updateAction,
    ---@diagnostic disable-next-line: assign-type-mismatch
    UpdateTags = updateTags and json.encode(updateTags) or nil,
    ---@diagnostic disable-next-line: assign-type-mismatch
    UpdateData = updateData and json.encode(updateData) or nil
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Descriminator = notice.Tags.Descriminator,
    UpdateProcess = notice.Tags.UpdateProcess,
    UpdateAction = notice.Tags.UpdateAction,
    UpdateTags = notice.Tags.UpdateTags,
    UpdateData = notice.Tags.UpdateData,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorUnstageUpdateNotice: BaseNotice
--- @field Hash string The hash of the staged update

--- Configurator unstage update
--- @warning Only callable by the configurator admin, else the transaction will fail
--- @warning Update must be staged, else the transaction will fail
--- @param discriminator string The discriminator
--- @param updateProcess string The process to update
--- @param updateAction string The update message action
--- @param updateTags table|nil The update message tags or `nil`
--- @param updateData table|nil The update message data or `nil`
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Unstage-Update-Notice`: **configurator → ao.id** -- Logs the unstage update action
--- @return ConfiguratorUnstageUpdateNotice The configurator unstage update notice
function Outcome.configuratorUnstageUpdate(discriminator, updateProcess, updateAction, updateTags, updateData)
  -- Validate input
  assert(discriminator, "`discriminator` is required.")
  assert(type(discriminator) == "string", "`discriminator` must be a string.")
  assert(updateProcess, "`updateProcess` is required.")
  assert(sharedUtils.isValidArweaveAddress(updateProcess), "`updateProcess` must be a valid Arweave address.")
  assert(updateAction, "`updateAction` is required.")
  assert(type(updateAction) == "string", "`updateAction` must be a string.")
  if updateTags then validateKeyValueTable(updateTags, "updateTags") end
  if updateData then validateKeyValueTable(updateData, "updateData") end
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Unstage-Update",
    Discriminator = discriminator,
    UpdateProcess = updateProcess,
    UpdateAction = updateAction,
    ---@diagnostic disable-next-line: assign-type-mismatch
    UpdateTags = updateTags and json.encode(updateTags) or nil,
    ---@diagnostic disable-next-line: assign-type-mismatch
    UpdateData = updateData and json.encode(updateData) or nil
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorActionUpdateNotice: BaseNotice
--- @field Hash string The hash of the staged update

--- Configurator action update
--- @warning Only callable by the configurator admin, else the transaction will fail
--- @warning Update must have been staged for at least the delay period; otherwise, the transaction will fail
--- @param discriminator string The discriminator
--- @param updateProcess string The process to update
--- @param updateAction string The update message action
--- @param updateTags table|nil The update message tags or `nil`
--- @param updateData table|nil The update message data or `nil`
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Action-Update-Notice`: **configurator → ao.id** -- Logs the action update action
--- @return ConfiguratorActionUpdateNotice The configurator action update notice
function Outcome.configuratorActionUpdate(discriminator, updateProcess, updateAction, updateTags, updateData)
  -- Validate input
  assert(discriminator, "`discriminator` is required.")
  assert(type(discriminator) == "string", "`discriminator` must be a string.")
  assert(updateProcess, "`updateProcess` is required.")
  assert(sharedUtils.isValidArweaveAddress(updateProcess), "`updateProcess` must be a valid Arweave address.")
  assert(updateAction, "`updateAction` is required.")
  assert(type(updateAction) == "string", "`updateAction` must be a string.")
  if updateTags then validateKeyValueTable(updateTags, "updateTags") end
  if updateData then validateKeyValueTable(updateData, "updateData") end
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Action-Update",
    Discriminator = discriminator,
    UpdateProcess = updateProcess,
    UpdateAction = updateAction,
    ---@diagnostic disable-next-line: assign-type-mismatch
    UpdateTags = updateTags and json.encode(updateTags) or nil,
    ---@diagnostic disable-next-line: assign-type-mismatch
    UpdateData = updateData and json.encode(updateData) or nil
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorStageUpdateAdminNotice: BaseNotice
--- @field UpdateAdmin string The admin to update
--- @field Hash string The hash of the staged update

--- Configurator stage update admin
--- @warning Only callable by the configurator admin
--- @param updateAdmin string The admin to update
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Stage-Update-Admin-Notice`: **configurator → ao.id** -- Logs the stage update admin action
--- @return ConfiguratorStageUpdateAdminNotice The configurator stage update admin notice
function Outcome.configuratorStageUpdateAdmin(updateAdmin)
  -- Validate input
  validateValidArweaveAddress(updateAdmin, "updateAdmin")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Stage-Update-Admin",
    UpdateAdmin = updateAdmin
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    UpdateAdmin = notice.Tags.UpdateAdmin,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorUnstageUpdateAdminNotice: BaseNotice
--- @field Hash string The hash of the staged update

--- Configurator unstage update admin
--- @warning Only callable by the configurator admin
--- @param updateAdmin string The admin to update
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Unstage-Update-Admin-Notice`: **configurator → ao.id** -- Logs the unstage update admin action
--- @return ConfiguratorUnstageUpdateAdminNotice The configurator unstage update admin notice
function Outcome.configuratorUnstageUpdateAdmin(updateAdmin)
  -- Validate input
  validateValidArweaveAddress(updateAdmin, "updateAdmin")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Unstage-Update-Admin",
    UpdateAdmin = updateAdmin
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorActionUpdateAdminNotice: BaseNotice
--- @field Hash string The hash of the staged update

--- Configurator action update admin
--- @warning Only callable by the configurator admin
--- @param updateAdmin string The admin to update
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Action-Update-Admin-Notice`: **configurator → ao.id** -- Logs the action update admin action
--- @return ConfiguratorActionUpdateAdminNotice The configurator action update admin notice
function Outcome.configuratorActionUpdateAdmin(updateAdmin)
  -- Validate input
  validateValidArweaveAddress(updateAdmin, "updateAdmin")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Action-Update-Admin",
    UpdateAdmin = updateAdmin
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorStageUpdateDelayNotice: BaseNotice
--- @field UpdateDelay number The new delay (in days)
--- @field Hash string The hash of the staged update

--- Configurator stage update delay
--- @warning Only callable by the configurator admin
--- @param updateDelay number The delay to update (in days)
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Stage-Update-Delay-Notice`: **configurator → ao.id** -- Logs the stage update delay action
--- @return ConfiguratorStageUpdateDelayNotice The configurator stage update delay notice
function Outcome.configuratorStageUpdateDelay(updateDelay)
  -- Validate input
  validatePositiveIntegerOrZero(tostring(updateDelay), "updateDelay")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Stage-Update-Delay",
    UpdateDelay = tostring(updateDelay)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    UpdateDelay = notice.Tags.UpdateDelay,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorUnstageUpdateDelayNotice: BaseNotice
--- @field Hash string The hash of the staged update

--- Configurator unstage update delay
--- @warning Only callable by the configurator admin
--- @param updateDelay number The delay to update (in days)
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Unstage-Update-Delay-Notice`: **configurator → ao.id** -- Logs the unstage update delay action
--- @return ConfiguratorUnstageUpdateDelayNotice The configurator unstage update delay notice
function Outcome.configuratorUnstageUpdateDelay(updateDelay)
  -- Validate input
  validatePositiveIntegerOrZero(tostring(updateDelay), "updateDelay")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Unstage-Update-Delay",
    UpdateDelay = tostring(updateDelay)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class ConfiguratorActionUpdateDelayNotice: BaseNotice
--- @field Hash string The hash of the staged update

--- Configurator action update delay
--- @warning Only callable by the configurator admin
--- @param updateDelay number The delay to update (in days)
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Action-Update-Delay-Notice`: **configurator → ao.id** -- Logs the action update delay action
--- @return ConfiguratorActionUpdateDelayNotice The configurator action update delay notice
function Outcome.configuratorActionUpdateDelay(updateDelay)
  -- Validate input
  validatePositiveIntegerOrZero(tostring(updateDelay), "updateDelay")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Action-Update-Delay",
    UpdateDelay = tostring(updateDelay)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Hash = notice.Tags.Hash,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--[[
============
MARKET: INFO
============
]]

---@class MarketInfo: BaseMessage
---@field Name string The market name
---@field Ticker string The market ticker
---@field Logo string The market LP token logo
---@field Logos table<string> The market position token logos
---@field Denomination number The market denomination
---@field CollateralToken string The market collateral token
---@field Configurator string The market configurator
---@field Incentives string The market incentives controller
---@field DataIndex string The market data index
---@field ResolutionAgent string The market resolution agent
---@field Question string The market question
---@field Rules string The market rules
---@field Category string The market category
---@field Subcategory string The market subcategory
---@field Creator string The market creator process ID
---@field CreatorFee number The market creator fee
---@field CreatorFeeTarget string The market creator fee target
---@field ProtocolFee number The market protocol fee
---@field ProtocolFeeTarget string The market protocol fee target
---@field LpFee number The market liquidity provider fee
---@field LpFeePoolWeight number The market liquidity provider fee pool weight
---@field LpFeeTotalWithdrawn number The market liquidity provider fee total withdrawn

--- Market info
--- @param market string The market process ID
--- @return MarketInfo The market info
function Outcome.marketInfo(market)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local info = ao.send({
    Target = market,
    Action = "Info"
  }).receive()
  -- Return formatted response
  return {
    Name = info.Tags.Name,
    Ticker = info.Tags.Ticker,
    Logo = info.Tags.Logo,
    Logos = json.decode(info.Tags.Logos),
    Denomination = tonumber(info.Tags.Denomination),
    CollateralToken = info.Tags.CollateralToken,
    Configurator = info.Tags.Configurator,
    Incentives = info.Tags.Incentives,
    DataIndex = info.Tags.DataIndex,
    ResolutionAgent = info.Tags.ResolutionAgent,
    Question = info.Tags.Question,
    Rules = info.Tags.Rules,
    Category = info.Tags.Category,
    Subcategory = info.Tags.Subcategory,
    Creator = info.Tags.Creator,
    CreatorFee = tonumber(info.Tags.CreatorFee),
    CreatorFeeTarget = info.Tags.CreatorFeeTarget,
    ProtocolFee = tonumber(info.Tags.ProtocolFee),
    ProtocolFeeTarget = info.Tags.ProtocolFeeTarget,
    LpFee = tonumber(info.Tags.LpFee),
    LpFeePoolWeight = tonumber(info.Tags.LpFeePoolWeight),
    LpFeeTotalWithdrawn = tonumber(info.Tags.LpFeeTotalWithdrawn),
    MessageId = info.Id,
    Timestamp = info.Timestamp,
    ["Block-Height"] = info["Block-Height"]
  }
end

--[[
==================
MARKET: CPMM WRITE
==================
]]

--- @class MarketAddFundingDebitNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field Quantity string The quantity of collateral tokens transferred
--- @field Recipient string The recipient of the debit, i.e. the market process ID
--- @field X-Action string The forwarded action
--- @field X-OnBehalfOf string The recipient of the outcome position tokens
--- @field X-Distribution string? The initial probability distribution, if applicable

--- Market add funding
--- @warning `distribution` is required for initial market funding.
---          Omit it for subsequent funding, or the transaction will fail.
--- @warning `distribution` must be a numeric table matching the outcome slot count,
---          with a total sum greater than zero, or `nil`.
--- @param market string The market process ID
--- @param collateral string The collateral token process ID
--- @param quantity string The quantity of collateral tokens to transfer, a.k.a. the funding amount
--- @param distribution table<number>|nil The initial probability distribution. **Pass `nil` for subsequent funding**
--- @param onBehalfOf string? The recipient of the outcome LP tokens. **Defaults to the sender if omitted.**
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Notice`: **collateral → ao.id**     -- Transfers collateral tokens from the provider
--- - `Credit-Notice`: **collateral → market**   -- Transfers collateral tokens to the market
--- **✨ Interim Notices (Default silenced)**
--- - `Mint-Batch-Notice`: **market → market**      -- Mints position tokens to the market
--- - `Split-Position-Notice`: **market → market**  -- Splits collateral into position tokens
--- - `Mint-Notice`: **market → ao.id**             -- Mints LP tokens to the onBehalfOf address
--- **📊 Logging & Analytics**
--- - `Log-Funding-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the funding
--- **✅ Success Notice**
--- - `Add-Funding-Notice`: **market → ao.id**  -- Logs the add funding action
--- @return MarketAddFundingDebitNotice The market add funding debit notice
function Outcome.marketAddFunding(market, collateral, quantity, distribution, onBehalfOf, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validateValidArweaveAddress(collateral, "collateral")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  if distribution then validateNonEmptyNumericTable(distribution, "distribution") end
  if onBehalfOf then validateValidArweaveAddress(onBehalfOf, "onBehalfOf") end
  -- Send and receive response
  local notice = ao.send({
    Target = collateral,
    Action = "Transfer",
    Quantity = quantity,
    Recipient = market,
    ["X-Action"] = "Add-Funding",
    ---@diagnostic disable-next-line: assign-type-mismatch
    ["X-Distribution"] = distribution and json.encode(distribution) or nil,
    ["X-OnBehalfOf"] = onBehalfOf or ao.id,
     ---@diagnostic disable-next-line: assign-type-mismatch
    ["X-SendInterim"] = sendInterim and "true" or nil,
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Collateral = notice.From,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    ["X-Action"] = notice.Tags["X-Action"],
    ["X-Distribution"] = notice.Tags["X-Distribution"] or nil,
    ["X-OnBehalfOf"] = notice.Tags["X-OnBehalfOf"],
    ["X-SendInterim"] = notice.Tags["X-SendInterim"] or nil,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketRemoveFundingtNotice: BaseNotice
--- @field SendAmounts table The amounts of position tokens sent back to the provider
--- @field CollateralRemovedFromFeePool string The quantity collateral received as fees
--- @field SharesToBurn string The number of LP shares to burn
--- @field OnBehalfOf string The recipient of the position tokens

--- Market remove funding
--- @notice Calling `marketRemoveFunding` will simultaneously return the liquidity provider's share of accrued fees
--- @param market string The market process ID
--- @param quantity string The quantity of LP tokens to transfer, i.e. the amount of shares to burn
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @note **Emits the following notices:**
--- **✨ Interim Notices (Default silenced)**
--- - `Withdraw-Fees-Notice`: **market → ao.id**  -- Distributes accrued LP fees to the provider
--- - `Burn-Notice`: **market → market**  -- Burns the returned LP tokens
--- - `Debit-Batch-Notice`: **market → market** -- Transfers position tokens from the market
--- - `Credit-Batch-Notice`: **market → ao.id** -- Transfers position tokens to the onBehalfOf address
--- **📊 Logging & Analytics**
--- - `Log-Funding-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the funding
--- **✅ Success Notice**
--- - `Remove-Funding-Notice`: **market → ao.id** -- Logs the remove funding action
--- @return MarketRemoveFundingtNotice The market remove funding notice
function Outcome.marketRemoveFunding(market, quantity, onBehalfOf, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Remove-Funding",
    Quantity = quantity,
    OnBehalfOf = onBehalfOf or ao.id,
    ---@diagnostic disable-next-line: assign-type-mismatch
    SendInterim = sendInterim and "true" or nil
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    SendAmounts = json.decode(notice.Tags.SendAmounts),
    CollateralRemovedFromFeePool = notice.Tags.CollateralRemovedFromFeePool,
    SharesToBurn = notice.Tags.SharesToBurn,
    OnBehalfOf = notice.Tags.OnBehalfOf,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketBuyCollateralDebitNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field Quantity string The quantity of collateral tokens transferred
--- @field Recipient string The recipient of the debit, i.e. the market process ID
--- @field X-Action string The forwarded action
--- @field X-PositionId string The outcome position token position ID
--- @field X-MinPositionTokensToBuy string The minimum outcome position tokens to buy
--- @field X-OnBehalfOf string The recipient of the outcome position tokens

--- Market buy
--- @warning Ensure sufficient liquidity exists before calling `marketBuy`, or the transaction may fail
--- @use Call `marketCalcBuyAmount` to verify liquidity and the number of outcome position tokens to be purchased
--- @param market string The market process ID
--- @param collateral string The collateral token process ID
--- @param quantity string The quantity of collateral tokens to transfer, a.k.a. the investment amount
--- @param positionId string The outcome position token position ID
--- @param minPositionTokensToBuy string The minimum outcome position tokens to buy
--- @param onBehalfOf string? The recipient of the outcome position tokens. **Defaults to the sender if omitted.**
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Notice`: **collateral → ao.id**     -- Transfers collateral from the buyer
--- - `Credit-Notice`: **collateral → market**   -- Transfers collateral to the market
--- **✨ Interim Notices (Default silenced)**
--- - `Mint-Batch-Notice`: **market → market**      -- Mints new position tokens
--- - `Split-Position-Notice`: **market → market**  -- Splits collateral into position tokens
--- - `Debit-Single-Notice`: **market → market**    -- Transfers position tokens from the market
--- - `Credit-Single-Notice`: **market → ao.id**    -- Transfers position tokens to the buyer
--- **📊 Logging & Analytics**
--- - `Log-Prediction-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the prediction
--- - `Log-Probabilities-Notice`: **market → Outcome.dataIndex**                            -- Logs the updated probabilities
--- **✅ Success Notice**
--- - `Buy-Notice`: **market → ao.id**  -- Logs the buy action
--- @return MarketBuyCollateralDebitNotice The market buy collateral debit notice
function Outcome.marketBuy(market, collateral, quantity, positionId, minPositionTokensToBuy, onBehalfOf, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validateValidArweaveAddress(collateral, "collateral")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  validatePositiveIntegerGreaterThanZero(positionId, "positionId")
  validatePositiveIntegerOrZero(minPositionTokensToBuy, "minPositionTokensToBuy")
  if onBehalfOf then validateValidArweaveAddress(onBehalfOf, "onBehalfOf") end
  -- Send and receive response
  local notice = ao.send({
    Target = collateral,
    Action = "Transfer",
    Quantity = quantity,
    Recipient = market,
    ["X-Action"] = "Buy",
    ["X-PositionId"] = positionId,
    ["X-MinPositionTokensToBuy"] = minPositionTokensToBuy,
    ["X-OnBehalfOf"] = onBehalfOf or ao.id,
    ---@diagnostic disable-next-line: assign-type-mismatch
    ["X-SendInterim"] = sendInterim and "true" or nil,
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Collateral = notice.From,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    ["X-Action"] = notice.Tags["X-Action"],
    ["X-PositionId"] = notice.Tags["X-PositionId"],
    ["X-MinPositionTokensToBuy"] = notice.Tags["X-MinPositionTokensToBuy"],
    ["X-OnBehalfOf"] = notice.Tags["X-OnBehalfOf"],
    ["X-SendInterim"] = notice.Tags["X-SendInterim"] or nil,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketSellNotice: BaseNotice
--- @field ReturnAmount string The quantity of collateral tokens to receive
--- @field FeeAmount string The fee amount paid to the liquidity pool
--- @field PositionId string The outcome position token position ID
--- @field PositionTokensSold string The number of outcome position tokens sold
--- @field OnBehalfOf string The recipient of the outcome position tokens

--- Market sell
--- @warning Ensure sufficient liquidity exists before calling `marketSell`, or the transaction may fail
--- @use Call `marketCalcSellAmount` to verify liquidity and the number of outcome position tokens to be sold
--- @param market string The market process ID
--- @param returnAmount string The quantity of collateral tokens to receive
--- @param positionId string The outcome position token position ID
--- @param maxPositionTokensToSell string The max outcome position tokens to sell
--- @param onBehalfOf string? The recipient of the outcome position tokens. **Defaults to the sender if omitted.**
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @note **Emits the following notices:**
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Single-Notice`: **market → ao.id**          -- Transfers sold position tokens from the seller
--- - `Credit-Single-Notice`: **market → market**        -- Transfers sold position tokens to the market
--- - `Batch-Burn-Notice`: **market → market**           -- Burns sold position tokens
--- - `Merge-Positions-Notice`: **market → market**      -- Merges sold position tokens back to collateral
--- - `Debit-Notice`: **collateral → market**            -- Transfers collateral from the seller
--- - `Credit-Notice`: **collateral → onBehalfOf**       -- Transfers collateral to the onBehalfOf address
--- - `Debit-Single-Notice`: **market → market**         -- Returns unburned position tokens from the market
--- - `Credit-Single-Notice`: **market → onBehalfOf**    -- Returns unburned position tokens to the onBehalfOf address
--- **📊 Logging & Analytics**
--- - `Log-Prediction-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the prediction
--- - `Log-Probabilities-Notice`: **market → Outcome.dataIndex**                            -- Logs the updated probabilities
--- **✅ Success Notice**
--- - `Sell-Notice`: **market → ao.id** -- Logs the sell action
--- @return MarketSellNotice The market sell notice
function Outcome.marketSell(market, returnAmount, positionId, maxPositionTokensToSell, onBehalfOf, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(returnAmount, "returnAmount")
  validatePositiveIntegerGreaterThanZero(positionId, "positionId")
  validatePositiveIntegerGreaterThanZero(maxPositionTokensToSell, "maxPositionTokensToSell")
  if onBehalfOf then validateValidArweaveAddress(onBehalfOf, "onBehalfOf") end
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Sell",
    ReturnAmount = returnAmount,
    PositionId = positionId,
    MaxPositionTokensToSell = maxPositionTokensToSell,
    OnBehalfOf = onBehalfOf or ao.id,
    ---@diagnostic disable-next-line: assign-type-mismatch
    SendInterim = sendInterim and "true" or nil,
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    ReturnAmount = notice.Tags.ReturnAmount,
    FeeAmount = notice.Tags.FeeAmount,
    PositionId = notice.Tags.PositionId,
    PositionTokensSold = notice.Tags.PositionTokensSold,
    OnBehalfOf = notice.Tags.OnBehalfOf,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketWithdrawFeesNotice: BaseNotice
--- @field FeeAmount string The fee amount withdrawn
--- @field OnBehalfOf string The recipient of the fee withdrawal

--- Market withdraw fees
--- @param market string The market process ID
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @note **Emits the following notices:**
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Notice`: **collateral → market**  -- Transfers LP fees from the market
--- - `Credit-Notice`: **collateral → ao.id**  -- Transfers LP fees to the provider
--- **✅ Success Notice**
--- - `Withdraw-Fees-Notice`: **market → ao.id** -- Logs the withdraw fees action
--- @return MarketWithdrawFeesNotice The market withdraw fees notice
function Outcome.marketWithdrawFees(market, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Withdraw-Fees",
    ---@diagnostic disable-next-line: assign-type-mismatch
    SendInterim = sendInterim and "true" or nil,
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    FeeAmount = notice.Tags.FeeAmount,
    OnBehalfOf = notice.Tags.OnBehalfOf,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--[[
=================
MARKET: CPMM READ
=================
]]

--- @class MarketCalcBuyAmountResponse: BaseMessage
--- @field InvestmentAmount string The investment amount in collateral tokens
--- @field PositionId string The outcome position token position ID
--- @field BuyAmount string The amount of outcome position tokens to be bought for the given investment amount

--- Market calc buy amount
--- @warning Ensure sufficient liquidity exists before calling `marketCalcBuyAmount`, or the transaction may fail
--- @param market string The market process ID
--- @param investmentAmount string The investment amount
--- @param positionId string The outcome position token position ID
--- @return MarketCalcBuyAmountResponse The market calc buy amount response message
function Outcome.marketCalcBuyAmount(market, investmentAmount, positionId)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(investmentAmount, "investmentAmount")
  validatePositiveIntegerGreaterThanZero(positionId, "positionId")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Calc-Buy-Amount",
    InvestmentAmount = investmentAmount,
    PositionId = positionId
  }).receive()
  -- Return formatted response
  return {
    BuyAmount = notice.Tags.BuyAmount,
    PositionId = notice.Tags.PositionId,
    InvestmentAmount = notice.Tags.InvestmentAmount,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketCalcSellAmountResponse: BaseMessage
--- @field ReturnAmount string The return amount in collateral tokens
--- @field PositionId string The outcome position token position ID
--- @field SellAmount string The amount of outcome positionn tokens to be sold for the given return amount

--- Market calc sell amount
--- @warning Ensure sufficient liquidity exists before calling `marketCalcSellAmount`, or the transaction may fail
--- @param market string The market process ID
--- @param returnAmount string The return amount
--- @param positionId string The outcome position token position ID
--- @return MarketCalcSellAmountResponse The market calc sell amount response message
function Outcome.marketCalcSellAmount(market, returnAmount, positionId)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(returnAmount, "returnAmount")
  validatePositiveIntegerGreaterThanZero(positionId, "positionId")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Calc-Sell-Amount",
    ReturnAmount = returnAmount,
    PositionId = positionId
  }).receive()
  -- Return formatted response
  return {
    SellAmount = response.Tags.SellAmount,
    PositionId = response.Tags.PositionId,
    ReturnAmount = response.Tags.ReturnAmount,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketCollectedFeesResponse: BaseMessage
--- @field CollectedFees string The collected fees

--- Market collected fees
--- @param market string The market process ID
--- @return MarketCollectedFeesResponse The market collected fees response message
function Outcome.marketCollectedFees(market)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Collected-Fees"
  }).receive()
  -- Return formatted response
  return {
    CollectedFees = response.Tags.CollectedFees,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketFeesWithdrawableResponse: BaseMessage
--- @field FeesWithdrawable string The fees withdrawable by the account
--- @field Account string The account process ID

--- Market fees withdrawable
--- @param market string The market process ID
--- @param account string? The account process ID or `nil` for the sender
--- @return MarketFeesWithdrawableResponse The market fees withdrawable response message
function Outcome.marketFeesWithdrawable(market, account)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  if account then validateValidArweaveAddress(account, "account") end
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Fees-Withdrawable",
    ---@diagnostic disable-next-line: assign-type-mismatch
    Account = account or nil
  }).receive()
  -- Return formatted response
  return {
    FeesWithdrawable = response.Tags.FeesWithdrawable,
    Account = response.Tags.Account,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--[[
======================
MARKET: LP TOKEN WRITE
======================
]]

--- @class MarketLpTokenDebitNotice: BaseNotice
--- @field Collateral string The LP token, i.e. the market process ID
--- @field Quantity string The quantity of collateral tokens transferred
--- @field Recipient string The recipient of the transfer

--- Market LP token transfer
--- @param market string The market process ID
--- @param recipient string The recipient process ID
--- @param quantity string The quantity of LP tokens to transfer
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @note **Emits the following notices:**
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Notice`: **collateral → market**  -- Transfers LP fees from the market
--- - `Credit-Notice`: **collateral → ao.id**  -- Transfers LP fees to the provider
--- - `Withdraw-Fees-Notice`: **market → ao.id** -- Logs the withdraw fees action
--- **✅ Success Notice**
--- - `Debit-Notice`: **market → ao.id**      -- Transfers LP tokens from the sender
--- - `Credit-Notice`: **market → recipient** -- Transfers LP tokens to the recipient
--- @return MarketLpTokenDebitNotice The market LP token debit notice
function Outcome.marketLpTokenTransfer(market, recipient, quantity, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validateValidArweaveAddress(recipient, "recipient")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Transfer",
    Quantity = quantity,
    Recipient = recipient,
    ---@diagnostic disable-next-line: assign-type-mismatch
    SendInterim = sendInterim and "true" or nil,
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Collateral = notice.From,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"],
  }
end

--[[
=====================
MARKET: LP TOKEN READ
=====================
]]

--- @class MarketLpTokenBalanceResponse: BaseMessage
--- @field Balance string The LP token balance of the account
--- @field Ticker string The LP token ticker
--- @field Account string The account process ID

--- Market LP token balance
--- @param market string The market process ID
--- @param recipient string? The recipient process ID or `nil` for the sender
--- @return MarketLpTokenBalanceResponse The market LP token balance response message
function Outcome.marketLpTokenBalance(market, recipient)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  if recipient then validateValidArweaveAddress(recipient, "recipient") end
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Balance",
    ---@diagnostic disable-next-line: assign-type-mismatch
    Recipient = recipient or nil
  }).receive()
  -- Return formatted response
  return {
    Balance = response.Tags.Balance,
    Ticker = response.Tags.Ticker,
    Account = response.Tags.Account,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketLpTokenBalancesResponse: BaseMessage
--- @field Balances table<string, string> The LP token balances; a mapping of account process IDs to their LP token balances

--- Market LP token balances
--- @param market string The market process ID
--- @return MarketLpTokenBalancesResponse The market LP token balances response message
function Outcome.marketLpTokenBalances(market)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Balances"
  }).receive()
  -- Return formatted response
  return {
    Balances = json.decode(response.Data),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketLpTokenTotalSupplyResponse: BaseMessage
--- @field TotalSupply string The LP token total supply

--- Market LP token total supply
--- @param market string The market process ID
--- @return MarketLpTokenTotalSupplyResponse The market LP token total supply response message
function Outcome.marketLpTokenTotalSupply(market)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Total-Supply"
  }).receive()
  -- Return formatted response
  return {
    TotalSupply = response.Data,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--[[
=======================
MARKET: POSITIONS WRITE
=======================
]]

--- @class MarketMergePositionsNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field Quantity string The quantity of collateral tokens to return to user

--- Market outcome position tokens merge positions
--- @warning User must have stated quantity of outcome position tokens from each position ID,
--- and their must be sufficient liquidity to merge for collateral, or the transaction will fail
--- @param market string The market process ID
--- @param quantity string The quantity of outcome position tokens from each position ID to merge for collataral
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @param onBehalfOf string? The recipient of the collateral tokens, or `nil` for the sender
--- @note **Emits the following notices:**
--- **✨ Interim Notices (Default silenced)**
--- - `Burn-Batch-Notice`: **market → ao.id** -- Burns the position tokens
--- - `Debit-Notice`: **collateral → market** -- Transfers collateral from the market
--- - `Credit-Notice`: **collateral → ao.id** -- Transfers collateral to the recipient
--- **✅ Success Notice**
--- - `Merge-Positions-Notice`: **market → ao.id**  -- Logs the merge positions action
--- @return MarketMergePositionsNotice The market merge positions notice
function Outcome.marketMergePositions(market, quantity, onBehalfOf, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  if onBehalfOf then validateValidArweaveAddress(onBehalfOf, "onBehalfOf") end
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Merge-Positions",
    Quantity = quantity,
    ---@diagnostic disable-next-line: assign-type-mismatch
    OnBehalfOf = onBehalfOf or nil,
    ---@diagnostic disable-next-line: assign-type-mismatch
    SendInterim = sendInterim and "true" or nil
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Collateral = notice.Tags.CollateralToken,
    Quantity = notice.Tags.Quantity,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketReportPayoutsNotice: BaseNotice
--- @field PayoutNumerators table<number> The payout numerators; where each index value divided by the sum represents the proportional payout
--- @field ResolutionAgent string The resolution agent process ID

--- Market report payouts
--- @warning Only callable by the resolution agent, and once, or the transaction will fail
--- @param market string The market process ID
--- @param payouts table<number> The payout numerators
--- @note **Emits the following notices:**
--- **✅ Success Notice**
---  - `Report-Payouts-Notice`: **market → ao.id** -- Logs the report payouts action
--- @return MarketReportPayoutsNotice The market report payouts notice
function Outcome.marketReportPayouts(market, payouts)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validateNonEmptyNumericTable(payouts, "payouts")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Report-Payouts",
    Payouts = json.encode(payouts)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    PayoutNumerators = json.decode(notice.Tags.PayoutNumerators),
    ResolutionAgent = notice.Tags.ResolutionAgent,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketRedeemPositionsNotice: BaseNotice
--- @field GrossPayout string The gross payout amount (before fees)
--- @field NetPayout string The net payout amount (after fees)
--- @field Collateral string The collateral token

--- Market redeem positions
--- @warning Market must be resolve or the transaction will fail
--- @param market string The market process ID
--- @param sendInterim string? The sendInterim is set to send interim notices. **Defaults to silenced if omitted.**
--- @note **Emits the following notices:**
--- **✨ Interim Notices (Default silenced)**
--- - `Burn-Single-Notice`: **market → ao.id**    -- Burns redeemed position tokens (for each position ID held by the sender)
--- - `Debit-Notice`: **collateral → market**     -- Transfers collateral from the market
--- - `Credit-Notice`: **collateral → ao.id**     -- Transfers collateral to the sender
--- **✅ Success Notice**
--- - `Redeem-Positions-Notice`: **market → ao.id** -- Logs the redeem positions action
--- @return MarketRedeemPositionsNotice The market redeem positions notice
function Outcome.marketRedeemPositions(market, sendInterim)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Redeem-Positions",
    ---@diagnostic disable-next-line: assign-type-mismatch
    SendInterim = sendInterim and "true" or nil
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    GrossPayout = notice.Tags.GrossPayout,
    NetPayout = notice.Tags.NetPayout,
    Collateral = notice.Tags.CollateralToken,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketPositionDebitSingleNotice: BaseNotice
--- @field Market string The outcome position token (a.k.a.) market process ID
--- @field Quantity string The quantity of outcome position tokens transferred
--- @field PositionId string The outcome position token position ID
--- @field Recipient string The recipient of the token transfer

--- Market outcome position token transfer
--- @param market string The market process ID
--- @param quantity string The quantity of outcome position tokens to transfer
--- @param positionId string The outcome position token position ID
--- @param recipient string The recipient of the outcome position tokens
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
---  - `Debit-Single-Notice`: **market → ao.id**     -- Transfers position tokens from the sender
---  - `Credit-Single-Notice`: **market → recipient** -- Transfers position tokens to the recipient
--- @return MarketPositionDebitSingleNotice The market outcome position token debit single notice
function Outcome.marketPositionTransfer(market, quantity, positionId, recipient)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  validatePositiveIntegerGreaterThanZero(positionId, "positionId")
  validateValidArweaveAddress(recipient, "recipient")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Transfer-Single",
    Quantity = quantity,
    PositionId = positionId,
    Recipient = recipient
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Market = notice.From,
    Quantity = notice.Tags.Quantity,
    PositionId = notice.Tags.PositionId,
    Recipient = notice.Tags.Recipient,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketPositionDebitBatchNotice: BaseNotice
--- @field Market string The outcome position token (a.k.a.) market process ID
--- @field Quantities table<string> The quantiies per position ID
--- @field PositionId string The position IDs
--- @field Recipient string The recipient of the token transfer

--- Market outcome position token transfer batch
--- @param market string The market process ID
--- @param quantities table<string> The quantities of outcome position tokens to transfer per position ID
--- @param positionIds table<string> The outcome position token position IDs
--- @param recipient string The recipient of the outcome position tokens
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Batch-Notice`: **market → ao.id**     -- Transfers position tokens from the sender
--- - `Credit-Batch-Notice`: **market → recipient** -- Transfers position tokens to the recipient
--- @return MarketPositionDebitBatchNotice The market outcome position token debit batch notice
function Outcome.marketPositionTransferBatch(market, quantities, positionIds, recipient)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerTable(quantities, "quantities")
  validatePositiveIntegerTable(positionIds, "positionIds")
  validateValidArweaveAddress(recipient, "recipient")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Transfer-Batch",
    Quantities = json.encode(quantities),
    PositionIds = json.encode(positionIds),
    Recipient = recipient
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Market = notice.From,
    Quantities = json.decode(notice.Tags.Quantities),
    PositionIds = json.decode(notice.Tags.PositionIds),
    Recipient = notice.Tags.Recipient,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--[[
======================
MARKET: POSITIONS READ
======================
]]

--- @class MarketGetPayoutNumeratorsResponse: BaseMessage
--- @field PayoutNumerators table<number> The payout numerators; where each index value divided by the sum represents the proportional payout

--- Market get payout numerators
--- @param market string The market process ID
--- @return MarketGetPayoutNumeratorsResponse The market get payout numerators response message
function Outcome.marketGetPayoutNumerators(market)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Get-Payout-Numerators"
  }).receive()
  -- Return formatted response
  return {
    PayoutNumerators = json.decode(response.Data),
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketGetPayoutDenominatorResponse: BaseMessage
--- @field PayoutDenominator number The payout denominator; the sum of the payout numerators, zero if the market is not resolved

--- Market get payout denominator
--- @param market string The market process ID
--- @return MarketGetPayoutDenominatorResponse The market get payout denominator response message
function Outcome.marketGetPayoutDenominator(market)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Get-Payout-Denominator"
  }).receive()
  -- Return formatted response
  return {
    PayoutDenominator = tonumber(response.Data),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketPositionBalanceResponse: BaseMessage
--- @field Balance string The balance of the account
--- @field PositionId string The outcome position token position ID
--- @field Account string The account process ID

--- Market outcome position tokens balance by ID
--- @param market string The market process ID
--- @param positionId string The outcome position token position ID
--- @param recipient string? The recipient process ID or `nil` for the sender
--- @return MarketPositionBalanceResponse The market position balance response message
function Outcome.marketPositionBalance(market, positionId, recipient)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(positionId, "positionId")
  if recipient then validateValidArweaveAddress(recipient, "recipient") end
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Balance-By-Id",
    PositionId = positionId,
    ---@diagnostic disable-next-line: assign-type-mismatch
    Recipient = recipient or nil
  }).receive()
  -- Return formatted response
  return {
    Balance = response.Tags.Balance,
    PositionId = response.Tags.PositionId,
    Account = response.Tags.Account,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketPositionBalancesResponse: BaseMessage
--- @field Balances string The balance of the recipient
--- @field PositionId string The outcome position token position ID

--- Market outcome position tokens balances by ID
--- @param market string The market process ID
--- @param positionId string The outcome position token position ID
--- @return MarketPositionBalancesResponse The market position balances response message
function Outcome.marketPositionBalances(market, positionId)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerGreaterThanZero(positionId, "positionId")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Balances-By-Id",
    PositionId = positionId
  }).receive()
  -- Return formatted response
  return {
    Balances = json.decode(response.Data),
    PositionId = response.Tags.PositionId,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketPositionBatchBalanceResponse: BaseMessage
--- @field Balances table<string> The outcome position tokens balance for each indexed position ID and account pair provided
--- @field PositionIds table<string> The outcome position token position IDs
--- @field Accounts table<string> The account process IDs

--- Market outocome position tokens batch balance
--- @param market string The market process ID
--- @param positionIds table<string> The outcome position token position IDs
--- @param recipients table<string> The recipient process IDs
--- @return MarketPositionBatchBalanceResponse The market position batch balance response message
function Outcome.marketPositionBatchBalance(market, positionIds, recipients)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerTable(positionIds, "positionIds")
  validateArweaveAddressTable(recipients, "recipients")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Batch-Balance",
    PositionIds = json.encode(positionIds),
    Recipients = json.encode(recipients)
  }).receive()
  -- Return formatted response
  return {
    Balances = json.decode(response.Data),
    PositionIds = json.decode(response.Tags.PositionIds),
    Accounts = json.decode(response.Tags.Accounts),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketPositionBatchBalancesResponse: BaseMessage
--- @field Balances table<string, table<string, string>> The user outcome position tokens balances, mapping position IDs to user process IDs to their balances
--- @field PositionIds table<string> The outcome position token position IDs

--- Market outcome position tokens batch balances
--- @param market string The market process ID
--- @param positionIds table<string> The outcome position token position IDs
--- @return MarketPositionBatchBalancesResponse The market position batch balances response message
function Outcome.marketPositionBatchBalances(market, positionIds)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerTable(positionIds, "positionIds")
  -- Send and receive response
  local response = ao.send({
    Target = market,
    Action = "Batch-Balances",
    PositionIds = json.encode(positionIds)
  }).receive()
  -- Return formatted response
  return {
    Balances = json.decode(response.Data),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--[[
====================
MARKET: CONFIGURATOR
====================
]]

--- @class MarketProposeConfiguratorNotice: BaseNotice
--- @field Configurator string The proposed configurator process ID

--- Market propose configurator
--- @warning Only callable by the market configurator, or the transaction will fail
--- @param market string The market process ID
--- @param configurator string The new configurator process ID
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Propose-Configurator-Notice`: **market → ao.id** -- Logs the propose configurator action
--- @return MarketProposeConfiguratorNotice The market propose configurator notice
function Outcome.marketProposeConfigurator(market, configurator)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validateValidArweaveAddress(configurator, "configurator")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Propose-Configurator",
    Configurator = configurator
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Configurator = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketAcceptConfiguratorNotice: BaseNotice
--- @field Configurator string The accepted configurator process ID

--- Market accept configurator
--- @warning Only callable by the market proposedConfigurator, or the transaction will fail
--- @param market string The market process ID
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Accept-Configurator-Notice`: **market → ao.id** -- Logs the accept configurator action
--- @return MarketAcceptConfiguratorNotice The market accept configurator notice
function Outcome.marketAcceptConfigurator(market)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Accept-Configurator"
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Configurator = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketUpdateDataIndexNotice: BaseNotice
--- @field DataIndex string The new dataIndex process ID

--- Market update dataIndex
--- @warning Only callable by the market configurator, or the transaction will fail
--- @param market string The market process ID
--- @param dataIndex string The new dataIndex process ID
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Data-Index-Notice`: **market → ao.id** -- Logs the update data index action
--- @return MarketUpdateDataIndexNotice The market update data index notice
function Outcome.marketUpdateDataIndex(market, dataIndex)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validateValidArweaveAddress(dataIndex, "dataIndex")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Update-Data-Index",
    DataIndex = dataIndex
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    DataIndex = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketUpdateTakeFeeNotice: BaseNotice
--- @field CreatorFee number The new creator fee
--- @field ProtocolFee number The new protocol fee
--- @field TakeFee number The new net take fee; the sum of the creator and protocol fees

--- Market update take fee
--- @warning Only callable by the market configurator, or the transaction will fail
--- @warning The `creatorFee` and `protocolFee` must be in basis points, with a maximum net take fee of 1000 (10%) or the transaction will fail
--- @param market string The market process ID
--- @param creatorFee number The new creator fee, in basis points
--- @param protocolFee number The new protocol fee, in basis points
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Take-Fee-Notice`: **market → ao.id** -- Logs the update take fee action
--- @return MarketUpdateTakeFeeNotice The market update take fee notice
function Outcome.marketUpdateTakeFee(market, creatorFee, protocolFee)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validatePositiveIntegerOrZero(tostring(creatorFee), "creatorFee")
  validatePositiveIntegerOrZero(tostring(protocolFee), "protocolFee")
  assert(creatorFee + protocolFee <= 1000, "`creatorFee` and `protocolFee` must sum to 1000 or less.")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Update-Take-Fee",
    CreatorFee = tostring(creatorFee),
    ProtocolFee = tostring(protocolFee)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    CreatorFee = tonumber(notice.Tags.CreatorFee),
    ProtocolFee = tonumber(notice.Tags.ProtocolFee),
    TakeFee = tonumber(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketUpdateProtocolFeeTargetNotice: BaseNotice
--- @field ProtocolFeeTarget string The new protocol fee target

--- Market update protocol fee target
--- @warning Only callable by the market configurator, or the transaction will fail
--- @param market string The market process ID
--- @param protocolFeeTarget string The new protocol fee target
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Take-Fee-Target-Notice`: **market → ao.id** -- Logs the update protocol fee target action
--- @return MarketUpdateProtocolFeeTargetNotice The market update protocol fee target notice
function Outcome.marketUpdateProtocolFeeTarget(market, protocolFeeTarget)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  validateValidArweaveAddress(protocolFeeTarget, "protocolFeeTarget")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Update-Protocol-Fee-Target",
    ProtocolFeeTarget = protocolFeeTarget
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    ProtocolFeeTarget = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketUpdateLogoNotice: BaseNotice
--- @field Logo string The new logo URL

--- Market update logo
--- @warning Only callable by the market configurator, or the transaction will fail
--- @param market string The market process ID
--- @param logo string The new logo Arweave TxID
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Logo-Notice`: **market → ao.id** -- Logs the update logo action
--- @return MarketUpdateLogoNotice The market update logo notice
function Outcome.marketUpdateLogo(market, logo)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  assert(logo, "`logo` is required.")
  assert(type(logo) == "string", "`logo` must be a string.")
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Update-Logo",
    Logo = logo
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Logo = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketUpdateLogosNotice: BaseNotice
--- @field Logos table<string> The new logos URLs for each market position token

--- Market update logos
--- @warning Only callable by the market configurator, or the transaction will fail
--- @param market string The market process ID
--- @param logos table<string> The new logos Arweave TxIDs
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Logos-Notice`: **market → ao.id** -- Logs the update logos action
--- @return MarketUpdateLogosNotice The market update logo notice
function Outcome.marketUpdateLogos(market, logos)
  -- Validate input
  validateValidArweaveAddress(market, "market")
  assert(logos, "`logos` is required.")
  assert(type(logos) == "table", "`logos` must be a table.")
  for i, logo in ipairs(logos) do
    assert(type(logo) == "string", "`logos[" .. i .. "]` must be a string.")
  end
  -- Send and receive response
  local notice = ao.send({
    Target = market,
    Action = "Update-Logos",
    Logos = json.encode(logos)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Logos = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--[[
====================
MARKET FACTORY: INFO
====================
]]

--- @class MarketFactoryInfo: BaseMessage
--- @field Configurator string The market factory configurator process ID
--- @field VeToken string The market factory VE Token process ID
--- @field LpFee number The market factory LP fee
--- @field ProtocolFee number The market factory protocol fee
--- @field ProtocolFeeTarget string The market factory protocol fee target
--- @field MaximumTakeFee number The market factory maximum take fee
--- @field AllowedCreators table<string> The market factory allowed creators
--- @field ListedCollateralTokens table<string> The market factory listed collateral tokens
--- @field TestCollateral string The market factory test collateral token process ID

--- Market factory info
--- @return MarketFactoryInfo The market factory info
function Outcome.marketFactoryInfo()
  -- Send and receive response
  local info = ao.send({
    Target = Outcome.marketFactory,
    Action = "Info"
  }).receive()
  -- Return formatted response
  return {
    Configurator = info.Tags.Configurator,
    VeToken = info.Tags.VeToken,
    LpFee = tonumber(info.Tags.LpFee),
    ProtocolFee = tonumber(info.Tags.ProtocolFee),
    ProtocolFeeTarget = info.Tags.ProtocolFeeTarget,
    MaximumTakeFee = tonumber(info.Tags.MaximumTakeFee),
    AllowedCreators = json.decode(info.Tags.AllowedCreators),
    ListedCollateralTokens = json.decode(info.Tags.ListedCollateralTokens),
    TestCollateral = info.Tags.TestCollateral,
    MessageId = info.Id,
    Timestamp = info.Timestamp,
    ["Block-Height"] = info["Block-Height"]
  }
end

--[[
=====================
MARKET FACTORY: WRITE
=====================
]]

--- @class MarketFactoryCreateEventNotice: BaseNotice
--- @field CollateralToken string The collateral token process ID
--- @field DataIndex string The data index process ID
--- @field OutcomeSlotCount number The number of outcome slots
--- @field Question string The market question
--- @field Rules string The market rules
--- @field Category string The market category
--- @field Subcategory string The market subcategory
--- @field Logo string The market logo URL

--- Market factory create event
--- @warning Only callable by utility token stakers with sufficient stake, or the transaction will fail
--- @param collateralToken string The collateral token process ID
--- @param dataIndex string The data index process ID
--- @param outcomeSlotCount number The number of outcome slots
--- @param question string The market question
--- @param rules string The market rules
--- @param category string The market category
--- @param subcategory string The market subcategory
--- @param logo string The market logo URL
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Create-Event-Notice`: **marketFactory → ao.id** -- Logs the create event action
--- @return MarketFactoryCreateEventNotice The market factory create event notice
function Outcome.marketFactoryCreateEvent(
  collateralToken,
  dataIndex,
  outcomeSlotCount,
  question,
  rules,
  category,
  subcategory,
  logo
)
  -- Validate input
  validateValidArweaveAddress(collateralToken, "collateralToken")
  validateValidArweaveAddress(dataIndex, "dataIndex")
  validatePositiveIntegerOrZero(tostring(outcomeSlotCount), "outcomeSlotCount")
  assert(tonumber(outcomeSlotCount) >= 2, "`outcomeSlotCount` must be greater than or equal to 2.")
  assert(tonumber(outcomeSlotCount) <= 256, "`outcomeSlotCount` must be less than or equal to 256.")
  assert(question, "`question` is required.")
  assert(type(question) == "string", "`question` must be a string.")
  assert(rules, "`rules` is required.")
  assert(type(rules) == "string", "`rules` must be a string.")
  assert(category, "`category` is required.")
  assert(type(category) == "string", "`category` must be a string.")
  assert(subcategory, "`subcategory` is required.")
  assert(type(subcategory) == "string", "`subcategory` must be a string.")
  assert(logo, "`logo` is required.")
  assert(type(logo) == "string", "`logo` must be a string.")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Create-Event",
    CollateralToken = collateralToken,
    DataIndex = dataIndex,
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    CollateralToken = notice.Tags.CollateralToken,
    DataIndex = notice.Tags.DataIndex,
    OutcomeSlotCount = tonumber(notice.Tags.OutcomeSlotCount),
    Question = notice.Tags.Question,
    Rules = notice.Tags.Rules,
    Category = notice.Tags.Category,
    Subcategory = notice.Tags.Subcategory,
    Logo = notice.Tags.Logo,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactorySpawnMarketNotice: BaseNotice
--- @field CollateralToken string The collateral token process ID
--- @field ResolutionAgent string The resolution agent process ID
--- @field DataIndex string The data index process ID
--- @field OutcomeSlotCount number The number of outcome slots
--- @field Question string The market question
--- @field Rules string The market rules
--- @field Category string The market category
--- @field Subcategory string The market subcategory
--- @field Logo string The market LP token logo Arweave TxID
--- @field Logos table<string> The market position tokens logo Arweave TxIDs
--- @field StartTime number The market start time in millisecond
--- @field EndTime number The market end time in millisecond
--- @field Creator string The creator process ID
--- @field CreatorFee number The creator fee in basis points
--- @field CreatorFeeTarget string The creator fee target process ID
--- @field Original-Msg-Id string The message ID of the spawn request

--- Market factory spawn market
--- @warning Only callable by utility token stakers with sufficient stake, or the transaction will fail
--- @param collateralToken string The collateral token process ID
--- @param resolutionAgent string The resolution agent process ID
--- @param dataIndex string The data index process ID
--- @param outcomeSlotCount number The number of outcome slots
--- @param question string The market question
--- @param rules string The market rules
--- @param category string The market category
--- @param subcategory string The market subcategory
--- @param logo string The market LP token logo Arweave TxID
--- @param logos table<string> The market position tokens logo Arweave TxIDs
--- @param eventId string|nil The event ID or `nil` if not applicable
--- @param startTime number The market start time in milliseconds
--- @param endTime number The market end time in milliseconds
--- @param creatorFee number The creator fee in basis points
--- @param creatorFeeTarget string The creator fee target process ID
--- @note **Emits the following notices:**
--- **✨ Market Creation**
--- - `Spawned`: **marketFactory → marketFactory**   -- Spawns a new market process
--- **✅ Success Notice**
--- - `Spawn-Market-Notice`: **marketFactory → ao.id** -- Logs the spawn market action
--- @return MarketFactorySpawnMarketNotice The market factory spawn market notice
function Outcome.marketFactorySpawnMarket(
  collateralToken,
  resolutionAgent,
  dataIndex,
  outcomeSlotCount,
  question,
  rules,
  category,
  subcategory,
  logo,
  logos,
  eventId,
  startTime,
  endTime,
  creatorFee,
  creatorFeeTarget
)
  -- Validate input
  validateValidArweaveAddress(collateralToken, "collateralToken")
  validateValidArweaveAddress(resolutionAgent, "resolutionAgent")
  validateValidArweaveAddress(dataIndex, "dataIndex")
  validatePositiveIntegerOrZero(tostring(outcomeSlotCount), "outcomeSlotCount")
  assert(tonumber(outcomeSlotCount) >= 2, "`outcomeSlotCount` must be greater than or equal to 2.")
  assert(tonumber(outcomeSlotCount) <= 256, "`outcomeSlotCount` must be less than or equal to 256.")
  assert(question, "`question` is required.")
  assert(type(question) == "string", "`question` must be a string.")
  assert(rules, "`rules` is required.")
  assert(type(rules) == "string", "`rules` must be a string.")
  assert(category, "`category` is required.")
  assert(type(category) == "string", "`category` must be a string.")
  assert(subcategory, "`subcategory` is required.")
  assert(type(subcategory) == "string", "`subcategory` must be a string.")
  assert(logo, "`logo` is required.")
  assert(type(logo) == "string", "`logo` must be a string.")
  assert(logos, "`logos` is required.")
  assert(type(logos) == "table", "`logos` must be a table.")
  assert(#logos == tonumber(outcomeSlotCount), "`logos` must have the same length as `outcomeSlotCount`.")
  for _, l in ipairs(logos) do
    assert(type(l) == "string", "`logos` must be a table of strings.")
  end
  if eventId then
    assert(type(eventId) == "string", "`eventId` must be a string.")
  end
  assert(startTime, "`startTime` is required.")
  assert(type(startTime) == "number", "`startTime` must be a number.")
  assert(endTime, "`endTime` is required.")
  assert(type(endTime) == "number", "`endTime` must be a number.")
  validatePositiveIntegerOrZero(tostring(creatorFee), "creatorFee")
  validateValidArweaveAddress(creatorFeeTarget, "creatorFeeTarget")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Spawn-Market",
    CollateralToken = collateralToken,
    ResolutionAgent = resolutionAgent,
    DataIndex = dataIndex,
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    Logos = json.encode(logos),
    EventId = eventId or "",
    StartTime = tostring(startTime),
    EndTime = tostring(endTime),
    CreatorFee = tostring(creatorFee),
    CreatorFeeTarget = creatorFeeTarget
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    CollateralToken = notice.Tags.CollateralToken,
    ResolutionAgent = notice.Tags.ResolutionAgent,
    DataIndex = notice.Tags.DataIndex,
    OutcomeSlotCount = tonumber(notice.Tags.OutcomeSlotCount),
    Question = notice.Tags.Question,
    Category = notice.Tags.Category,
    Subcategory = notice.Tags.Subcategory,
    Logo = notice.Tags.Logo,
    Logos = json.decode(notice.Tags.Logos),
    Rules = notice.Tags.Rules,
    EventId = notice.Tags.EventId,
    StartTime = tonumber(notice.Tags.StartTime),
    EndTime = tonumber(notice.Tags.EndTime),
    Creator = notice.Tags.Creator,
    CreatorFee = tonumber(notice.Tags.CreatorFee),
    CreatorFeeTarget = notice.Tags.CreatorFeeTarget,
    ["Original-Msg-Id"] = notice.Tags["Original-Msg-Id"],
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryInitMarketNotice: BaseNotice
--- @field MarketProcessIds table<string> The init market process IDs

--- Market factory init market
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
--- - `Log-Market-Notice`: **marketFactory → dataIndex**and **marketFactory → ao.id** -- Logs the market
--- **✅ Success Notice**
--- - `Init-Market-Notice`: **marketFactory → ao.id** -- Logs the init market action
--- @return MarketFactoryInitMarketNotice The market factory init market notice
function Outcome.marketFactoryInitMarket()
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Init-Market"
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    MarketProcessIds = json.decode(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--[[
====================
MARKET FACTORY: READ
====================
]]

--- @class MarketFactoryMarketsPendingResponse: BaseMessage
--- @field MarketsPending table<string> The pending market process IDs

--- Market factory markets pending
--- @return MarketFactoryMarketsPendingResponse The market factory markets pending response message
function Outcome.marketFactoryMarketsPending()
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.marketFactory,
    Action = "Markets-Pending"
  }).receive()
  -- Return formatted response
  return {
    MarketsPending = json.decode(response.Data),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketFactoryMarketsInitResponse: BaseMessage
--- @field MarketsInit table<string> The initialized market process IDs

--- Market factory markets init
--- @return MarketFactoryMarketsInitResponse The market factory markets init response message
function Outcome.marketFactoryMarketsInit()
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.marketFactory,
    Action = "Markets-Init"
  }).receive()
  -- Return formatted response
  return {
    MarketsInit = json.decode(response.Data),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketFactoryEventsByCreatorResponse: BaseMessage
--- @field EventsByCreator table<string> The event IDs created by the creator
--- @field Creator string The creator process ID

--- Market factory events by creator
--- @param creator string The creator process ID or `nil` for the sender
function Outcome.marketFactoryEventsByCreator(creator)
  -- Validate input
  validateValidArweaveAddress(creator, "creator")
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.marketFactory,
    Action = "Events-By-Creator",
    Creator = creator or ao.id
  }).receive()
  -- Return formatted response
  return {
    EventsByCreator = json.decode(response.Data),
    Creator = response.Tags.Creator,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketFactoryMarketsByCreatorResponse: BaseMessage
--- @field MarketsByCreator table<string> The market process IDs spawned by the creator
--- @field Creator string The creator process ID

--- Market factory markets by creator
--- @param creator string The creator process ID or `nil` for the sender
function Outcome.marketFactoryMarketsByCreator(creator)
  -- Validate input
  validateValidArweaveAddress(creator, "creator")
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.marketFactory,
    Action = "Markets-By-Creator",
    Creator = creator or ao.id
  }).receive()
  -- Return formatted response
  return {
    MarketsByCreator = json.decode(response.Data),
    Creator = response.Tags.Creator,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketFactoryGetProcessIdResponse: BaseMessage
--- @field ProcessId string The market factory process ID
--- @field Original-Msg-Id string The original message ID of the spawn market request

--- Market factory get process ID
--- @param originalMsgId string The original message ID of the spawn market request
--- @return MarketFactoryGetProcessIdResponse The market factory get process ID response message
function Outcome.marketFactoryGetProcessId(originalMsgId)
  -- Validate input
  validateValidArweaveAddress(originalMsgId, "originalMsgId")
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.marketFactory,
    Action = "Get-Process-Id",
    ["Original-Msg-Id"] = originalMsgId
  }).receive()
  -- Return formatted response
  return {
    ProcessId = response.Data,
    ["Original-Msg-Id"] = response.Tags["Original-Msg-Id"],
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketFactoryGetLatestProcessIdForCreatorResponse: BaseMessage
--- @field ProcessId string The latest market process ID spawned by the creator
--- @field Creator string The creator process ID

--- Market factory get latest process ID for creator
--- @param creator string? The creator process ID or `nil` for the sender
function Outcome.marketFactoryGetLatestProcessIdForCreator(creator)
  -- Validate input
  if creator then validateValidArweaveAddress(creator, "creator") end
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.marketFactory,
    Action = "Get-Latest-Process-Id-For-Creator",
    Creator = creator or ao.id
  }).receive()
  -- Return formatted response
  return {
    ProcessId = response.Data,
    Creator = response.Tags.Creator,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--[[
========================
MARKET FACTORY: VE TOKEN
========================
]]

-- TODO: `Allow-Creator`
-- TODO: `Disallow-Creator`

--[[
============================
MARKET FACTORY: CONFIGURATOR
============================
]]

--- @class MarketFactoryProposeConfiguratorNotice: BaseNotice
--- @field Configurator string The proposed configurator process ID

--- Market factory propose configurator
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param configurator string The proposed configurator process ID
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Propose-Configurator-Notice`: **marketFactory → ao.id** -- Logs the propose configurator action
--- @return MarketFactoryProposeConfiguratorNotice The market factory propose configurator notice
function Outcome.marketFactoryProposeConfigurator(configurator)
  -- Validate input
  validateValidArweaveAddress(configurator, "configurator")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Propose-Configurator",
    Configurator = configurator
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Configurator = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end


--- Market factory accept configurator
--- @warning Only callable by the market factory proposedConfigurator, or the transaction will fail
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Accept-Configurator-Notice`: **marketFactory → ao.id** -- Logs the accept configurator action
--- @return MarketFactoryProposeConfiguratorNotice The market factory propose configurator notice
function Outcome.marketFactoryAcceptConfigurator()
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Accept-Configurator"
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Configurator = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryUpdateVeTokenNotice: BaseNotice
--- @field VeToken string The new VE token process ID

--- Market factory update VE token
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param veToken string The new VE token process ID
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Ve-Token-Notice`: **marketFactory → ao.id** -- Logs the update VE token action
--- @return MarketFactoryUpdateVeTokenNotice The market factory update VE token notice
function Outcome.marketFactoryUpdateVeToken(veToken)
  -- Validate input
  validateValidArweaveAddress(veToken, "veToken")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Update-Ve-Token",
    VeToken = veToken
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    VeToken = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryUpdateMarketProcessCodeNotice: BaseNotice

--- Market factory update market process code
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param marketProcessCode string The new market process code
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Market-Process-Code-Notice`: **marketFactory → ao.id** -- Logs the update market process code action
--- @return MarketFactoryUpdateMarketProcessCodeNotice The market factory update market process code notice
function Outcome.marketFactoryUpdateMarketProcessCode(marketProcessCode)
  -- Validate input
  assert(marketProcessCode, "`marketProcessCode` is required.")
  assert(type(marketProcessCode) == "string", "`marketProcessCode` must be a string.")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Update-Market-Process-Code",
    Data = marketProcessCode
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Data = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryUpdateLpFeeNotice: BaseNotice
--- @field LpFee number The new LP fee

--- Market factory update LP fee
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param lpFee number The new LP fee, in basis points
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Lp-Fee-Notice`: **marketFactory → ao.id** -- Logs the update LP fee action
--- @return MarketFactoryUpdateLpFeeNotice The market factory update LP fee notice
function Outcome.marketFactoryUpdateLpFee(lpFee)
  -- Validate input
  validatePositiveIntegerOrZero(tostring(lpFee), "lpFee")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Update-Lp-Fee",
    LpFee = tostring(lpFee)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    LpFee = tonumber(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryUpdateProtocolFeeNotice: BaseNotice
--- @field ProtocolFee number The new protocol fee

--- Market factory update protocol fee
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param protocolFee number The new protocol fee, in basis points
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Protocol-Fee-Notice`: **marketFactory → ao.id** -- Logs the update protocol fee action
--- @return MarketFactoryUpdateProtocolFeeNotice The market factory update protocol fee notice
function Outcome.marketFactoryUpdateProtocolFee(protocolFee)
  -- Validate input
  validatePositiveIntegerOrZero(tostring(protocolFee), "protocolFee")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Update-Protocol-Fee",
    ProtocolFee = tostring(protocolFee)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    ProtocolFee = tonumber(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryUpdateProtocolFeeTargetNotice: BaseNotice
--- @field ProtocolFeeTarget string The new protocol fee target

--- Market factory update protocol fee target
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param protocolFeeTarget string The new protocol fee target
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Protocol-Fee-Target-Notice`: **marketFactory → ao.id** -- Logs the update protocol fee target action
--- @return MarketFactoryUpdateProtocolFeeTargetNotice The market factory update protocol fee target notice
function Outcome.marketFactoryUpdateProtocolFeeTarget(protocolFeeTarget)
  -- Validate input
  validateValidArweaveAddress(protocolFeeTarget, "protocolFeeTarget")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Update-Protocol-Fee-Target",
    ProtocolFeeTarget = protocolFeeTarget
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    ProtocolFeeTarget = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryUpdateMaximumTakeFeeNotice: BaseNotice
--- @field MaximumTakeFee number The new maximum take fee

--- Market factory update maximum take fee
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param maximumTakeFee number The new maximum take fee, in basis points
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Maximum-Take-Fee-Notice`: **marketFactory → ao.id** -- Logs the update maximum take fee action
--- @return MarketFactoryUpdateMaximumTakeFeeNotice The market factory update maximum take fee notice
function Outcome.marketFactoryUpdateMaximumTakeFee(maximumTakeFee)
  -- Validate input
  validatePositiveIntegerOrZero(tostring(maximumTakeFee), "maximumTakeFee")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Update-Maximum-Take-Fee",
    MaximumTakeFee = tostring(maximumTakeFee)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    MaximumTakeFee = tonumber(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryUpdateMaximumIterationsNotice: BaseNotice
--- @field MaximumIterations number The new maximum number of iterations in the init market call

--- Market factory update maximum iterations
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param maximumIterations number The new maximum iterations
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-Maximum-Iterations-Notice`: **marketFactory → ao.id** -- Logs the update maximum iterations action
--- @return MarketFactoryUpdateMaximumIterationsNotice The market factory update maximum iterations notice
function Outcome.marketFactoryUpdateMaximumIterations(maximumIterations)
  -- Validate input
  validatePositiveIntegerGreaterThanZero(tostring(maximumIterations), "maximumIterations")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Update-Maximum-Iterations",
    MaximumIterations = tostring(maximumIterations)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    MaximumIterations = tonumber(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryListCollateralTokenNotice: BaseNotice
--- @field CollateralToken string The collateral token process ID
--- @field Name string The collateral token name
--- @field Ticker string The collateral token ticker
--- @field Denomination number The collateral token denomination

--- Market factory list collateral token
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param collateral string The collateral token process ID
--- @param name string The collateral token name
--- @param ticker string The collateral token ticker
--- @param denomination number The collateral token denomination
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `List-Collateral-Token-Notice`: **marketFactory → ao.id** -- Logs the list collateral token action
--- @return MarketFactoryListCollateralTokenNotice The market factory list collateral token notice
function Outcome.marketFactoryListCollateralToken(collateral, name, ticker, denomination)
  -- Validate input
  validateValidArweaveAddress(collateral, "collateral")
  assert(name, "`name` is required.")
  assert(type(name) == "string", "`name` must be a string.")
  assert(ticker, "`ticker` is required.")
  assert(type(ticker) == "string", "`ticker` must be a string.")
  validatePositiveIntegerGreaterThanZero(denomination, "denomination")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "List-Collateral-Token",
    CollateralToken = collateral,
    Name = name,
    Ticker = ticker,
    Denomination = tostring(denomination)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Collateral = notice.Tags.CollateralToken,
    Name = notice.Tags.Name,
    Ticker = notice.Tags.Ticker,
    Denomination = tonumber(notice.Tags.Denomination),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end


--- @class MarketFactoryDelistCollateralTokenNotice: BaseNotice
--- @field CollateralToken string The collateral token process ID

--- Market factory delist collateral token
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param collateral string The collateral token process ID
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Delist-Collateral-Token-Notice`: **marketFactory → ao.id** -- Logs the delist collateral token action
--- @return MarketFactoryDelistCollateralTokenNotice The market factory delist collateral token notice
function Outcome.marketFactoryDelistCollateralToken(collateral)
  -- Validate input
  validateValidArweaveAddress(collateral, "collateral")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Delist-Collateral-Token",
    CollateralToken = collateral
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Collateral = notice.Tags.CollateralToken,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketFactoryTransferNotice: BaseNotice
--- @field Token string The token process ID
--- @field Quantity string The quantity of tokens to transfer
--- @field Recipient string The recipient process ID

--- Market factory transfer
--- @notice Used as a fallback to retrieve any tokens sent in error
--- @warning Only callable by the market factory configurator, or the transaction will fail
--- @param token string The token process ID
--- @param quantity string The quantity of tokens to transfer
--- @param recipient string The recipient process ID
--- @note **Emits the following notices:**
--- **🔄 Administrative Transfers**
--- - `Debit-Notice`: **token → marketFactory**            -- Transfers token quantity from the market factory
--- - `Credit-Notice`: **token → recipient**               -- Transfers token quantity to the recipient
--- **✅ Final Notices (Always sent)**
--- - `Transfer-Notice`: **marketFactory → ao.id**         -- Logs the transfer action
--- - `Transfer-Success-Notice`: **marketFactory → ao.id** -- Logs on transfer success
--- @return MarketFactoryTransferNotice The market factory transfer notice
function Outcome.marketFactoryTransfer(token, quantity, recipient)
  -- Validate input
  validateValidArweaveAddress(token, "token")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  validateValidArweaveAddress(recipient, "recipient")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.marketFactory,
    Action = "Transfer",
    Token = token,
    Quantity = quantity,
    Recipient = recipient
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Token = notice.From,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--[[
=====
TOKEN
=====
]]

--- @class TokenInfo: BaseMessage
--- @field Name string The token name
--- @field Ticker string The token ticker
--- @field Logo string The token logo
--- @field Denomination number The token denomination
--- @field MaximumSupply number? The token maximum supply (applies only to Outcome.token)

--- Info
--- @param target string? The token process ID or `nil` to use Outcome.token
--- @return TokenInfo The token info
function Outcome.tokenInfo(target)
  -- Validate input
  if target then validateValidArweaveAddress(target, "target") end
  -- Send and receive response
  local info = ao.send({
    Target = target or Outcome.token,
    Action = "Info"
  }).receive()
  -- Return formatted response
  return {
    Name = info.Tags.Name,
    Ticker = info.Tags.Ticker,
    Logo = info.Tags.Logo,
    Denomination = tonumber(info.Tags.Denomination),
    MaximumSupply = tonumber(info.Tags.MaximumSupply),
    MessageId = info.Id,
    Timestamp = info.Timestamp,
    ["Block-Height"] = info["Block-Height"]
  }
end

--- @class TokenClaimNotice: BaseNotice
--- @field Quantity string The quantity of tokens claimed
--- @field Recipient string The recipient process ID

--- Token claim
--- @param onBehalfOf string? The recipient process ID or `nil` for the sender
--- @note **Emits the following notices:**
--- **🔄 Settlement Transfers**
--- - `Debit-Notice`: **token → token**      -- Transfers token claim from the token
--- - `Credit-Notice`: **token → recipient** -- Transfers token claim to the recipient
--- **📊 Logging & Analytics**
--- - `Token-Claim-Notice`: **token → ao.id** -- Logs the token claim action
--- @return TokenClaimNotice The token claim notice
function Outcome.tokenClaim(onBehalfOf)
  -- Validate input
  if onBehalfOf then validateValidArweaveAddress(onBehalfOf, "onBehalfOf") end
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.token,
    Action = "Claim",
    ---@diagnostic disable-next-line: assign-type-mismatch
    OnBehalfOf = onBehalfOf or nil
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenTransferDebitNotice: BaseNotice
--- @field Quantity string The quantity of tokens debited
--- @field Recipient string The recipient process ID

--- Token transfer
--- @param quantity string The quantity of tokens to transfer
--- @param recipient string The recipient process ID
--- @param target string? The token process ID or `nil` to use Outcome.token
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Notice`: **token → ao.id**    -- Transfers token quantity from the sender
--- - `Credit-Notice`: **token → recipient** -- Transfers token quantity to the recipient
--- @return TokenTransferDebitNotice The token transfer debit notice
function Outcome.tokenTransfer(quantity, recipient, target)
  -- Validate input
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  validateValidArweaveAddress(recipient, "recipient")
  if target then validateValidArweaveAddress(target, "target") end
  -- Send and receive response
  local notice = ao.send({
    Target = target or Outcome.token,
    Action = "Transfer",
    Quantity = quantity,
    Recipient = recipient
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenMintNotice: BaseNotice
--- @field Quantity string The quantity of tokens minted
--- @field Recipient string The recipient of the minted tokens

--- Token mint
--- @notice Not supported by `Outcome.token`. Only available for `Outcome.testCollateral`
--- @param target string The token process ID
--- @param quantity string The quantity of tokens to mint
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
--- - `Mint-Notice`: **token → recipient** -- Mints tokens to the sender
--- @return TokenMintNotice The test collateral mint notice
function Outcome.tokenMint(target, quantity)
  -- Validate input
  validateValidArweaveAddress(target, "target")
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  assert(target ~= Outcome.token, "Token mint is not supported by Outcome.token")
  -- Send and receive response
  local notice = ao.send({
    Target = target,
    Action = "Mint",
    Quantity = quantity,
    Recipient = ao.id
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenBurnNotice: BaseNotice
--- @field Quantity string The quantity of tokens burned

--- Token burn
--- @param quantity string The quantity of tokens to burn
--- @param target string? The token process ID or `nil` to use Outcome.token
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
--- - `Burn-Notice`: **token → ao.id** -- Logs the token burn action
--- @return TokenBurnNotice The token burn notice
function Outcome.tokenBurn(quantity, target)
  -- Validate input
  validatePositiveIntegerGreaterThanZero(quantity, "quantity")
  if target then validateValidArweaveAddress(target, "target") end
  -- Send and receive response
  local notice = ao.send({
    Target = target or Outcome.token,
    Action = "Burn",
    Quantity = quantity
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Quantity = notice.Tags.Quantity,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenClaimBalanceResponse: BaseMessage
--- @field Balance string The claim balance of the account
--- @field Account string The account process ID

--- Token claim balance
--- @param account string The account process ID or `nil` for the sender
--- @return TokenClaimBalanceResponse The token claim balance response message
function Outcome.tokenClaimBalance(account)
  -- Validate input
  validateValidArweaveAddress(account, "account")
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.token,
    Action = "Claim-Balance",
    Account = account or ao.id
  }).receive()
  -- Return formatted response
  return {
    Balance = response.Tags.Balance,
    Account = response.Tags.Account,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class TokenClaimBalancesResponse: BaseMessage
--- @field Balances table<string, string> The mapping of account claim balances

--- Token claim balances
--- @return TokenClaimBalancesResponse The token claim balances response message
function Outcome.tokenClaimBalances()
  -- Send and receive response
  local response = ao.send({
    Target = Outcome.token,
    Action = "Claim-Balances"
  }).receive()
  -- Return formatted response
  return {
    Balances = json.decode(response.Data),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class TokenBalanceResponse: BaseMessage
--- @field Balance string The balance of the account
--- @field Account string The account process ID

--- Token balance
--- @param target string? The token process ID or `nil` to use Outcome.token
--- @param account string? The account process ID or `nil` for the sender
--- @return TokenBalanceResponse The token balance response message
function Outcome.tokenBalance(target, account)
  -- Validate input
  if target then validateValidArweaveAddress(target, "target") end
  if account then validateValidArweaveAddress(account, "account") end
  -- Send and receive response
  local response = ao.send({
    Target = target or Outcome.token,
    Action = "Balance",
    Account = account or ao.id
  }).receive()
  -- Return formatted response
  return {
    Balance = response.Tags.Balance,
    Account = response.Tags.Account,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class TokenBalancesResponse: BaseMessage
--- @field Balances table<string, string> The mapping of account balances

--- Token balances
--- @param target string? The token process ID or `nil` to use Outcome.token
--- @return TokenBalancesResponse The token balances response message
function Outcome.tokenBalances(target)
  -- Validate input
  if target then validateValidArweaveAddress(target, "target") end
  -- Send and receive response
  local response = ao.send({
    Target = target or Outcome.token,
    Action = "Balances"
  }).receive()
  -- Return formatted response
  return {
    Balances = json.decode(response.Data),
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class TokenTotalSupplyResponse: BaseMessage
--- @field TotalSupply string The total supply of the token

--- Token total supply
--- @param target string? The token process ID or `nil` to use Outcome.token
--- @return TokenTotalSupplyResponse The token total supply response message
function Outcome.tokenTotalSupply(target)
  -- Validate input
  if target then validateValidArweaveAddress(target, "target") end
  -- Send and receive response
  local response = ao.send({
    Target = target or Outcome.token,
    Action = "Total-Supply"
  }).receive()
  -- Return formatted response
  return {
    TotalSupply = response.Data,
    Error = response.Tags.Error or nil,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class TokenUpdateConfiguratorNotice: BaseNotice
--- @field Configurator string The new configurator process ID

--- Token update configurator
--- @warning Only callable by the token configurator, or the transaction will fail
--- @param configurator string The new configurator process ID
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
--- - `Update-Configurator-Notice`: **token → ao.id** -- Logs the token update configurator action
--- @return TokenUpdateConfiguratorNotice The token update configurator notice
function Outcome.tokenUpdateConfigurator(configurator)
  -- Validate input
  validateValidArweaveAddress(configurator, "configurator")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.token,
    Action = "Update-Configurator",
    Configurator = configurator
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Configurator = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenUpdateLpToHolderRatioNotice: BaseNotice
--- @field Ratio string The new LP to Holder ratio

--- Token update LP to Holder ratio
--- @warning Only callable by the token configurator, or the transaction will fail
--- @param ratio string The new LP to Holder ratio
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
--- - `Update-Lp-To-Holder-Ratio-Notice`: **token → ao.id** -- Logs the token update LP to holder ratio action
--- @return TokenUpdateLpToHolderRatioNotice The token update LP to Holder ratio notice
function Outcome.tokenUpdateLpToHolderRatio(ratio)
  -- Validate input
  validatePositiveNumberGreaterThanZero(ratio, "ratio")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.token,
    Action = "Update-LP-Holder-Ratio",
    Ratio = ratio
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    Ratio = notice.Data,
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenUpdateCollateralPricesNotice: BaseNotice
--- @field CollateralPrices table<string, string> The new mapping of collateral prices

--- Token update collateral prices
--- @warning Only callable by the token configurator, or the transaction will fail
--- @param collateralPrices table<string, string> The new mapping of collateral prices
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
--- - `Update-Collateral-Prices-Notice`: **token → ao.id** -- Logs the token update collateral prices action
--- @return TokenUpdateCollateralPricesNotice The token update collateral prices notice
function Outcome.tokenUpdateCollateralPrices(collateralPrices)
  -- Validate input
  validateArweaveToPositiveNumberMap(collateralPrices, "collateralPrices")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.token,
    Action = "Update-Collateral-Prices",
    CollateralPrices = json.encode(collateralPrices)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    CollateralPrices = json.decode(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenUpdateCollateralFactorsNotice: BaseNotice
--- @field CollateralFactors table<string, string> The new mapping of collateral factors

--- Token update collateral factors
--- @warning Only callable by the token configurator, or the transaction will fail
--- @param collateralFactors table<string, string> The new mapping of collateral factors
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
---  - `Update-Collateral-Factors-Notice`: **token → ao.id** -- Logs the token update collateral factors action
--- @return TokenUpdateCollateralFactorsNotice The token update collateral factors notice
function Outcome.tokenUpdateCollateralFactors(collateralFactors)
  -- Validate input
  validateArweaveToNumberMap(collateralFactors, "collateralFactors")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.token,
    Action = "Update-Collateral-Factors",
    CollateralFactors = json.encode(collateralFactors)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    CollateralFactors = json.decode(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class TokenUpdateCollateralDenominationsNotice: BaseNotice
--- @field CollateralDenominations table<string, string> The new mapping of collateral denominations

--- Token update collateral denominations
--- @warning Only callable by the token configurator, or the transaction will fail
--- @param collateralDenominations table<string, string> The new mapping of collateral denominations
--- @note **Emits the following notices:**
--- **📊 Logging & Analytics**
--- - `Update-Collateral-Denominations-Notice`: **token → ao.id** -- Logs the token update collateral denominations action
--- @return TokenUpdateCollateralDenominationsNotice The token update collateral denominations notice
function Outcome.tokenUpdateCollateralDenominations(collateralDenominations)
  -- Validate input
  validateArweaveToPositiveIntegerMap(collateralDenominations, "collateralDenominations")
  -- Send and receive response
  local notice = ao.send({
    Target = Outcome.token,
    Action = "Update-Collateral-Denominations",
    CollateralDenominations = json.encode(collateralDenominations)
  }).receive()
  -- Return formatted response
  return {
    Action = notice.Tags.Action,
    CollateralDenominations = json.decode(notice.Data),
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

return Outcome