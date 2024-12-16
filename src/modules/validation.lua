local json = require('json')
local bint = require('.bint')(256)
local utils = require('.utils')

local validation = {}

---------------------------------------------------------------------------------
-- CONFIG HANDLERS --------------------------------------------------------------
---------------------------------------------------------------------------------

function validation.updateConfigurator(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Configurator, 'Configurator is required!')
end

function validation.updateIncentives(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Incentives, 'Incentives is required!')
end

function validation.updateTakeFee(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.CreatorFee, 'CreatorFee is required!')
  assert(tonumber(msg.Tags.CreatorFee), 'CreatorFee must be a number!')
  assert(tonumber(msg.Tags.CreatorFee) > 0, 'CreatorFee must be greater than zero!')
  assert(tonumber(msg.Tags.CreatorFee) % 1 == 0, 'CreatorFee must be an integer!')
  assert(msg.Tags.ProtocolFee, 'ProtocolFee is required!')
  assert(tonumber(msg.Tags.ProtocolFee), 'ProtocolFee must be a number!')
  assert(tonumber(msg.Tags.ProtocolFee) > 0, 'ProtocolFee must be greater than zero!')
  assert(tonumber(msg.Tags.ProtocolFee) % 1 == 0, 'ProtocolFee must be an integer!')
  assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Net fee must be less than or equal to 1000 bps')
end

function validation.updateProtocolFeeTarget(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.ProtocolFeeTarget, 'ProtocolFeeTarget is required!')
end

function validation.updateLogo(msg)
  assert(msg.From == CPMM.configurator, 'Sender must be configurator!')
  assert(msg.Tags.Logo, 'Logo is required!')
end

return validation