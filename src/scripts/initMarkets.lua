local constants = require('scripts.constants')

local InitMarkets = {}

function InitMarkets:run(env, msg)
  assert(env, 'env is required')
  assert(env == "DEV" or env == "PROD", 'env must be dev or prod')
  local marketFactory = constants[env].marketFactory

  ao.send({
    Target = marketFactory,
    Action = "Init-Market",
  })

  return msg.reply({ Action = 'Init-Markets-Script-Notice', Env = env, MessageIds = msg.Id })
end


return InitMarkets