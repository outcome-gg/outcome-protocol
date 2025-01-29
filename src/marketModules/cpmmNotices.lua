--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

-- local ao = require('.ao') @dev required for unit tests?
local json = require('json')

local CPMMNotices = {}

--- Sends a funding added notice
--- @param from string The address that added funding
--- @param fundingAdded table The funding added
--- @param mintAmount number The mint amount
--- @return Message The funding added notice
function CPMMNotices.fundingAddedNotice(from, fundingAdded, mintAmount)
  return ao.send({
    Target = from,
    Action = "Funding-Added-Notice",
    FundingAdded = json.encode(fundingAdded),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

--- Sends a funding removed notice
--- @param from string The address that removed funding
--- @param sendAmounts table The send amounts
--- @param collateralRemovedFromFeePool number The collateral removed from the fee pool
--- @param sharesToBurn number The shares to burn
--- @return Message The funding removed notice
function CPMMNotices.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  return ao.send({
    Target = from,
    Action = "Funding-Removed-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
    SharesToBurn = tostring(sharesToBurn),
    Data = "Successfully removed funding"
  })
end

--- Sends a buy notice
--- @param from string The address that bought
--- @param onBehalfOf string The address that receives the outcome tokens
--- @param investmentAmount number The investment amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param outcomeTokensToBuy number The outcome tokens to buy
--- @return Message The buy notice
function CPMMNotices.buyNotice(from, onBehalfOf, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
  return ao.send({
    Target = from,
    Action = "Buy-Notice",
    OnBehalfOf = onBehalfOf,
    InvestmentAmount = tostring(investmentAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    OutcomeTokensToBuy = tostring(outcomeTokensToBuy),
    Data = "Successful buy order"
  })
end

--- Sends a sell notice
--- @param from string The address that sold
--- @param returnAmount number The return amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param outcomeTokensToSell number The outcome tokens to sell
--- @return Message The sell notice
function CPMMNotices.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
  return ao.send({
    Target = from,
    Action = "Sell-Notice",
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    OutcomeTokensToSell = tostring(outcomeTokensToSell),
    Data = "Successful sell order"
  })
end

--- Sends an update configurator notice
--- @param configurator string The updated configurator address
--- @param msg Message The message received
--- @return Message The configurator updated notice
function CPMMNotices.updateConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Configurator-Updated",
    Data = configurator
  })
end

--- Sends an update take fee notice
--- @param creatorFee string The updated creator fee
--- @param protocolFee string The updated protocol fee
--- @param takeFee string The updated take fee
--- @param msg Message The message received
function CPMMNotices.updateTakeFeeNotice(creatorFee, protocolFee, takeFee, msg)
  return msg.reply({
    Action = "Take-Fee-Updated",
    CreatorFee = tostring(creatorFee),
    ProtocolFee = tostring(protocolFee),
    Data = tostring(takeFee)
  })
end

--- Sends an update protocol fee target notice
--- @param protocolFeeTarget string The updated protocol fee target
--- @param msg Message The message received
--- @return Message The protocol fee target updated notice
function CPMMNotices.updateProtocolFeeTargetNotice(protocolFeeTarget, msg)
  return msg.reply({
    Action = "Protocol-Fee-Target-Updated",
    Data = protocolFeeTarget
  })
end

--- Sends an update logo notice
--- @param logo string The updated logo
--- @param msg Message The message received
--- @return Message The logo updated notice
function CPMMNotices.updateLogoNotice(logo, msg)
  return msg.reply({
    Action = "Logo-Updated",
    Data = logo
  })
end

return CPMMNotices