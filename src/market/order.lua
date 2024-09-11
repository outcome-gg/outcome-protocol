local json = require('json')
local Order = {}
local OrderMethods = {}

-- Constructor
function Order:new(uid, isBid, size, price)
  -- Create a new object and set the metatable to OrderMethods directly
  local obj = {
    uid = uid,
    isBid = isBid,
    size = size,
    price = price,
    nextItem = nil,
    previousItem = nil,
    root = nil
  }
  -- Set the metatable to OrderMethods for method lookup
  setmetatable(obj,  { __index = OrderMethods })
  return obj
end

function OrderMethods:popFromList()
  assert(self.root, "Error: order has no root (OrderList reference) set")

  if self.previousItem then
    self.previousItem.nextItem = self.nextItem
  else
    -- If there's no previous item, this is the head, so update the head pointer
    self.root.head = self.nextItem
  end
  if self.nextItem then
    self.nextItem.previousItem = self.previousItem
  else
    -- If there's no next item, this is the tail, so update the tail pointer
    self.root.tail = self.previousItem
  end
  -- Decrement the count and size in the root (OrderList)
  self.root.count = self.root.count - 1
  self.root.parentLimit.size = self.root.parentLimit.size - self.size
end


return Order
