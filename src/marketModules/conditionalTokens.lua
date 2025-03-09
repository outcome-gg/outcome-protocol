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

local ConditionalTokens = {}
local ConditionalTokensMethods = {}
local ConditionalTokensNotices = require('marketModules.conditionalTokensNotices')
local SemiFungibleTokens = require('marketModules.semiFungibleTokens')
local bint = require('.bint')(256)
local ao = ao or require('.ao')

--- Represents ConditionalTokens
--- @class ConditionalTokens
--- @field name string The token name
--- @field ticker string The token ticker
--- @field logos table<string> The token logos Arweave TxID for each ID
--- @field balancesById table<string, table<string, string>> The account token balances by ID
--- @field totalSupplyById table<string, string> The total supply of the token by ID
--- @field denomination number The number of decimals
--- @field resolutionAgent string The process ID of the resolution agent
--- @field collateralToken string The process ID of the collateral token
--- @field positionIds table<string> The position IDs representing outcomes
--- @field payoutNumerators table<number> The relative payouts for each outcome slot
--- @field payoutDenominator number The sum of payout numerators, zero if unreported
--- @field creatorFee number The creator fee to be paid, in basis points
--- @field creatorFeeTarget string The process ID to receive the creator fee
--- @field protocolFee number The protocol fee to be paid, in basis points
--- @field protocolFeeTarget string The process ID to receive the protocol fee

--- Creates a new ConditionalTokens instance
--- @param name string The token name
--- @param ticker string The token ticker
--- @param logos table<string> The token logos Arweave TxID for each ID
--- @param balancesById table<string, table<string, string>> The account token balances by ID
--- @param totalSupplyById table<string, string> The total supply of the token by ID
--- @param denomination number The number of decimals
--- @param resolutionAgent string The process ID of the resolution agent
--- @param collateralToken string The process ID of the collateral token
--- @param positionIds table<string> The position IDs representing outcomes
--- @param creatorFee number The creator fee to be paid, in basis points
--- @param creatorFeeTarget string The process ID to receive the creator fee
--- @param protocolFee number The protocol fee to be paid, in basis points
--- @param protocolFeeTarget string The process ID to receive the protocol fee
--- @return ConditionalTokens conditionalTokens The new ConditionalTokens instance
function ConditionalTokens.new(
  name,
  ticker,
  logos,
  balancesById,
  totalSupplyById,
  denomination,
  resolutionAgent,
  collateralToken,
  positionIds,
  creatorFee,
  creatorFeeTarget,
  protocolFee,
  protocolFeeTarget
)
  ---@class ConditionalTokens : SemiFungibleTokens
  local conditionalTokens = SemiFungibleTokens.new(name, ticker, logos, balancesById, totalSupplyById, denomination)
  conditionalTokens.resolutionAgent = resolutionAgent
  conditionalTokens.collateralToken = collateralToken
  conditionalTokens.positionIds = positionIds
  conditionalTokens.creatorFee = tonumber(creatorFee) or 0
  conditionalTokens.creatorFeeTarget = creatorFeeTarget
  conditionalTokens.protocolFee = tonumber(protocolFee) or 0
  conditionalTokens.protocolFeeTarget = protocolFeeTarget
  conditionalTokens.payoutDenominator = 0
  -- Initialize the payout vector as zeros.
  conditionalTokens.payoutNumerators = {}
  for _ = 1, #positionIds do
    table.insert(conditionalTokens.payoutNumerators, 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  conditionalTokens.payoutDenominator = 0

  local semiFungibleTokensMetatable = getmetatable(conditionalTokens)
  setmetatable(conditionalTokens, {
    __index = function(_, k)
      if ConditionalTokensMethods[k] then
        return ConditionalTokensMethods[k]
      elseif ConditionalTokensNotices[k] then
        return ConditionalTokensNotices[k]
      else
        -- Fallback directly to the parent metatable
        return semiFungibleTokensMetatable.__index(_, k)
      end
    end
  })
  return conditionalTokens
end

--- Split position
--- @param from string The process ID of the account that split the position
--- @param collateralToken string The process ID of the collateral token
--- @param quantity string The quantity of collateral to split
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message| nil The position split notice if not cast
function ConditionalTokensMethods:splitPosition(from, collateralToken, quantity, cast, sendInterim, detached, msg)
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "Condition not prepared!")
  -- Create equal split positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Mint the stake in the split target positions.
  self:batchMint(from, self.positionIds, quantities, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- Send notice.
  if not cast then return self.positionSplitNotice(from, collateralToken, quantity, detached, msg) end
end

--- Merge positions
--- @param from string The process ID of the account that merged the positions
--- @param onBehalfOf string The process ID of the account that will receive the collateral
--- @param quantity string The quantity of collateral to merge
--- @param isSell boolean True if the merge is a sell, false otherwise
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message|nil The positions merge notice if not cast
function ConditionalTokensMethods:mergePositions(from, onBehalfOf, quantity, isSell, cast, sendInterim, detached, msg)
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "Condition not prepared!")
  -- Create equal merge positions.
  local quantities = {}
  for _ = 1, #self.positionIds do
    table.insert(quantities, quantity)
  end
  -- Burn equal quantiies from user positions.
  self:batchBurn(from, self.positionIds, quantities, not sendInterim, true, msg) -- @dev `true`: sends detatched message
  -- @dev below already handled within the sell method.
  -- sell method w/ a different quantity and recipient.
  if not isSell then
    -- Return the collateral to the user.
    ao.send({
      Target = self.collateralToken,
      Action = "Transfer",
      Quantity = quantity,
      Recipient = onBehalfOf,
    ---@diagnostic disable-next-line: assign-type-mismatch
      Cast = not sendInterim and "true" or nil
    })
  end
  -- Send notice.
  if not cast then return self.positionsMergeNotice(self.collateralToken, quantity, onBehalfOf, detached, msg) end
end

--- Report payouts
--- @param payouts table<number> The resolution agent's answer
--- @param msg Message The message received
--- @return Message reportPayoutsNotice The report payouts notice
function ConditionalTokensMethods:reportPayouts(payouts, msg)
  assert(#payouts == #self.positionIds, "Payouts must match outcome slot count!")
  assert(msg.From == self.resolutionAgent, "Sender not resolution agent!")
  assert(self.payoutDenominator == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, #self.positionIds do
    local num = payouts[i]
    den = den + num
    assert(self.payoutNumerators[i] == 0, "payout numerator already set")
    self.payoutNumerators[i] = num
  end
  assert(den > 0, "payout is all zeroes")
  self.payoutDenominator = den
  -- Send notice.
  return self.reportPayoutsNotice(msg.From, self.payoutNumerators, msg)
end

--- Redeem positions
--- Transfers any payout minus fees to the message sender
--- @param onBehalfOf string The process ID of the account to receive the collateral
--- @param cast boolean The cast is set to true to silence the notice
--- @param sendInterim boolean If true, sends intermediate notices
--- @param msg Message The message received
--- @return Message|nil The payout redemption notice if not cast
function ConditionalTokensMethods:redeemPositions(onBehalfOf, cast, sendInterim, msg)
  local den = self.payoutDenominator
  assert(den > 0, "market not resolved")
  assert(self.payoutNumerators and #self.payoutNumerators > 0, "market not initialized")
  local totalPayout = 0
  local totalPayoutMinusFee = "0"
  for i = 1, #self.positionIds do
    local positionId = self.positionIds[i]
    local payoutNumerator = self.payoutNumerators[tonumber(positionId)]
    -- Get the stake to redeem.
    if not self.balancesById[positionId] then self.balancesById[positionId] = {} end
    if not self.balancesById[positionId][msg.From] then self.balancesById[positionId][msg.From] = "0" end
    local payoutStake = self.balancesById[positionId][msg.From]
    if bint.__lt(0, bint(payoutStake)) then
      -- Calculate the payout and burn position.
      totalPayout = math.floor(totalPayout + (payoutStake * payoutNumerator) / den)
      self:burn(msg.From, positionId, payoutStake, not sendInterim, true, msg) -- @dev `true`: sends detatched message
    end
  end
  -- Return total payout minus take fee.
  if totalPayout > 0 then
    totalPayout = math.floor(totalPayout)
    totalPayoutMinusFee = self:returnTotalPayoutMinusTakeFee(self.collateralToken, onBehalfOf, totalPayout, not sendInterim)
  end
  -- Send notice.
  if not cast then return self.redeemPositionsNotice(self.collateralToken, totalPayout, totalPayoutMinusFee, onBehalfOf, msg) end
end

--- Return total payout minus take fee
--- Distributes payout and fees to the redeem account, creator and protocol
--- @param collateralToken string The collateral token
--- @param from string The account to receive the payout minus fees
--- @param totalPayout number The total payout assciated with the acount stake
--- @param cast boolean The cast is set to true to silence the notice
--- @return string The total payout minus fee amount
function ConditionalTokensMethods:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout, cast)
  local protocolFee =  tostring(bint.ceil(bint.__div(bint.__mul(totalPayout, self.protocolFee), 1e4)))
  local creatorFee =  tostring(bint.ceil(bint.__div(bint.__mul(totalPayout, self.creatorFee), 1e4)))
  local takeFee = tostring(bint.__add(bint(creatorFee), bint(protocolFee)))
  local totalPayoutMinusFee = tostring(bint.__sub(totalPayout, bint(takeFee)))
  -- prepare txns
  local protocolFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = self.protocolFeeTarget,
    Quantity = protocolFee,
    Cast = cast and "true" or nil
  }
  local creatorFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = self.creatorFeeTarget,
    Quantity = creatorFee,
    Cast = cast and "true" or nil
  }
  local totalPayoutMinutTakeFeeTxn = {
    Target = collateralToken,
    Action = "Transfer",
    Recipient = from,
    Quantity = totalPayoutMinusFee,
    Cast = cast and "true" or nil
  }
  -- send txns
  ao.send(protocolFeeTxn)
  ao.send(creatorFeeTxn)
  ao.send(totalPayoutMinutTakeFeeTxn)

  return totalPayoutMinusFee
end

return ConditionalTokens
