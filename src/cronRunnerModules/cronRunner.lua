local CronRunner = {}
local CronRunnerMethods = {}
local CronRunnerNotices = require("cronRunnerModules.cronRunnerNotices")

--- Represents a CronRunner
--- @class CronRunner
--- @field processIds table<string> The list of process IDs to call
--- @return table CronRunner The CronRunner object

function CronRunner.new()
  local cronRunner = {
    processIds = {}
  }
  setmetatable(cronRunner, {
    __index = function(_, k)
      if CronRunnerMethods[k] then
        return CronRunnerMethods[k]
      elseif CronRunnerNotices[k] then
        return CronRunnerNotices[k]
      else
        return nil
      end
    end
  })
  return cronRunner
end

function CronRunnerMethods:info(msg)
  msg.reply({
    ProcessIds = self.processIds
  })
end

function CronRunnerMethods:addJob(processId, msg)
  table.insert(self.processIds, processId)
  return self.addJobNotice(processId, msg)
end

function CronRunnerMethods:removeJob(processId, msg)
  for i, j in ipairs(self.processIds) do
    if j == processId then
      table.remove(self.processIds, i)
    end
  end
  return self.removeJobNotice(processId, msg)
end

function CronRunnerMethods:addJobs(processIds, msg)
  for _, processId in ipairs(processIds) do
    table.insert(self.processIds, processId)
  end
  return self.addJobsNotice(processIds, msg)
end

function CronRunnerMethods:removeJobs(processIds, msg)
  for _, processId in ipairs(processIds) do
    for i, j in ipairs(self.processIds) do
      if j == processId then
        table.remove(self.processIds, i)
      end
    end
  end
  return self.removeJobsNotice(processIds, msg)
end

function CronRunnerMethods:runJobs()
  for _, processId in ipairs(self.processIds) do
    ao.send({Target = processId, Action = "Run-Cron-Job"})
  end
  -- Log runs
  print(string.format(
    "[%s] Completed running cron for %d processes",
    os.date("%Y-%m-%d %H:%M:%S"),
    #self.processIds
  ))
end

return CronRunner