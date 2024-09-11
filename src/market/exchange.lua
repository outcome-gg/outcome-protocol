local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local crypto = require('.crypto')
local ao = require('.ao')
local limitOrderBook = require('limitOrderBook')
local limitOrderBookOrder = require('order')

--[[
    GLOBALS
  ]]
--
-- @dev used to reset state between integration tests
ResetState = true

Version = "1.0.1"
Initialized = false

-- @dev init new limit order book
LimitOrderBook = limitOrderBook:new()

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


local function assertMaxDp(value, maxDp)
  -- Calculate the rounding factor based on the max decimal places
  local factor = 10 ^ maxDp

  -- Round the value to the specified number of decimal places
  local roundedValue = math.floor(value * factor + 0.5) / factor

  -- Assert if the original value exceeds the allowed precision
  assert(value == roundedValue, "Value has more than " .. maxDp .. " decimal places")

  -- If the value passes the assertion, return it as a string without decimals
  return tostring(math.floor(roundedValue * factor))
end


--[[
    Orders
  ]]
--
-- @returns success, orderId
local function processOrder(order, msgId, i)
  -- Create unique id if not provided
  order.uid = order.uid or msgId .. '_' .. i
  -- Create order object
  order = limitOrderBookOrder:new(order.uid, order.isBid, order.size, order.price)
  -- Process order
  local success = LimitOrderBook:process(order)
  return success, order.uid
end

local function processOrders(orders, msgId)
  local successList = {}
  local orderIdList = {}
  for i = 1, #orders do
    local success, orderId = processOrder(orders[i], msgId, i)
    table.insert(successList, success)
    table.insert(orderIdList, orderId)
  end
  return successList, orderIdList
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
  print('Process-Order:srt')
  local order = json.decode(msg.Data)
  assert(type(order.isBid) == 'boolean', 'isBid is required!')
  assert(type(order.size) == 'number', 'size is required!')
  assertMaxDp(order.size, 0)
  assert(type(order.price) == 'number', 'price is required!')
  local priceString = assertMaxDp(order.price, 3)
  order.price = priceString

  -- process single order
  local success, orderId = processOrder(order, msg.Id, 1)

  ao.send({
    Target = msg.From,
    Action = 'Order-Processed',
    Success = tostring(success),
    OrderId = orderId,
    Data = msg.Data
  })
  print('Process-Order:end')
end)

Handlers.add('Process-Orders', Handlers.utils.hasMatchingTag('Action', 'Process-Orders'), function(msg)
  print("==")
  print('Process-Orders')
  local orders = json.decode(msg.Data)
  for i = 1, #orders do
    assert(type(orders[i].isBid) == 'boolean', 'isBid is required!')
    assert(type(orders[i].size) == 'number', 'size is required!')
    assertMaxDp(orders[i].size, 0)
    assert(type(orders[i].price) == 'number', 'price is required!')
    local priceString = assertMaxDp(orders[i].price, 3)
    orders[i].price = priceString
  end

  -- process multiple orders
  local successList, orderIds = processOrders(orders, msg.Id)

  ao.send({
    Target = msg.From,
    Action = 'Orders-Processed',
    Successes = json.encode(successList),
    OrdersIds = json.encode(orderIds),
    Data = msg.Data
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