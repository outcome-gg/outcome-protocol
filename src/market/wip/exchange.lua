local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local crypto = require('.crypto')
local ao = require('.ao')
local orderBook = require('orderBook')

--[[
    GLOBALS
  ]]
--
-- @dev used to reset state between integration tests
ResetState = true

Version = "1.0.1"
Initialized = false

--[[
    Exchange
  ]]
--
if not DataIndex or ResetState then DataIndex = '' end

if not ConditionalTokens or ResetState then ConditionalTokens = '' end
if not ConditionId or ResetState then ConditionId = '' end

if not ParentCollectionId or ResetState then ParentCollectionId = '' end
if not CollateralToken or ResetState then CollateralToken = '' end

if not CollateralBalance or ResetState then CollateralBalance = '0' end
if not UserCollateralBalance or ResetState then UserCollateralBalance = {} end

if not Name or ResetState then Name = 'Exchange-v' .. Version end

--[[
    NOTICES
  ]]
--
-- TODO

--[[
    HELPER FUNCTIONS
  ]]
--

--[[
    CORE FUNCTIONS
  ]]
--

--[[
    Funding
  ]]
--
local function addFunding(sender, addedFunds)
  -- Add to CollateralBalance
  CollateralBalance = tostring(bint.__add(bint(CollateralBalance), bint(addedFunds)))

  -- Add to UserCollateralBalance
  if not CollateralBalance[sender] then CollateralBalance[sender] = '0' end
  CollateralBalance = tostring(bint.__add(bint(CollateralBalance), bint(addedFunds)))

  -- Create Position 
  ao.send({
    Target = CollateralToken,
    Action = 'Transfer',
    Quantity = addedFunds,
    Recipient = ConditionalTokens,
    ['X-Action'] = 'Create-Position',
    ['X-ParentCollectionId'] = ParentCollectionId,
    ['X-ConditionId'] = ConditionId,
    ['X-Partition'] = json.encode({1,2}),
    ['X-Sender'] = sender
  })
end

local function removeFunding()
  -- TODO
end

--[[
    Orders
  ]]
--
MyOrderBook = orderBook:new()

local function processOrder(order)
  local trades, orderInBook = MyOrderBook:processOrder(order, false, false)
  return trades, orderInBook
end

local function processOrders(orders)
  print("processOrders")
  local ordersInBook = {}
  local tradesList = {}
  for i = 1, #orders do
    local trades, orderInBook = processOrder(orders[i])
    table.insert(tradesList, trades)
    table.insert(ordersInBook, orderInBook)
  end
  return tradesList, ordersInBook
end

local function cancelOrder()
  -- TODO
end

local function modifyOrder()
  -- TODO
end

--[[
    Data
  ]]
--
local function getVolumeAtPrice()
  -- TODO
end

local function getBestBid()
  -- TODO
end

local function getBestAsk()
  -- TODO
end

--[[
    HANDLERS
  ]]
--

--[[
    Funding
  ]]
--
local function isAddFundingCollateralToken(msg)
  if msg.From == CollateralToken  and msg.Action == "Credit-Notice" and msg["X-Action"] == "Add-Funding" then
    return true
  else
    return false
  end
end

local function isAddFundingConditionalTokens(msg)
  if msg.From == CollateralToken  and msg.Action == "Credit-Batch-Notice" and msg["X-Action"] == "Add-Funding" then
    return true
  else
    return false
  end
end

Handlers.add('Add-Funding-CollateralToken', isAddFundingCollateralToken, function(msg)
  assert(msg.Tags.Quantity, 'Quantity is required!')
  assert(bint.__lt(0, bint(msg.Tags.Quantity)), 'Quantity must be greater than zero!')

  addFunding(msg.From, msg.Tags.Quantity)
end)

Handlers.add('Add-Funding-ConditionalTokens', isAddFundingConditionalTokens, function(msg)
  assert(msg.Tags.Quantities, 'Quantities is required!')
  -- assert(bint.__lt(0, bint(msg.Tags.Quantities)), 'Quantity must be greater than zero!')
  assert(msg.Tags.TokenIds, 'TokenIds is required!')
  assert(msg.Tags['X-Order'], 'X-Order is required!')

  -- TODO: Pass X-Order through conditionalTokens transferBatchNotice

end)

Handlers.add('Remove-Funding', Handlers.utils.hasMatchingTag('Action', 'Remove-Funding'), function(msg)
-- TODO
end)

--[[
    Order Functions
  ]]
--
Handlers.add('Process-Order', Handlers.utils.hasMatchingTag('Action', 'Process-Order'), function(msg)
  local order = json.decode(msg.Data)
  local trades, orderInBook = processOrder(order)

  ao.send({
    Target = msg.From,
    Action = 'Order-Processed',
    OrderId = orderInBook.orderId,
    OrderInBook = json.encode(orderInBook),
    Data = json.encode(trades)
  })
  print("processOrder handle 3")
end)

Handlers.add('Process-Orders', Handlers.utils.hasMatchingTag('Action', 'Process-Orders'), function(msg)
  local orders = json.decode(msg.Data)
  local tradesList, ordersInBook = processOrders(orders)

  print("tradesList: " .. json.encode(tradesList))
  print("ordersInBook: " .. json.encode(ordersInBook))

  ao.send({
    Target = msg.From,
    Action = 'Orders-Processed',
    OrdersInBook = json.encode(ordersInBook),
    Data = json.encode(tradesList)
  })
end)

Handlers.add('Cancel-Order', Handlers.utils.hasMatchingTag('Action', 'Cancel-Order'), function(msg)
-- TODO
end)

Handlers.add('Modify-Order', Handlers.utils.hasMatchingTag('Action', 'Modify-Order'), function(msg)
-- TODO
end)

--[[
    Data Functions
  ]]
--
Handlers.add('Get-Volume-At-Price', Handlers.utils.hasMatchingTag('Action', 'Get-Volume-At-Price'), function(msg)
-- TODO
end)

Handlers.add('Get-Best-Bid', Handlers.utils.hasMatchingTag('Action', 'Get-Best-Bid'), function(msg)
-- TODO
end)

Handlers.add('Get-Best-Ask', Handlers.utils.hasMatchingTag('Action', 'Get-Best-Ask'), function(msg)
-- TODO
end)

return 'ok'