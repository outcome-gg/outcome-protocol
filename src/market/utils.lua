local Utils = {}

-- Circular reference detection integrated into serialization
function Utils.serializeWithoutCircularReferences(obj, seen)
  seen = seen or {}

  -- Check if the object has been seen to detect circular references
  if seen[obj] then
    return {}  -- Return an empty table if a circular reference is detected
  end
  seen[obj] = true

  local copy = {}
  for key, value in pairs(obj) do
    -- Skip circular reference fields like 'previousItem', 'nextItem'
    if key ~= "previousItem" and key ~= "nextItem" then
      if type(value) == "table" then
        copy[key] = Utils.serializeWithoutCircularReferences(value, seen)
      else
        copy[key] = value
      end
    end
  end

  seen[obj] = nil  -- Reset the object in the seen table to allow for other paths
  return copy
end

-- Circular reference detection method
function Utils.detectCircularReferences(obj, seen)
  seen = seen or {}
  if seen[obj] then
    return true  -- Circular reference detected
  end
  seen[obj] = true

  for key, value in pairs(obj) do
    if type(value) == "table" and Utils.detectCircularReferences(value, seen) then
      print("Circular reference found at key: " .. key)
      return true
    end
  end
  return false
end

return Utils
