local crypto = require('.crypto')
local bint = require('.bint')(256)

local AMMHelpers = {}

-- Utility function: CeilDiv
function AMMHelpers.ceildiv(x, y)
  if x > 0 then
    return math.floor((x - 1) / y) + 1
  end
  return math.floor(x / y)
end

-- Generate basic partition
--@dev hardcoded to 2 outcomesSlotCount
function AMMHelpers.generateBasicPartition()
  local partition = {}
  for i = 0, 1 do
    table.insert(partition, 1 << i)
  end
  return partition
end

-- Split positions through all conditions
--@dev hardcoded to 2 outcomesSlotCount
function AMMHelpers:splitPosition(from, outcomeIndex, quantity)
  -- local partition = self.generateBasicPartition()

  -- ao.send({
  --   Target = CollateralToken,
  --   Action = "Transfer",
  --   Quantity = tostring(quantity),
  --   Recipient = ConditionalTokens,
  --   ['X-Action'] = "Create-Position",
  --   ['X-ParentCollectionId'] = "",
  --   ['X-ConditionId'] = ConditionId,
  --   ['X-Partition'] = json.encode(partition),
  --   ['X-OutcomeIndex'] = tostring(outcomeIndex),
  --   ['X-Sender'] = from
  -- })
end

-- Merge positions through all conditions
function AMMHelpers:mergePositionsThroughAllConditions(amount)
  -- for i = 1, #ConditionIds do
  --   local partition = generateBasicPartition(OutcomeSlotCounts[i])
  --   for j = 1, #CollectionIds[i] do
  --     ConditionalTokens.mergePositions(
  --       CollateralToken,
  --       CollectionIds[i][j],
  --       ConditionIds[i],
  --       partition,
  --       amount
  --     )
  --   end
  -- end
end

--[[
    Helper Functions
  ]]
--
-- local function recordCollectionIdsForAllOutcomes(conditionId, i, j)
--   ao.send({
--     Target = ConditionalTokens,
--     Action = "Get-Collection-Id",
--     ParentCollectionId = "",
--     ConditionId = conditionId,
--     IndexSet = j
--   }).onReply(
--     function(m)
--       local collectionId = m.CollectionId
--       CollectionIds[i][j] = collectionId
--       PositionIds[i][j] = crypto.digest.keccak256(CollateralToken .. collectionId).asHex()
--     end
--   )
-- end

-- local function recordOutcomeSlotCounts(conditionId, i)
--   ao.send({ Target = ConditionalTokens, Action = "Get-Outcome-Slot-Count", ConditionId = conditionId}).onReply(
--     function(m)
--       local outcomeSlotCount = m.OutcomeSlotCount
--       OutcomeSlotCounts[i] = outcomeSlotCount

--       -- Prepare tables: CollectionIds and PositionIds
--       for j = 1, outcomeSlotCount do
--         CollectionIds[i][j] = ""
--         PositionIds[i][j] = ""
--       end

--       -- Populate CollectionIds and PositionIds
--       for j = 1, outcomeSlotCount do
--         recordCollectionIdsForAllOutcomes(conditionId, i, j)
--       end
--     end
--   )
-- end

-- local function recordCollectionIdsForAllConditions(conditionId, i)
--   ao.send({
--     Target = ConditionalTokens,
--     Action = "Get-Collection-Id",
--     ParentCollectionId = "",
--     ConditionId = conditionId,
--     IndexSet = indexSet
--   }).onReply(
--     function(m)
--       local collectionId = m.CollectionId
--       CollectionIds[i] = collectionId
--       PositionIds[i] = crypto.digest.keccak256(CollateralToken .. collectionId).asHex()
--     end
--   )
-- end

return AMMHelpers