local ao = require('.ao')
local market = require('modules.market')
---------------------------------------------------------------------------------
-- MARKET -----------------------------------------------------------------------
---------------------------------------------------------------------------------
Env = 'DEV'
Version = '1.0.1'
-- @dev Reset state while in DEV mode
if not Market or Env == 'DEV' then Market = market:new() end
-- @dev Expected LP Token namespace variables, set during `init`
Name = ''
Ticker = ''
Logo = ''
Denominator = nil
---------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------
---------------------------------------------------------------------------------
-- CPMM
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

---------------------------------------------------------------------------------
-- INFO HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Info
Handlers.add("Info", {Action = "Info"}, function(msg)
  Market:info(msg)
end)

---------------------------------------------------------------------------------
-- CPMM WRITE HANDLERS ----------------------------------------------------------
---------------------------------------------------------------------------------

-- Init
Handlers.add("Init", {Action = "Init"}, function(msg)
  Market:init(msg)
  -- Set LP Token namespace variables
  Name = Market.cpmm.token.name
  Ticker = Market.cpmm.token.ticker
  Logo = Market.cpmm.token.logo
  Denomination = Market.cpmm.token.denomination
end)

-- Add Funding
Handlers.add('Add-Funding', isAddFunding, function(msg)
  Market:addFunding(msg)
end)

-- Remove Funding
-- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
  Market:removeFunding(msg)
end)

-- Buy
-- @dev called on credit-notice from collateralToken with X-Action == 'Buy'
Handlers.add("Buy", isBuy, function(msg)
  Market:buy(msg)
end)

-- Sell
-- @dev refactoring as now within same process
Handlers.add("Sell", {Action = "Sell"}, function(msg)
  Market:sell(msg)
end)

-- Withdraw Fees
-- @dev Withdraws withdrawable fees to the message sender
Handlers.add("Withdraw-Fees", {Action = "Withdraw-Fees"}, function(msg)
  Market:withdrawFees(msg)
end)

---------------------------------------------------------------------------------
-- CPMM READ HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Calc Buy Amount
Handlers.add("Calc-Buy-Amount", {Action = "Calc-Buy-Amount"}, function(msg)
  Market:calcBuyAmount(msg)
end)

-- Calc Sell Amount
Handlers.add("Calc-Sell-Amount", {Action = "Calc-Sell-Amount"}, function(msg)
  Market:calcSellAmount(msg)
end)

-- Collected Fees
-- @dev Returns fees collected by the protocol that haven't been withdrawn
Handlers.add("Collected-Fees", {Action = "Collected-Fees"}, function(msg)
  Market:collectedFees(msg)
end)

-- Fees Withdrawable
-- @dev Returns fees withdrawable by the message sender
Handlers.add("Fees-Withdrawable", {Action = "Fees-Withdrawable"}, function(msg)
  Market:feesWithdrawable(msg)
end)

---------------------------------------------------------------------------------
-- LP TOKEN WRITE HANDLERS ------------------------------------------------------
---------------------------------------------------------------------------------

-- Transfer
Handlers.add('Transfer', {Action = "Transfer"}, function(msg)
  Market:transfer(msg)
end)

---------------------------------------------------------------------------------
-- LP TOKEN READ HANDLERS -------------------------------------------------------
---------------------------------------------------------------------------------

-- Balance
Handlers.add('Balance', {Action = "Balance"}, function(msg)
  Market:balance(msg)
end)

-- Balances
Handlers.add('Balances', {Action = "Balances"}, function(msg)
  Market:balances(msg)
end)

-- Total Supply
Handlers.add('Total-Supply', {Action = "Total-Supply"}, function(msg)
  Market:totalSupply(msg)
end)

---------------------------------------------------------------------------------
-- CTF WRITE HANDLERS -----------------------------------------------------------
---------------------------------------------------------------------------------

-- Merge Positions
Handlers.add("Merge-Positions", {Action = "Merge-Positions"}, function(msg)
  Market:mergePositions(msg)
end)

-- Report Payouts
Handlers.add("Report-Payouts", {Action = "Report-Payouts"}, function(msg)
  Market:reportPayouts(msg)
end)

-- Redeem Positions
Handlers.add("Redeem-Positions", {Action = "Redeem-Positions"}, function(msg)
  Market:redeemPositions(msg)
end)

---------------------------------------------------------------------------------
-- CTF READ HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------

-- Get Payout Numerators
Handlers.add("Get-Payout-Numerators", {Action = "Get-Payout-Numerators"}, function(msg)
  Market:getPayoutNumerators(msg)
end)

-- Get Payout Denominator
Handlers.add("Get-Payout-Denominator", {Action = "Get-Payout-Denominator"}, function(msg)
  Market:getPayoutDenominator(msg)
end)

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN WRITE HANDLERS -------------------------------------------
---------------------------------------------------------------------------------

-- Transfer Single
Handlers.add('Transfer-Single', {Action = "Transfer-Single"}, function(msg)
  Market:transferSingle(msg)
end)

-- Transfer Batch
Handlers.add('Transfer-Batch', {Action = "Transfer-Batch"}, function(msg)
  Market:transferBatch(msg)
end)

---------------------------------------------------------------------------------
-- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
---------------------------------------------------------------------------------

-- Balance By Id
Handlers.add("Balance-By-Id", {Action = "Balance-By-Id"}, function(msg)
  Market:balanceById(msg)
end)

-- Balances By Id
Handlers.add('Balances-By-Id', {Action = "Balances-By-Id"}, function(msg)
  Market:balancesById(msg)
end)

-- Batch Balance (Filtered by users and ids)
Handlers.add("Batch-Balance", {Action = "Batch-Balance"}, function(msg)
  Market:batchBalance(msg)
end)

-- Batch Balances (Filtered by Ids, only)
Handlers.add('Batch-Balances', {Action = "Batch-Balances"}, function(msg)
  Market:batchBalances(msg)
end)

-- Balances All
Handlers.add('Balances-All', {Action = "Balances-All"}, function(msg)
  Market:balancesAll(msg)
end)

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------

-- Update Configurator
Handlers.add('Update-Configurator', {Action = "Update-Configurator"}, function(msg)
  Market:updateConfigurator(msg)
end)

-- Update Incentives
Handlers.add('Update-Incentives', {Action = "Update-Incentives"}, function(msg)
  Market:updateIncentives(msg)
end)

-- Update Take Fee Percentage
Handlers.add('Update-Take-Fee', {Action = "Update-Take-Fee"}, function(msg)
  Market:updateTakeFee(msg)
end)

-- Update Protocol Fee Target
Handlers.add('Update-Protocol-Fee-Target', {Action = "Update-Protocol-Fee-Target"}, function(msg)
  Market:updateProtocolFeeTarget(msg)
end)

-- Update Logo
Handlers.add('Update-Logo', {Action = "Update-Logo"}, function(msg)
  Market:updateLogo(msg)
end)

---------------------------------------------------------------------------------
-- EVAL HANDLER -----------------------------------------------------------------
---------------------------------------------------------------------------------

-- Eval
Handlers.once("Complete-Eval", {Action = "Complete-Eval"}, function(msg)
  Market:completeEval(msg)
end)

-- @dev TODO: remove?
ao.send({Target = ao.id, Action = 'Complete-Eval'})

return "ok"
