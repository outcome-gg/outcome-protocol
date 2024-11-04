local crypto = require('.crypto')
local bint = require('.bint')(256)
local json = require('json')

local ConditionalTokensHelpers = {}

-- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
-- @param ResolutionAgent The process assigned to report the result for the prepared condition.
-- @param QuestionId An identifier for the question to be answered by the resolutionAgent.
-- @param OutcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
function ConditionalTokensHelpers.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
end

-- @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
-- Performs elementwise addtion for communicative ids.
-- @param parentCollectionId Collection ID of the parent outcome collection, or "" if there's no parent.
-- @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
-- @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
function ConditionalTokensHelpers.getCollectionId(parentCollectionId, conditionId, indexSet)
  -- Hash parentCollectionId & (conditionId, indexSet) separately
  local h1 = parentCollectionId
  local h2 = crypto.digest.keccak256(conditionId .. indexSet).asHex()

  if h1 == "" then
    return h2
  end

  -- Convert to arrays
  local x1 = crypto.utils.array.fromHex(h1)
  local x2 = crypto.utils.array.fromHex(h2)

  -- Variable to store the concatenated hex string
  local result = ""

  -- Iterate over the elements of both arrays
  local maxLength = math.max(#x1, #x2)
  for i = 1, maxLength do
    -- Get elements from arrays, default to 0 if index exceeds array length
    local elem1 = x1[i] or 0
    local elem2 = x2[i] or 0
    -- Perform addition
    local sum = bint(elem1) + bint(elem2)
    -- Convert the result to a hex string and concatenate
    result = result .. sum:tobase(16)
  end
  return result
end

-- @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the Semi-Fungible ID for this contract.
-- @param collateralToken Collateral token which backs the position.
-- @param collectionId ID of the outcome collection associated with this position.
function ConditionalTokensHelpers.getPositionId(collateralToken, collectionId)
  return crypto.digest.keccak256(collateralToken .. collectionId).asHex()
end

function ConditionalTokensHelpers:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout, parentCollectionId, conditionId, indexSets)
  local takeFee = (totalPayout * self.takeFeePercentage) / self.ONE
  local totalPayoutMinusFee = totalPayout - takeFee

  -- Send Take Fee to Take Fee Target
  ao.send({
    Target = collateralToken,
    Action = "Transfer",
    Recipient = self.takeFeeTarget,
    Quantity = tostring(takeFee),
  })

  -- Return Total Payout minus Take Fee
  ao.send({
    Target = collateralToken,
    Action = "Transfer",
    Recipient = from,
    Quantity = tostring(totalPayoutMinusFee),
    ['X-Action'] = "Redeem-Positions-Completion",
    ['X-CollateralToken'] = collateralToken,
    ['X-ParentCollectionId'] = parentCollectionId,
    ['X-ConditionId'] = conditionId,
    ['X-IndexSets'] = json.encode(indexSets),
    ['X-TotalPayout'] = json.encode(totalPayout)
  })
end

return ConditionalTokensHelpers
