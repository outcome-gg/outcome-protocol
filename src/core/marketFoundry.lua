local ao = require('.ao')
local json = require('json')
local crypto = require('.crypto')
local sqlite3 = require('lsqlite3')

-- @dev used to monitor AOS processes
Environment = "TEST" -- DEV, TEST, PROD
Version = "0.0.1"
Name = "[" .. Environment .. "]" .. "MarketFoundry" .. "-v" .. Version

-- @dev used to reset state between integration tests
ResetState = Environment ~= "PROD"

-- @dev maintain or reset state as per environment
if not db or ResetState then db = sqlite3.open_memory() end
dbAdmin = require('dbAdmin').new(db)

-- @dev TODO: set the Conditional Tokens address using the configurator
ConditionalTokens = 'TovBwHAyP-bBwO0S4YWzvn2_5I6l6XzNE3IyN-Qpw4A'
Admin = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I'

--[[
    DB SCHEMA  
  ]]
--
QUESTIONS = [[
  CREATE TABLE IF NOT EXISTS Questions (
    id TEXT PRIMARY KEY,
    question TEXT NOT NULL,
    proposed_by TEXT NOT NULL,
    proposed_at TEXT NOT NULL
  );
]]

CONDITIONS = [[
  CREATE TABLE IF NOT EXISTS Conditions (
    id TEXT PRIMARY KEY,
    question_id TEXT NOT NULL,
    resolution_agent TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('drafted', 'prepared', 'registered')),
    drafted_by TEXT NOT NULL,
    drafted_at TEXT NOT NULL,
    prepared_at TEXT,
    registered_at TEXT
  );
]]

MARKETS = [[
  CREATE TABLE IF NOT EXISTS Markets (
    id TEXT PRIMARY KEY,
    condition_id TEXT NOT NULL,
    collateral_token TEXT NOT NULL,
    created_by TEXT NOT NULL,
    created_at TEXT
  );
]]

--[[
    Admin Functions
  ]]
--
-- @dev Accessible via the configurator, only
local function setConditionalTokensId(processId)
end

--[[
    DB Admin Functions
  ]]
--
function InitDb()
  db:exec(QUESTIONS)
  db:exec(CONDITIONS)
  db:exec(MARKETS)
  return dbAdmin:tables()
end

--[[
    Helper Functions
  ]]
--

-- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
local function getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
end

-- -- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
-- -- @param conditionId The id of the condition, i.e. set of (resolutionAgent, questionId, outcomeSlotCount).
-- -- @param collateralToken The token to be used for making predictions.
-- -- @param sender The address used to create the market.
-- local function getMarketId(conditionId, collateralToken, sender)
--   return crypto.digest.keccak256(conditionId .. collateralToken .. sender).asHex()
-- end

-- @dev creates a unique questionId using the question, processId and msg.From
local function prepareQuestion(question, proposed_by, proposed_at)
  -- generate questionId for question, processId and msg.From
  local questionId = crypto.digest.keccak256(question .. ao.id .. proposed_by).asHex()

  local numberOfQuestions = #dbAdmin:exec(
    string.format([[
      SELECT * FROM Questions
      WHERE id = "%s";
    ]], questionId)
  )

  if numberOfQuestions == 0 then
    db:exec(
      string.format([[
        INSERT INTO Questions (id, question, proposed_by, proposed_at)
        VALUES ("%s", "%s", "%s", "%s");
      ]], questionId, question, proposed_by, proposed_at)
    )
  end

  return questionId, numberOfQuestions == 0

end

local function getQuestionData(questionId)
  local questionData = dbAdmin:exec(
    string.format([[
      SELECT * FROM Questions
      WHERE id = "%s";
    ]], questionId)
  )[1]

  return questionData
end

-- @dev returns true if prepareCondition is requested, false otherwise
local function prepareCondition(questionId, resolutionAgent, drafted_by, drafted_at)
  -- @dev calls the conditional tokens process to prepare a Condition
  -- auto-registers those from admin address
  -- open to anyone to prepare a condition?

  -- Prepare the ConditionalTokens data package
  local data = {
    resolutionAgent = resolutionAgent,
    questionId = questionId,
    outcomeSlotCount = 2
  }

  -- Get the conditionId
  local conditionId = getConditionId(resolutionAgent, questionId, "2")

  -- Check condition is not already prepared
  local numberOfConditions = #dbAdmin:exec(
    string.format([[
      SELECT * FROM Conditions
      WHERE id = "%s";
    ]], conditionId)
  )

  local numberOfPreparedConditions = #dbAdmin:exec(
    string.format([[
      SELECT * FROM Conditions
      WHERE id = "%s" AND (status = "prepared" OR status = "registered");
    ]], conditionId)
  )

  -- Set the condition status to drafted if it does not exist
  if numberOfConditions == 0 then
    db:exec(
      string.format([[
        INSERT INTO Conditions (id, question_id, resolution_agent, status, drafted_by, drafted_at)
        VALUES ("%s", "%s", "%s", "%s", "%s", "%s");
      ]], conditionId, questionId, resolutionAgent, 'drafted', drafted_by, drafted_at)
    )
  end

  -- Call ConditionalTokens to Prepare Condition
  if numberOfPreparedConditions == 0 then
    ao.send({
      Target = ConditionalTokens,
      Action = 'Prepare-Condition',
      Data = json.encode(data)
    })

    return conditionId, data, true
  else
    return conditionId, data, false
  end
end

-- @dev returns true if prepareCondition is successful, false otherwise
local function prepareConditionSuccess(conditionId, preparedAt)
  -- Check if the condition is in drafted state
  local conditionsToPrepare = dbAdmin:exec(
    string.format([[
      SELECT * FROM Conditions
      WHERE id = "%s" AND status = "drafted";
    ]], conditionId)
  )

  -- Update the condition status to prepared
  if #conditionsToPrepare == 1 then
    local newStatus = conditionsToPrepare[1].drafted_by == Admin and "registered" or "prepared"
    if newStatus == "registered" then
      db:exec(
        string.format([[
          UPDATE Conditions SET status = "%s", prepared_at = "%s", registered_at = "%s"
          WHERE id = "%s"
        ]], newStatus, preparedAt, preparedAt, conditionId)
      )
    else
      db:exec(
        string.format([[
          UPDATE Conditions SET status = "%s", prepared_at = "%s"
          WHERE id = "%s"
        ]], newStatus, preparedAt, conditionId)
      )
    end
  end

  -- Get the condition data
  local conditionData = dbAdmin:exec(
    string.format([[
      SELECT * FROM Conditions
      WHERE id = "%s";
    ]], conditionId)
  )[1]

  return conditionData, #conditionsToPrepare == 1

end

local function getConditionData(conditionId)
  local conditionData = dbAdmin:exec(
    string.format([[
      SELECT * FROM Conditions
      WHERE id = "%s";
    ]], conditionId)
  )[1]

  return conditionData
end

-- @dev should only be callable by the admin address
local function registerCondition(conditionId, registeredAt)
  db:exec(
    string.format([[
      UPDATE Conditions SET status = "registered", registered_at = "%s"
      WHERE id = "%s"
    ]], registeredAt, conditionId)
  )

  return getConditionData(conditionId)
end

local function createMarket() --questionId, collateralToken, resolutionAgent)
  -- @dev open to anyone, collateralToken must be approved
  local processId = ao.spawn(ao.env.Module.Id, {
    ["Memory-Limit"] = "500-mb",
    ["Compute-Limit"] = "900000000000000000"
  }).receive().Process
  return processId
end


--[[
     Handlers for each incoming Action as defined by the Protocol DB Specification
   ]]
--

--[[
     DB  
   ]]
--

--[[
     Init  
   ]]
--
Handlers.add("DB.Init", Handlers.utils.hasMatchingTag('Action', 'DB-Init'), function (msg)
  local tables = InitDb()
  Send({Target = msg.From, Action = "DB-Inited", Data = json.encode(tables)})
end)

--[[
     Prepare Question
   ]]
--
Handlers.add('prepareQuestion', Handlers.utils.hasMatchingTag('Action', 'Prepare-Question'), function(msg)
  assert(msg.Tags.Question, 'Question is required!')

  local questionId, success = prepareQuestion(msg.Tags.Question, msg.From, msg.Timestamp)

  if success then
    ao.send({
      Target = msg.From,
      Action = 'Question-Prepared',
      QuestionId = questionId,
      Data = msg.Tags.Question
    })
  else
    ao.send({
      Target = msg.From,
      Action = 'Question-Error',
      QuestionId = questionId,
      ['Message-Id'] = msg.Id,
      Error = 'Question already exists!',
      Data = msg.Tags.Question
    })
  end
end)

--[[
     Get Question
   ]]
--
Handlers.add('getQuestion', Handlers.utils.hasMatchingTag('Action', 'Get-Question'), function(msg)
  assert(msg.Tags.QuestionId, 'QuestionId is required!')
  local questionData = getQuestionData(msg.Tags.QuestionId)
  ao.send({
    Target = msg.From,
    Action = 'Question-Received',
    QuestionId = msg.Tags.QuestionId,
    Data = questionData
  })
end)

--[[
     Prepare Condition
   ]]
--
Handlers.add('prepareCondition', Handlers.utils.hasMatchingTag('Action', 'Prepare-Condition'), function(msg)
  assert(msg.Tags.QuestionId, 'QuestionId is required!')
  assert(msg.Tags.ResolutionAgent, 'ResolutionAgent is required!')

  local conditionId, conditionData, success = prepareCondition(msg.Tags.QuestionId, msg.Tags.ResolutionAgent, msg.From, msg.Timestamp)

  if success then
    ao.send({
      Target = msg.From,
      Action = 'Condition-Drafted',
      ConditionId = conditionId,
      Data = json.encode(conditionData)
    })
  else
    ao.send({
      Target = msg.From,
      Action = 'Condition-Draft-Error',
      ConditionId = conditionId,
      ['Message-Id'] = msg.Id,
      Error = 'Condition already prepared!',
      Data = json.encode(conditionData)
    })
  end
end)

--[[
     Prepare Condition Success
   ]]
--
local function isPrepareConditionSuccess(msg)
  if msg.From == ConditionalTokens and msg.Action == "Condition-Preparation-Notice" then
    return true
  else
    return false
  end
end

Handlers.add('prepareConditionSuccess', isPrepareConditionSuccess, function(msg)
  assert(msg.Tags.QuestionId, 'QuestionId is required!')
  assert(msg.Tags.ConditionId, 'ConditionId is required!')
  assert(msg.Tags.ResolutionAgent, 'ResolutionAgent is required!')
  assert(msg.Tags.OutcomeSlotCount, 'OutcomeSlotCount is required!')

  local conditionData, success = prepareConditionSuccess(msg.Tags.ConditionId, msg.Timestamp)

  if success then
    ao.send({
      Target = conditionData.drafted_by,
      Action = 'Condition-Prepared',
      ConditionId = msg.Tags.ConditionId,
      Data = json.encode(conditionData)
    })
  else
    ao.send({
      Target = conditionData.drafted_by,
      Action = 'Condition-Draft-Error',
      ConditionId = msg.Tags.ConditionId,
      ['Message-Id'] = msg.Id,
      Error = 'Condition already prepared!',
      Data = json.encode(conditionData)
    })
  end
end)

--[[
     Get Condition
   ]]
--
Handlers.add('getCondition', Handlers.utils.hasMatchingTag('Action', 'Get-Condition'), function(msg)
  assert(msg.Tags.ConditionId, 'ConditionId is required!')
  local conditionData = getConditionData(msg.Tags.ConditionId)
  ao.send({
    Target = msg.From,
    Action = 'Condition-Received',
    ConditionId = msg.Tags.ConditionId,
    Data = json.encode(conditionData)
  })
end)

--[[
     Register Condition
   ]]
--
Handlers.add('registerCondition', Handlers.utils.hasMatchingTag('Action', 'Register-Condition'), function(msg)
  assert(msg.From == Admin, 'Sender must be admin!')
  assert(msg.Tags.ConditionId, 'ConditionId is required!')
  local conditionData = registerCondition(msg.Tags.ConditionId, msg.Timestamp)
  ao.send({
    Target = msg.From,
    Action = 'Condition-Registered',
    ConditionId = msg.Tags.ConditionId,
    Data = json.encode(conditionData)
  })
end)

--[[
     Create Market
   ]]
--
--@dev TODO: decide if this should be open to anyone
--@dev TODO: decide if a minimum collateral amount should be required
Handlers.add('createMarket', Handlers.utils.hasMatchingTag('Action', 'Create-Market'), function(msg)
  assert(msg.Tags.ConditionId, 'ConditionId is required!')
  assert(msg.Tags.CollateralToken, 'CollateralToken is required!')

  -- @dev TODO: add market code to new process
  local marketId = createMarket()
  local numberOfMarkets = #dbAdmin:exec(
    string.format([[
      SELECT * FROM Markets
      WHERE id = "%s";
    ]], marketId)
  )

  if marketId ~= "" and numberOfMarkets == 0 then
    db:exec(
      string.format([[
        INSERT INTO Markets (id, condition_id, collateral_token, created_by, created_at)
        VALUES ("%s", "%s", "%s", "%s", "%s");
      ]], marketId, msg.Tags.ConditionId, msg.Tags.CollateralToken, msg.From, msg.Timestamp)
    )
  end

  ao.send({
    Target = msg.From,
    Action = 'Market-Created',
    MarketId = marketId,
    Data = marketId
    -- ['Message-Id'] = msg.Id,
    -- Process = id
  })
end)


return "ok"