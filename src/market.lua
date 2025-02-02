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

--[[
======
MARKET
======
]]

Env = "DEV"
Version = "1.0.1"

--- Represents the Market Configuration  
--- @class MarketConfiguration  
--- @field configurator string The Configurator process ID  
--- @field incentives string The Incentives process ID  
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
    incentives = ao.env.Process.Tags.Incentives or constants.marketConfig[Env].incentives,
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
  Market = market:new(
    marketConfig.configurator,
    marketConfig.incentives,
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

--- Match on remove funding from CPMM
--- @param msg Message The message to match
--- @return boolean True if the message is to remove funding, false otherwise
local function isRemoveFunding(msg)
  if (
    msg.From == ao.id and
    msg.Action == "Credit-Notice" and
    msg["X-Action"] == "Remove-Funding"
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
--- @return Message infoNotice The info notice
Handlers.add("Info", {Action = "Info"}, function(msg)
  return Market:info(msg)
end)

--[[
===================
CPMM WRITE HANDLERS
===================
]]

--- Add funding handler
--- @param msg Message The message received
--- @return Message addFundingNotice The add funding notice
Handlers.add('Add-Funding', isAddFunding, function(msg)
  return Market:addFunding(msg)
end)

--- Remove funding handler
--- @param msg Message The message received
--- @return Message removeFundingNotice The remove funding notice
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  return Market:removeFunding(msg)
end)

--- Buy handler
--- @param msg Message The message received
--- @return Message buyNotice The buy notice
Handlers.add("Buy", isBuy, function(msg)
  return Market:buy(msg)
end)

--- Sell handler
--- @param msg Message The message received
--- @return Message sellNotice The sell notice
Handlers.add("Sell", {Action = "Sell"}, function(msg)
  return Market:sell(msg)
end)

--- Withdraw fees handler
--- @param msg Message The message received
--- @return Message withdrawFees The amount withdrawn
Handlers.add("Withdraw-Fees", {Action = "Withdraw-Fees"}, function(msg)
  return Market:withdrawFees(msg)
end)

--[[
==================
CPMM READ HANDLERS
==================
]]

--- Calc buy amount handler
--- @param msg Message The message received
--- @return Message buyAmount The amount of tokens to be purchased
Handlers.add("Calc-Buy-Amount", {Action = "Calc-Buy-Amount"}, function(msg)
  return Market:calcBuyAmount(msg)
end)

--- Calc sell amount handler
--- @param msg Message The message received
--- @return Message sellAmount The amount of tokens to be sold
Handlers.add("Calc-Sell-Amount", {Action = "Calc-Sell-Amount"}, function(msg)
  return Market:calcSellAmount(msg)
end)

--- Colleced fees handler
--- @param msg Message The message received
--- @return Message collectedFees The total unwithdrawn fees collected by the CPMM
Handlers.add("Collected-Fees", {Action = "Collected-Fees"}, function(msg)
  return Market:collectedFees(msg)
end)

--- Fees withdrawable handler
--- @param msg Message The message received
--- @return Message feesWithdrawable The fees withdrawable by the account
Handlers.add("Fees-Withdrawable", {Action = "Fees-Withdrawable"}, function(msg)
  return Market:feesWithdrawable(msg)
end)

--[[
=======================
LP TOKEN WRITE HANDLERS
=======================
]]

--- Transfer handler
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferNotices The transfer notices, error notice or nothing
Handlers.add('Transfer', {Action = "Transfer"}, function(msg)
  return Market:transfer(msg)
end)

--[[
======================
LP TOKEN READ HANDLERS
======================
]]

--- Balance handler
--- @param msg Message The message received
--- @return Message balance The balance of the account
Handlers.add('Balance', {Action = "Balance"}, function(msg)
  return Market:balance(msg)
end)

--- Balances handler
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
Handlers.add('Balances', {Action = "Balances"}, function(msg)
  return Market:balances(msg)
end)

--- Total supply handler
--- @param msg Message The message received
--- @return Message totalSupply The total supply of the LP token
Handlers.add('Total-Supply', {Action = "Total-Supply"}, function(msg)
  return Market:totalSupply(msg)
end)

--[[
=================================
CONDITIONAL TOKENS WRITE HANDLERS
=================================
]]

--- Merge positions handler
--- @param msg Message The message received
--- @return Message mergePositionsNotice The positions merge notice or error message
Handlers.add("Merge-Positions", {Action = "Merge-Positions"}, function(msg)
  return Market:mergePositions(msg)
end)

--- Report payouts handler
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The condition resolution notice 
Handlers.add("Report-Payouts", {Action = "Report-Payouts"}, function(msg)
  return Market:reportPayouts(msg)
end)

--- Redeem positions handler
--- @param msg Message The message received
--- @return Message payoutRedemptionNotice The payout redemption notice
Handlers.add("Redeem-Positions", {Action = "Redeem-Positions"}, function(msg)
  return Market:redeemPositions(msg)
end)

--[[
================================
CONDITIONAL TOKENS READ HANDLERS
================================
]]

--- Get payout numerators handler
--- @param msg Message The message received
--- @return Message payoutNumerators payout numerators for the condition
Handlers.add("Get-Payout-Numerators", {Action = "Get-Payout-Numerators"}, function(msg)
  return Market:getPayoutNumerators(msg)
end)

--- Get payout denominator handler
--- @param msg Message The message received
--- @return Message payoutDenominator The payout denominator for the condition
Handlers.add("Get-Payout-Denominator", {Action = "Get-Payout-Denominator"}, function(msg)
  return Market:getPayoutDenominator(msg)
end)

--[[
===================================
SEMI-FUNGIBLE TOKENS WRITE HANDLERS
===================================
]]

--- Transfer single handler
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferSingleNotices The transfer notices, error notice or nothing
Handlers.add('Transfer-Single', {Action = "Transfer-Single"}, function(msg)
  return Market:transferSingle(msg)
end)

--- Transfer batch handler
--- @param msg Message The message received
--- @return table<Message>|Message|nil transferBatchNotices The transfer notices, error notice or nothing
Handlers.add('Transfer-Batch', {Action = "Transfer-Batch"}, function(msg)
  return Market:transferBatch(msg)
end)

--[[
==================================
SEMI-FUNGIBLE TOKENS READ HANDLERS
==================================
]]

--- Balance by ID handler
--- @param msg Message The message received
--- @return Message balanceById The balance of the account filtered by ID
Handlers.add("Balance-By-Id", {Action = "Balance-By-Id"}, function(msg)
  return Market:balanceById(msg)
end)

--- Balances by ID handler
--- @param msg Message The message received
--- @return Message balancesById The balances of all accounts filtered by ID
Handlers.add('Balances-By-Id', {Action = "Balances-By-Id"}, function(msg)
  return Market:balancesById(msg)
end)

--- Batch balance handler
--- @param msg Message The message received
--- @return Message batchBalance The balance accounts filtered by IDs
Handlers.add("Batch-Balance", {Action = "Batch-Balance"}, function(msg)
  return Market:batchBalance(msg)
end)

--- Batch balances hanlder
--- @param msg Message The message received
--- @return Message batchBalances The balances of all accounts filtered by IDs
Handlers.add('Batch-Balances', {Action = "Batch-Balances"}, function(msg)
  return Market:batchBalances(msg)
end)

--- Balances all handler
--- @param msg Message The message received
--- @return Message balances The balances of all accounts
Handlers.add('Balances-All', {Action = "Balances-All"}, function(msg)
  return Market:balancesAll(msg)
end)

--[[
===========================
CONFIGURATOR WRITE HANDLERS
===========================
]]

--- Update configurator handler
--- @param msg Message The message received
--- @return Message configuratorUpdateNotice The configurator update notice
Handlers.add('Update-Configurator', {Action = "Update-Configurator"}, function(msg)
  return Market:updateConfigurator(msg)
end)

--- Update incentives handler
--- @param msg Message The message received
--- @return Message incentivesUpdateNotice The incentives update notice
Handlers.add('Update-Incentives', {Action = "Update-Incentives"}, function(msg)
  return Market:updateIncentives(msg)
end)

--- Update take fee handler
--- @param msg Message The message received
--- @return Message takeFeeUpdateNotice The take fee update notice
Handlers.add('Update-Take-Fee', {Action = "Update-Take-Fee"}, function(msg)
  return Market:updateTakeFee(msg)
end)

--- Update protocol fee target handler
--- @param msg Message The message received
--- @return Message protocolTargetUpdateNotice The protocol fee target update notice
Handlers.add('Update-Protocol-Fee-Target', {Action = "Update-Protocol-Fee-Target"}, function(msg)
  return Market:updateProtocolFeeTarget(msg)
end)

--- Update logo handler
--- @param msg Message The message received
--- @return Message logoUpdateNotice The logo update notice
Handlers.add('Update-Logo', {Action = "Update-Logo"}, function(msg)
  return Market:updateLogo(msg)
end)

return "ok"
