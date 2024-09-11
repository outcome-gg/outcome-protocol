local json = require('json')

local OrderList = require("OrderList")

local LimitLevel = {}
local LimitLevelMethods = {}

-- Constructor
function LimitLevel:new(order)
  -- Create a new object and set the metatable to LimitLevelMethods directly
  local obj = {
    price = order.price,
    size = order.size,
    parent = nil,
    leftChild = nil,
    rightChild = nil,
    orders = OrderList:new(self),
    height = 1  -- New property to track the height of the node
  }
  -- Set the metatable to LimitLevelMethods for method lookup
  setmetatable(obj, { __index = LimitLevelMethods })
  -- Append order to limit level
  obj:append(order)
  return obj
end

function LimitLevelMethods:append(order)
  return self.orders:append(order)
end

function LimitLevelMethods:isRoot()
  return self.parent == nil
end

-- Calculate the balance factor (left height - right height)
function LimitLevelMethods:balanceFactor()
  local leftHeight = self.leftChild and self.leftChild.height or 0
  local rightHeight = self.rightChild and self.rightChild.height or 0
  return leftHeight - rightHeight
end

-- Update the height of the node based on its children
function LimitLevelMethods:updateHeight()
  local leftHeight = self.leftChild and self.leftChild.height or 0
  local rightHeight = self.rightChild and self.rightChild.height or 0
  self.height = math.max(leftHeight, rightHeight) + 1
end

-- Rotate left (for right-heavy trees)
function LimitLevelMethods:rotateLeft()
  local newRoot = self.rightChild
  self.rightChild = newRoot.leftChild
  if newRoot.leftChild then
    newRoot.leftChild.parent = self
  end
  newRoot.parent = self.parent
  if not self.parent then
    -- This was the root node
  elseif self == self.parent.leftChild then
    self.parent.leftChild = newRoot
  else
    self.parent.rightChild = newRoot
  end
  newRoot.leftChild = self
  self.parent = newRoot
  -- Update heights
  self:updateHeight()
  newRoot:updateHeight()
end

-- Rotate right (for left-heavy trees)
function LimitLevelMethods:rotateRight()
  local newRoot = self.leftChild
  self.leftChild = newRoot.rightChild
  if newRoot.rightChild then
    newRoot.rightChild.parent = self
  end
  newRoot.parent = self.parent
  if not self.parent then
    -- This was the root node
  elseif self == self.parent.leftChild then
    self.parent.leftChild = newRoot
  else
    self.parent.rightChild = newRoot
  end
  newRoot.rightChild = self
  self.parent = newRoot
  -- Update heights
  self:updateHeight()
  newRoot:updateHeight()
end

return LimitLevel
