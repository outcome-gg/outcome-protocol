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

local market = require('marketModules.market')
local constants = require('marketModules.constants')
local json = require('json')
local cpmmValidation = require('marketModules.cpmmValidation')
local tokenValidation = require('marketModules.tokenValidation')
local marketValidation = require('marketModules.marketValidation')
local semiFungibleTokensValidation = require('marketModules.semiFungibleTokensValidation')
local conditionalTokensValidation = require('marketModules.conditionalTokensValidation')

--[[
======
MARKET
======
]]

Env = "DEV"

--- Represents the Market Configuration
--- @class MarketConfiguration
--- @field configurator string The Configurator process ID
--- @field dataIndex string The Data Index process ID
--- @field collateralToken string The Collateral Token process ID
--- @field resolutionAgent string The Resolution Agent process ID
--- @field creator string The Creator address
--- @field question string The Market question
--- @field rules string The Market rules
--- @field category string The Market category
--- @field subcategory string The Market subcategory
--- @field positionIds table<string> The Position process IDs
--- @field name string The Market name
--- @field ticker string The Market ticker
--- @field logo string The Market logo
--- @field lpFee number The LP fee
--- @field creatorFee number The Creator fee
--- @field creatorFeeTarget string The Creator fee target
--- @field protocolFee number The Protocol fee
--- @field protocolFeeTarget string The Protocol fee target

--- Retrieve Market Configuration
--- Fetches configuration parameters from the environment, set by the market factory
--- @return MarketConfiguration marketConfiguration The market configuration
local function retrieveMarketConfig()
  local config = {
    configurator = ao.env.Process.Tags.Configurator or constants.marketConfig[Env].configurator,
    dataIndex = ao.env.Process.Tags.DataIndex or constants.marketConfig[Env].dataIndex,
    collateralToken = ao.env.Process.Tags.CollateralToken or constants.marketConfig[Env].collateralToken,
    resolutionAgent = ao.env.Process.Tags.ResolutionAgent or constants.marketConfig[Env].resolutionAgent,
    creator = ao.env.Process.Tags.Creator or constants.marketConfig[Env].creator,
    question = ao.env.Process.Tags.Question or constants.marketConfig[Env].question,
    rules = ao.env.Process.Tags.Rules or constants.marketConfig[Env].rules,
    category = ao.env.Process.Tags.Category or constants.marketConfig[Env].category,
    subcategory = ao.env.Process.Tags.Subcategory or constants.marketConfig[Env].subcategory,
    positionIds = json.decode(ao.env.Process.Tags.PositionIds or constants.marketConfig[Env].positionIds),
    name = ao.env.Process.Tags.Name or constants.marketConfig[Env].name,
    ticker = ao.env.Process.Tags.Ticker or constants.marketConfig[Env].ticker,
    logo = ao.env.Process.Tags.Logo or constants.marketConfig[Env].logo,
    lpFee = tonumber(ao.env.Process.Tags.LpFee or constants.marketConfig[Env].lpFee),
    creatorFee = tonumber(ao.env.Process.Tags.CreatorFee or constants.marketConfig[Env].creatorFee),
    creatorFeeTarget = ao.env.Process.Tags.CreatorFeeTarget or constants.marketConfig[Env].creatorFeeTarget,
    protocolFee = tonumber(ao.env.Process.Tags.ProtocolFee or constants.marketConfig[Env].protocolFee),
    protocolFeeTarget = ao.env.Process.Tags.ProtocolFeeTarget or constants.marketConfig[Env].protocolFeeTarget
  }
  -- update name and ticker with a unique postfix
  local postfix = string.sub(ao.id, 1, 4) .. string.sub(ao.id, -4)
  -- shorten name to first word and append postfix
  config.name = string.match(config.name, "^(%S+)") .. "-" .. postfix
  config.ticker = config.ticker .. "-" .. postfix
  return config
end

--- @dev Reset Market state during development mode or if uninitialized
if not Market or Env == 'DEV' then
  local marketConfig = retrieveMarketConfig()
  Market = market.new(
    marketConfig.configurator,
    marketConfig.dataIndex,
    marketConfig.collateralToken,
    marketConfig.resolutionAgent,
    marketConfig.creator,
    marketConfig.question,
    marketConfig.rules,
    marketConfig.category,
    marketConfig.subcategory,
    marketConfig.positionIds,
    marketConfig.name,
    marketConfig.ticker,
    marketConfig.logo,
    marketConfig.lpFee,
    marketConfig.creatorFee,
    marketConfig.creatorFeeTarget,
    marketConfig.protocolFee,
    marketConfig.protocolFeeTarget
  )
end

-- Set LP Token namespace variables
Denomination = constants.denomination

--[[
========
MATCHING
========
]]

--- Match on add funding to CPMM
--- @param msg Message The message to match
--- @return boolean True if the message is to add funding, false otherwise
local function isAddFunding(msg)
  if (
    msg.From == Market.cpmm.tokens.collateralToken and
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Add-Funding"
  ) then
    return true
  else
    return false
  end
end

--- Match on buy from CPMM
--- @param msg Message The message to match
--- @return boolean True if the message is to buy, false otherwise
local function isBuy(msg)
  if (
    msg.From == Market.cpmm.tokens.collateralToken and
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Buy"
  ) then
    return true
  else
    return false
  end
end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message received
Handlers.add("Info", {Action = "Info"}, function(msg)
  Market:info(msg)
end)

--[[
===================
CPMM WRITE HANDLERS
===================
]]

--- Add funding handler
--- @param msg Message The message received, expected to contain:
---   - msg.Tags.Quantity (string): The amount of funding to add (numeric string).
---   - msg.Tags.Distribution (stringified table):
---     * JSON-encoded table specifying the initial distribution of funding.
---     * Required on the first call to `addFunding`.
---     * Must NOT be included in subsequent calls, or the operation will fail.
---   - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the LP tokens.
Handlers.add("Add-Funding", isAddFunding, function(msg)
  -- Validate input
  local success, err = cpmmValidation.addFunding(msg, Market.cpmm.token.totalSupply, Market.cpmm.tokens.positionIds)
  -- If validation fails, return funds to sender and provide error response.
  if not success then
    msg.reply({
      Action = "Transfer",
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      ["X-Action"] = "Add-Funding-Error",
      ["X-Error"] = err
    })
    return
  end
  -- If validation passes, add funding to the CPMM.
  Market:addFunding(msg)
end)

--- Remove funding handler
--- @param msg Message The message received
Handlers.add("Remove-Funding", {Action = "Remove-Funding"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.removeFunding(msg, Market.cpmm.token.balances[msg.From])
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Remove-Funding-Error",
      Error = err
    })
    return
  end
  -- If validation passes, remove funding from the CPMM.
  Market:removeFunding(msg)
end)

--- Buy handler
--- @param msg Message The message received
Handlers.add("Buy", isBuy, function(msg)
  -- Validate input
  local success, err = cpmmValidation.buy(msg, Market.cpmm)
  -- If validation fails, return funds to sender and provide error response.
  if not success then
    msg.reply({
      Action = "Transfer",
      Recipient = msg.Tags.Sender,
      Quantity = msg.Tags.Quantity,
      ["X-Action"] = "Buy-Error",
      ["X-Error"] = err
    })
    return
  end
  -- If validation passes, buy from the CPMM.
  Market:buy(msg)
end)

--- Sell handler
--- @param msg Message The message received
Handlers.add("Sell", {Action = "Sell"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.sell(msg, Market.cpmm)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Sell-Error",
      Error = err
    })
    return
  end
  -- If validation passes, sell to the CPMM.
  Market:sell(msg)
end)

--- Withdraw fees handler
--- @param msg Message The message received
Handlers.add("Withdraw-Fees", {Action = "Withdraw-Fees"}, function(msg)
  Market:withdrawFees(msg)
end)

--[[
==================
CPMM READ HANDLERS
==================
]]

--- Calc buy amount handler
--- @param msg Message The message received
Handlers.add("Calc-Buy-Amount", {Action = "Calc-Buy-Amount"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.calcBuyAmount(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Calc-Buy-Amount-Error",
      Error = err
    })
    return
  end
  -- If validation passes, calculate the buy amount.
  Market:calcBuyAmount(msg)
end)

--- Calc sell amount handler
--- @param msg Message The message received
Handlers.add("Calc-Sell-Amount", {Action = "Calc-Sell-Amount"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.calcSellAmount(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Calc-Sell-Amount-Error",
      Error = err
    })
    return
  end
  -- If validation passes, calculate the sell amount.
  Market:calcSellAmount(msg)
end)

--- Colleced fees handler
--- @param msg Message The message received
Handlers.add("Collected-Fees", {Action = "Collected-Fees"}, function(msg)
  Market:collectedFees(msg)
end)

--- Fees withdrawable handler
--- @param msg Message The message received
Handlers.add("Fees-Withdrawable", {Action = "Fees-Withdrawable"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.feesWithdrawable(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Fees-Withdrawable-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get fees withdrawable.
  Market:feesWithdrawable(msg)
end)

--[[
=======================
LP TOKEN WRITE HANDLERS
=======================
]]

--- Transfer handler
--- @param msg Message The message received
Handlers.add('Transfer', {Action = "Transfer"}, function(msg)
  -- Validate input
  local success, err = tokenValidation.transfer(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Transfer-Error",
      Error = err
    })
    return
  end
  -- If validation passes, transfer the LP tokens.
  Market:transfer(msg)
end)

--[[
======================
LP TOKEN READ HANDLERS
======================
]]

--- Balance handler
--- @param msg Message The message received
Handlers.add('Balance', {Action = "Balance"}, function(msg)
  -- Validate input
  local success, err = tokenValidation.balance(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Balance-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the LP token balance.
  Market:balance(msg)
end)

--- Balances handler
--- @param msg Message The message received
Handlers.add('Balances', {Action = "Balances"}, function(msg)
  Market:balances(msg)
end)

--- Total supply handler
--- @param msg Message The message received
Handlers.add('Total-Supply', {Action = "Total-Supply"}, function(msg)
  Market:totalSupply(msg)
end)

--[[
=================================
CONDITIONAL TOKENS WRITE HANDLERS
=================================
]]

--- Merge positions handler
--- @param msg Message The message received
Handlers.add("Merge-Positions", {Action = "Merge-Positions"}, function(msg)
  -- Validate input
  local success, err = conditionalTokensValidation.mergePositions(msg, Market.cpmm)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Merge-Positions-Error",
      Error = err
    })
    return
  end
  -- If validation passes, merge the positions.
  Market:mergePositions(msg)
end)

--- Report payouts handler
--- @param msg Message The message received
Handlers.add("Report-Payouts", {Action = "Report-Payouts"}, function(msg)
  -- Validate input
  local success, err = conditionalTokensValidation.reportPayouts(msg, Market.cpmm.tokens.resolutionAgent)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Report-Payouts-Error",
      Error = err
    })
    return
  end
  -- If validation passes, report the payouts.
  Market:reportPayouts(msg)
end)

--- Redeem positions handler
--- @param msg Message The message received
Handlers.add("Redeem-Positions", {Action = "Redeem-Positions"}, function(msg)
  Market:redeemPositions(msg)
end)

--[[
================================
CONDITIONAL TOKENS READ HANDLERS
================================
]]

--- Get payout numerators handler
--- @param msg Message The message received
Handlers.add("Get-Payout-Numerators", {Action = "Get-Payout-Numerators"}, function(msg)
  Market:getPayoutNumerators(msg)
end)

--- Get payout denominator handler
--- @param msg Message The message received
Handlers.add("Get-Payout-Denominator", {Action = "Get-Payout-Denominator"}, function(msg)
  Market:getPayoutDenominator(msg)
end)

--[[
===================================
SEMI-FUNGIBLE TOKENS WRITE HANDLERS
===================================
]]

--- Transfer single handler
--- @param msg Message The message received
Handlers.add("Transfer-Single", {Action = "Transfer-Single"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.transferSingle(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Transfer-Single-Error",
      Error = err
    })
    return
  end
  -- If validation passes, execute transfer single.
  Market:transferSingle(msg)
end)

--- Transfer batch handler
--- @param msg Message The message received
Handlers.add('Transfer-Batch', {Action = "Transfer-Batch"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.transferBatch(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Transfer-Batch-Error",
      Error = err
    })
    return
  end
  -- If validation passes, execute transfer batch.
  Market:transferBatch(msg)
end)

--[[
==================================
SEMI-FUNGIBLE TOKENS READ HANDLERS
==================================
]]

--- Balance by ID handler
--- @param msg Message The message received
Handlers.add("Balance-By-Id", {Action = "Balance-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.balanceById(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Balance-By-Id-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the balance by ID.
  Market:balanceById(msg)
end)

--- Balances by ID handler
--- @param msg Message The message received
Handlers.add('Balances-By-Id', {Action = "Balances-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.balancesById(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Balances-By-Id-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the balances by ID.
  Market:balancesById(msg)
end)

--- Batch balance handler
--- @param msg Message The message received
Handlers.add("Batch-Balance", {Action = "Batch-Balance"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.batchBalance(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Batch-Balance-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the batch balance.
  Market:batchBalance(msg)
end)

--- Batch balances hanlder
--- @param msg Message The message received
Handlers.add('Batch-Balances', {Action = "Batch-Balances"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.batchBalances(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Batch-Balances-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the batch balances.
  Market:batchBalances(msg)
end)

--- Balances all handler
--- @warning Not recommended for production use; returns an unbounded amount of data.
--- @param msg Message The message received
Handlers.add('Balances-All', {Action = "Balances-All"}, function(msg)
  Market:balancesAll(msg)
end)

--[[
===========================
CONFIGURATOR WRITE HANDLERS
===========================
]]

--- Update configurator handler
--- @param msg Message The message received
Handlers.add('Update-Configurator', {Action = "Update-Configurator"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateConfigurator(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Configurator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the configurator.
  Market:updateConfigurator(msg)
end)

--- Update data index handler
--- @param msg Message The message received
Handlers.add("Update-Data-Index", {Action = "Update-Data-Index"}, function(msg)
  -- Validate input
  local success, err = marketValidation.updateDataIndex(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Data-Index-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the data index.
  Market:updateDataIndex(msg)
end)

--- Update take fee handler
--- @param msg Message The message received
Handlers.add('Update-Take-Fee', {Action = "Update-Take-Fee"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateTakeFee(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Take-Fee-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the take fee.
  Market:updateTakeFee(msg)
end)

--- Update protocol fee target handler
--- @param msg Message The message received
Handlers.add('Update-Protocol-Fee-Target', {Action = "Update-Protocol-Fee-Target"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateProtocolFeeTarget(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Protocol-Fee-Target-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the protocol fee target.
  Market:updateProtocolFeeTarget(msg)
end)

--- Update logo handler
--- @param msg Message The message received
Handlers.add('Update-Logo', {Action = "Update-Logo"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateLogo(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Logo-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the logo.
  Market:updateLogo(msg)
end)

return "ok"
