--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cronRunner.lua for full license details.
=========================================================
]]

local cronRunnerValidation = {}
local sharedValidation = require('modules.sharedValidation')
local json = require('json')

--- Validates add job
--- @param msg Message The message to be validated
function cronRunnerValidation.addJob(msg)
  sharedValidation.validateAddress(msg.Tags.ProcessId, 'ProcessId')
end

--- validates add jobs
--- @param msg Message The message to be validated
function cronRunnerValidation.addJobs(msg)
  sharedValidation.validateJSONArray(msg.Tags.ProcessIds, 'ProcessIds')
  local processIds = json.decode(msg.Tags.ProcessIds)
  for _, processId in ipairs(processIds) do
    sharedValidation.validateAddress(processId, 'ProcessId')
  end
end

--- Validates remove job
--- @param msg Message The message to be validated
function cronRunnerValidation.removeJob(msg)
  sharedValidation.validateAddress(msg.Tags.ProcessId, 'ProcessId')
end

--- Validates remove jobs
--- @param msg Message The message to be validated
function cronRunnerValidation.removeJobs(msg)
  sharedValidation.validateJSONArray(msg.Tags.ProcessIds, 'ProcessIds')
  local processIds = json.decode(msg.Tags.ProcessIds)
  for _, processId in ipairs(processIds) do
    sharedValidation.validateAddress(processId, 'ProcessId')
  end
end

return cronRunnerValidation