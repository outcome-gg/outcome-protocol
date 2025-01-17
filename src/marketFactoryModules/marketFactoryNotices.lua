--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See factory.lua for full license details.
=========================================================
]]

local MarketFactoryNotices = {}
local json = require('json')

--- Spawn market notice
--- @param resolutionAgent string The resolution agent address
--- @param collateralToken string The collateral token address
--- @param creator string The creator address
--- @param creatorFee number The creator fee
--- @param creatorFeeTarget string The creator fee target
--- @param question string The market question
--- @param outcomeSlotCount number The number of outcome slots
--- @param msg Message The message received
--- @return Message spawnMarketNotice The spawn market notice
function MarketFactoryNotices.spawnMarketNotice(resolutionAgent, collateralToken, creator, creatorFee, creatorFeeTarget, question, outcomeSlotCount, msg)
  return msg.reply({
    Action = "Market-Spawned-Notice",
    ResolutionAgent = resolutionAgent,
    CollateralToken = collateralToken,
    Creator = creator,
    CreatorFee = creatorFee,
    CreatorFeeTarget = creatorFeeTarget,
    Question = question,
    OutcomeSlotCount = outcomeSlotCount,
    ["Original-Msg-Id"] = msg.Id
  })
end

--- Init market notice
--- @param marketProcessIds table The market process IDs
--- @param msg Message The message received
--- @return Message initMarketNotice The init market notice
function MarketFactoryNotices.initMarketNotice(marketProcessIds, msg)
  return msg.reply({
    Action = "Market-Init-Notice",
    MarketProcessIds = json.encode(marketProcessIds)
  })
end

--- Update configurator notice
--- @param updateConfigurator string The new configurator address
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
function MarketFactoryNotices.updateConfiguratorNotice(updateConfigurator, msg)
  return msg.reply({
    Action = "Update-Configurator-Notice",
    UpdateConfigurator = updateConfigurator
  })
end

--- Update incentives notice
--- @param updateIncentives string The new incentives address
--- @param msg Message The message received
--- @return Message updateIncentivesNotice The update incentives notice
function MarketFactoryNotices.updateIncentivesNotice(updateIncentives, msg)
  return msg.reply({
    Action = "Update-Incentives-Notice",
    UpdateIncentives = updateIncentives
  })
end

--- Update lpFee notice
--- @param updateLpFee string The new lp fee
--- @param msg Message The message received
--- @return Message updateLpFeeNotice The update lp fee notice
function MarketFactoryNotices.updateLpFeeNotice(updateLpFee, msg)
  return msg.reply({
    Action = "Update-LpFee-Notice",
    UpdateLpFee = updateLpFee
  })
end

--- Update protocolFee notice
--- @param updateProtocolFee string The new protocol fee
--- @param msg Message The message received
--- @return Message updateProtocolFeeNotice The update protocol fee notice
function MarketFactoryNotices.updateProtocolFeeNotice(updateProtocolFee, msg)
  return msg.reply({
    Action = "Update-ProtocolFee-Notice",
    UpdateProtocolFee = updateProtocolFee
  })
end

--- Update protocolFeeTarget notice
--- @param updateProtocolFeeTarget string The new protocol fee target
--- @param msg Message The message received
--- @return Message updateProtocolFeeTargetNotice The update protocol fee target notice
function MarketFactoryNotices.updateProtocolFeeTargetNotice(updateProtocolFeeTarget, msg)
  return msg.reply({
    Action = "Update-ProtocolFeeTarget-Notice",
    UpdateProtocolFeeTarget = updateProtocolFeeTarget
  })
end

--- Update maximumTakeFee notice
--- @param updateMaximumTakeFee string The new maximum take fee
--- @param msg Message The message received
--- @return Message updateMaximumTakeFeeNotice The update maximum take fee notice
function MarketFactoryNotices.updateMaximumTakeFeeNotice(updateMaximumTakeFee, msg)
  return msg.reply({
    Action = "Update-MaximumTakeFee-Notice",
    UpdateMaximumTakeFee = updateMaximumTakeFee
  })
end

--- Update utilityToken notice
--- @param updateUtilityToken string The new utility token address
--- @param msg Message The message received
--- @return Message updateUtilityTokenNotice The update utility token notice
function MarketFactoryNotices.updateUtilityTokenNotice(updateUtilityToken, msg)
  return msg.reply({
    Action = "Update-UtilityToken-Notice",
    UpdateUtilityToken = updateUtilityToken
  })
end

--- Update minimumPayment notice
--- @param minimumPayment string The new minimum payment amount
--- @param msg Message The message received
--- @return Message updateMinimumPaymentNotice The update minimum payment amount notice
function MarketFactoryNotices.updateMinimumPaymentNotice(minimumPayment, msg)
  return msg.reply({
    Action = "Update-MinimumPayment-Notice",
    UpdateMinimumPayment = minimumPayment
  })
end

--- Approve collateral token notice
--- @param collateralToken string The collateral token address
--- @param isApprove boolean The approval status, true if approved, false otherwise
--- @param msg Message The message received
--- @return Message approveCollateralTokenNotice The approve collateral token notice
function MarketFactoryNotices.approveCollateralTokenNotice(collateralToken, isApprove, msg)
  return msg.reply({
    Action = "Approve-CollateralToken-Notice",
    CollateralToken = collateralToken,
    IsApprove = tostring(isApprove)
  })
end

--- Transfer notice
--- @param token string The token address
--- @param recipient string The recipient address
--- @param quantity string The quantity to transfer
--- @param msg Message The message received
--- @return Message transferNotice The transfer notice
function MarketFactoryNotices.transferNotice(token, recipient, quantity, msg)
  return msg.reply({
    Action = "Transfer-Notice",
    Token = token,
    Recipient = recipient,
    Quantity = quantity
  })
end

return MarketFactoryNotices