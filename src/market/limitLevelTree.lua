local json = require('json')
local Utils = require('Utils')

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

-- Get the next best level in the tree
function LimitLevelTreeMethods:nextBest(currentNode)
  if not self.root then
    return nil  -- If the tree is empty, there's no next best
  end

  local nextBestNode = nil

  -- Traverse up to find the next best price, ignoring zero size nodes
  local function traverseUp(node, visited)
    -- 'visited' will track nodes to prevent revisiting
    visited = visited or {}

    while node do
      -- Check if the node has been visited to prevent infinite looping
      if visited[node] then
        return nil  -- Avoid looping back to the same node
      end

      -- Mark this node as visited
      visited[node] = true

      -- First, check the parent node's orders
      if node.orders and node.orders.count > 0 then
        return node  -- Found a valid node with orders
      end

      -- For bids, prioritize higher prices, for asks prioritize lower prices
      if self.root.isBid then
        -- Bid traversal (right child first)
        if node.rightChild and node.rightChild.size > 0 then
          node = node.rightChild
        elseif node.leftChild and node.leftChild.size > 0 then
          node = node.leftChild
        else
          return node.parent   -- No valid node found
        end
      else
        -- Ask traversal (left child first)
        if node.leftChild and node.leftChild.size > 0 then
          node = node.leftChild
        elseif node.rightChild and node.rightChild.size > 0 then
          node = node.rightChild
        else
          return node.parent  -- No valid node found
        end
      end
    end
    return nil  -- If no valid node is found, return nil
  end

  -- Start at the current node, check if it has a valid size
  local visited = {}
  nextBestNode = traverseUp(currentNode or self.root, visited)

  -- Continue traversal to find a valid next best node
  while nextBestNode and nextBestNode.size == 0 do
    nextBestNode = traverseUp(nextBestNode, visited)
  end

  return nextBestNode
end

function LimitLevelTreeMethods:allLevels()
  local levels = {}

  -- Helper function to perform in-order traversal
  local function traverse(node)
    if not node then return end

    -- Traverse the left subtree
    traverse(node.leftChild)

    -- Collect the current node (price level)
    table.insert(levels, node)

    -- Traverse the right subtree
    traverse(node.rightChild)
  end

  -- Start traversal from the root
  traverse(self.root)

  return levels
end


return LimitLevelTree
