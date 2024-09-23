-- Conflict Free Replicated Data Type (CRDT) implementation
local CRDT = {}

function CRDT:new()
  local obj = {
    state = {}
  }
  setmetatable(obj, { __index = CRDT })
  return obj
end

-- Insert a new node into the CRDT state
function CRDT:insert(node)
  self.state[node.price] = node
end

-- Merge remote CRDT state into the current state
function CRDT:merge(remoteState)
  for price, node in pairs(remoteState.state) do
    if not self.state[price] then
      self.state[price] = node
    end
  end
end

-- Get the best node (highest bid or lowest ask)
function CRDT:getBest()
  local best = nil
  for price, node in pairs(self.state) do
    if not best or tonumber(price) > tonumber(best.price) then
      best = node
    end
  end
  return best
end

return CRDT
