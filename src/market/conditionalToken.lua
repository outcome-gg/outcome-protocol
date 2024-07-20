-- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
local ao = require('ao')
local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")
local crypto = require('.crypto')

_DATA_INDEX = ''

--[[
    NOTICES
  ]]
--

--[[
    Semi-Fungible Token Notices
  ]]
--

-- event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

-- event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);


local function mintSingleNotice(recipient, id, quantity)
  ao.send({
    Target = recipient,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Mint-Single-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  })
end

local function mintBatchNotice(recipient, ids, quantities)
  ao.send({
    Target = recipient,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Action = 'Mint-Batch-Notice',
    Data = "Successfully minted batch"
  })
end

local function burnSingleNotice(holder, id, quantity)
  ao.send({
    Target = holder,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Burn-Single-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  })
end

local function burnBatchNotice(holder, ids, quantities)
  ao.send({
    Target = holder,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Action = 'Burn-Batch-Notice',
    Data = "Successfully burned batch"
  })
end

local function creditSingleNotice(sender, recipient, id, quantity)
  -- Send Debit-Notice to the Sender
  ao.send({
    Target = sender,
    Action = 'Debit-Single-Notice',
    Recipient = recipient,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
  })
  -- Send Credit-Notice to the Recipient
  ao.send({
    Target = recipient,
    Action = 'Credit-Single-Notice',
    Sender = sender,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You received " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " from " .. Colors.green .. sender .. Colors.reset
  })
end

local function creditBatchNotice(sender, recipient, ids, quantities)
  -- Send Debit-Notice to the Sender
  ao.send({
    Target = sender,
    Action = 'Debit-Batch-Notice',
    Recipient = recipient,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You transferred batch to " .. Colors.green .. recipient .. Colors.reset
  })
  -- Send Credit-Notice to the Recipient
  ao.send({
    Target = recipient,
    Action = 'Credit-Batch-Notice',
    Sender = sender,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You received batch from " .. Colors.green .. sender .. Colors.reset
  })
end

--[[
    Conditional Token Notices
  ]]
--

-- @dev Emitted upon the successful preparation of a condition.
-- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
local function conditionPreparationNotice(conditionId, resolutionAgent, questionId, outcomesSlotCount)
  ao.send({
    Target = _DATA_INDEX,
    Action = "Condition-Preparation-Notice",
    Process = ao.id,
    ConditionId = conditionId,
    ResolutionAgent = resolutionAgent,
    QuestionId = questionId,
    OutcomeSlotCount = outcomesSlotCount
  })
end

local function conditionResolutionNotice(conditionId, resolutionAgent, questionId, outcomesSlotCount, payoutNumerators)
  ao.send({
    Target = _DATA_INDEX,
    Action = "Condition-Resolution-Notice",
    Process = ao.id,
    ConditionId = conditionId,
    ResolutionAgent = resolutionAgent,
    QuestionId = questionId,
    OutcomeSlotCount = outcomesSlotCount,
    PayoutNumerators = payoutNumerators
  })
end

-- @dev Emitted when a position is successfully split.
local function positionSplitNotice(stakeholder, collateralToken, parentCollectionId, conditionId, partition, quantity)
  ao.send({
    Target = _DATA_INDEX,
    Action = "Position-Split-Notice",
    Process = ao.id,
    Stakeholder = stakeholder,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    Partition = partition,
    Quantity = quantity
  })
end

-- @dev Emitted when positions are successfully merged.
local function positionsMergeNotice(stakeholder, collateralToken, parentCollectionId, conditionId, partition, amount)
  ao.send({
    Target = _DATA_INDEX,
    Action = "Positions-Merge-Notice",
    Process = ao.id,
    Stakeholder = stakeholder,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    Partition = partition,
    Amount = amount
  })
end

local function payoutRedemptionNotice(redeemer, collateralToken, parentCollectionId, conditionId, indexSets, payout)
  ao.send({
    Target = _DATA_INDEX,
    Action = "Payout-Redemption-Notice",
    Process = ao.id,
    Redeemer = redeemer,
    CollateralToken = collateralToken,
    ParentCollectionId = parentCollectionId,
    ConditionId = conditionId,
    IndexSets = indexSets,
    Payout = payout
  })
end

--[[
    VARIABLES
  ]]
--
if not BalancesOf then BalancesOf = {} end

if Name ~= 'Conditional Framework Token' then Name = 'Conditional Framework Token' end

if Ticker ~= 'CFT' then Ticker = 'CFT' end

if Denomination ~= 12 then Denomination = 12 end

-- @dev Mapping key is an condition ID. Value represents numerators of the payout vector associated with the condition. 
-- This array is initialized with a length equal to the outcome slot count. E.g. Condition with 3 outcomes [A, B, C] and two of those correct [0.5, 0.5, 0]. 
-- @dev Note from source: In Ethereum there are no decimal values, so here, 0.5 is represented by fractions like 1/2 == 0.5. That's why we need numerator and denominator values. Payout numerators are also used as a check of initialization. If the numerators array is empty (has length zero), the condition was not created/prepared. See getOutcomeSlotCount.
if not PayoutNumerators then PayoutNumerators = {} end

-- @dev Denominator is also used for checking if the condition has been resolved. If the denominator is non-zero, then the condition has been resolved.
if not PayoutDenominator then PayoutDenominator = {} end

if not Logo then Logo = '' end

--[[
    FUNCTIONS
  ]]
--

--[[
    Helper Functions
  ]]
--

-- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
-- @param ResolutionAgent The process assigned to report the result for the prepared condition.
-- @param QuestionId An identifier for the question to be answered by the resolutionAgent.
-- @param OutcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
local function getConditionId(resolutionAgent, questionId, outcomeSlotCount)
  return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
end

-- local function getCollectionId2(parentCollectionId, conditionId, indexSet)
--   -- Hash parentCollectionId & (conditionId, indexSet) separately
--   local h1 = parentCollectionId
--   local h2 = crypto.digest.keccak256(conditionId .. indexSet).asHex()

--   if h1 == "" then
--     return h1, h2, h2
--   end

--   -- Convert to arrays
--   local x1 = crypto.utils.array.fromHex(h1)
--   local x2 = crypto.utils.array.fromHex(h2)

--   -- Variable to store the concatenated hex string
--   local result = ""

--   -- Iterate over the elements of both arrays
--   local maxLength = math.max(#x1, #x2)
--   for i = 1, maxLength do
--       -- Get elements from arrays, default to 0 if index exceeds array length
--       local elem1 = x1[i] or 0
--       local elem2 = x2[i] or 0

--       -- Convert elements to bint
--       local bint1 = bint(elem1)
--       local bint2 = bint(elem2)

--       -- Perform addition
--       local sum = bint1 + bint2

--       -- Convert the result to a hex string and concatenate
--       result = result .. sum:tobase(16)
--   end

--   return h1, h2, result
-- end

-- @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
-- Performs elementwise addtion for communicative ids.
-- @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
-- @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
-- @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
local function getCollectionId(parentCollectionId, conditionId, indexSet)
  -- Hash parentCollectionId & (conditionId, indexSet) separately
  -- local h1 = crypto.digest.keccak256(parentCollectionId).asHex()
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

      -- Convert elements to bint
      local bint1 = bint(elem1)
      local bint2 = bint(elem2)

      -- Perform addition
      local sum = bint1 + bint2

      -- Convert the result to a hex string and concatenate
      result = result .. sum:tobase(16)
  end

  return result
end


-- @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
-- @param collateralToken Collateral token which backs the position.
-- @param collectionId ID of the outcome collection associated with this position.
local function getPositionId(collateralToken, collectionId)
  return crypto.digest.keccak256(collateralToken .. collectionId).asHex()
end

--[[
    Semi-Fungible Token Functions
  ]]
--

-- @dev Internal function to mint an amount of a token with the given ID
-- @param to The address that will own the minted token
-- @param id ID of the token to be minted
-- @param quantity Quantity of the token to be minted
local function mint(to, id, quantity)
  assert(type(quantity) == 'string', 'Quantity is required!')
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  if not BalancesOf[id] then BalancesOf[id] = {} end
  if not BalancesOf[id][to] then BalancesOf[id][to] = "0" end
  BalancesOf[id][to] = tostring(bint.__add(BalancesOf[id][to], quantity))
  -- Send notice
  mintSingleNotice(to, id, quantity)
end

-- @dev Internal fuction to batch mint amounts of tokens with the given IDs
-- @param to The address that will own the minted token
-- @param ids IDs of the tokens to be minted
-- @param values Amounts of the tokens to be minted
local function batchMint(to, ids, quantities)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')

  for i = 1, #ids do
    if not BalancesOf[ids[i]] then BalancesOf[ids[i]] = {} end
    if not BalancesOf[ids[i]][to] then BalancesOf[ids[i]][to] = "0" end
    BalancesOf[ids[i]][to] = tostring(bint.__add(BalancesOf[ids[i]][to], quantities[i]))
  end
  -- Send notice
  mintBatchNotice(to, ids, quantities)
end

-- @dev Internal function to burn an amount of a token with the given ID
-- @param from The address that will burn the token
-- @param id ID of the token to be burned
-- @param quantity Quantity of the token to be burned
local function burn(from, id, quantity)
  assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  assert(BalancesOf[id], 'Id must exist! ' ..  id)
  assert(BalancesOf[id][from], 'User must hold token!')
  assert(bint.__le(quantity, BalancesOf[id][from]), 'User must have sufficient tokens! ' .. id)
  -- Burn tokens
  BalancesOf[id][from] = tostring(bint.__sub(BalancesOf[id][from], quantity))
  -- Send notice
  burnSingleNotice(from, id, quantity)
end

-- @dev Internal fuction to batch burn amounts of tokens with the given IDs
-- @param from The address that will burn the tokens
-- @param ids IDs of the tokens to be burned
-- @param quantity Quantities of the tokens to be burned
local function batchBurn(from, ids, quantities)
  assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  -- Validate batch input
  for i = 1, #ids do
    assert(bint.__lt(0, quantities[i]), 'Quantity must be greater than zero!')
    assert( BalancesOf[ids[i]], 'Id must exist!')
    assert(BalancesOf[ids[i]][from], 'User must hold token!')
    assert(bint.__le(quantities[i], BalancesOf[ids[i]][from]), 'User must have sufficient tokens!')
  end
  -- Burn batch
  for i = 1, #ids do
    BalancesOf[ids[i]][from] = tostring(bint.__sub(BalancesOf[ids[i]][from], quantities[i]))
  end
  -- Send notice
  burnBatchNotice(from, ids, quantities)
end

--[[
    Conditional Token Functions
  ]]
--

-- @dev This function prepares a condition by initializing a payout vector associated with the condition.
-- @param resolutionAgent The process assigned to report the result for the prepared condition.
-- @param questionId An identifier for the question to be answered by the resolutionAgent.
-- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
local function prepareCondition(msg)
  local data = json.decode(msg.Data)
  assert(data.resolutionAgent, "resolutionAgent is required!" )
  assert(data.questionId, "questionId is required!")
  assert(data.outcomeSlotCount, "outcomeSlotCount is required!")
  assert(type(data.outcomeSlotCount) == 'number', "outcomeSlotCount must be a number!")
  -- Limit of 256 because we use a partition array that is a number of 256 bits.
  assert(data.outcomeSlotCount <= 256, "too many outcome slots")
  assert(data.outcomeSlotCount > 1, "there should be more than one outcome slot")
  -- Contruct conditionId from resolutionAgent, questionId, and outcomeSlotCount
  local conditionId = getConditionId(data.resolutionAgent, data.questionId, tostring(data.outcomeSlotCount))
  assert(PayoutNumerators[conditionId] == nil, "condition already prepared")
  -- Initialize the payout vector associated with the condition.
  PayoutNumerators[conditionId] = {}
  for _ = 1, data.outcomeSlotCount do
    table.insert(PayoutNumerators[conditionId], 0)
  end
  -- Initialize the denominator to zero to indicate that the condition has not been resolved.
  PayoutDenominator[conditionId] = 0
  -- Send the condition preparation notice.
  conditionPreparationNotice(conditionId, data.resolutionAgent, data.questionId, data.outcomeSlotCount)
end

-- @dev Called by the resolutionAgent for reporting results of conditions. Will set the payout vector for the condition with the ID `keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount))`, 
-- where ResolutionAgent is the message sender, QuestionId is one of the parameters of this function, and OutcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
-- @param QuestionId The question ID the oracle is answering for
-- @param Payouts The oracle's answer
local function reportPayouts(msg)
  local data = json.decode(msg.Data)
  assert(data.questionId, "QuestionId is required!")
  assert(data.payouts, "Payouts is required!")
  -- IMPORTANT, the payouts length accuracy is enforced because outcomeSlotCount is part of the hash.
  local outcomeSlotCount = #data.payouts
  assert(outcomeSlotCount > 1, "there should be more than one outcome slot")
  -- IMPORTANT, the resolutionAgent is enforced to be the sender because it's part of the hash.
  local conditionId = getConditionId(msg.From, data.questionId, tostring(outcomeSlotCount))
  assert(#PayoutNumerators[conditionId] == outcomeSlotCount, "condition not prepared or found")
  assert(PayoutDenominator[conditionId] == 0, "payout denominator already set")
  -- Set the payout vector for the condition.
  local den = 0
  for i = 1, outcomeSlotCount do
    local num = data.payouts[i]
    den = den + num
    assert(PayoutNumerators[conditionId][i] == 0, "payout numerator already set")
    PayoutNumerators[conditionId][i] = num
  end
  assert(den > 0, "payout is all zeroes")
  PayoutDenominator[conditionId] = den
  -- Send the condition resolution notice.
  conditionResolutionNotice(conditionId, msg.From, data.questionId, outcomeSlotCount, PayoutNumerators[conditionId])
end

-- @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. 
-- Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of semi-fungible tokens. 
-- Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert.
-- The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
-- @param from The initiator of the original Split-Position / Create-Position action message.
-- @param collateralToken The address of the positions' backing collateral token.
-- @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
-- @param conditionId The ID of the condition to split on.
-- @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
-- @param quantity The quantity of collateral or stake to split.
-- @param isCreate True if the position is being split from the collateralToken.
local function splitPosition(from, collateralToken, parentCollectionId, conditionId, partition, quantity, isCreate)
  assert(#partition > 1, "got empty or singleton partition")
  assert(PayoutNumerators[conditionId] and #PayoutNumerators[conditionId] > 0, "condition not prepared yet")

  local outcomeSlotCount = #PayoutNumerators[conditionId]

  -- For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
  local fullIndexSet = (1 << outcomeSlotCount) - 1

  -- freeIndexSet starts as the full collection
  local freeIndexSet = fullIndexSet

  -- This loop checks that all condition sets are disjoint (the same outcome is not part of more than 1 set)
  local positionIds = {}
  local quantities = {}
  for i = 1, #partition do
    local indexSet = partition[i]
    assert(indexSet > 0 and indexSet < fullIndexSet, "got invalid index set " .. "partition: " .. json.encode(partition) .. tostring(indexSet) .. " " .. tostring(fullIndexSet))
    assert((indexSet & freeIndexSet) == indexSet, "partition not disjoint")
    freeIndexSet = freeIndexSet ~ indexSet
    positionIds[i] = getPositionId(collateralToken, getCollectionId(parentCollectionId, conditionId, indexSet))
    quantities[i] = quantity
  end

  if freeIndexSet == 0 then
    -- Partitioning the full set of outcomes for the condition in this branch
    if parentCollectionId == "" then
      assert(isCreate, "could not receive collateral tokens")
    else
      burn(from, getPositionId(collateralToken, parentCollectionId), quantity)
    end
  else
    -- assert(false, "foo " .. tostring(fullIndexSet ~ freeIndexSet))
    -- Partitioning a subset of outcomes for the condition in this branch.
    -- For example, for a condition with three outcomes A, B, and C, this branch
    -- allows the splitting of a position $:(A|C) to positions $:(A) and $:(C).
    burn(from, getPositionId(collateralToken, parentCollectionId), quantity)
    -- burn(from, getPositionId(collateralToken, getCollectionId(parentCollectionId, conditionId, fullIndexSet ~ freeIndexSet)), quantity)
  end

  -- if parentCollectionId == "19ce26723d91b943bb1649d11810919a1648f1711509f15d134171171dcc9cd1e31857711d9d13cbc" then
  --   assert(false, "crypto.digest.keccak256(conditionId .. tostring(7)).asHex() " .. crypto.digest.keccak256(conditionId .. tostring(7)).asHex() .. " crypto.digest.keccak256(parentCollectionId).asHex() " .. crypto.digest.keccak256(parentCollectionId).asHex() .. " collateralToken " .. collateralToken)
  -- elseif parentCollectionId == "15212bfeb9fd1649479dbf0a51a3eeed9517e1bcb19c1141c8111112cbac1de1145514ff819dbf" then
  --   assert(false, "crypto.digest.keccak256(conditionId .. tostring(1)).asHex() " .. crypto.digest.keccak256(conditionId .. tostring(1)).asHex() .. " crypto.digest.keccak256(parentCollectionId).asHex() " .. crypto.digest.keccak256(parentCollectionId).asHex() .. " collateralToken " .. collateralToken)
  -- end

  batchMint(from, positionIds, quantities)

  positionSplitNotice(from, collateralToken, parentCollectionId, conditionId, partition, quantity)
end

-- /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
--   /// @param collateralToken The address of the positions' backing collateral token.
--   /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
--   /// @param conditionId The ID of the condition to split on.
--   /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
--   /// @param amount The amount of collateral or stake to split.
--   function splitPosition(
--       IERC20 collateralToken,
--       bytes32 parentCollectionId,
--       bytes32 conditionId,
--       uint[] calldata partition,
--       uint amount
--   ) external {
--       require(partition.length > 1, "got empty or singleton partition");
--       uint outcomeSlotCount = payoutNumerators[conditionId].length;
--       require(outcomeSlotCount > 0, "condition not prepared yet");

--       // For a condition with 4 outcomes fullIndexSet's 0b1111; for 5 it's 0b11111...
--       uint fullIndexSet = (1 << outcomeSlotCount) - 1;
--       // freeIndexSet starts as the full collection
--       uint freeIndexSet = fullIndexSet;
--       // This loop checks that all condition sets are disjoint (the same outcome is not part of more than 1 set)
--       uint[] memory positionIds = new uint[](partition.length);
--       uint[] memory amounts = new uint[](partition.length);
--       for (uint i = 0; i < partition.length; i++) {
--           uint indexSet = partition[i];
--           require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
--           require((indexSet & freeIndexSet) == indexSet, "partition not disjoint");
--           freeIndexSet ^= indexSet;
--           positionIds[i] = CTHelpers.getPositionId(collateralToken, CTHelpers.getCollectionId(parentCollectionId, conditionId, indexSet));
--           amounts[i] = amount;
--       }

--       if (freeIndexSet == 0) {
--           // Partitioning the full set of outcomes for the condition in this branch
--           if (parentCollectionId == bytes32(0)) {
--               require(collateralToken.transferFrom(msg.sender, address(this), amount), "could not receive collateral tokens");
--           } else {
--               _burn(
--                   msg.sender,
--                   CTHelpers.getPositionId(collateralToken, parentCollectionId),
--                   amount
--               );
--           }
--       } else {
--           // Partitioning a subset of outcomes for the condition in this branch.
--           // For example, for a condition with three outcomes A, B, and C, this branch
--           // allows the splitting of a position $:(A|C) to positions $:(A) and $:(C).
--           _burn(
--               msg.sender,
--               CTHelpers.getPositionId(collateralToken,
--                   CTHelpers.getCollectionId(parentCollectionId, conditionId, fullIndexSet ^ freeIndexSet)),
--               amount
--           );
--       }

--       _batchMint(
--           msg.sender,
--           // position ID is the ERC 1155 token ID
--           positionIds,
--           amounts,
--           ""
--       );
--       emit PositionSplit(msg.sender, collateralToken, parentCollectionId, conditionId, partition, amount);
--   }


local function mergePositions(msg)
  assert(msg.CollateralToken, "CollateralToken is required!")
  assert(msg.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.ConditionId, "ConditionId is required!")
  assert(msg.Partition, "Partition is required!")
  assert(msg.Amount, "Amount is required!")

  -- TODO
  positionsMergeNotice(msg.From, msg.CollateralToken, msg.ParentCollectionId, msg.ConditionId, msg.Partition, msg.Amount)
end

local function redeemPositions(msg)
  assert(msg.CollateralToken, "CollateralToken is required!")
  assert(msg.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.ConditionId, "ConditionId is required!")
  assert(msg.IndexSets, "IndexSets is required!")

  -- TODO
  local payout = 0
  payoutRedemptionNotice(msg.From, msg.CollateralToken, msg.ParentCollectionId, msg.ConditionId, msg.IndexSets, payout)
end

-- @dev Gets the outcome slot count of a condition.
-- @param ConditionId ID of the condition.
-- @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
local function getOutcomeSlotCount(msg)
  assert(msg.ConditionId, "ConditionId is required!")
  assert(type(msg.ConditionId) == 'string', "ConditionId must be a string!")
  return #PayoutNumerators[msg.ConditionId]
end

--[[
    HANDLERS
  ]]
--
Handlers.add("Prepare-Condition", Handlers.utils.hasMatchingTag("Action", "Prepare-Condition"), function(msg)
  prepareCondition(msg)
end)

Handlers.add("Report-Payouts", Handlers.utils.hasMatchingTag("Action", "Report-Payouts"), function(msg)
  reportPayouts(msg)
end)

local function isCreatePosition(msg)
  if msg.Action == "Credit-Notice" and msg["X-Action"] == "Create-Position" then
      return true
  else
      return false
  end
end

Handlers.add("Create-Position",
  isCreatePosition,
  function(msg)
    -- ao.send({ Target = '9876', Action = "Create-Position-Reached", Data = msg.Data })
    assert(msg.Tags["X-ParentCollectionId"], "ParentCollectionId is required!")
    assert(msg.Tags["X-ConditionId"], "ConditionId is required!")
    assert(msg.Tags["X-Partition"], "Partition is required!")
    splitPosition(msg.Sender, msg.From, msg.Tags["X-ParentCollectionId"], msg.Tags["X-ConditionId"], json.decode(msg.Tags["X-Partition"]), msg.Quantity, true)
  end
)

Handlers.add("Split-Position", Handlers.utils.hasMatchingTag("Action", "Split-Position"), function(msg)
  local data = json.decode(msg.Data)
  assert(data.collateralToken, "collateralToken is required!")
  assert(data.parentCollectionId, "parentCollectionId is required!")
  assert(data.conditionId, "conditionId is required!")
  assert(data.partition, "partition is required!")
  assert(data.quantity, "quantity is required!")
  splitPosition(msg.From, data.collateralToken, data.parentCollectionId, data.conditionId, data.partition, data.quantity, false)
end)

Handlers.add("Merge-Positions", Handlers.utils.hasMatchingTag("Action", "Merge-Positions"), function(msg)
  mergePositions(msg)
end)

Handlers.add("Redeem-Positions", Handlers.utils.hasMatchingTag("Action", "Redeem-Positions"), function(msg)
  redeemPositions(msg)
end)

Handlers.add("Get-Outcome-Slot-Count", Handlers.utils.hasMatchingTag("Action", "Get-Outcome-Slot-Count"), function(msg)
  local count = getOutcomeSlotCount(msg)
  ao.send({ Target = msg.From, Action = "Outcome-Slot-Count", ConditionId = msg.Tags.ConditionId, OutcomeSlotCount = tostring(count) })
end)

Handlers.add("Get-Condition-Id", Handlers.utils.hasMatchingTag("Action", "Get-Condition-Id"), function(msg)
  assert(msg.Tags.ResolutionAgent, "ResolutionAgent is required!")
  assert(msg.Tags.QuestionId, "QuestionId is required!")
  assert(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount is required!")
  return getConditionId(msg.Tags.ResolutionAgent, msg.Tags.QuestionId, msg.Tags.OutcomeSlotCount)
end)

Handlers.add("Get-Collection-Id", Handlers.utils.hasMatchingTag("Action", "Get-Collection-Id"), function(msg)
  assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  assert(msg.Tags.IndexSet, "IndexSet is required!")
  local collectionId = getCollectionId(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, msg.Tags.IndexSet)
  ao.send({ Target = msg.From, Action = "Collection-Id", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSet = msg.Tags.IndexSet, CollectionId = collectionId })
end)

-- Handlers.add("Get-Collection-H12", Handlers.utils.hasMatchingTag("Action", "Get-Collection-H12"), function(msg)
--   assert(msg.Tags.ParentCollectionId, "ParentCollectionId is required!")
--   assert(msg.Tags.ConditionId, "ConditionId is required!")
--   assert(msg.Tags.IndexSet, "IndexSet is required!")
--   local h1, h2, result = getCollectionId2(msg.Tags.ParentCollectionId, msg.Tags.ConditionId, msg.Tags.IndexSet)
--   ao.send({ Target = msg.From, Action = "Collection-Id", ParentCollectionId = msg.Tags.ParentCollectionId, ConditionId = msg.Tags.ConditionId, IndexSet = msg.Tags.IndexSet, H1 = h1, H2 = h2, Result = result })
-- end)

Handlers.add("Get-Position-Id", Handlers.utils.hasMatchingTag("Action", "Get-Position-Id"), function(msg)
  assert(msg.Tags.CollateralToken, "CollateralToken is required!")
  assert(msg.Tags.CollectionId, "CollectionId is required!")
  local positionId = getPositionId(msg.Tags.CollateralToken, msg.Tags.CollectionId)
  ao.send({ Target = msg.From, Action = "Position-Id", CollateralToken = msg.Tags.CollateralToken, CollectionId = msg.Tags.CollectionId, PositionId = positionId })
end)

Handlers.add("Get-Denominator", Handlers.utils.hasMatchingTag("Action", "Get-Denominator"), function(msg)
  assert(msg.Tags.ConditionId, "ConditionId is required!")
  ao.send({ Target = msg.From, Action = "Denominator", ConditionId = msg.Tags.ConditionId, Denominator = tostring(PayoutDenominator[msg.Tags.ConditionId]) })
end)

Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Get-Info"), function(msg)
  ao.send({
    Target = msg.From,
    Name = Name,
    Ticker = Ticker,
    Logo = Logo,
    Denomination = tostring(Denomination)
  })
end)

Handlers.add("Balance-Of", Handlers.utils.hasMatchingTag("Action", "Balance-Of"), function(msg)
  assert(msg.Tags.Id, "Id is required!")
  local bal = '0'

  -- If Id is found then cointinue
  if BalancesOf[msg.Tags.Id] then
    -- If not Target is provided, then return the Senders balance
    if (msg.Tags.Target and BalancesOf[msg.Tags.Id][msg.Tags.Target]) then
      bal = BalancesOf[msg.Tags.Id][msg.Tags.Target]
    elseif BalancesOf[msg.Tags.Id][msg.From] then
      bal = BalancesOf[msg.Tags.Id][msg.From]
    end
  end

  ao.send({
    Target = msg.From,
    Balance = bal,
    TokenId = msg.Tags.Id,
    Ticker = Ticker,
    Account = msg.Tags.Target or msg.From,
    Data = bal
  })
end)

-- TODO: Decide if we want to return the balances of all ids or a single id
Handlers.add('Balances-Of', Handlers.utils.hasMatchingTag('Action', 'Balances-Of'), function(msg)
  assert(msg.Tags.TokenId, "TokenId is required!")
  ao.send({ Target = msg.From, Data = json.encode(BalancesOf[msg.Tags.TokenId]) })
end)

Handlers.add('Balances', Handlers.utils.hasMatchingTag('Action', 'Balances'), function(msg)
  ao.send({ Target = msg.From, Data = json.encode(BalancesOf) })
end)

return "ok"