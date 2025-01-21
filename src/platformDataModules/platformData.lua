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

local PlatformData = {}
local PlatformDataMethods = {}
local PlatformDataNotices = require('platformDataModules.platformDataNotices')
local activity = require('platformDataModules.activity')
local chatroom = require('platformDataModules.chatroom')
local json = require('json')

--- Represents PlatformData
--- @class PlatformData
--- @field db table The database
--- @field dbAdmin table The database admin
--- @field activity table The activity helpers
--- @field chatroom table The chatroom helpers
--- @field configurator string The configurator
--- @field moderators table<string> The moderators

--- Creates a new PlatformData instance
function PlatformData:new(dbAdmin, configurator, moderators, readers)
  local platformData = {
    dbAdmin = dbAdmin,
    activity = activity:new(dbAdmin),
    chatroom = chatroom:new(dbAdmin),
    configurator = configurator,
    moderators = moderators,
    readers = readers
  }
  -- set metatable
  setmetatable(platformData, {
    __index = function(_, k)
      if PlatformDataMethods[k] then
        return PlatformDataMethods[k]
      elseif PlatformDataNotices[k] then
        return PlatformDataNotices[k]
      else
        return nil
      end
    end
  })
  return platformData
end

--[[
===========
INFO METHOD
===========
]]

function PlatformDataMethods:info(msg)
  return msg.reply({
    Configurator = self.configurator,
    Moderators = json.encode(self.moderators),
    Data = json.encode(self.dbAdmin:tables())
  })
end

--[[
============
READ METHODS
============
]]

--- Query
--- @param sql string The SQL query
--- @param msg Message The message received
--- @return Message queryResults The query results
function PlatformDataMethods:query(sql, msg)
  local results = self.dbAdmin:exec(sql)
  return msg.reply({ Action = 'Query-Results', Data = json.encode(results) })
end

--[[
====================
CONFIGURATOR METHODS
====================
]]

--- Update configurator
--- @param updateConfigurator string The new configurator address
--- @param msg Message The message received
--- @return Message updateConfiguratorNotice The update configurator notice
function PlatformDataMethods:updateConfigurator(updateConfigurator, msg)
  self.configurator = updateConfigurator
  return self.updateConfiguratorNotice(updateConfigurator, msg)
end

--- Update moderators
--- @param moderators table The list of moderators
--- @param msg Message The message received
--- @return Message updateModeratorsNotice The update moderators notice
function PlatformDataMethods:updateModerators(moderators, msg)
  self.moderators = moderators
  return self.updateModeratorsNotice(moderators, msg)
end

--- Update readers
--- @param readers table The list of readers
--- @param msg Message The message received
--- @return Message updateReadersNotice The update readers notice
function PlatformDataMethods:updateReaders(readers, msg)
  self.readers = readers
  return self.updateReadersNotice(readers, msg)
end

return PlatformData