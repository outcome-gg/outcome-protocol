local validation = {}

function validation.stageUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(type(msg.Tags.UpdateTagName) == 'string', 'UpdateTagName is required!')
  assert(type(msg.Tags.UpdateTagValue) == 'string', 'UpdateTagValue is required!')
end

function validation.unstageUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(type(msg.Tags.UpdateTagName) == 'string', 'UpdateTagName is required!')
  assert(type(msg.Tags.UpdateTagValue) == 'string', 'UpdateTagValue is required!')
end

function validation.actionUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(type(msg.Tags.UpdateProcess) == 'string', 'UpdateProcess is required!')
  assert(type(msg.Tags.UpdateAction) == 'string', 'UpdateAction is required!')
  assert(type(msg.Tags.UpdateTagName) == 'string', 'UpdateTagName is required!')
  assert(type(msg.Tags.UpdateTagValue) == 'string', 'UpdateTagValue is required!')
end

function validation.stageAdminUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
end

function validation.unstageAdminUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
end

function validation.actionAdminUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateAdmin, 'UpdateAdmin is required!')
end

function validation.stageDelayUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
  assert(tonumber(msg.Tags.UpdateDelay), 'UpdateDelay must be a number!')
  assert(tonumber(msg.Tags.UpdateDelay) > 0, 'UpdateDelay must be greater than zero!')
  assert(tonumber(msg.Tags.UpdateDelay) % 1 == 0, 'UpdateDelay must be an integer!')
end

function validation.unstageDelayUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
end

function validation.actionDelayUpdate(msg)
  assert(msg.From == Configurator.admin, 'Sender must be admin!')
  assert(msg.Tags.UpdateDelay, 'UpdateDelay is required!')
end

return validation