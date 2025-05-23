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
--- @param onBehalfOf string The address to receive the LP tokens
--- @param msg Message The message received
--- @return Message The funding added notice
function CPMMNotices.addFundingNotice(fundingAdded, mintAmount, onBehalfOf, msg)
  return msg.forward(msg.Tags.Sender, {
    Action = "Add-Funding-Notice",
    FundingAdded = json.encode(fundingAdded),
    MintAmount = tostring(mintAmount),
    OnBehalfOf = onBehalfOf,
    Data = "Successfully added funding"
  })
end

--- Sends a remove funding notice
--- @param sendAmounts table The send amounts
--- @param collateralRemovedFromFeePool string The collateral removed from the fee pool
--- @param sharesToBurn string The shares to burn
--- @param onBehalfOf string The address to receive the position tokens
--- @param msg Message The message received
--- @return Message The funding removed notice
function CPMMNotices.removeFundingNotice(sendAmounts, collateralRemovedFromFeePool, sharesToBurn, onBehalfOf, msg)
  return msg.reply({
    Action = "Remove-Funding-Notice",
    SendAmounts = json.encode(sendAmounts),
    CollateralRemovedFromFeePool = collateralRemovedFromFeePool,
    SharesToBurn = sharesToBurn,
    OnBehalfOf = onBehalfOf,
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
    Data = "Successfully bought"
  })
end

--- Sends a sell notice
--- @param from string The address that sold
--- @param onBehalfOf string The address that receives the collateral
--- @param returnAmount number The return amount
--- @param feeAmount number The fee amount
--- @param positionId string The position ID
--- @param positionTokensSold number The outcome position tokens sold
--- @param msg Message The message received
--- @return Message The sell notice
function CPMMNotices.sellNotice(from, onBehalfOf, returnAmount, feeAmount, positionId, positionTokensSold, msg)
  return msg.forward(from, {
    Action = "Sell-Notice",
    OnBehalfOf = onBehalfOf,
    ReturnAmount = tostring(returnAmount),
    FeeAmount = tostring(feeAmount),
    PositionId = positionId,
    PositionTokensSold = tostring(positionTokensSold),
    Data = "Successfully sold"
  })
end

--- Sends a withdraw fees notice
--- @dev Ensures the final notice is sent to the user, preventing unintended message handling
--- @param feeAmount number The fee amount
--- @param onBehalfOf string The address to receive the fees
--- @param detached boolean Whether to use `ao.send` or `msg.reply`
--- @param msg Message The message received
--- @return Message The withdraw fees notice
function CPMMNotices.withdrawFeesNotice(feeAmount, onBehalfOf, detached, msg)
  local notice = {
    Action = "Withdraw-Fees-Notice",
    FeeAmount = tostring(feeAmount),
    OnBehalfOf = onBehalfOf,
    Data = "Successfully withdrew fees"
  }
  if not detached then return msg.reply(notice) end
  notice.Target = msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Propose configurator notice
--- @param configurator string The proposed configurator address
--- @param msg Message The message received
--- @return Message proposeConfiguratorNotice The propose configurator notice
function CPMMNotices.proposeConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Propose-Configurator-Notice",
    Data = configurator
  })
end

--- Accept configurator notice
--- @param msg Message The message received
--- @return Message acceptConfiguratorNotice The accept configurator notice
function CPMMNotices.acceptConfiguratorNotice(msg)
  return msg.reply({
    Action = "Accept-Configurator-Notice",
    Data = msg.From
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

--- Sends an update logos notice
--- @param logos table<string> The updated logos
--- @param msg Message The message received
--- @return Message The logo updated notice
function CPMMNotices.updateLogosNotice(logos, msg)
  return msg.reply({
    Action = "Update-Logos-Notice",
    Data = json.encode(logos)
  })
end

return CPMMNotices