--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See factory.lua for full license details.
=========================================================
]]

local MarketFactoryNotices = {}
local json = require('json')

--- Create event notice
--- @param collateral string The collateral token address
--- @param dataIndex string The data index address
--- @param denomination number The denomination
--- @param outcomeSlotCount string The number of outcome slots
--- @param question string The event title
--- @param rules string The event rules
--- @param category string The event category
--- @param subcategory string The event subcategory
--- @param logo string The event logo
--- @param startTime string The event start time
--- @param endTime string The event end time
--- @param creator string The creator address
--- @param msg Message The message received
--- @return Message createEventNotice The create event notice
function MarketFactoryNotices.createEventNotice(collateral, dataIndex, denomination, outcomeSlotCount, question, rules, category, subcategory, logo, startTime, endTime, creator, msg)
  return msg.reply({
    Action = "Create-Event-Notice",
    EventId = msg.Id,
    Collateral = collateral,
    DataIndex = dataIndex,
    Denomination = tostring(denomination),
    OutcomeSlotCount = outcomeSlotCount,
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    StartTime = startTime,
    EndTime = endTime,
    Creator = creator
  })
end

--- Spawn market notice
--- @param resolutionAgent string The resolution agent address
--- @param collateralToken string The collateral token address
--- @param dataIndex string The data index address
--- @param denomination number The denomination
--- @param outcomeSlotCount number The number of outcome slots
--- @param question string The market question
--- @param rules string The market rules
--- @param category string The market category
--- @param subcategory string The market subcategory
--- @param logo string The LP token logo
--- @param logos table<string> The position token logos
--- @param eventId string The event ID
--- @param startTime string The market start time
--- @param endTime string The market end time
--- @param creator string The creator address
--- @param creatorFee number The creator fee
--- @param creatorFeeTarget string The creator fee target
--- @param msg Message The message received
--- @return Message spawnMarketNotice The spawn market notice
function MarketFactoryNotices.spawnMarketNotice(
  resolutionAgent,
  collateralToken,
  dataIndex,
  denomination,
  outcomeSlotCount,
  question,
  rules,
  category,
  subcategory,
  logo,
  logos,
  eventId,
  startTime,
  endTime,
  creator,
  creatorFee,
  creatorFeeTarget,
  msg
)
  return msg.reply({
    Action = "Spawn-Market-Notice",
    ResolutionAgent = resolutionAgent,
    CollateralToken = collateralToken,
    DataIndex = dataIndex,
    Denomination = tostring(denomination),
    OutcomeSlotCount = tostring(outcomeSlotCount),
    Question = question,
    Rules = rules,
    Category = category,
    Subcategory = subcategory,
    Logo = logo,
    Logos = json.encode(logos),
    EventId = eventId,
    StartTime = startTime,
    EndTime = endTime,
    Creator = creator,
    CreatorFee = tostring(creatorFee),
    CreatorFeeTarget = creatorFeeTarget,
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

--- Approve creator notice
--- @param creator string The creator account address
--- @param approved boolean The approval status, true if approved, false otherwise
--- @param msg Message The message received
--- @return Message approveCreatorNotice The approve creator notice
function MarketFactoryNotices.approveCreatorNotice(creator, approved, msg)
  return msg.reply({
    Action = "Approve-Creator-Notice",
    Creator = creator,
    Approved = tostring(approved),
  })
end

--- Propose configurator notice
--- @param configurator string The proposed configurator address
--- @param msg Message The message received
--- @return Message proposeConfiguratorNotice The propose configurator notice
function MarketFactoryNotices.proposeConfiguratorNotice(configurator, msg)
  return msg.reply({
    Action = "Propose-Configurator-Notice",
    Data = configurator
  })
end

--- Accept configurator notice
--- @param msg Message The message received
--- @return Message acceptConfiguratorNotice The accept configurator notice
function MarketFactoryNotices.acceptConfiguratorNotice(msg)
  return msg.reply({
    Action = "Accept-Configurator-Notice",
    Data = msg.From
  })
end

--- Update veToken notice
--- @param veToken string The new veToken
--- @param msg Message The message received
--- @return Message updateVeTokenNotice The update veToken notice
function MarketFactoryNotices.updateVeTokenNotice(veToken, msg)
  return msg.reply({
    Action = "Update-Ve-Token-Notice",
    Data = tostring(veToken)
  })
end

--- Update market process code notice
--- @return Message updateMarketProcessCodeNotice The update market process code notice
function MarketFactoryNotices.updateMarketProcessCodeNotice(msg)
  return msg.reply({
    Action = "Update-Market-Process-Code-Notice",
    Data = "Successfully updated market process code"
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

--- Update maxIterations notice
--- @param maxIterations number The new maximum iterations
--- @param msg Message The message received
--- @return Message updateMaxIterationsNotice The update max iterations notice
function MarketFactoryNotices.updateMaxIterationsNotice(maxIterations, msg)
  return msg.reply({
    Action = "Update-Max-Iterations-Notice",
    Data = tostring(maxIterations)
  })
end

--- List collateral token notice
--- @param collateralToken string The collateral token address
--- @param name string The collateral token name
--- @param ticker string The collateral token ticker
--- @param denomination number The denomination; the number of decimal places
--- @param msg Message The message received
--- @return Message listCollateralTokenNotice The list collateral token notice
function MarketFactoryNotices.listCollateralTokenNotice(collateralToken, name, ticker, denomination, msg)
  return msg.reply({
    Action = "List-Collateral-Token-Notice",
    CollateralToken = collateralToken,
    Name = name,
    Ticker = ticker,
    Denomination = tostring(denomination)
  })
end

--- Delist collateral token notice
--- @param collateralToken string The collateral token address
--- @param msg Message The message received
--- @return Message delistCollateralTokenNotice The delist collateral token notice
function MarketFactoryNotices.delistCollateralTokenNotice(collateralToken, msg)
  return msg.reply({
    Action = "Delist-Collateral-Token-Notice",
    CollateralToken = collateralToken
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