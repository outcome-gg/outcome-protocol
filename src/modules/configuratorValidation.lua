local json = require('json')
local sharedUtils = require('modules.sharedUtils')

local configuratorValidation = {}

function configuratorValidation.updateProcess(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(sharedUtils.isValidArweaveAddress(msg.Tags.UpdateProcess), 'UpdateProcess must be a valid Arweave address!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(sharedUtils.isValidKeyValueJSON(msg.Tags.UpdateTags) or msg.Tags.UpdateTags == nil, 'UpdateTags must be valid JSON!')
  assert(sharedUtils.isValidKeyValueJSON(msg.Tags.UpdateData) or msg.Tags.UpdateData == nil, 'UpdateData must be valid JSON!')
end

function configuratorValidation.updateAdmin(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateAdmin) == 'string', 'UpdateAdmin is required!')
  assert(sharedUtils.isValidArweaveAddress(msg.Tags.UpdateAdmin), 'UpdateAdmin must be a valid Arweave address!')
end

function configuratorValidation.updateDelay(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
  assert(tonumber(msg.Tags.UpdateDelay), 'UpdateDelay must be a number!')
  assert(tonumber(msg.Tags.UpdateDelay) > 0, 'UpdateDelay must be greater than zero!')
  assert(tonumber(msg.Tags.UpdateDelay) % 1 == 0, 'UpdateDelay must be an integer!')
end

return configuratorValidation