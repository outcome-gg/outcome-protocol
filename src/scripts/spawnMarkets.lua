local spawnMarketsInput = require('scripts.spawnMarketsInput')
local constants = require('scripts.constants')
local json = require('json')

local SpawnMarkets = {}

function SpawnMarkets:run(env, msg)
  assert(env, 'env is required')
  assert(env == "DEV" or env == "PROD", 'env must be dev or prod')
  local marketFactory = constants[env].marketFactory
  local msgIds = {}

  for _, market in ipairs(spawnMarketsInput) do
    ao.send({
      Target = marketFactory,
      Action = "Spawn-Market",
      Tags = {
        CollateralToken = market.collateralToken,
        ResolutionAgent = market.resolutionAgent,
        Question = market.question,
        Rules = market.rules,
        OutcomeSlotCount = market.outcomeSlotCount,
        CreatorFee = market.creatorFee,
        CreatorFeeTarget = market.creatorFeeTarget,
        Category = market.category,
        Subcategory = market.subcategory,
        Logo = market.logo,
      }
    })

    table.insert(msgIds, msg.Id)
  end

  return msg.reply({ Action = 'Spawn-Markets-Notice', Env = env, MessageIds = json.encode(msgIds) })
end


return SpawnMarkets