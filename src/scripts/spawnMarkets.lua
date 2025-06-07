local spawnMarketsInput = require('scripts.spawnMarketsInput')
local constants = require('scripts.constants')
local json = require('json')

local SpawnMarkets = {}

function SpawnMarkets:run(env, msg)
  assert(env, 'env is required')
  assert(env == "DEV" or env == "PROD", 'env must be dev or prod')
  local marketFactory = constants[env].marketFactory
  local dataIndex = constants[env].dataIndex
  local chatroom = constants[env].chatroom
  local collateralToken = constants[env].collateralToken
  local msgIds = {}

  for _, market in ipairs(spawnMarketsInput) do
    ao.send({
      Target = marketFactory,
      Action = "Spawn-Market",
      Tags = {
        DataIndex = dataIndex,
        Chatroom = chatroom,
        CollateralToken = collateralToken,
        ResolutionAgent = market.resolutionAgent,
        Question = market.question,
        Rules = market.rules,
        OutcomeSlotCount = market.outcomeSlotCount,
        CreatorFee = market.creatorFee,
        CreatorFeeTarget = market.creatorFeeTarget,
        Category = market.category,
        Subcategory = market.subcategory,
        Logo = market.logo,
        StartTime = tostring(os.time()),
        EndTime = tostring(os.time() + 30 * 24 * 60 * 60 * 1000), -- 30 days from now
      }
    })

    table.insert(msgIds, msg.Id)
  end

  return msg.reply({ Action = 'Spawn-Markets-Script-Notice', Env = env, MessageIds = json.encode(msgIds) })
end

function SpawnMarkets:runViaAOS(env)
  assert(env, 'env is required')
  assert(env == "DEV" or env == "PROD", 'env must be dev or prod')
  local marketFactory = constants[env].marketFactory
  local dataIndex = constants[env].dataIndex
  local chatroom = constants[env].chatroom
  local collateralToken = constants[env].collateralToken
  local msgIds = {}

  for _, market in ipairs(spawnMarketsInput) do
    print("market..")
    ao.send({
      Target = marketFactory,
      Action = "Spawn-Market",
      Tags = {
        DataIndex = dataIndex,
        Chatroom = chatroom,
        CollateralToken = collateralToken,
        ResolutionAgent = market.resolutionAgent,
        Question = market.question,
        Rules = market.rules,
        OutcomeSlotCount = market.outcomeSlotCount,
        CreatorFee = market.creatorFee,
        CreatorFeeTarget = market.creatorFeeTarget,
        Category = market.category,
        Subcategory = market.subcategory,
        Logo = market.logo,
        StartTime = tostring(os.time()),
        EndTime = tostring(os.time() + 30 * 24 * 60 * 60 * 1000), -- 30 days from now
      }
    })
    print("market done..")

    -- table.insert(msgIds, msg.Id)
  end

  return json.encode(msgIds)
end

return SpawnMarkets