--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See factory.lua for full license details.
=========================================================
]]

local MarketFactoryNotices = {}
local json = require('json')

--- Create market group notice
--- @param collateral string The collateral token address
--- @param creator string The creator address
--- @param question string The group title
--- @param rules string The group rules
--- @param category string The group category
--- @param subcategory string The group subcategory
--- @param logo string The group logo
--- @param msg Message The message received
--- @return Message createGroupNotice The create group notice
function MarketFactoryNotices.createMarketGroupNotice(collateral, creator, question, rules, category, subcategory, logo, msg)
  return msg.reply({
    Action = "Create-Market-Group-Notice",
    GroupId = msg.Id,
    Collateral = collateral,
    Creator = creator,
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo
  })
end

--- Spawn market notice
--- @param resolutionAgent string The resolution agent address
--- @param collateralToken string The collateral token address
--- @param creator string The creator address
--- @param creatorFee number The creator fee
--- @param creatorFeeTarget string The creator fee target
--- @param question string The market question
--- @param rules string The market rules
--- @param outcomeSlotCount number The number of outcome slots
--- @param category string The market category
--- @param subcategory string The market subcategory
--- @param logo string The market logo
--- @param groupId string The group ID
--- @param msg Message The message received
--- @return Message spawnMarketNotice The spawn market notice
function MarketFactoryNotices.spawnMarketNotice(
  resolutionAgent,
  collateralToken,
  creator,
  creatorFee,
  creatorFeeTarget,
  question,
  rules,
  outcomeSlotCount,
  category,
  subcategory,
  logo,
  groupId,
  msg
)
  return msg.reply({
    Action = "Spawn-Market-Notice",
    ResolutionAgent = resolutionAgent,
    CollateralToken = collateralToken,
    Creator = creator,
    CreatorFee = tostring(creatorFee),
    CreatorFeeTarget = creatorFeeTarget,
    Question = question,
    Rules = rules,
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    GroupId = groupId,
    ["Original-Msg-Id"] = msg.Id
  })
end

--- Init market notice
--- @param marketProcessIds table The market process IDs
--- @param msg Message The message received
--- @return Message initMarketNotice The init market notice
function MarketFactoryNotices.initMarketNotice(marketProcessIds, msg)
  return msg.reply({
    Action = "Init-Market-Notice",
    Data = json.encode(marketProcessIds)
  })
end

--- Update configurator notice
--- @param configurator string The new configurator address
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
function MarketFactoryNotices.updateConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Update-Configurator-Notice",
    Data = configurator
  })
end

--- Update incentives notice
--- @param incentives string The new incentives address
--- @param msg Message The message received
--- @return Message updateIncentivesNotice The update incentives notice
function MarketFactoryNotices.updateIncentivesNotice(incentives, msg)
  return msg.reply({
    Action = "Update-Incentives-Notice",
    Data = incentives
  })
end

--- Update lpFee notice
--- @param lpFee number The new lp fee
--- @param msg Message The message received
--- @return Message updateLpFeeNotice The update lp fee notice
function MarketFactoryNotices.updateLpFeeNotice(lpFee, msg)
  return msg.reply({
    Action = "Update-Lp-Fee-Notice",
    Data = tostring(lpFee)
  })
end

--- Update protocolFee notice
--- @param protocolFee number The new protocol fee
--- @param msg Message The message received
--- @return Message updateProtocolFeeNotice The update protocol fee notice
function MarketFactoryNotices.updateProtocolFeeNotice(protocolFee, msg)
  return msg.reply({
    Action = "Update-Protocol-Fee-Notice",
    Data = tostring(protocolFee)
  })
end

--- Update protocolFeeTarget notice
--- @param protocolFeeTarget string The new protocol fee target
--- @param msg Message The message received
--- @return Message updateProtocolFeeTargetNotice The update protocol fee target notice
function MarketFactoryNotices.updateProtocolFeeTargetNotice(protocolFeeTarget, msg)
  return msg.reply({
    Action = "Update-Protocol-Fee-Target-Notice",
    Data = protocolFeeTarget
  })
end

--- Update maximumTakeFee notice
--- @param maximumTakeFee number The new maximum take fee
--- @param msg Message The message received
--- @return Message updateMaximumTakeFeeNotice The update maximum take fee notice
function MarketFactoryNotices.updateMaximumTakeFeeNotice(maximumTakeFee, msg)
  return msg.reply({
    Action = "Update-Maximum-Take-Fee-Notice",
    Data = tostring(maximumTakeFee)
  })
end

--- Approve collateral token notice
--- @param collateralToken string The collateral token address
--- @param approved boolean The approval status, true if approved, false otherwise
--- @param msg Message The message received
--- @return Message approveCollateralTokenNotice The approve collateral token notice
function MarketFactoryNotices.approveCollateralTokenNotice(collateralToken, approved, msg)
  return msg.reply({
    Action = "Approve-Collateral-Token-Notice",
    CollateralToken = collateralToken,
    Approved = tostring(approved),
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