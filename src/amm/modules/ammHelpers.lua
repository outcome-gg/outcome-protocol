local crypto = require('.crypto')
local bint = require('.bint')(256)
local json = require('json')
local ao = require('.ao')

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

function AMMHelpers:validateAddFunding(from, quantity, distribution)
  local error = false
  local errorMessage = ''

  -- Ensure distribution
  if not distribution then
    error = true
    errorMessage = 'X-Distribution is required!'
  elseif not error then
    if bint.iszero(bint(self.tokens.totalSupply)) then
      -- Ensure distribution is set across all position ids
      if #distribution ~= #self.positionIds then
        error = true
        errorMessage = "Distribution length mismatch"
      end
    else
      -- Ensure distribution set only for initial funding
      if bint.__lt(0, #distribution) then
        error = true
        errorMessage = "Cannot specify distribution after initial funding"
      end
    end
  end
  if error then
    -- Return funds and assert error
    ao.send({
      Target = self.collateralToken,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Add-Funding Error: ' .. errorMessage
    })
  end
  return not error
end

function AMMHelpers:validateRemoveFunding(from, quantity)
  local error = false
  local balance = self.tokens.balances[from] or '0'
  if not bint.__lt(bint(quantity), bint(balance)) then
    error = true
    ao.send({
      Target = ao.id,
      Action = 'Transfer',
      Recipient = from,
      Quantity = quantity,
      Error = 'Remove-Funding Error: Quantity must be less than balance!'
    })
  end
  return not error
end

function AMMHelpers:createPosition(from, quantity, outcomeIndex, outcomeTokensToBuy, lpTokensMintAmount, sendBackAmounts)
  ao.send({
    Target = self.collateralToken,
    Action = "Transfer",
    Quantity = quantity,
    Recipient = self.conditionalTokens,
    ['X-Action'] = "Create-Position",
    ['X-ParentCollectionId'] = "",
    ['X-ConditionId'] = self.conditionId,
    ['X-Partition'] = json.encode(self.generateBasicPartition()),
    ['X-OutcomeIndex'] = tostring(outcomeIndex),
    ['X-OutcomeTokensToBuy'] = tostring(outcomeTokensToBuy),
    ['X-LPTokensMintAmount'] = tostring(lpTokensMintAmount),
    ['X-SendBackAmounts'] = json.encode(sendBackAmounts),
    ['X-Sender'] = from
  })
end

function AMMHelpers:mergePositions(from, returnAmount, returnAmountPlusFees, outcomeIndex, outcomeTokensToSell)
  ao.send({
    Target = self.conditionalTokens,
    Action = "Merge-Positions",
    ['X-Sender'] = from,
    ['X-ReturnAmount'] = returnAmount,
    ['X-OutcomeIndex'] = tostring(outcomeIndex),
    ['X-OutcomeTokensToSell'] = tostring(outcomeTokensToSell),
    Data = json.encode({
      collateralToken = self.collateralToken,
      parentCollectionId = '',
      conditionId = self.conditionId,
      partition = self.generateBasicPartition(),
      quantity = returnAmountPlusFees
    })
  })
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