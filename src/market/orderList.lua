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
    self.tail = order
    self.head = order
  else
    self.tail.nextItem = order
    order.previousItem = self.tail
    self.tail = order
  end
  order.root = self
  self.count = self.count + 1
  self.parentLimit.size = self.parentLimit.size + order.size
end

return OrderList
