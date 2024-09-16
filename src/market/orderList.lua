local json = require('json')
local Utils = require('Utils')

local OrderList = {}
local OrderListMethods = {}

-- Constructor
function OrderList:new(parentLimit)
  -- Ensure that the parentLimit has a size field initialized to 0
  parentLimit.size = parentLimit.size or 0

  -- Create a new object and set the metatable to OrderListMethods directly
  local obj = {
    head = nil,
    tail = nil,
    parentLimit = parentLimit,
    count = 0
  }
  -- Set the metatable to OrderListMethods for method lookup
  setmetatable(obj, { __index = OrderListMethods })
  return obj
end

function OrderListMethods:append(order)
  if not self.tail then
    -- The list is empty, so both head and tail should point to the new order
    self.tail = order
    self.head = order
  else
    -- There are existing orders, append this one to the tail
    self.tail.nextItem = order
    order.previousItem = self.tail
    self.tail = order
  end
  -- Set the root reference
  order.root = self
  -- Update the count and size
  self.count = self.count + 1
  self.parentLimit.size = self.parentLimit.size + order.size

  -- Debugging: Print the current state of the order list (head and tail)
  print("-")
  print("OrderListMethods:append - Head UID: " .. (self.head and tostring(self.head.uid) or "nil"))
  print("OrderListMethods:append - Tail UID: " .. (self.tail and tostring(self.tail.uid) or "nil"))
  print("OrderListMethods:append - List count: " .. tostring(self.count))
  print("OrderListMethods:append - Parent limit size: " .. tostring(self.parentLimit.size))
end

return OrderList
