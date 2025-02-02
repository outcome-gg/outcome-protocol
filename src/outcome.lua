--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

Outcome = { _version = "0.0.1"}
Outcome.__index = Outcome
Outcome.configurator = "KnOsk_EaaI5zNCb18PdbzeeBZYWVxq0jeg2ZgkhBO8M"
Outcome.marketFactory = "Gt0NBIvtGgJW8yiy1TzeA7wI38QVFZDNZ_6Nz8HEKjg"
Outcome.token = "haUOiKKmYMGum59nWZx5TVFEkDgI5LakIEY7jgfQgAI"

local sharedUtils = require('configuratorModules.sharedUtils')
local json = require('json')

--- @class Outcome
--- @field _version string The Outcome package version
--- @field configurator string The Outcome configurator process ID
--- @field marketFactory string The Outcome market factory process ID
--- @field token string The Outcome utility token process ID

--- @class AOMessage
--- @field MessageId string The message ID
--- @field Timestamp number The timestamp of the message
--- @field Block-Height number The block height of the message

--- @class BaseNotice: AOMessage
--- @field Action string The action name

--[[
========
INTERNAL
========
]]
local function validateConfiguratorUpdateProcess(updateProcess, updateAction, updateTags, updateData)
  assert(sharedUtils.isValidArweaveAddress(updateProcess), 'UpdateProcess must be a valid Arweave address!')
  assert(type(updateAction) == 'string', 'UpdateAction is required!')
  assert(sharedUtils.isValidKeyValueJSON(updateTags) or updateTags == nil, 'UpdateTags must be valid JSON!')
  assert(sharedUtils.isValidKeyValueJSON(updateData) or updateData == nil, 'UpdateData must be valid JSON!')
end

local function validateConfiguratorUpdateAdmin(updateAdmin)
  assert(sharedUtils.isValidArweaveAddress(updateAdmin), 'UpdateAdmin must be a valid Arweave address!')
end

--[[
====
INFO
====
]]

--- Info
--- @return table outcomeInfo The Outcome package info
function Outcome.info()
  return {
    Version = Outcome._version,
    Configurator = Outcome.configurator,
    MarketFactory = Outcome.marketFactory,
    Token = Outcome.token
  }
end

--[[
==================
CONFIGURATOR: INFO
==================
]]

---@class ConfiguratorInfo
---@field Admin string The configurator admin process ID
---@field Delay number The update delay in seconds
---@field Staged table<string, number> A mapping of update hashes to their staged timestamps

--- Configurator info
--- @return ConfiguratorInfo configuratorInfo The configurator info
function Outcome.configuratorInfo()
  local info = ao.send({
    Target = Outcome.configurator,
    Action = "Info"
  }).receive()
  return {
    Admin = info.Tags.Admin,
    Delay = tonumber(info.Tags.Delay),
    Staged = json.decode(info.Tags.Staged)
  }
end

--[[
===================
CONFIGURATOR: WRITE
===================
]]

--- @class ConfiguratorStageUpdateNotice: BaseNotice
--- @field UpdateProcess string The process to update
--- @field UpdateAction string The update message action
--- @field UpdateTags string The update message tags
--- @field UpdateData string The update message data
--- @field Hash string The hash of the staged update

--- Configurator stage update
--- @warning Only callable by the configurator admin
--- @param updateProcess string The process to update
--- @param updateAction string The update message action
--- @param updateTags table The update message tags or `nil`
--- @param updateData table The update message data or `nil`
--- @return ConfiguratorStageUpdateNotice configuratorStageUpdateNotice The configurator stage update notice
function Outcome.configuratorStageUpdate(updateProcess, updateAction, updateTags, updateData)
  validateConfiguratorUpdateProcess(updateProcess, updateAction, updateTags, updateData)
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Stage-Update",
    UpdateProcess = updateProcess,
    UpdateAction = updateAction,
    UpdateTags = updateTags and json.encode(updateTags) or nil,
    UpdateData = updateData and json.encode(updateData) or nil
  }).receive()
  return {
    Action = notice.Tags.Action,
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
--- @warning Only callable by the configurator admin
--- @param updateProcess string The process to update
--- @param updateAction string The update message action
--- @param updateTags table The update message tags or `nil`
--- @param updateData table The update message data or `nil`
--- @return ConfiguratorUnstageUpdateNotice configuratorUnstageUpdateNotice The configurator unstage update notice
function Outcome.configuratorUnstageUpdate(updateProcess, updateAction, updateTags, updateData)
  validateConfiguratorUpdateProcess(updateProcess, updateAction, updateTags, updateData)
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Unstage-Update",
    UpdateProcess = updateProcess,
    UpdateAction = updateAction,
    UpdateTags = updateTags and json.encode(updateTags) or nil,
    UpdateData = updateData and json.encode(updateData) or nil
  }).receive()
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
--- @warning Only callable by the configurator admin
--- @param updateProcess string The process to update
--- @param updateAction string The update message action
--- @param updateTags table The update message tags or `nil`
--- @param updateData table The update message data or `nil`
--- @return ConfiguratorActionUpdateNotice configuratorActionUpdateNotice The configurator action update notice
function Outcome.configuratorActionUpdate(updateProcess, updateAction, updateTags, updateData)
  validateConfiguratorUpdateProcess(updateProcess, updateAction, updateTags, updateData)
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Action-Update",
    UpdateProcess = updateProcess,
    UpdateAction = updateAction,
    UpdateTags = updateTags and json.encode(updateTags) or nil,
    UpdateData = updateData and json.encode(updateData) or nil
  }).receive()
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
-- @return ConfiguratorStageUpdateAdminNotice configuratorStageUpdateAdminNotice The configurator stage update admin notice
function Outcome.configuratorStageUpdateAdmin(updateAdmin)
  validateConfiguratorUpdateAdmin(updateAdmin)
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Stage-Update-Admin",
    UpdateAdmin = updateAdmin
  }).receive()
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
--- @return ConfiguratorUnstageUpdateAdminNotice configuratorUnstageUpdateAdminNotice The configurator unstage update admin notice
function Outcome.configuratorUnstageUpdateAdmin(updateAdmin)
  validateConfiguratorUpdateAdmin(updateAdmin)
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Unstage-Update-Admin",
    UpdateAdmin = updateAdmin
  }).receive()
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
--- @return ConfiguratorActionUpdateAdminNotice configuratorActionUpdateAdminNotice The configurator action update admin notice
function Outcome.configuratorActionUpdateAdmin(updateAdmin)
  validateConfiguratorUpdateAdmin(updateAdmin)
  local notice = ao.send({
    Target = Outcome.configurator,
    Action = "Action-Update-Admin",
    UpdateAdmin = updateAdmin
  }).receive()
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

---@class MarketInfo: AOMessage
---@field Name string The market name
---@field Ticker string The market ticker
---@field Logo string The market logo
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
--- @return MarketInfo market The market info
function Outcome.marketInfo(market)
  local info = ao.send({
    Target = market,
    Action = "Info"
  }).receive()
  return {
    Name = info.Tags.Name,
    Ticker = info.Tags.Ticker,
    Logo = info.Tags.Logo,
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
--- @field X-Distribution string The initial probability distribution

--- @dev Emitted when funding is successfully added to the market
--- @class MarketAddFundingNotice: BaseNotice
--- @field FundingAdded string A JSON-encoded array of funding amounts per position ID, produced via `json.encode(table<number>)` 
--- @field MintAmount string The amount of LP tokens minted

--- Market add funding
--- @warning Param `distribution` is required for initial market funding but must be omitted for subsequent funding, or the transaction will fail
--- @warning The `distribution` must be a numeric table matching the outcome slot count, with a total sum greater than zero, or `nil`
--- @param market string The market process ID
--- @param collateral string The collateral token process ID
--- @param quantity number The quantity of collateral tokens to transfer, a.k.a. the funding amount
--- @param distribution table<number> The initial probability distribution
--- @param onBehalfOf string? The recipient of the outcome position tokens (optional)
function Outcome.marketAddFunding(market, collateral, quantity, distribution, onBehalfOf)
  local notice = ao.send({
    Target = collateral,
    Action = "Transfer",
    Quantity = tostring(quantity),
    Recipient = market,
    ["X-Action"] = "Add-Funding",
    ["X-Distribution"] = distribution and json.encode(distribution) or nil,
    ["X-OnBehalfOf"] = onBehalfOf or ao.id
  }).receive()
  return {
    Action = notice.Tags.Action,
    Collateral = notice.From,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    ["X-Action"] = notice.Tags["X-Action"],
    ["X-Distribution"] = notice.Tags["X-Distribution"],
    ["X-OnBehalfOf"] = notice.Tags["X-OnBehalfOf"],
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketRemoveFundingDebitNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field Quantity string The quantity of LP tokens transferred, i.e. the amount of shares to burn
--- @field Recipient string The recipient of the debit, i.e. the market process ID
--- @field X-Action string The forwarded action

--- @dev Emitted when funding is successfully removed from the market
--- @notice The sender receives a credit of outcome position tokens, not collateral tokens
--- @use Call `marketMergePositions` to merge outcome position tokens back into collateral
--- @class MarketOpTokensCreditBatchNotice: BaseNotice
--- @field Sender string The sender of the outcome position tokens
--- @field PositionIds string The outcome position token position IDs, produced via `json.encode(table<string>)`
--- @field Quantities string The quantities of outcome position tokens transferred per ID, produced via `json.encode(table<string>)`

--- @dev Emitted when funding is successfully removed from the market
--- @notice The `SharesToBurn` may be less than the `Quantity` of LP tokens sent. In this case, the sender should credit notice for the difference
--- @class MarketRemoveFundingNotice: BaseNotice
--- @field SendAmounts string A JSON-encoded array of send amounts per position ID, produced via `json.encode(table<number>)`
--- @field CollateralRemovedFromFeePool string The collateral removed from the fee pool
--- @field SharesToBurn string The shares to burn, i.e. the LP tokens transferred minus any amount returned to the sender

--- Market remove funding
--- @notice Calling `marketRemoveFunding` will simultaneously return the liquidity provider's share of accrued fees
--- @param market string The market process ID
--- @param quantity number The quantity of LP tokens to transfer, i.e. the amount of shares to burn
--- @return MarketRemoveFundingDebitNotice marketRemoveFundingDebitNotice The market remove funding debit notice
function Outcome.marketRemoveFunding(market, quantity)
  local notice = ao.send({
    Target = market,
    Action = "Transfer",
    Quantity = tostring(quantity),
    Recipient = market,
    ["X-Action"] = "Remove-Funding",
  }).receive()
  return {
    Action = notice.Tags.Action,
    Collateral = notice.From,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    ["X-Action"] = notice.Tags["X-Action"],
    Error = notice.Tags.Error or nil,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketBuyDebitNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field Quantity string The quantity of collateral tokens transferred
--- @field Recipient string The recipient of the debit, i.e. the market process ID
--- @field X-Action string The forwarded action
--- @field X-OnBehalfOf string The recipient of the outcome position tokens
--- @field X-PositionId string The outcome position token position ID
--- @field X-MinPositionTokensToBuy string The minimum outcome position tokens to buy

--- @dev Emitted when outcome position tokens are successfully bought from the market
--- @class MarketBuyNotice: BaseNotice
--- @field OnBehalfOf string The recipient of the outcome position tokens
--- @field InvestmentAmount string The investment amount paid in collateral tokens
--- @field FeeAmount string The fee amount paid to the liquidity pool
--- @field PositionId string The outcome position token position ID
--- @field PositionTokensBought string The number of outcome position tokens bought

--- @dev Emitted when outcome position tokens are successfully credited to the recipient
--- @class MarketOpTokensCreditSingleNotice: BaseNotice
--- @field Sender string The sender of the outcome position tokens
--- @field PositionId string The outcome position token position ID
--- @field Quantity string The quantity of outcome position tokens transferred

--- Market buy
--- @warning Ensure sufficient liquidity exists before calling `marketBuy`, or the transaction may fail
--- @use Call `marketCalcBuyAmount` to verify liquidity and the number of outcome position tokens to be purchased
--- @param market string The market process ID
--- @param collateral string The collateral token process ID
--- @param quantity number The quantity of collateral tokens to transfer, a.k.a. the investment amount
--- @param positionId string The outcome position token position ID
--- @param minPositionTokensToBuy number The minimum outcome position tokens to buy
--- @param onBehalfOf string? The recipient of the outcome position tokens (optional)
--- @return MarketBuyDebitNotice marketBuyDebitNotice The market buy debit notice
function Outcome.marketBuy(market, collateral, quantity, positionId, minPositionTokensToBuy, onBehalfOf)
  onBehalfOf = onBehalfOf or ao.id
  local notice = ao.send({
    Target = collateral,
    Action = "Transfer",
    Quantity = tostring(quantity),
    Recipient = market,
    ["X-Action"] = "Buy",
    ["X-OnBehalfOf"] = onBehalfOf,
    ["X-PositionId"] = positionId,
    ["X-MinPositionTokensToBuy"] = tostring(minPositionTokensToBuy)
  }).receive()
  return {
    Action = notice.Tags.Action,
    Collateral = notice.From,
    Quantity = notice.Tags.Quantity,
    Recipient = notice.Tags.Recipient,
    ["X-Action"] = notice.Tags["X-Action"],
    ["X-OnBehalfOf"] = notice.Tags["X-OnBehalfOf"],
    ["X-PositionId"] = notice.Tags["X-PositionId"],
    ["X-MinPositionTokensToBuy"] = notice.Tags["X-MinPositionTokensToBuy"],
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

--- Market sell
--- @warning Ensure sufficient liquidity exists before calling `marketSell`, or the transaction may fail
--- @use Call `marketCalcSellAmount` to verify liquidity and the number of outcome position tokens to be sold
--- @param market string The market process ID
--- @param quantity number The quantity of outcome position tokens to transfer, a.k.a. the max outcome position tokens to sell
--- @param positionId string The outcome position token position ID
--- @param returnAmount number The quantity of collateral tokens to receive
--- @return MarketSellNotice marketSellNotice The market sell notice
function Outcome.marketSell(market, quantity, positionId, returnAmount)
  local notice = ao.send({
    Target = market,
    Action = "Sell",
    Quantity = tostring(quantity),
    PositionId = positionId,
    ReturnAmount = tostring(returnAmount)
  }).receive()
  return {
    Action = notice.Tags.Action,
    ReturnAmount = notice.Tags.ReturnAmount,
    FeeAmount = notice.Tags.FeeAmount,
    PositionId = notice.Tags.PositionId,
    PositionTokensSold = notice.Tags.PositionTokensSold,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketWithdrawFeesNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field FeeAmount string The fee amount withdrawn

--- @dev Emitted when fees exceed zero and collateral tokens are successfully transferred
--- @class MarketWithdrawFeesCreditNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field Quantity string The quantity of collateral tokens transferred, i.e. the amount of fees withdrawn
--- @field Sender string The sender of the credit, i.e. the market process ID

--- Market withdraw fees
--- @param market string The market process ID
--- @return MarketWithdrawFeesNotice marketWithdrawFeesNotice The market withdraw fees notice
function Outcome.marketWithdrawFees(market)
  local notice = ao.send({
    Target = market,
    Action = "Withdraw-Fees"
  }).receive()
  return {
    Action = notice.Tags.Action,
    FeeAmount = notice.Tags.FeeAmount,
    Collateral = notice.From,
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

--- @class MarketCalcBuyAmountResponse: AOMessage
--- @field InvestmentAmount string The investment amount in collateral tokens
--- @field PositionId string The outcome position token position ID
--- @field BuyAmount string The amount of outcome position tokens to be bought for the given investment amount

--- Market calc buy amount
--- @warning Ensure sufficient liquidity exists before calling `marketCalcBuyAmount`, or the transaction may fail
--- @param market string The market process ID
--- @param investmentAmount number The investment amount
--- @param positionId string The outcome position token position ID
--- @return MarketCalcBuyAmountResponse marketCalcBuyAmountResponse The market calc buy amount response message
function Outcome.marketCalcBuyAmount(market, investmentAmount, positionId)
  local notice = ao.send({
    Target = market,
    Action = "Calc-Buy-Amount",
    InvestmentAmount = tostring(investmentAmount),
    PositionId = positionId
  }).receive()
  return {
    BuyAmount = notice.Tags.BuyAmount,
    PositionId = notice.Tags.PositionId,
    InvestmentAmount = notice.Tags.InvestmentAmount,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketCalcSellAmountResponse: AOMessage
--- @field ReturnAmount string The return amount in collateral tokens
--- @field PositionId string The outcome position token position ID
--- @field SellAmount string The amount of outcome positionn tokens to be sold for the given return amount

--- Market calc sell amount
--- @warning Ensure sufficient liquidity exists before calling `marketCalcSellAmount`, or the transaction may fail
--- @param market string The market process ID
--- @param returnAmount number The return amount
--- @param positionId string The outcome position token position ID
--- @return MarketCalcSellAmountResponse marketCalcSellAmountResponse The market calc sell amount response message
function Outcome.marketCalcSellAmount(market, returnAmount, positionId)
  local response = ao.send({
    Target = market,
    Action = "Calc-Sell-Amount",
    ReturnAmount = tostring(returnAmount),
    PositionId = positionId
  }).receive()
  return {
    SellAmount = response.Tags.SellAmount,
    PositionId = response.Tags.PositionId,
    ReturnAmount = response.Tags.ReturnAmount,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketCollectedFeesResponse: AOMessage
--- @field CollectedFees string The collected fees

--- Market collected fees
--- @param market string The market process ID
--- @return MarketCollectedFeesResponse marketCollectedFeesResponse The market collected fees response message
function Outcome.marketCollectedFees(market)
  local response = ao.send({
    Target = market,
    Action = "Collected-Fees"
  }).receive()
  return {
    CollectedFees = response.Tags.CollectedFees,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketFeesWithdrawableResponse: AOMessage
--- @field FeesWithdrawable string The fees withdrawable by the account
--- @field Account string The account process ID

--- Market fees withdrawable
--- @param market string The market process ID
--- @param account string The account process ID or `nil` for the sender
--- @return MarketFeesWithdrawableResponse marketFeesWithdrawableResponse The market fees withdrawable response message
function Outcome.marketFeesWithdrawable(market, account)
  local response = ao.send({
    Target = market,
    Action = "Fees-Withdrawable",
    Account = account
  }).receive()
  return {
    FeesWithdrawable = response.Tags.FeesWithdrawable,
    Account = response.Tags.Account,
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

--- @dev Emitted when LP fees are accrued and automatically withdrawn before transfer
--- @class MarketWithdrawFeesNotice: BaseNotice

--- Market LP token transfer
--- @param market string The market process ID
--- @param recipient string The recipient process ID
--- @param quantity number The quantity of LP tokens to transfer
--- @return MarketLpTokenDebitNotice marketLpTokenDebitNotice The market LP token debit notice
function Outcome.marketLpTokenTransfer(market, recipient, quantity)
  local notice = ao.send({
    Target = market,
    Action = "Transfer",
    Quantity = tostring(quantity),
    Recipient = recipient
  }).receive()
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

--- @class MarketLpTokenBalanceResponse: AOMessage
--- @field Balance string The LP token balance of the account
--- @field Ticker string The LP token ticker
--- @field Account string The account process ID

--- Market LP token balance
--- @param market string The market process ID
--- @param recipient string The recipient process ID or `nil` for the sender
--- @return MarketLpTokenBalanceResponse marketLpTokenBalanceResponse The market LP token balance response message
function Outcome.marketLpTokenBalance(market, recipient)
  local response = ao.send({
    Target = market,
    Action = "Balance",
    Recipient = recipient
  }).receive()
  return {
    Balance = response.Tags.Balance,
    Ticker = response.Tags.Ticker,
    Account = response.Tags.Account,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketLpTokenBalancesResponse: AOMessage
--- @field Balances table<string, string> The LP token balances; a mapping of account process IDs to their LP token balances

--- Market LP token balances
--- @param market string The market process ID
--- @return MarketLpTokenBalancesResponse marketLpTokenBalancesResponse The market LP token balances response message
function Outcome.marketLpTokenBalances(market)
  local response = ao.send({
    Target = market,
    Action = "Balances"
  }).receive()
  return {
    Balances = json.decode(response.Data),
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketLpTokenTotalSupplyResponse: AOMessage
--- @field TotalSupply string The LP token total supply

--- Market LP token total supply
--- @param market string The market process ID
--- @return MarketLpTokenTotalSupplyResponse marketLpTokenTotalSupplyResponse The market LP token total supply response message
function Outcome.marketLpTokenTotalSupply(market)
  local response = ao.send({
    Target = market,
    Action = "Total-Supply"
  }).receive()
  return {
    TotalSupply = response.Data,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--[[
=======================
MARKET: OP TOKENS WRITE
=======================
]]

--- @class MarketMergePositionsNotice: BaseNotice
--- @field Collateral string The collateral token
--- @field Quantity string The quantity of collateral tokens to return to user

--- @dev Emitted when outcome position tokens are successfully burned
--- @class MarketOpTokensMergePositionsBurnBatchNotice: BaseNotice

--- @dev Emitted when collateral tokens are successfully transferred
--- @class MarketMergePositionsCreditNotice: BaseNotice

--- Market outcome position tokens merge positions
--- @warning User must have stated quantity of outcome position tokens from each position ID, 
--- and their must be sufficient liquidity to merge for collateral, or the transaction will fail
--- @param market string The market process ID
--- @param quantity number The quantity of outcome position tokens from each position ID to merge for collataral
--- @param onBehalfOf string The recipient of the collateral tokens, or `nil` for the sender
--- @return MarketMergePositionsNotice marketMergePositionsNotice The market merge positions notice
function Outcome.marketMergePositions(market, quantity, onBehalfOf)
  local notice = ao.send({
    Target = market,
    Action = "Merge-Positions",
    Quantity = tostring(quantity),
    OnBehalfOf = onBehalfOf or nil
  }).receive()
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
--- @return MarketReportPayoutsNotice marketReportPayoutsNotice The market report payouts notice
function Outcome.marketReportPayouts(market, payouts)
  local notice = ao.send({
    Target = market,
    Action = "Report-Payouts",
    Payouts = json.encode(payouts)
  }).receive()
  return {
    Action = notice.Tags.Action,
    PayoutNumerators = json.decode(notice.Tags.PayoutNumerators),
    ResolutionAgent = notice.Tags.ResolutionAgent,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketRedeemPositionsNotice: BaseNotice
--- @field Payout string The payout amount
--- @field Collateral string The collateral token

--- @dev Emitted when outcome position tokens are successfully burned; one notice for each position ID held by the sender
--- @class MarketOpTokensBurnSingleNotice: BaseNotice

--- @dev Emitted when collateral tokens are successfully transferred
--- @class MarketRedeemPositionsCreditNotice: BaseNotice

--- Market redeem positions
--- @warning Market must be resolve or the transaction will fail
--- @param market string The market process ID
--- @return MarketRedeemPositionsNotice marketRedeemPositionsNotice The market redeem positions notice
function Outcome.marketRedeemPositions(market)
  local notice = ao.send({
    Target = market,
    Action = "Redeem-Positions"
  }).receive()
  return {
    Action = notice.Tags.Action,
    Payout = notice.Tags.Payout,
    Collateral = notice.Tags.CollateralToken,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketOpTokensDebitSingleNotice: BaseNotice
--- @field Market string The outcome position token (a.k.a.) market process ID
--- @field Quantity string The quantity of outcome position tokens transferred
--- @field PositionId string The outcome position token position ID
--- @field Recipient string The recipient of the token transfer

--- Market outcome position token transfer
--- @param market string The market process ID
--- @param quantity number The quantity of outcome position tokens to transfer
--- @param positionId string The outcome position token position ID
--- @param recipient string The recipient of the outcome position tokens
--- @return MarketOpTokensDebitSingleNotice marketOpTokensDebitSingleNotice The market outcome position token debit single notice
function Outcome.marketOpTokensTransfer(market, quantity, positionId, recipient)
  local notice = ao.send({
    Target = market,
    Action = "Transfer-Single",
    Quantity = tostring(quantity),
    PositionId = positionId,
    Recipient = recipient
  }).receive()
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

--- @class MarketOpTokensDebitBatchNotice: BaseNotice
--- @field Market string The outcome position token (a.k.a.) market process ID
--- @field Quantities table<string> The quantiies per position ID
--- @field PositionId string The position IDs
--- @field Recipient string The recipient of the token transfer

--- Market outcome position token transfer batch
--- @param market string The market process ID
--- @param quantities table<string> The quantities of outcome position tokens to transfer per position ID
--- @param positionIds table<string> The outcome position token position IDs
--- @param recipient string The recipient of the outcome position tokens
--- @return MarketOpTokensDebitBatchNotice marketOpTokensDebitBatchNotice The market outcome position token debit batch notice
function Outcome.marketOpTokensTransferBatch(market, quantities, positionIds, recipient)
  local notice = ao.send({
    Target = market,
    Action = "Transfer-Batch",
    Quantities = json.encode(quantities),
    PositionIds = json.encode(positionIds),
    Recipient = recipient
  }).receive()
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
MARKET: OP TOKENS READ
======================
]]

--- @class MarketGetPayoutNumeratorsResponse: AOMessage
--- @field PayoutNumerators table<number> The payout numerators; where each index value divided by the sum represents the proportional payout

--- Market get payout numerators
--- @param market string The market process ID
--- @return MarketGetPayoutNumeratorsResponse marketGetPayoutNumeratorsResponse The market get payout numerators response message
function Outcome.marketGetPayoutNumerators(market)
  local response = ao.send({
    Target = market,
    Action = "Get-Payout-Numerators"
  }).receive()
  return {
    PayoutNumerators = json.decode(response.Data),
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketGetPayoutDenominatorResponse: AOMessage
--- @field PayoutDenominator number The payout denominator; the sum of the payout numerators, zero if the market is not resolved

--- Market get payout denominator
--- @param market string The market process ID
--- @return MarketGetPayoutDenominatorResponse marketGetPayoutDenominatorResponse The market get payout denominator response message
function Outcome.marketGetPayoutDenominator(market)
  local response = ao.send({
    Target = market,
    Action = "Get-Payout-Denominator"
  }).receive()
  return {
    PayoutDenominator = tonumber(response.Data),
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketOpTokensBalanceByIdResponse: AOMessage
--- @field Balance string The balance of the recipient
--- @field PositionId string The outcome position token position ID
--- @field Account string The account process ID

--- Market outcome position tokens balance by ID
--- @param market string The market process ID
--- @param positionId string The outcome position token position ID
--- @param recipient string The recipient process ID or `nil` for the sender
--- @return MarketOpTokensBalanceByIdResponse marketOpTokensBalanceByIdResponse The market outcome position tokens balance by ID response message
function Outcome.marketOpTokensBalanceById(market, positionId, recipient)
  local response = ao.send({
    Target = market,
    Action = "Balance-By-Id",
    PositionId = positionId,
    Recipient = recipient
  }).receive()
  return {
    Balance = response.Tags.Balance,
    PositionId = response.Tags.PositionId,
    Account = response.Tags.Account,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketOpTokensBalancesByIdResponse: AOMessage
--- @field Balances string The balance of the recipient
--- @field PositionId string The outcome position token position ID

--- Market outcome position tokens balances by ID
--- @param market string The market process ID
--- @param positionId string The outcome position token position ID
--- @return MarketOpTokensBalancesByIdResponse marketOpTokensBalancesByIdResponse The market outcome position tokens balances by ID response message
function Outcome.marketOpTokensBalancesById(market, positionId)
  local response = ao.send({
    Target = market,
    Action = "Balances-By-Id",
    PositionId = positionId
  }).receive()
  return {
    Balances = json.decode(response.Data),
    PositionId = response.Tags.PositionId,
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketOpTokensBatchBalanceResponse: AOMessage
--- @field Balances table<string> The outcome position tokens balance for each indexed position ID and account pair provided
--- @field PositionIds table<string> The outcome position token position IDs
--- @field Accounts table<string> The account process IDs

--- Market outocome position tokens batch balance
--- @param market string The market process ID
--- @param positionIds table<string> The outcome position token position IDs
--- @param recipients table<string> The recipient process IDs
--- @return MarketOpTokensBatchBalanceResponse marketOpTokensBatchBalanceResponse The market outcome position tokens batch balance response message
function Outcome.marketOpTokensBatchBalance(market, positionIds, recipients)
  local response = ao.send({
    Target = market,
    Action = "Batch-Balance",
    PositionIds = json.encode(positionIds),
    Recipients = json.encode(recipients)
  }).receive()
  return {
    Balances = json.decode(response.Data),
    PositionIds = json.decode(response.Tags.PositionIds),
    Accounts = json.decode(response.Tags.Accounts),
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--- @class MarketOpTokensBatchBalancesResponse: AOMessage
--- @field Balances table<string, table<string, string>> The user outcome position tokens balances for the position IDs provided, mapping position IDs to user process IDs to their balances
--- @field PositionIds table<string> The outcome position token position IDs

--- Market outcome position tokens batch balances
--- @param market string The market process ID
--- @param positionIds table<string> The outcome position token position IDs
function Outcome.marketOpTokensBatchBalances(market, positionIds)
  local response = ao.send({
    Target = market,
    Action = "Batch-Balances",
    PositionIds = json.encode(positionIds)
  }).receive()
  return {
    Balances = json.decode(response.Data),
    MessageId = response.Id,
    Timestamp = response.Timestamp,
    ["Block-Height"] = response["Block-Height"]
  }
end

--[[
==========================
MARKET: CONFIGURATOR WRITE
==========================
]]

--- @class MarketUpdateConfiguratorNotice: BaseNotice
--- @field Configurator string The new configurator process ID

--- Market update configurator
--- @warning Only callable by the market configurator, or the transaction will fail
--- @param market string The market process ID
--- @param configurator string The new configurator process ID
--- @return MarketUpdateConfiguratorNotice marketUpdateConfiguratorNotice The market update configurator notice
function Outcome.marketUpdateConfigurator(market, configurator)
  local notice = ao.send({
    Target = market,
    Action = "Update-Configurator",
    Configurator = configurator
  }).receive()
  return {
    Action = notice.Tags.Action,
    Configurator = notice.Data,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--- @class MarketUpdateIncentivesNotice: BaseNotice
--- @field Incentives string The new incentives process ID

--- Market update incentives
--- @warning Only callable by the market configurator, or the transaction will fail
--- @param market string The market process ID
--- @param incentives string The new incentives process ID
--- @return MarketUpdateIncentivesNotice marketUpdateIncentivesNotice The market update incentives notice
function Outcome.marketUpdateIncentives(market, incentives)
  local notice = ao.send({
    Target = market,
    Action = "Update-Incentives",
    Incentives = incentives
  }).receive()
  return {
    Action = notice.Tags.Action,
    Incentives = notice.Data,
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
--- @return MarketUpdateTakeFeeNotice marketUpdateTakeFeeNotice The market update take fee notice
function Outcome.marketUpdateTakeFee(market, creatorFee, protocolFee)
  local notice = ao.send({
    Target = market,
    Action = "Update-Take-Fee",
    CreatorFee = tostring(creatorFee),
    ProtocolFee = tostring(protocolFee)
  }).receive()
  return {
    Action = notice.Tags.Action,
    CreatorFee = tonumber(notice.Tags.CreatorFee),
    ProtocolFee = tonumber(notice.Tags.ProtocolFee),
    TakeFee = tonumber(notice.Data),
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
--- @return MarketUpdateProtocolFeeTargetNotice marketUpdateProtocolFeeTargetNotice The market update protocol fee target notice
function Outcome.marketUpdateProtocolFeeTarget(market, protocolFeeTarget)
  local notice = ao.send({
    Target = market,
    Action = "Update-Protocol-Fee-Target",
    ProtocolFeeTarget = protocolFeeTarget
  }).receive()
  return {
    Action = notice.Tags.Action,
    ProtocolFeeTarget = notice.Data,
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
function Outcome.marketUpdateLogo(market, logo)
  local notice = ao.send({
    Target = market,
    Action = "Update-Logo",
    Logo = logo
  }).receive()
  return {
    Action = notice.Tags.Action,
    Logo = notice.Data,
    MessageId = notice.Id,
    Timestamp = notice.Timestamp,
    ["Block-Height"] = notice["Block-Height"]
  }
end

--[[
==============
MARKET FACTORY
==============
]]

function Outcome.marketFactory()
end

function Outcome.marketFactoryInfo()
end

function Outcome.marketFactorySpawnMarket()
end

function Outcome.marketFactoryInitMarket()
end

function Outcome.marketFactoryMarketsPending()
end

function Outcome.marketFactoryMarketsInit()
end

function Outcome.marketFactoryMarketsSpawnedByCreator()
end

function Outcome.marketFactoryGetProcessId()
end

function Outcome.marketFactoryGetLatestProcessIdForCreator()
end

function Outcome.marketFactoryUpdateConfigurator()
end

function Outcome.marketFactoryUpdateIncentives()
end

function Outcome.marketFactoryUpdateLpFee()
end

function Outcome.marketFactoryUpdateProtocolFee()
end

function Outcome.marketFactoryUpdateProtocolFeeTarget()
end

function Outcome.marketFactoryUpdateMaximumTakeFee()
end

function Outcome.marketFactoryUpdateUtilityToken()
end

function Outcome.marketFactoryApproveCollateralToken()
end

function Outcome.marketFactoryTransfer()
end

--[[
=====
TOKEN
=====
]]

function Outcome.token()
end

function Outcome.tokenInfo()
end

function Outcome.tokenClaim()
end

function Outcome.tokenTransfer()
end

function Outcome.tokenBurn()
end

function Outcome.tokenBalance()
end

function Outcome.tokenBalances()
end

function Outcome.tokenTotalSupply()
end

function Outcome.tokenClaimBalance()
end

function Outcome.tokenClaimBalances()
end

function Outcome.tokenUpdateLpHolderRatio()
end

function Outcome.tokenUpdateCollateralPrices()
end

function Outcome.tokenUpdateCollateralFactors()
end

function Outcome.tokenUpdateCollateralDenominations()
end

function Outcome.tokenUpdateConfigurator()
end

return Outcome