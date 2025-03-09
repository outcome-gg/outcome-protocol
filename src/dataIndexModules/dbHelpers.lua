local DbHelpers = {}
local json = require("json")

-- General validation for parameters
function DbHelpers.validateParams(params, allowedActions)
  -- Validate 'user'
  if params.user ~= nil and type(params.user) ~= "string" then
    error("Parameter 'user' must be a string or nil.")
  end
  -- Validate 'action'
  if params.action ~= nil and allowedActions and not allowedActions[params.action] then
    error(string.format("Parameter 'action' must be one of: %s", table.concat(allowedActions, ", ")))
  end
  -- Validate 'timestamp'
  if params.timestamp ~= nil and not params.timestamp:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$") then
    error("Parameter 'timestamp' must match format: 'YYYY-MM-DD HH:MM:SS'.")
  end
  -- Validate 'limit' and 'offset'
  if params.limit ~= nil and (params.limit <= 0 or math.floor(params.limit) ~= params.limit) then
    error("Parameter 'limit' must be a positive integer.")
  end
  if params.offset ~= nil and (params.offset < 0 or math.floor(params.offset) ~= params.offset) then
    error("Parameter 'offset' must be a non-negative integer.")
  end
  -- Validate 'orderDirection'
  if params.orderDirection ~= nil and params.orderDirection ~= 'ASC' and params.orderDirection ~= 'DESC' then
    error("Parameter 'orderDirection' must be 'ASC' or 'DESC'.")
  end
end

-- Build a query with shared filters
function DbHelpers.buildQuery(baseQuery, params, allowedActions, isCount, tableName, isFinalizedQuery)
  -- Validate parameters
  DbHelpers.validateParams(params, allowedActions)
  -- Extract parameters
  local market = params.market
  local user = params.user
  local silenced = params.silenced
  local action = params.action
  local outcome = params.outcome
  local keyword = params.keyword
  local timestamp = params.timestamp
  local hours = params.hours
  local startTimestamp = params.startTimestamp
  local limit = tonumber(params.limit) or nil
  local offset = tonumber(params.offset) or nil
  local orderDirection = params.orderDirection or "DESC"
  -- Start building the query
  local query = isCount and string.format("SELECT COUNT(*) as count FROM %s", tableName) or baseQuery
  local conditions = {}
  local bindings = {}
  -- Add filters
  if market then
    table.insert(conditions, "market = ?")
    table.insert(bindings, market)
  end
  if user then
    table.insert(conditions, "user = ?")
    table.insert(bindings, user)
  end
  if silenced ~= nil then
    table.insert(conditions, "silenced = ?")
    table.insert(bindings, silenced and 1 or 0)
  end
  if keyword then
    table.insert(conditions, "body LIKE ?")
    table.insert(bindings, "%" .. keyword .. "%")
  end
  if action then
    table.insert(conditions, "action = ?")
    table.insert(bindings, action)
  end
  if outcome then
    table.insert(conditions, "outcome = ?")
    table.insert(bindings, outcome)
  end
  -- Add time filter if applicable
  if startTimestamp then
    print("h1")
    -- table.insert(conditions, "timestamp >= ?")
    -- table.insert(bindings, startTimestamp)
  elseif hours then
    print("h2")
    -- table.insert(conditions, "timestamp >= datetime('now', ? || ' hours')")
    -- table.insert(bindings, '-' .. hours)
  elseif timestamp then
    print("h3")
    -- local comparator = (orderDirection == "ASC") and ">=" or "<="
    -- table.insert(conditions, string.format("timestamp %s ?", comparator))
    -- table.insert(bindings, timestamp)
  end
  -- Apply WHERE clause
  if #conditions > 0 then
    query = query .. " WHERE " .. table.concat(conditions, " AND ")
  end
  -- Add ordering and pagination
  if not isCount then
    query = query .. string.format(" ORDER BY timestamp %s", orderDirection)
    if limit then
      query = query .. " LIMIT ?"
      table.insert(bindings, limit)
    end
    if offset then
      query = query .. " OFFSET ?"
      table.insert(bindings, offset)
    end
  end
  -- Finalize query
  if isFinalizedQuery then
    query = query .. ";"
  end
  return query, bindings
end

-- Build specific queries (users, messages, fundings, predictions, probabilities)
function DbHelpers.buildUserQuery(params, isCount, isFinalizedQuery)
  return DbHelpers.buildQuery("SELECT * FROM Users", params, nil, isCount, "Users", isFinalizedQuery)
end

function DbHelpers.buildMessageQuery(params, isCount, isFinalizedQuery)
  return DbHelpers.buildQuery("SELECT * FROM Messages", params, nil, isCount, "Messages", isFinalizedQuery)
end

function DbHelpers.buildFundingsQuery(params, isCount, isFinalizedQuery)
  return DbHelpers.buildQuery("SELECT * FROM Fundings", params, { add = true, remove = true }, isCount, "Fundings", isFinalizedQuery)
end

function DbHelpers.buildPredictionsQuery(params, isCount, isFinalizedQuery)
  return DbHelpers.buildQuery("SELECT * FROM Predictions", params, { buy = true, sell = true }, isCount, "Predictions", isFinalizedQuery)
end

function DbHelpers.buildProbabilitiesQuery(params, isCount, isFinalizedQuery)
  -- Specific to probabilities (includes join logic)
  local query = isCount and [[
    SELECT COUNT(*) as count
    FROM Probabilities PE
    JOIN ProbabilitySets PS ON PE.set_id = PS.id
  ]] or [[
    SELECT
      PE.id AS id,
      PE.set_id AS set_id,
      PE.outcome AS outcome,
      PE.probability AS probability,
      PS.timestamp AS timestamp
    FROM Probabilities PE
    JOIN ProbabilitySets PS ON PE.set_id = PS.id
  ]]
  print("queryyy" .. query)
  -- Use shared logic
  print("params" .. json.encode(params))
  return DbHelpers.buildQuery(query, params, nil, isCount, nil, isFinalizedQuery)
end

-- Execute a count query and return the result
function DbHelpers.executeCountQuery(dbAdmin, query, bindings)
  local result = dbAdmin:safeExec(query, true, table.unpack(bindings))
  return #result
end

return DbHelpers