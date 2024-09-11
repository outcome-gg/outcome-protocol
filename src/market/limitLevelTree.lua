local LimitLevel = require("LimitLevel")

local LimitLevelTree = {}
local LimitLevelTreeMethods = {}

-- Constructor
function LimitLevelTree:new()
  -- Create a new object and set the metatable to LimitLevelTree directly
  local obj = {
    root = nil
  }
  -- Set the metatable to LimitLevelTreeMethods for method lookup
  setmetatable(obj, { __index = LimitLevelTreeMethods })
  return obj
end

function LimitLevelTreeMethods:insert(limitLevel)
  if not self.root then
    self.root = limitLevel
  else
    self.root = self:_insertNode(self.root, limitLevel)
  end
end

-- Recursive insertion with balancing
function LimitLevelTreeMethods:_insertNode(currentNode, newNode)
  if not currentNode then
    return newNode
  end

  if newNode.price < currentNode.price then
    currentNode.leftChild = self:_insertNode(currentNode.leftChild, newNode)
    currentNode.leftChild.parent = currentNode
  else
    currentNode.rightChild = self:_insertNode(currentNode.rightChild, newNode)
    currentNode.rightChild.parent = currentNode
  end

  -- Update the height of the current node
  currentNode:updateHeight()

  -- Rebalance the node if necessary
  return self:_rebalance(currentNode)
end

-- Rebalance the tree if unbalanced
function LimitLevelTreeMethods:_rebalance(node)
  local balance = node:balanceFactor()

  -- Left heavy (balance > 1)
  if balance > 1 then
    if node.leftChild:balanceFactor() < 0 then
      -- Left-right case
      node.leftChild:rotateLeft()
    end
    -- Left-left case
    node:rotateRight()
  end

  -- Right heavy (balance < -1)
  if balance < -1 then
    if node.rightChild:balanceFactor() > 0 then
      -- Right-left case
      node.rightChild:rotateRight()
    end
    -- Right-right case
    node:rotateLeft()
  end

  return node
end

-- New: nextBest function to get the next best level in the tree
function LimitLevelTreeMethods:nextBest()
  if not self.root then
    return nil  -- If the tree is empty, there's no next best
  end

  -- Traverse the tree to find the next best price
  local node = self.root
  local nextBestNode = nil

  -- If we're working with bids, we want the highest price just below the current best bid
  -- For asks, we want the lowest price just above the current best ask
  while node do
    if node.leftChild then
      nextBestNode = node.leftChild
      node = node.leftChild
    elseif node.rightChild then
      nextBestNode = node.rightChild
      node = node.rightChild
    else
      break
    end
  end

  return nextBestNode
end

return LimitLevelTree
