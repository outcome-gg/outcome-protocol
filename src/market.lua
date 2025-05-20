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

Env = ao.env.Process.Tags.Env or "DEV"

-- Revoke ownership if the Market is not in development mode
if Env ~= "DEV" then
  Owner = ""
end

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
--- @field logo string The Market LP token logo
--- @field logos table<string> The Market Position tokens logos
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
    configurator = ao.env.Process.Tags.Configurator or constants.marketConfig.configurator,
    dataIndex = ao.env.Process.Tags.DataIndex or constants.marketConfig.dataIndex,
    collateralToken = ao.env.Process.Tags.CollateralToken or constants.marketConfig.collateralToken,
    resolutionAgent = ao.env.Process.Tags.ResolutionAgent or constants.marketConfig.resolutionAgent,
    creator = ao.env.Process.Tags.Creator or constants.marketConfig.creator,
    question = ao.env.Process.Tags.Question or constants.marketConfig.question,
    rules = ao.env.Process.Tags.Rules or constants.marketConfig.rules,
    category = ao.env.Process.Tags.Category or constants.marketConfig.category,
    subcategory = ao.env.Process.Tags.Subcategory or constants.marketConfig.subcategory,
    positionIds = json.decode(ao.env.Process.Tags.PositionIds or constants.marketConfig.positionIds),
    name = ao.env.Process.Tags.Name or constants.marketConfig.name,
    ticker = ao.env.Process.Tags.Ticker or constants.marketConfig.ticker,
    denomination = tonumber(ao.env.Process.Tags.Denomination or constants.marketConfig.denomination),
    logo = ao.env.Process.Tags.Logo or constants.marketConfig.logo,
    logos = json.decode(ao.env.Process.Tags.Logos or constants.marketConfig.logos),
    lpFee = tonumber(ao.env.Process.Tags.LpFee or constants.marketConfig.lpFee),
    creatorFee = tonumber(ao.env.Process.Tags.CreatorFee or constants.marketConfig.creatorFee),
    creatorFeeTarget = ao.env.Process.Tags.CreatorFeeTarget or constants.marketConfig.creatorFeeTarget,
    protocolFee = tonumber(ao.env.Process.Tags.ProtocolFee or constants.marketConfig.protocolFee),
    protocolFeeTarget = ao.env.Process.Tags.ProtocolFeeTarget or constants.marketConfig.protocolFeeTarget
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
    marketConfig.denomination,
    marketConfig.logo,
    marketConfig.logos,
    marketConfig.lpFee,
    marketConfig.creatorFee,
    marketConfig.creatorFeeTarget,
    marketConfig.protocolFee,
    marketConfig.protocolFeeTarget
  )
  -- Set LP Token namespace variable
  Denomination = marketConfig.denomination
end

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
--- @note **Replies with the following tags:**
--- Name (string): The Market name
--- Ticker (string): The Market ticker
--- Logo (string): The Market LP token logo
--- Logos (string): The Market Position tokens logos (stringified table)
--- Denomination (string): The LP token denomination
--- PositionIds (string): The Market Position tokens process IDs (stringified table)
--- CollateralToken (string): The Market collateral token process ID
--- Configurator (string): The Market configurator process ID
--- DataIndex (string): The Market data index process ID
--- ResolutionAgent (string): The Market resolution agent process ID
--- Question (string): The Market question
--- Rules (string): The Market rules
--- Category (string): The Market category
--- Subcategory (string): The Market subcategory
--- Creator (string): The Market creator address
--- CreatorFee (string): The Market creator fee (numeric string, basis points)
--- CreatorFeeTarget (string): The Market creator fee target
--- ProtocolFee (string): The Market protocol fee (numeric string, basis points)
--- ProtocolFeeTarget (string): The Market protocol fee target
--- LpFee (string): The Market LP fee (numeric string, basis points)
--- LpFeePoolWeight (string): The Market LP fee pool weight
--- LpFeeTotalWithdrawn (string): The Market LP fee total withdrawn
--- Owner (string): The Market process owner
Handlers.add("Info", {Action = "Info"}, function(msg)
  Market:info(msg)
end)

--[[
===================
CPMM WRITE HANDLERS
===================
]]

--- Add funding handler
--- @notice On error the funding is returned to the sender
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity (string): The amount of funding to add (numeric string).
--- - msg.Tags.Distribution (stringified table):
---   * JSON-encoded table specifying the initial distribution of funding.
---   * Required on the first call to `addFunding`.
---   * Must NOT be included in subsequent calls, or the operation will fail.
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the LP tokens.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Notice`: **collateral → provider**     -- Transfers collateral tokens from the provider
--- - `Credit-Notice`: **collateral → market**   -- Transfers collateral tokens to the market
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Add-Funding-Error`: **market → provider** -- Returns an error message
--- - `Debit-Notice`: **collateral → market**     -- Returns collateral tokens from the market
--- - `Credit-Notice`: **collateral → provider**   -- Returns collateral tokens to the provider
--- **✨ Interim Notices (Default silenced) **
--- - `Mint-Batch-Notice`: **market → market**      -- Mints position tokens to the market
--- - `Split-Position-Notice`: **market → market**  -- Splits collateral into position tokens
--- - `Mint-Notice`: **market → onBehalfOf**             -- Mints LP tokens to the onBehalfOf address
--- **✅ Success Notice (Default broadcast)**
--- - `Log-Funding-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the funding
--- **📊 Logging & Analytics**
--- - `Add-Funding-Notice`: **market → provider**  -- Logs the add funding action
--- @note **Replies with the following tags:**
--- Action (string): "Add-Funding-Notice"
--- FundingAdded (string) The amount of funding added for each position ID (stringified table)
--- MintAmount (string): The amount of LP tokens minted (numeric string)
--- OnBehalfOf (string): The address of the account to receive the LP tokens
--- Data (string): "Successfully added funding"
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
--- @notice Calling `marketRemoveFunding` will simultaneously return the liquidity provider's share of accrued fees
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity (string): The amount of LP tokens to burn (numeric string).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the position tokens.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Remove-Funding-Error`: **market → provider** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Withdraw-Fees-Notice`: **market → provider**  -- Distributes accrued LP fees to the onBehalfOf address
--- - `Burn-Notice`: **market → market**  -- Burns the returned LP tokens
--- - `Debit-Batch-Notice`: **market → market** -- Transfers position tokens from the market
--- - `Credit-Batch-Notice`: **market → onBehalfOf** -- Transfers position tokens to the onBehalfOf address
--- **📊 Logging & Analytics**
--- - `Log-Funding-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the funding
--- **✅ Success Notice (Default broadcast)**
--- - `Remove-Funding-Notice`: **market → provider** -- Logs the remove funding action
--- @note **Replies with the following tags:**
--- Action (string): "Remove-Funding-Notice"
--- SendAmounts (string): The amount of position tokens returned for each ID (stringified table)
--- CollateralRemovedFromFeePool (string): The amount of collateral removed from the fee pool (numeric string)
--- SharesToBurn (string): The amount of LP tokens to burn (numeric string)
--- OnBehalfOf (string): The address of the account to receive the position tokens
--- Data (string): "Successfully removed funding"
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
--- @warning Ensure sufficient liquidity exists before calling `marketBuy`, or the transaction may fail
--- @use Call `marketCalcBuyAmount` to verify liquidity and the number of outcome position tokens to be purchased
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity (string): The amount of collateral tokens transferred, i.e. the investment amount (numeric string).
--- - msg.Tags["X-PositionId"] (string): The position ID of the outcome token to purchase.
--- - msg.Tags["X-MinPositionTokensToBuy"] (string): The minimum number of outcome position tokens to purchase (numeric string).
--- - msg.Tags["X-OnBehalfOf"] (string, optional): The address of the account to receive the position tokens.
--- - msg.Tags["X-Cast"] (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags["X-SendInterim"] (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **🔄 Execution Transfers**
--- - `Debit-Notice`: **collateral → buyer**     -- Transfers collateral from the buyer
--- - `Credit-Notice`: **collateral → market**   -- Transfers collateral to the market
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Buy-Error`: **market → sender** -- Returns an error message
--- - `Debit-Notice`: **collateral → market**     -- Returns collateral from the market
--- - `Credit-Notice`: **collateral → buyer**   -- Returns collateral to the buyer
--- **✨ Interim Notices (Default silenced)**
--- - `Mint-Batch-Notice`: **market → market**      -- Mints new position tokens
--- - `Split-Position-Notice`: **market → market**  -- Splits collateral into position tokens
--- - `Debit-Single-Notice`: **market → market**    -- Transfers position tokens from the market
--- - `Credit-Single-Notice`: **market → onBehalfOf**    -- Transfers position tokens to the onBehalfOf address
--- **📊 Logging & Analytics**
--- - `Log-Prediction-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the prediction
--- - `Log-Probabilities-Notice`: **market → Outcome.dataIndex**                            -- Logs the updated probabilities
--- **✅ Success Notice (Default broadcast)**
--- - `Buy-Notice`: **market → buyer**  -- Logs the buy action
--- @note **Replies with the following tags:**
--- Action (string): "Buy-Notice"
--- InvestmentAmount (string): The amount of collateral tokens transferred, i.e. the investment amount (numeric string).
--- FeeAmount (string): The amount of fees paid (numeric string).
--- PositionId (string): The position ID of the outcome token purchased.
--- PositionTokensBought (string): The amount of outcome position tokens purchased (numeric string).
--- OnBehalfOf (string): The address of the account to receive the position tokens
--- Data (string): "Successfully bought"
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
--- @warning Ensure sufficient liquidity exists before calling `marketSell`, or the transaction may fail
--- @use Call `marketCalcSellAmount` to verify liquidity and the number of outcome position tokens to be sold
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to sell.
--- - msg.Tags.MaxPositionTokensToSell (string) The maximum number of position tokens to sell (numeric string).
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the collateral tokens.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Sell-Error`: **market → seller** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Single-Notice`: **market → seller**     -- Transfers sold position tokens from the seller
--- - `Credit-Single-Notice`: **market → market**   -- Transfers sold position tokens to the market
--- - `Batch-Burn-Notice`: **market → market**      -- Burns sold position tokens
--- - `Merge-Positions-Notice`: **market → market** -- Merges sold position tokens back to collateral
--- - `Debit-Notice`: **collateral → market**       -- Transfers collateral from the seller
--- - `Credit-Notice`: **collateral → seller**       -- Transfers collateral to the onBehalfOf address
--- - `Debit-Single-Notice`: **market → market**     -- Returns unburned position tokens from the market
--- - `Credit-Single-Notice`: **market → seller**   -- Returns unburned position tokens to the onBehalfOf address
--- **📊 Logging & Analytics**
--- - `Log-Prediction-Notice`: **market → Outcome.token**and **market → Outcome.dataIndex** -- Logs the prediction
--- - `Log-Probabilities-Notice`: **market → Outcome.dataIndex**                            -- Logs the updated probabilities
--- **✅ Success Notice (Default broadcast)**
--- - `Sell-Notice`: **market → seller** -- Logs the sell action
--- @note **Replies with the following tags:**
--- Action (string): "Sell-Notice"
--- ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- FeeAmount (string): The amount of fees paid (numeric string).
--- PositionId (string): The position ID of the outcome token sold.
--- PositionTokensSold (string): The amount of outcome position tokens sold (numeric string).
--- OnBehalfOf (string): The address of the account to receive the collateral tokens
--- Data (string): "Successfully sold"
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the fees.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Withdraw-Fees-Error`: **market → provider** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Notice`: **collateral → market**  -- Transfers LP fees from the market
--- - `Credit-Notice`: **collateral → provider**  -- Transfers LP fees to the provider
--- **✅ Success Notice (Default broadcast)**
--- - `Withdraw-Fees-Notice`: **market → provider** -- Logs the withdraw fees action
--- @note **Replies with the following tags:**
--- Action (string): "Withdraw-Fees-Notice"
--- FeeAmount (string): The amount of fees withdrawn (numeric string).
--- OnBehalfOf (string): The address of the account to receive the fees
--- Data (string): "Successfully withdrew fees"
Handlers.add("Withdraw-Fees", {Action = "Withdraw-Fees"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.withdrawFees(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Withdraw-Fees-Error",
      Error = err
    })
    return
  end
  -- If validation passes, withdraw fees from the CPMM.
  Market:withdrawFees(msg)
end)

--[[
==================
CPMM READ HANDLERS
==================
]]

--- Calc buy amount handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.InvestmentAmount (string): The amount of collateral tokens to invest (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to purchase.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Calc-Buy-Amount-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - BuyAmount (string): The amount of outcome tokens to purchase (numeric string).
--- - PositionId (string): The position ID of the outcome token to purchase.
--- - InvestmentAmount (string): The amount of collateral tokens to invest (numeric string).
--- - Data (string): The BuyAmount.
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to sell.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Calc-Sell-Amount-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - SellAmount (string): The amount of outcome tokens to sell (numeric string).
--- - PositionId (string): The position ID of the outcome token to sell.
--- - ReturnAmount (string): The amount of collateral tokens to receive (numeric string).
--- - Data (string): The SellAmount.
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

--- Calc return amount handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.OutcomeTokensToSell (string): The number of outcome tokens to sell (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to sell.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Calc-Return-Amount-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - ReturnAmount (string): The amount of collateral tokens to receive.
--- - PositionId (string): The position ID of the outcome token sold.
--- - OutcomeTokensToSell (string): The number of outcome tokens to sell.
--- - Data (string): The ReturnAmount.
Handlers.add("Calc-Return-Amount", {Action = "Calc-Return-Amount"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.calcReturnAmount(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Calc-Return-Amount-Error",
      Error = err
    })
    return
  end
  -- If validation passes, calculate the return amount.
  Market:calcReturnAmount(msg)
end)

--- Colleced fees handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - CollectedFees (string): The total unwithdrawn fees collected by the CPMM (numeric string).
--- - Data (string): The CollectedFees.
Handlers.add("Collected-Fees", {Action = "Collected-Fees"}, function(msg)
  Market:collectedFees(msg)
end)

--- Fees withdrawable handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the queried account.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Fees-Withdrawable-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - FeesWithdrawable (string): The total fees withdrawable by the account (numeric string).
--- - Account (string): The address of the queried account.
--- - Data (string): The FeesWithdrawable.
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the account to receive the LP tokens.
--- - msg.Tags.Quantity (string): The amount of LP tokens to transfer (numeric string).
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (string, optional) The sendInterim is set to send interim notices.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Transfer-Error`: **market → sender** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Debit-Notice`: **collateral → market**  -- Transfers LP fees from the market
--- - `Credit-Notice`: **collateral → provider**  -- Transfers LP fees to the provider
--- - `Withdraw-Fees-Notice`: **market → provider** -- Logs the withdraw fees action
--- **✅ Success Notices (Sent if `msg.Tags.Cast = nil`)**
--- - `Debit-Notice`: **market → provider**      -- Transfers LP tokens from the provider
--- - `Credit-Notice`: **market → recipient** -- Transfers LP tokens to the recipient
--- @note **Replies with the following tags:**
--- - Action (string): "Debit-Notice"
--- - Recipient (string): The address of the account to receive the LP tokens.
--- - Quantity (string): The amount of LP tokens transferred (numeric string).
--- - Data (string): "You transferred..."
--- - X-[Tag] (string): Any forwarded x-tags
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string, optional): The address of the account to query.
--- - msg.Tags.Target (string, optional): The address of the account to query (alternative option).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Balance-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - Balance (string): The LP token balance of the account (numeric string).
--- - Ticker (string): The LP token ticker.
--- - Account (string): The address of the queried account.
--- - Data (string): The Balance.
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
--- @warning Not recommended for production use; returns an unbounded amount of data.
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string) Balances of all LP token holders (stringified table).
Handlers.add('Balances', {Action = "Balances"}, function(msg)
  Market:balances(msg)
end)

--- Total supply handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string): The total supply of LP tokens (numeric string).
Handlers.add('Total-Supply', {Action = "Total-Supply"}, function(msg)
  Market:totalSupply(msg)
end)

--[[
=================================
CONDITIONAL TOKENS WRITE HANDLERS
=================================
]]

--- Merge positions handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Quantity The quantity of outcome position tokens from each position ID to merge for collataral
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the position tokens.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Merge-Positions-Error`: **market → sender** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Burn-Batch-Notice`: **market → holder** -- Burns the position tokens
--- - `Debit-Notice`: **collateral → market** -- Transfers collateral from the market
--- - `Credit-Notice`: **collateral → onBehalfOf** -- Transfers collateral to onBehalfOf
--- **✅ Success Notice (Default broadcast)**
--- - `Merge-Positions-Notice`: **market → holder**  -- Logs the merge positions action
--- @note **Replies with the following tags:**
--- - Action (string): "Merge-Positions-Notice"
--- - Quantity (string): The quantity of outcome position tokens merged for collateral (numeric string)
--- - CollateralToken (string): The collateral token process ID
--- - OnBehalfOf (string): The address of the account to receive the collateral tokens
--- - Data (string): "Successfully merged positions"
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
--- @notice Only callable by the resolution agent
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Payouts (stringified table): The payouts to report
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Replort-Payouts-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
---  - `Report-Payouts-Notice`: **market → resolutionAgent** -- Logs the report payouts action
--- @note **Replies with the following tags:**
--- - Action (string): "Report-Payouts-Notice"
--- - ResolutionAgent (string): The resolution agent process ID
--- - PayoutNumerators (string): The payout numerators for each outcome slot (stringified table)
--- - Data (string): "Successfully reported payouts"
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.OnBehalfOf (string, optional): The address of the account to receive the collateral tokens.
--- - msg.Tags.SendInterim (boolean, optional): The sendInterim is set to send interim notices (default `nil`to silience).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Redeem-Positions-Error`: **market → sender** -- Returns an error message
--- **✨ Interim Notices (Default silenced)**
--- - `Burn-Single-Notice`: **market → holder**    -- Burns redeemed position tokens (for each position ID held by the sender)
--- - `Debit-Notice`: **collateral → market**     -- Transfers collateral from the market
--- - `Credit-Notice`: **collateral → onBehalfOf**     -- Transfers collateral to onBehalfOf
--- **✅ Success Notice**
--- - `Redeem-Positions-Notice`: **market → holder** -- Logs the redeem positions action
--- @note **Replies with the following tags:**
--- - Action (string): "Redeem-Positions-Notice"
--- - CollateralToken (string): The collateral token process ID
--- - GrossPayout (string): The gross payout amount, before fees (numeric string)
--- - NetPayout (string): The net payout amount, after fees (numeric string)
--- - OnBehalfOf (string): The address of the account to receive the collateral tokens
--- - Data (string): "Successfully redeemed positions"
Handlers.add("Redeem-Positions", {Action = "Redeem-Positions"}, function(msg)
  -- Validate input
  local success, err = conditionalTokensValidation.redeemPositions(msg)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Redeem-Positions-Error",
      Error = err
    })
    return
  end
  -- If validation passes, redeem positions.
  Market:redeemPositions(msg)
end)

--[[
================================
CONDITIONAL TOKENS READ HANDLERS
================================
]]

--- Get payout numerators handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string): The payout numerators (stringified table).
Handlers.add("Get-Payout-Numerators", {Action = "Get-Payout-Numerators"}, function(msg)
  Market:getPayoutNumerators(msg)
end)

--- Get payout denominator handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- @note - Data (string): The payout denominator (numeric string).
Handlers.add("Get-Payout-Denominator", {Action = "Get-Payout-Denominator"}, function(msg)
  Market:getPayoutDenominator(msg)
end)

--[[
===================================
SEMI-FUNGIBLE TOKENS WRITE HANDLERS
===================================
]]

--- Transfer single handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the account to receive the position tokens.
--- - msg.Tags.Quantity (string): The amount of position tokens to transfer (numeric string).
--- - msg.Tags.PositionId (string): The position ID of the outcome token to transfer.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Transfer-Single-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice (Default broadcast)**
--- - `Debit-Single-Notice`: **market → sender** -- Transfers tokens from the sender
--- - `Credit-Single-Notice`: **market → recipient** -- Transfers tokens to the recipient
--- @note **Replies with the following tags:**
--- - Action (string): "Debit-Single-Notice"
--- - Recipient (string): The address of the account to receive the position tokens.
--- - Quantity (string): The amount of position tokens transferred (numeric string).
--- - PositionId (string): The position ID of the outcome token transferred.
--- - Data (string): "You transferred..."
--- - X-[Tag] (string): Any forwarded x-tags
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipient (string): The address of the account to receive the position tokens.
--- - msg.Tags.PositionIds (stringified table): The position IDs of the outcome tokens to transfer.
--- - msg.Tags.Quantities (stringified table): The amounts of position tokens to transfer.
--- - msg.Tags.Cast (string, optional): The cast is set to silence the final notice (default `nil`to broadcast).
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Transfer-Batch-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notices (Sent if `msg.Tags.Cast = nil`)**
--- - `Debit-Batch-Notice`: **market → sender** -- Transfers tokens from the sender
--- - `Credit-Batch-Notice`: **market → recipient** -- Transfers tokens to the recipient
--- @note **Replies with the following tags:**
--- - Action (string): "Debit-Batch-Notice"
--- - Recipient (string): The address of the account to receive the position tokens.
--- - PositionIds (string): The IDs of the position tokens transferred (stringified table).
--- - Quantities (string): The amounts of position tokens transferred (stringified table).
--- - Data (string): "You transferred..."
--- - X-[Tag] (string): Any forwarded x-tags
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionId (string): The position ID of the outcome token to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Balance-By-Id-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - Balance (string): The balance of the account (numeric string).
--- - PositionId (string): The position ID of the outcome token.
--- - Account (string): The address of the queried account.
--- - Data (string): The Balance.
Handlers.add("Balance-By-Id", {Action = "Balance-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.balance(msg, Market.cpmm.tokens.positionIds)
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionId (string): The position ID of the outcome token to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Balances-By-Id-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionId (string): The position ID of the outcome token.
--- - Data (string): The balances of all accounts filtered by ID (stringified table).
Handlers.add('Balances-By-Id', {Action = "Balances-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.balance(msg, Market.cpmm.tokens.positionIds)
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
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Recipients (stringified table): The addresses of the accounts to query.
--- - msg.Tags.PositionIds (stringified table): The position IDs of the outcome tokens to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Batch-Balance-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionIds (string): The position IDs of the outcome tokens.
--- - Data (string): The balances of all accounts filtered by IDs (stringified table).
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

--- Batch balances handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionIds (stringified table): The position IDs of the outcome tokens to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Batch-Balances-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionIds (string): The position IDs of the outcome tokens.
--- - Data (string): The balances of all accounts filtered by ID (stringified table).
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
--- @note **Replies with the following tags:**
--- - Data (string): Balances of all accounts (stringified table).
Handlers.add('Balances-All', {Action = "Balances-All"}, function(msg)
  Market:balancesAll(msg)
end)

--- Logo by ID handler
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.PositionId (string): The position ID of the outcome token to query.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Logo-By-Id-Error`: **market → sender** -- Returns an error message
--- @note **Replies with the following tags:**
--- - PositionId (string): The position ID of the outcome token.
--- - Data (string): The logo of the outcome token.
Handlers.add('Logo-By-Id', {Action = "Logo-By-Id"}, function(msg)
  -- Validate input
  local success, err = semiFungibleTokensValidation.logoById(msg, Market.cpmm.tokens.positionIds)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Logo-By-Id-Error",
      Error = err
    })
    return
  end
  -- If validation passes, get the logo by ID.
  Market:logoById(msg)
end)

--- Logos handler
--- @param msg Message The message received
--- @note **Replies with the following tags:**
--- - Data (string): Logos of all outcome tokens (stringified table).
Handlers.add('Logos', {Action = "Logos"}, function(msg)
  Market:logos(msg)
end)

--[[
===========================
CONFIGURATOR WRITE HANDLERS
===========================
]]

--- Propose configurator handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Configurator (string): The proposed configurator.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Propose-Configurator-Error`: **market → sender** -- Returns an error message
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Propose-Configurator-Notice`: **market → sender** -- Logs the propose configurator action
Handlers.add('Propose-Configurator', {Action = "Propose-Configurator"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.proposeConfigurator(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Propose-Configurator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, propose the configurator.
  Market:proposeConfigurator(msg)
end)

--- Accept configurator handler
--- @notice Only callable by the proposedConfigurator
--- @param msg Message The message received.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Accept-Configurator-Error`: **market → sender** -- Returns an error message
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Accept-Configurator-Notice`: **market → sender** -- Logs the accept configurator action
Handlers.add('Accept-Configurator', {Action = "Accept-Configurator"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.acceptConfigurator(msg, Market.cpmm.proposedConfigurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Accpet-Configurator-Error",
      Error = err
    })
    return
  end
  -- If validation passes, accept the configurator.
  Market:acceptConfigurator(msg)
end)

--- Update data index handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.DataIndex (string): The new data index.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Data-Index-Error`: **market → sender** -- Returns an error message
--- @note **Emits the following notices:**
--- **✅ Success Notice**
--- - `Update-DataIndex-Notice`: **market → sender** -- Logs the update data index action
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
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.TakeFee (string): The new take fee.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Take-Fee-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-TakeFee-Notice`: **market → sender** -- Logs the update take fee action
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
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.ProtocolFeeTarget (string): The new protocol fee target.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Protocol-Fee-Target-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-ProtocolFeeTarget-Notice`: **market → sender** -- Logs the update protocol fee target action
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
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Logo (string): The new logo.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Logo-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-Logo-Notice`: **market → sender** -- Logs the update logo action
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

--- Update logos handler
--- @notice Only callable by the configurator
--- @param msg Message The message received, expected to contain:
--- - msg.Tags.Logos (stringified table): The new logos.
--- @note **Emits the following notices:**
--- **⚠️ Error Handling (Sent on failed input validation)**
--- - `Update-Logos-Error`: **market → sender** -- Returns an error message
--- **✅ Success Notice**
--- - `Update-Logos-Notice`: **market → sender** -- Logs the update logos action
Handlers.add('Update-Logos', {Action = "Update-Logos"}, function(msg)
  -- Validate input
  local success, err = cpmmValidation.updateLogos(msg, Market.cpmm.configurator)
  -- If validation fails, provide error response.
  if not success then
    msg.reply({
      Action = "Update-Logos-Error",
      Error = err
    })
    return
  end
  -- If validation passes, update the logos.
  Market:updateLogos(msg)
end)

return "ok"
