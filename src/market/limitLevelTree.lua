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

Count = 0

-- Recursive insertion with balancing
function LimitLevelTreeMethods:_insertNode(currentNode, newNode)
  Count = Count + 1
  print("")
  print("0====> LimitLevelTreeMethods:_insertNode")
  print("currentNode: " .. (currentNode and json.encode(Utils.serializeWithoutCircularReferences(currentNode)) or "nil"))
  print("")
  print("newNode: " .. (newNode and json.encode(Utils.serializeWithoutCircularReferences(newNode)) or "nil"))
  print("Count: " .. Count)
  if not currentNode then
    print("returning newNode")
    print("1====> LimitLevelTreeMethods:_insertNode")
    print("")
    return newNode
  end

  print("here0")

  if tonumber(newNode.price) < tonumber(currentNode.price) then
    currentNode.leftChild = self:_insertNode(currentNode.leftChild, newNode)
    currentNode.leftChild.parent = currentNode
  else
    currentNode.rightChild = self:_insertNode(currentNode.rightChild, newNode)
    currentNode.rightChild.parent = currentNode
  end

  print("here1")

  -- Update the height of the current node
  currentNode:updateHeight()

  print("here2")

  -- Rebalance the node if necessary
  -- return currentNode -- TESTING if rebalance is not working correctly
  return self:_rebalance(currentNode)
end

-- Rebalance the tree if unbalanced
function LimitLevelTreeMethods:_rebalance(node)
  print(">>node b4 rotation: " .. json.encode(Utils.serializeWithoutCircularReferences(node)))
  local balance = node:balanceFactor()
  print(">>balance: " .. balance)

  -- Left heavy (balance > 1)
  if balance > 1 then
    print(">>Left heavy (balance > 1)")
    if node.leftChild:balanceFactor() < 0 then
      -- Left-right case
      print(">>Left-right case")
      node.leftChild:rotateLeft()
    end
    -- Left-left case
    print(">>Left-left case")
    node:rotateRight()
  end

  -- Right heavy (balance < -1)
  if balance < -1 then
    print(">>Right heavy (balance < -1)")
    if node.rightChild:balanceFactor() > 0 then
      -- Right-left case
      print(">>Right-left case")
      node.rightChild:rotateRight()
    end
    -- Right-right case
    print(">>Right-right case")
    node:rotateLeft()
  end

  print("")
  print(">>node after rotation: " .. (node and json.encode(Utils.serializeWithoutCircularReferences(node)) or "nil"))
  print("2====> LimitLevelTreeMethods:_insertNode")
  print("")

  return node
end

-- Get the next best level in the tree
function LimitLevelTreeMethods:nextBest(currentNode)
  print("LimitLevelTreeMethods:nextBest:srt")
  if not self.root then
    return nil  -- If the tree is empty, there's no next best
  end

  local nextBestNode = nil

  -- Traverse up to find the next best price, ignoring zero size nodes
  local function traverseUp(node, visited)
    -- 'visited' will track nodes to prevent revisiting
    visited = visited or {}

    while node do
      print("here")
      print("-")
      print("node: " .. json.encode(Utils.serializeWithoutCircularReferences(node)))
      print("-")
      -- Check if the node has been visited to prevent infinite looping
      if visited[node] then
        print("visited break")
        return nil  -- Avoid looping back to the same node
      end

      -- Mark this node as visited
      visited[node] = true

      -- First, check the parent node's orders
      if node.orders and node.orders.count > 0 then
        print("first check")
        return node  -- Found a valid node with orders
      end

      -- For bids, prioritize higher prices, for asks prioritize lower prices
      if self.root.isBid then
        -- Bid traversal (right child first)
        if node.rightChild and node.rightChild.size > 0 then -- TESTING or node.rightChild.height > 1
          node = node.rightChild
        elseif node.leftChild and node.leftChild.size > 0 then -- TESTING or node.rightChild.height > 1
          node = node.leftChild
        else
          print("ask:second check")
          print("node.parent: " .. (node.parent and json.encode(Utils.serializeWithoutCircularReferences(node.parent)) or "nil"))
          return node.parent  -- No valid node found
        end
      else
        -- Ask traversal (left child first)
        if node.leftChild and node.leftChild.size > 0 then -- TESTING or node.rightChild.height > 1
          node = node.leftChild
        elseif node.rightChild and node.rightChild.size > 0 then -- TESTING or node.rightChild.height > 1
          node = node.rightChild
        else
          print("ask:second check")
          print("node.parent: " .. (node.parent and json.encode(Utils.serializeWithoutCircularReferences(node.parent)) or "nil"))
          return node.parent  -- No valid node found
        end
      end
    end
    print("returning nil")
    return nil  -- If no valid node is found, return nil
  end

  -- Start at the current node, check if it has a valid size
  local visited = {}
  nextBestNode = traverseUp(currentNode or self.root, visited)

  -- Continue traversal to find a valid next best node
  while nextBestNode and nextBestNode.size == 0 do
    nextBestNode = traverseUp(nextBestNode, visited)
  end
  print("--END OF LOOP--")

  return nextBestNode
end

return LimitLevelTree
