local MarketValidation = {}
local sharedValidation = require('marketModules.sharedValidation')

--- Validates update data index
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function MarketValidation.updateDataIndex(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  local success, err = sharedValidation.validateAddress(msg.Tags.DataIndex, 'DataIndex')
  if not success then return false, err end

  return true
end

--- Validates update incentives
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
--- @return boolean, string|nil Returns true on success, or false and an error message on failure
function MarketValidation.updateIncentives(msg, configurator)
  if msg.From ~= configurator then
    return false, 'Sender must be configurator!'
  end

  local success, err = sharedValidation.validateAddress(msg.Tags.Incentives, 'Incentives')
  if not success then return false, err end

  return true
end

return MarketValidation