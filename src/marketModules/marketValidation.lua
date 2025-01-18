local MarketValidation = {}
local sharedValidation = require('marketModules.sharedValidation')

--- Validates update data index
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function MarketValidation.updateDataIndex(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.DataIndex, 'DataIndex')
end

--- Validates update incentives
--- @param msg Message The message to be validated
--- @param configurator string The configurator address
function MarketValidation.updateIncentives(msg, configurator)
  assert(msg.From == configurator, 'Sender must be configurator!')
  sharedValidation.validateAddress(msg.Tags.Incentives, 'Incentives')
end

return MarketValidation