local json = require('json')
local bint = require(".bint")(256)
local OrderTree = require("orderTree")
local utils = require(".utils")

local OrderBook = {}
local OrderBookMethods = {}

-- Optimize frequently used global functions
local insert = table.insert
local tostring = tostring

-- Helper function to create a deque (double-ended queue) in Lua
local function createDeque(maxlen)
  return { first = 0, last = -1, maxlen = maxlen or nil }
end

local function dequePush(deque, value)
  local last = deque.last + 1
  deque.last = last
  deque[last] = value
  if deque.maxlen and deque.last - deque.first + 1 > deque.maxlen then
    deque[deque.first] = nil
    deque.first = deque.first + 1
  end
end

-- Constructor
function OrderBook:new(tickSize)
  -- Create a new object and set the metatable to OrderBookMethods directly
  local obj = {}
  obj.tape = createDeque(nil)               -- A deque to store trade history
  obj.bids = OrderTree:new()                -- OrderTree for bids
  obj.asks = OrderTree:new()                -- OrderTree for asks
  obj.lastTick = nil                        -- Last processed tick
  obj.lastTimestamp = 0                     -- Last timestamp
  obj.tickSize = tostring(tickSize or '1')  -- Store tick size as string
  obj.time = 0                              -- Internal time counter
  obj.nextOrderId = 0                       -- Incremental order ID

  -- Set the metatable to OrderBookMethods for method lookup
  setmetatable(obj, { __index = OrderBookMethods })
  return obj
end

-- Update the internal system time
function OrderBookMethods:updateTime()
  self.time = self.time + 1
end

-- Process an incoming order
function OrderBookMethods:processOrder(quote, fromData, verbose)
  local orderType = quote.type
  local orderInBook = nil
  local trades = {}

  if fromData then
    self.time = tonumber(quote.timestamp)
  else
    self:updateTime()
    quote.timestamp = self.time
  end

  if tonumber(quote.quantity) <= 0 then
    error("processOrder() given order with quantity <= 0")
  end

  if not fromData then
    self.nextOrderId = self.nextOrderId + 1
    quote.orderId = self.nextOrderId
  end

  if orderType == "market" then
    trades = self:processMarketOrder(quote, verbose)
  elseif orderType == "limit" then
    trades, orderInBook = self:processLimitOrder(quote, fromData, verbose)
  else
    error("processOrder() received an unknown order type")
  end

  return trades, orderInBook
end

-- Process market orders
function OrderBookMethods:processMarketOrder(quote, verbose)
  local trades = {}
  local quantityToTrade = quote.quantity
  local side = quote.side
  local newTrades = nil

  if side == "bid" then
    while quantityToTrade > 0 and self.asks:len() > 0 do
      local bestPriceAsks = self.asks:minPriceList()
      quantityToTrade, newTrades = self:processOrderList("ask", bestPriceAsks, quantityToTrade, quote, verbose)
      trades = { table.unpack(trades), table.unpack(newTrades) }
    end
  elseif side == "ask" then
    while quantityToTrade > 0 and self.bids:len() > 0 do
      local bestPriceBids = self.bids:maxPriceList()
      quantityToTrade, newTrades = self:processOrderList("bid", bestPriceBids, quantityToTrade, quote, verbose)
      trades = { table.unpack(trades), table.unpack(newTrades) }
    end
  else
    error('processMarketOrder() received neither "bid" nor "ask"')
  end

  return trades
end

-- Process limit orders
function OrderBookMethods:processLimitOrder(quote, fromData, verbose)
  local trades = {}
  local orderInBook = nil
  local quantityToTrade = quote.quantity
  local side = quote.side
  local price = tostring(quote.price)  -- Store price as string
  local newTrades = nil

  print("keys srt: " .. json.encode(utils.keys(self.asks)))
  local keys = utils.keys(self.asks)
  print("self.asks srt: " .. " " .. json.encode(self.asks))
  for i = 1, #keys do
    print("self.asks[keys[i]]: " .. " " .. keys[i] .. " " .. json.encode(self.asks[keys[i]]))
  end

  if side == "bid" then
    while self.asks:len() > 0 and bint(price) >= bint(self.asks:minPrice()) and quantityToTrade > 0 do
      local bestPriceAsks = self.asks:minPriceList()
      quantityToTrade, newTrades = self:processOrderList("ask", bestPriceAsks, quantityToTrade, quote, verbose)
      trades = { table.unpack(trades), table.unpack(newTrades) }
    end

    if quantityToTrade > 0 then
      if not fromData then
        quote.orderId = self.nextOrderId
      end
      quote.quantity = quantityToTrade
      self.bids:insertOrder(quote)
      orderInBook = quote
    end
  elseif side == "ask" then
    while self.bids:len() > 0 and bint(price) <= bint(self.bids:maxPrice()) and quantityToTrade > 0 do
      print("--here--")
      local bestPriceBids = self.bids:maxPriceList()
      quantityToTrade, newTrades = self:processOrderList("bid", bestPriceBids, quantityToTrade, quote, verbose)
      trades = { table.unpack(trades), table.unpack(newTrades) }
      print("--trades-- " .. json.encode(trades))
    end

    if quantityToTrade > 0 then
      if not fromData then
        quote.orderId = self.nextOrderId
      end
      quote.quantity = quantityToTrade
      print("--self.asks--" .. json.encode(self.asks))
      print("--")
      print("--quote--" .. json.encode(quote))
      self.asks:insertOrder(quote)
      print("--before asks--")
      print("--self.asks--" .. json.encode(self.asks))
      orderInBook = quote
    end
  else
    error('processLimitOrder() given neither "bid" nor "ask"')
  end

  print("keys end: " .. json.encode(utils.keys(self.asks)))
  print("self.asks['prices'] end: " .. " " .. json.encode(self.asks["prices"]))
  print("self.asks['depth'] end: " .. " " .. json.encode(self.asks["depth"]))
  print("self.asks['numOrder'] end: " .. " " .. json.encode(self.asks["numOrder"]))
  print("self.asks['volume'] end: " .. " " .. json.encode(self.asks["volume"]))
  print("self.asks['orderMap'] end: " .. " " .. json.encode(self.asks["orderMap"])) -- circular reference
  print("self.asks['priceMap'] end: " .. " " .. json.encode(self.asks["priceMap"])) -- invalid table: mixed or invalid key types
  print("self.asks end: " .. " " .. json.encode(self.asks))
  for i = 1, #keys do
    print("self.asks[keys[i]]: " .. " " .. keys[i] .. " " .. json.encode(self.asks[keys[i]]))
  end

  return trades, orderInBook
end

-- Process an order list and match trades
function OrderBookMethods:processOrderList(side, orderList, quantityStillToTrade, quote, verbose)
  local trades = {}
  local quantityToTrade = quantityStillToTrade

  while #orderList > 0 and quantityToTrade > 0 do
    local headOrder = orderList:getHeadOrder()
    local tradedPrice = headOrder.price
    local counterParty = headOrder.tradeId
    local newBookQuantity
    local tradedQuantity

    if quantityToTrade < headOrder.quantity then
      tradedQuantity = quantityToTrade
      newBookQuantity = tostring(bint(headOrder.quantity) - bint(quantityToTrade))  -- Store as string
      headOrder:updateQuantity(newBookQuantity, headOrder.timestamp)
      quantityToTrade = 0
    else
      tradedQuantity = headOrder.quantity
      if side == "bid" then
        self.bids:removeOrderById(headOrder.orderId)
      else
        self.asks:removeOrderById(headOrder.orderId)
      end
      quantityToTrade = tostring(bint(quantityToTrade) - bint(tradedQuantity))  -- Store as string
    end

    if verbose then
      print(string.format("TRADE: Time - %d, Price - %s, Quantity - %s, TradeID - %s, Matching TradeID - %s",
        self.time, tostring(tradedPrice), tostring(tradedQuantity), counterParty, quote.tradeId)
      )
    end

    local transactionRecord = {
      timestamp = self.time,
      price = tradedPrice,
      quantity = tradedQuantity,
      time = self.time
    }

    if side == "bid" then
      transactionRecord.party1 = { counterParty, "bid", headOrder.orderId, newBookQuantity }
      transactionRecord.party2 = { quote.tradeId, "ask", nil, nil }
    else
      transactionRecord.party1 = { counterParty, "ask", headOrder.orderId, newBookQuantity }
      transactionRecord.party2 = { quote.tradeId, "bid", nil, nil }
    end

    dequePush(self.tape, transactionRecord)
    insert(trades, transactionRecord)
  end

  return quantityToTrade, trades
end

-- Cancel an order by its ID and side
function OrderBookMethods:cancelOrder(side, orderId, time)
  if time then
    self.time = time
  else
    self:updateTime()
  end

  if side == "bid" then
    if self.bids:orderExists(orderId) then
      self.bids:removeOrderById(orderId)
    end
  elseif side == "ask" then
    if self.asks:orderExists(orderId) then
      self.asks:removeOrderById(orderId)
    end
  else
    error('cancelOrder() given neither "bid" nor "ask"')
  end
end

-- Modify an order by its ID
function OrderBookMethods:modifyOrder(orderId, orderUpdate, time)
  if time then
    self.time = time
  else
    self:updateTime()
  end

  local side = orderUpdate.side
  orderUpdate.orderId = orderId
  orderUpdate.timestamp = self.time

  if side == "bid" then
    if self.bids:orderExists(orderId) then
      self.bids:updateOrder(orderUpdate)
    end
  elseif side == "ask" then
    if self.asks:orderExists(orderId) then
      self.asks:updateOrder(orderUpdate)
    end
  else
    error('modifyOrder() given neither "bid" nor "ask"')
  end
end

-- Get the volume at a specific price
function OrderBookMethods:getVolumeAtPrice(side, price)
  if side == "bid" then
    if self.bids:priceExists(price) then
      return self.bids:getPriceList(price).volume
    end
  elseif side == "ask" then
    if self.asks:priceExists(price) then
      return self.asks:getPriceList(price).volume
    end
  else
    error('getVolumeAtPrice() given neither "bid" nor "ask"')
  end

  return 0
end

-- Get the best bid (highest price in bids)
function OrderBookMethods:getBestBid()
  return self.bids:maxPrice()
end

-- Get the worst bid (lowest price in bids)
function OrderBookMethods:getWorstBid()
  return self.bids:minPrice()
end

-- Get the best ask (lowest price in asks)
function OrderBookMethods:getBestAsk()
  return self.asks:minPrice()
end

-- Get the worst ask (highest price in asks)
function OrderBookMethods:getWorstAsk()
  return self.asks:maxPrice()
end

return OrderBook
