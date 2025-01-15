--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See cronRunner.lua for full license details.
=========================================================
]]

local cronRunnerNotices = {}
local json = require('json')

function cronRunnerNotices.addJobNotice(processId, msg)
  return msg.reply({ Action = 'Add-Job-Notice', ProcessId = processId })
end

function cronRunnerNotices.addJobsNotice(processIds, msg)
  return msg.reply({ Action = 'Add-Jobs-Notice', ProcessIds = json.encode(processIds) })
end

function cronRunnerNotices.removeJobNotice(processId, msg)
  return msg.reply({ Action = 'Remove-Job-Notice', ProcessId = processId })
end

function cronRunnerNotices.removeJobsNotice(processIds, msg)
  return msg.reply({ Action = 'Remove-Jobs-Notice', ProcessIds = json.encode(processIds) })
end

return cronRunnerNotices