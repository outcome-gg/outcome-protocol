local json = require('json')
local ao = ao or require('.ao')

local MarketFactoryNotices = {}

--- Sends a new market notice
--- @param configurator string The configurator address
--- @param incentives string The incentives address
--- @param collateralToken string The collateral token address
--- @param marketId string The market ID
--- @param conditionId string The condition ID
--- @param positionIds table The position IDs
--- @param outcomeSlotCount number The number of outcome slots
--- @param name string The market name
--- @param ticker string The market ticker
--- @param logo string The market logo
--- @param lpFee number The LP fee
--- @param creatorFee number The creator fee
--- @param creatorFeeTarget string The creator fee target
--- @param protocolFee number The protocol fee
--- @param protocolFeeTarget string The protocol fee target
--- @param msg Message The message received
--- @return Message The new market notice
function MarketFactoryNotices.newMarketNotice(configurator, incentives, collateralToken, marketId, conditionId, positionIds, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
  return msg.reply({
    Action = "New-Market-Notice",
    MarketId = marketId,
    ConditionId = conditionId,
    Configurator = configurator,
    Incentives = incentives,
    CollateralToken = collateralToken,
    PositionIds = json.encode(positionIds),
    OutcomeSlotCount = tostring(outcomeSlotCount),
    LpFee = lpFee,
    CreatorFee = creatorFee,
    CreatorFeeTarget = creatorFeeTarget,
    ProtocolFee = protocolFee,
    ProtocolFeeTarget = protocolFeeTarget,
    Name = name,
    Ticker = ticker,
    Logo = logo,
    Data = "Successfully created market"
  })
end

--- Prepare condition notice
--- @param conditionId string The condition ID
--- @param outcomeSlotCount number The number of outcome slots
--- @param msg Message The message received
--- @return Message The condition preparation notice
function MarketFactoryNotices.conditionPreparationNotice(conditionId, outcomeSlotCount, msg)
  return msg.reply({
    Action = "Condition-Preparation-Notice",
    ConditionId = conditionId,
    OutcomeSlotCount = tostring(outcomeSlotCount)
  })
end

return MarketFactoryNotices