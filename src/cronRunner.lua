--[[
======================================================================================
Outcome © 2025. All Rights Reserved.
======================================================================================
This code is proprietary and owned by Outcome.

You are permitted to build applications, integrations, and extensions that interact
with the Outcome Protocol, provided such usage adheres to the official Outcome
terms of service and does not result in unauthorized forks or clones of this codebase.

Redistribution, modification, or unauthorized use of this code is strictly prohibited
without explicit written permission from Outcome.
======================================================================================
]]

local cronRunner = require("cronRunnerModules.cronRunner")
local cronRunnerValidation = require('cronRunnerModules.cronRunnerValidation')
local json = require('json')

--[[
===========
CRON RUNNER
===========
]]

Env = "DEV"
Version = "1.0.1"

if not CronRunner or Env == "DEV" then CronRunner = cronRunner:new() end

--[[
============
INFO HANDLER
============
]]

--- Info handler
--- @param msg Message The message to handle
--- @return Message The info message
Handlers.add("Info", {Action = "Info"}, function(msg)
  return CronRunner:info(msg)
end)

--[[
==============
WRITE HANDLERS
==============
]]

--- Add job
--- @param msg Message The message to handle
--- @return Message addJobNotice The add job notice
Handlers.add("Add-Job", {Action = "Add-Job"}, function(msg)
  cronRunnerValidation.addJob(msg)
  return CronRunner:addJob(msg.Tags.ProcessId, msg)
end)

--- Remove job
--- @param msg Message The message to handle
--- @return Message removeJobNotice The remove job notice
Handlers.add("Remove-Job", {Action = "Remove-Job"}, function(msg)
  cronRunnerValidation.removeJob(msg)
  return CronRunner:removeJob(msg.Tags.ProcessId)
end)

--- Add jobs
--- @param msg Message The message to handle
--- @return Message addJobsNotice The add jobs notice
Handlers.add("Add-Jobs", {Action = "Add-Jobs"}, function(msg)
  cronRunnerValidation.addJobs(msg)
  return CronRunner:addJobs(json.decode(msg.Tags.ProcessIds), msg)
end)

--- Remove jobs
--- @param msg Message The message to handle
--- @return Message removeJobsNotice The remove jobs notice
Handlers.add("Remove-Jobs", {Action = "Remove-Jobs"}, function(msg)
  cronRunnerValidation.removeJobs(msg)
  return CronRunner:removeJobs(json.decode(msg.Tags.ProcessIds), msg)
end)

--- Run jobs
--- @param msg Message The message to handle
Handlers.add("Run-Jobs", {Action = "Run-Jobs"}, function(msg)
  CronRunner:runJobs()
end)