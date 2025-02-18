--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cpmm.lua for full license details.
=========================================================
]]

-- local ao = require('.ao') @dev required for unit tests?
local json = require('json')

local CPMMNotices = {}

--- Sends an add funding notice
--- @param fundingAdded table The funding added
--- @param mintAmount number The mint amount
--- @param msg Message The message received
--- @return Message The funding added notice
function CPMMNotices.addFundingNotice(fundingAdded, mintAmount, msg)
  return msg.forward(msg.Tags.Sender, {
    Action = "Add-Funding-Notice",
    FundingAdded = json.encode(fundingAdded),
    MintAmount = tostring(mintAmount),
    Data = "Successfully added funding"
  })
end

--- Sends a remove funding notice
--- @param sendAmounts table The send amounts
--- @param collateralRemovedFromFeePool string The collateral removed from the fee pool
--- @param sharesToBurn string The shares to burn
--- @param msg Message The message received
--- @return Message The funding removed notice
function CPMMNotices.removeFundingNotice(sendAmounts, collateralRemovedFromFeePool, sharesToBurn, msg)
  return msg.reply({
    Action = "Remove-Funding-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = collateralRemovedFromFeePool,
    SharesToBurn = sharesToBurn,
    Data = "Successfully removed funding"
  })
end

--- Sends a buy notice
--- @param from string The address that bought
--- @param onBehalfOf string The address that receives the outcome tokens
--- @param investmentAmount number The investment amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param positionTokensBought number The outcome position tokens bought
--- @param msg Message The message received
--- @return Message The buy notice
function CPMMNotices.buyNotice(from, onBehalfOf, investmentAmount, feeAmount, positionId, positionTokensBought, msg)
  return msg.forward(from, {
    Action = "Buy-Notice",
    OnBehalfOf = onBehalfOf,
    InvestmentAmount = tostring(investmentAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    PositionTokensBought = tostring(positionTokensBought),
    Data = "Successful buy order"
  })
end

--- Sends a sell notice
--- @param from string The address that sold
--- @param returnAmount number The return amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param positionTokensSold number The outcome position tokens sold
--- @param msg Message The message received
--- @return Message The sell notice
function CPMMNotices.sellNotice(from, returnAmount, feeAmount, positionId, positionTokensSold, msg)
  return msg.forward(from, {
    Action = "Sell-Notice",
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    PositionTokensSold = tostring(positionTokensSold),
    Data = "Successful sell order"
  })
end

--- Sends a withdraw fees notice
--- @notice Returns notice with `msg.reply` if `useReply` is true, otherwise uses `ao.send`
--- @dev Ensures the final notice is sent to the user, preventing unintended message handling 
--- @param feeAmount number The fee amount
--- @param msg Message The message received
--- @param useReply boolean Whether to use `msg.reply` or `ao.send`
--- @return Message The withdraw fees notice
function CPMMNotices.withdrawFeesNotice(feeAmount, msg, useReply)
  local notice = {
    Action = "Withdraw-Fees-Notice",
    FeeAmount = tostring(feeAmount),
    Data = "Successfully withdrew fees"
  }
  if useReply then return msg.reply(notice) end
  notice.Target = msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Sends an update configurator notice
--- @param configurator string The updated configurator address
--- @param msg Message The message received
--- @return Message The configurator updated notice
function CPMMNotices.updateConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Update-Configurator-Notice",
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
    Action = "Update-Take-Fee-Notice",
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
    Action = "Update-Protocol-Fee-Target-Notice",
    Data = protocolFeeTarget
  })
end

--- Sends an update logo notice
--- @param logo string The updated logo
--- @param msg Message The message received
--- @return Message The logo updated notice
function CPMMNotices.updateLogoNotice(logo, msg)
  return msg.reply({
    Action = "Update-Logo-Notice",
    Data = logo
  })
end

return CPMMNotices