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
function PlatformData.new(dbAdmin, configurator, moderators, viewers)
  local platformData = {
    dbAdmin = dbAdmin,
    activity = activity.new(dbAdmin),
    chatroom = chatroom.new(dbAdmin),
    configurator = configurator,
    moderators = moderators,
    viewers = viewers
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
  return msg.reply({ Data = json.encode(results) })
end

--- Get market
--- @param market string The market ID
--- @param msg Message The message received
--- @return Message market The get market results
function PlatformDataMethods:getMarket(market, msg)
  local query = [[
    SELECT
      m.*,
      m.timestamp AS timestamp,
      m.creator_fee AS creator_fee,
      COALESCE(f.net_funding, 0) AS net_funding,
      COALESCE(p.bet_volume, 0) AS bet_volume,
      (
        SELECT
          json_group_object(
            pr.key,
            ROUND(pr.value, 2) -- Round to 2 decimal places
          )
        FROM
          ProbabilitySets ps
        INNER JOIN (
          SELECT
            market,
            MAX(timestamp) AS latest_timestamp
          FROM
            ProbabilitySets
          GROUP BY
            market
        ) latest_ps ON ps.market = latest_ps.market AND ps.timestamp = latest_ps.latest_timestamp
        CROSS JOIN json_each(ps.probabilities) pr
        WHERE ps.market = m.id
      ) AS probabilities
    FROM
      Markets m
    LEFT JOIN (
      SELECT
        market,
        SUM(CASE WHEN operation = 'add' THEN amount
                 WHEN operation = 'remove' THEN -amount
                 ELSE 0 END) AS net_funding
      FROM
        Fundings
      GROUP BY
        market
    ) f ON m.id = f.market
    LEFT JOIN (
      SELECT
        market,
        SUM(amount) AS bet_volume
      FROM
        Predictions
      GROUP BY
        market
    ) p ON m.id = p.market
    WHERE m.id = ?;
  ]]
  local results = self.dbAdmin:safeExec(query, true, market)
  local result = results[1] or nil
  return msg.reply({ Data = json.encode(result) })
end

--- Get markets
--- @param msg Message The message received
--- @return Message getMarkets The get markets results
function PlatformDataMethods:getMarkets(params, msg)
  local query = [[
    SELECT
      m.*,
      m.timestamp AS timestamp,
      m.creator_fee AS creator_fee,
      COALESCE(f.net_funding, 0) AS net_funding,
      COALESCE(p.bet_volume, 0) AS bet_volume,
      (
        SELECT
          json_group_object(
            pr.key,
            ROUND(pr.value, 2) -- Round to 2 decimal places
          )
        FROM
          ProbabilitySets ps
        INNER JOIN (
          SELECT
            market,
            MAX(timestamp) AS latest_timestamp
          FROM
            ProbabilitySets
          GROUP BY
            market
        ) latest_ps ON ps.market = latest_ps.market AND ps.timestamp = latest_ps.latest_timestamp
        CROSS JOIN json_each(ps.probabilities) pr
        WHERE ps.market = m.id
      ) AS probabilities
    FROM
      Markets m
    LEFT JOIN (
      SELECT
        market,
        SUM(CASE WHEN operation = 'add' THEN amount
                 WHEN operation = 'remove' THEN -amount
                 ELSE 0 END) AS net_funding
      FROM
        Fundings
      GROUP BY
        market
    ) f ON m.id = f.market
    LEFT JOIN (
      SELECT
        market,
        SUM(amount) AS bet_volume
      FROM
        Predictions
      GROUP BY
        market
    ) p ON m.id = p.market
  ]]

  local conditions = {}
  local bindings = {}

  if params then
    -- Add WHERE clause
    if params.status then
      table.insert(conditions, 'status = ?')
      table.insert(bindings, params.status)
    end
    if params.collateral then
      table.insert(conditions, 'collateral = ?')
      table.insert(bindings, params.collateral)
    end
    if params.creator then
      table.insert(conditions, 'creator = ?')
      table.insert(bindings, params.creator)
    end
    if params.category then
      table.insert(conditions, 'category = ?')
      table.insert(bindings, params.category)
    end
    if params.subcategory then
      table.insert(conditions, 'subcategory = ?')
      table.insert(bindings, params.subcategory)
    end
    if params.keyword then
      table.insert(conditions, "question LIKE '%' || ? || '%'")
      table.insert(bindings, params.keyword)
    end
    if params.minFunding then
      table.insert(conditions, "COALESCE(f.net_funding, 0) = ?")
      table.insert(bindings, params.minFunding)
    end
    if #conditions > 0 then
      query = query .. ' WHERE ' .. table.concat(conditions, ' AND ')
    end
    -- Add ORDER BY clause
    if params.orderBy then
      query = query .. ' ORDER BY ' .. params.orderBy
    end
    -- Add ORDER DIRECTION clause
    if params.orderDirection then
      query = query .. ' ' .. params.orderDirection
    end
    -- Add LIMIT clause
    if params.limit then
      query = query .. ' LIMIT ?'
      table.insert(bindings, params.limit)
    end
    -- Add OFFSET clause
    if params.offset then
      query = query .. ' OFFSET ?'
      table.insert(bindings, params.offset)
    end
  end
  -- Finalize query
  query = query .. ';'
  local results = self.dbAdmin:safeExec(query, true, table.unpack(bindings))
  return msg.reply({ Data = json.encode(results) })
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

--- Update viewers
--- @param viewers table The list of viewers
--- @param msg Message The message received
--- @return Message updateViewersNotice The update viewers notice
function PlatformDataMethods:updateViewers(viewers, msg)
  self.viewers = viewers
  return self.updateViewersNotice(viewers, msg)
end

return PlatformData