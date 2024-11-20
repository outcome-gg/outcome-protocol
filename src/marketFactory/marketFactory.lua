local ao = require('.ao')
local json = require('json')
local bint = require('.bint')(256)
local config = require('modules.config')
local marketFactory = require('modules.marketFactory')

---------------------------------------------------------------------------------
-- MarketFactory ----------------------------------------------------------------
---------------------------------------------------------------------------------
-- @dev Load config
if not Config or Config.resetState then Config = config:new() end
-- @dev Reset state while in DEV mode
if not MarketFactory or Config.resetState then MarketFactory = marketFactory:new(Config) end

---------------------------------------------------------------------------------
-- MATCHING ---------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Create Market
local function isCreateMarket(msg)
  if msg.Action == "Credit-Notice" and msg["X-Action"] == "Create-Market" then
      return true
  else
      return false
  end
end

-- Funding Added
local function isFundingAdded(msg)
  if msg.Action == "Funding-Added-Notice" then
      return true
  else
      return false
  end
end

---------------------------------------------------------------------------------
-- WRITE HANDLERS ---------------------------------------------------------------
---------------------------------------------------------------------------------
-- Update Conditional Tokens
Handlers.add('updateConditionalTokens', Handlers.utils.hasMatchingTag('Action', 'Update-Conditional-Tokens'), function(msg)
  assert(type(msg.Tags['Collateral-Token']) == 'string', 'Collateral-Token is required!')
  assert(type(msg.Tags['Conditional-Tokens']) == 'string', 'Conditional-Tokens is required!')
  config.updateConditionalTokens(msg.Tags['Collateral-Token'], msg.Tags['Conditional-Tokens'])

  msg.reply({ Action = 'Conditional-Tokens-Updated', CollateralToken = msg.Tags['Collateral-Token'], ConditionalTokens = msg.Tags['Conditional-Tokens'] })
end)

-- Create Market
--@dev TODO: decide if this should be open to anyone
--@dev TODO: decide if a minimum collateral amount should be required
Handlers.add('createMarket', isCreateMarket, function(msg)
  assert(msg.Tags['Sender'], 'Sender is required!')
  assert(msg.Tags['X-Question'], 'X-Question is required!')
  assert(msg.Tags['X-ResolutionAgent'], 'X-ResolutionAgent is required!')
  assert(msg.Tags['X-OutcomeSlotCount'], 'X-OutcomeSlotCount is required!')
  assert(bint.__lt(1, bint(msg.Tags['X-OutcomeSlotCount'])), 'X-OutcomeSlotCount must be greater than zero!')
  assert(msg.Tags['X-Partition'], 'X-Partition is required!')
  local partition = json.decode(msg.Tags['X-Partition'])
  assert(type(partition) == 'table', 'X-Partition must be a table!')
  assert(msg.Tags['X-ParentCollectionId'], 'X-ParentCollectionId is required!')
  assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
  local distribution = json.decode(msg.Tags['X-Distribution'])
  assert(type(distribution) == 'table', 'X-Distribution must be a table!')

  -- Create market
  local success, marketId = MarketFactory:createMarket(msg.Tags['X-Question'], msg.Tags['X-ResolutionAgent'], msg.Tags['X-OutcomeSlotCount'], partition, distribution, msg.Tags['X-ParentCollectionId'], msg.Tags.Quantity, msg.From, msg.Tags['Sender'])

  if not success then
    -- Return funds
    ao.send({
      Target = msg.From,
      Action = 'Transfer',
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags['Sender'],
      Error = 'Market-Created-Error: ' .. marketId
    })
    -- Return error
    msg.forward(msg.Tags['Sender'], {
      Action = 'Market-Created-Error',
      MarketId = marketId
    })
    return
  end
end)

-- @dev used in case init market process fails (i.e. when Init is processed before Eval)
Handlers.add('initMarket', Handlers.utils.hasMatchingTag('Action', 'Init-Market'), function(msg)
  assert(msg.Tags.MarketId, 'MarketId is required!')
  -- Init market
  local success, errorMessage = MarketFactory:initMarket(msg.Tags.MarketId, msg)

  if not success then
    -- Return error
    msg.reply({
      Action = 'Market-Initialized-Error',
      MarketId = msg.MarketId,
      Error = errorMessage
    })
    return
  end
end)

---------------------------------------------------------------------------------
-- READ HANDLERS ----------------------------------------------------------------
---------------------------------------------------------------------------------
-- Get Lookup
Handlers.add('updateConditionalTokens', Handlers.utils.hasMatchingTag('Action', 'Get-Lookup'), function(msg)
  msg.reply({Action = 'Lookup', Data = MarketFactory.lookup})
end)

-- Get Market
Handlers.add('getMarketData', Handlers.utils.hasMatchingTag('Action', 'Get-Market-Data'), function(msg)
  assert(msg.Tags.MarketId, 'MarketId is required!')
  local status = msg.Tags.Status or nil
  local marketData = MarketFactory:getMarketById(msg.Tags.MarketId, status)
  ao.send({
    Target = msg.From,
    Action = 'Market-Data',
    MarketId = msg.Tags.MarketId,
    Data = json.encode(marketData)
  })
end)

---------------------------------------------------------------------------------
-- CALLBACK HANDLERS ------------------------------------------------------------
---------------------------------------------------------------------------------
-- Funding Added Callback
Handlers.add('fundingAddedCallback', isFundingAdded, function(msg)
  MarketFactory:fundingAdded(msg.From)
end)

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------
Handlers.add('updateLookup', Handlers.utils.hasMatchingTag('Action', 'Update-Lookup'), function(msg)
  assert(msg.Tags['CollateralToken'], 'CollateralToken is required!')
  assert(msg.Tags['CollateralTokenTicker'], 'CollateralTokenTicker is required!')
  assert(msg.Tags['ConditionalTokens'], 'ConditionalTokens is required!')
  assert(msg.Tags['LpTokenLogo'], 'LpTokenLogo is required!')

  local data = Config:updateLookup(msg.Tags['CollateralToken'], msg.Tags['CollateralTokenTicker'], msg.Tags['ConditionalTokens'], msg.Tags['LpTokenLogo'])
  msg.reply({
    Action = 'Lookup-Updated',
    Data = data
  })
end)

Handlers.add('removeLookup', Handlers.utils.hasMatchingTag('Action', 'Remove-Lookup'), function(msg)
  assert(msg.Tags['Collateral-Token'], 'Collateral-Token is required!')
  assert(MarketFactory.lookup[msg.Tags['Collateral-Token']], 'Collateral Token not found!')
  Config:removeLookup(msg.Tags['Collateral-Token'])
  msg.reply({ Action = 'Lookup-Removed', CollateralToken = msg.Tags['Collateral-Token'] })
end)
return "ok"