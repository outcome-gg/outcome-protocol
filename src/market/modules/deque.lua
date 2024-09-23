-- Double-Ended Queue (Deque) implementation
local Deque = {}
local DequeMethods = {}

-- Constructor
function Deque:new()
  local obj = { head = 1, tail = 0, levelSize = 0, data = {} }
  setmetatable(obj, { __index = DequeMethods })
  return obj
end

-- Add to the tail (enqueue)
function DequeMethods:pushTail(value)
  self.tail = self.tail + 1
  self.data[self.tail] = value
  self.levelSize = self.levelSize + value.size
end

-- Remove from the head (dequeue)
function DequeMethods:popHead()
  if self:isEmpty() then return nil end
  local value = self.data[self.head]
  self.data[self.head] = nil -- Free memory
  self.head = self.head + 1
  self.levelSize = self.levelSize - value.size
  return value
end

-- Remove from the deque by uid
function DequeMethods:popByUid(uid)
  for i = self.head, self.tail do
    if self.data[i].uid == uid then
      self.levelSize = self.levelSize - self.data[i].size
      self.tail = self.tail - 1
      table.remove(self.data, i)
      return true
    end
  end
  return false
end

-- Check if deque is empty
function DequeMethods:isEmpty()
  return self.head > self.tail
end

-- Peek at the head
function DequeMethods:peekHead()
  if self:isEmpty() then return nil end
  return self.data[self.head]
end

-- Peek at the tail
function DequeMethods:peekTail()
  if self:isEmpty() then return nil end
  return self.data[self.tail]
end

-- Get the size of the deque
function DequeMethods:size()
  return self.tail - self.head + 1
end

return Deque
