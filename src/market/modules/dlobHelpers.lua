local crypto = require('.crypto')
local bint = require('.bint')(256)

local DLOBHelpers = {}

function DLOBHelpers.assertMaxDp(value, maxDp)
  local factor = 10 ^ maxDp
  local roundedValue = math.floor(value * factor + 0.5) / factor
  assert(value == roundedValue, "Value has more than " .. maxDp .. " decimal places")
  return tostring(math.floor(value * factor))
end

function DLOBHelpers.validateUserAssetBalance(from, orders)
  local totalFundQuantity = 0
  local totalShareQuantity = 0

  for i = 1, #orders do
    if orders[i].isBid then
      totalFundQuantity = totalFundQuantity + orders[i].size * orders[i].price
    else
      totalShareQuantity = totalShareQuantity + orders[i].size
    end
  end

  local availableFunds = tonumber(BalanceManager:getAvailableFunds(from))
  local availableShares = tonumber(BalanceManager:getAvailableShares(from))

  return totalFundQuantity <= availableFunds and totalShareQuantity <= availableShares
end

return DLOBHelpers
