return [===[
-- module: "modules.tokenNotices"
  local function _loaded_mod_modules_tokenNotices()
  local ao = require('.ao')
  
  local TokenNotices = {}
  
  function TokenNotices.mintNotice(recipient, quantity, msg)
    return msg.reply({
      Recipient = recipient,
      Quantity = tostring(quantity),
      Action = 'Mint-Notice',
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
    })
  end
  
  function TokenNotices.burnNotice(quantity, msg)
    return msg.reply({
      Quantity = tostring(quantity),
      Action = 'Burn-Notice',
      Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
    })
  end
  
  function TokenNotices.transferNotices(debitNotice, creditNotice, msg)
    return { msg.reply(debitNotice), ao.send(creditNotice) }
  end
  
  function TokenNotices.transferErrorNotice(msg)
    return msg.reply({
      Action = 'Transfer-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Insufficient Balance!'
    })
  end
  
  return TokenNotices
  end
  
  _G.package.loaded["modules.tokenNotices"] = _loaded_mod_modules_tokenNotices()
  
-- module: "modules.token"
  local function _loaded_mod_modules_token()
  local bint = require('.bint')(256)
  local json = require('json')
  local ao = require('.ao')
  
  local Token = {}
  local TokenMethods = require('modules.tokenNotices')
  
  -- Constructor for Token 
  function Token:new()
    -- This will store user balances of tokens and metadata
    local obj = {
      name = '',
      ticker = '',
      logo = '',
      balances = {},
      totalSupply = '0',
      denomination = 12
    }
    setmetatable(obj, { __index = TokenMethods })
    return obj
  end
  
  -- @dev Internal function to mint a quantity of tokens
  -- @param to The address that will own the minted token
  -- @param quantity Quantity of the token to be minted
  function TokenMethods:mint(to, quantity, msg)
    assert(quantity, 'Quantity is required!')
    assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
    -- Mint tokens
    if not self.balances[to] then self.balances[to] = '0' end
    self.balances[to] = tostring(bint.__add(bint(self.balances[to]), quantity))
    self.totalSupply = tostring(bint.__add(bint(self.totalSupply), quantity))
    -- Send notice
    return self.mintNotice(to, quantity, msg)
  end
  
  -- @dev Internal function to burn a quantity of tokens
  -- @param from The address that will burn the token
  -- @param quantity Quantity of the token to be burned
  function TokenMethods:burn(from, quantity, msg)
    assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
    assert(self.balances[from], 'Must have token balance!')
    assert(bint.__le(quantity, self.balances[from]), 'Must have sufficient tokens!')
    -- Burn tokens
    self.balances[from] = tostring(bint.__sub(self.balances[from], quantity))
    self.totalSupply = tostring(bint.__sub(bint(self.totalSupply), quantity))
    -- Send notice
    return self.burnNotice(quantity, msg)
  end
  
  -- @dev Internal function to transfer a quantity of tokens
  -- @param recipient The address that will send the token
  -- @param from The address that will receive the token
  -- @param quantity Quantity of the token to be burned
  -- @param cast Cast to silence the transfer notice
  -- @param msg The message (used for x-tag forwarding and reporting)
  function TokenMethods:transfer(from, recipient, quantity, cast, msg)
    if not self.balances[from] then self.balances[from] = "0" end
    if not self.balances[recipient] then self.balances[recipient] = "0" end
  
    local qty = bint(quantity)
    local balance = bint(self.balances[from])
  
    if bint.__le(qty, balance) then
      self.balances[from] = tostring(bint.__sub(balance, qty))
      self.balances[recipient] = tostring(bint.__add(self.balances[recipient], qty))
  
      -- Only send the notifications to the Sender and Recipient
      -- if the Cast tag is not set on the Transfer message
      if not cast then
        -- Debit-Notice message template, that is sent to the Sender of the transfer
        local debitNotice = {
          Target = from,
          Action = 'Debit-Notice',
          Recipient = recipient,
          Quantity = quantity,
          Data = Colors.gray ..
              "You transferred " ..
              Colors.blue .. quantity .. Colors.gray .. " to " .. Colors.green .. recipient .. Colors.reset
        }
        -- Credit-Notice message template, that is sent to the Recipient of the transfer
        local creditNotice = {
          Target = recipient,
          Action = 'Credit-Notice',
          Sender = from,
          Quantity = quantity,
          Data = Colors.gray ..
              "You received " ..
              Colors.blue .. quantity .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
        }
  
        -- Add forwarded tags to the credit and debit notice messages
        for tagName, tagValue in pairs(msg.Tags) do
          -- Tags beginning with "X-" are forwarded
          if string.sub(tagName, 1, 2) == "X-" then
            debitNotice[tagName] = tagValue
            creditNotice[tagName] = tagValue
          end
        end
  
        -- Send Debit-Notice and Credit-Notice
        return self.transferNotices(debitNotice, creditNotice, msg)
      end
    else
      return self.transferErrorNotice(msg)
    end
  end
  
  return Token
  
  end
  
  _G.package.loaded["modules.token"] = _loaded_mod_modules_token()

-- module: "modules.semiFungibleTokensNotices"
  local function _loaded_mod_modules_semiFungibleTokensNotices()
  local ao = require('.ao')
  local json = require('json')
  
  local SemiFungibleTokensNotices = {}
  
  -- @dev Mint single token notice
  -- @param to The address that will own the minted token
  -- @param id ID of the token to be minted
  -- @param quantity Quantity of the token to be minted
  function SemiFungibleTokensNotices.mintSingleNotice(to, id, quantity, msg)
    return msg.reply({
      Recipient = to,
      TokenId = tostring(id),
      Quantity = tostring(quantity),
      Action = 'Mint-Single-Notice',
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
    })
  end
  
  -- @dev Mint batch notice
  -- @param to The address that will own the minted token
  -- @param ids IDs of the tokens to be minted
  -- @param quantities Quantities of the tokens to be minted
  function SemiFungibleTokensNotices.mintBatchNotice(to, ids, quantities, msg)
    return msg.reply({
      Recipient = to,
      TokenIds = json.encode(ids),
      Quantities = json.encode(quantities),
      Action = 'Mint-Batch-Notice',
      Data = "Successfully minted batch"
    })
  end
  
  -- @dev Burn single token notice
  -- @param from The address that will burn the token
  -- @param id ID of the token to be burned
  -- @param quantity Quantity of the token to be burned
  function SemiFungibleTokensNotices.burnSingleNotice(from, id, quantity, msg)
    -- Prepare notice
    local notice = {
      Recipient = from,
      TokenId = tostring(id),
      Quantity = tostring(quantity),
      Action = 'Burn-Single-Notice',
      Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
    }
    -- Forward X-Tags
    for tagName, tagValue in pairs(msg) do
      -- Tags beginning with "X-" are forwarded
      if string.sub(tagName, 1, 2) == "X-" then
        notice[tagName] = tagValue
      end
    end
    -- Send notice
    return msg.reply(notice)
  end
  
  -- @dev Burn batch tokens notice
  -- @param notice The prepared notice to be sent
  function SemiFungibleTokensNotices.burnBatchNotice(notice, msg)
    -- Forward X-Tags
    for tagName, tagValue in pairs(msg) do
      -- Tags beginning with "X-" are forwarded
      if string.sub(tagName, 1, 2) == "X-" then
        notice[tagName] = tagValue
      end
    end
    -- Send notice
    return msg.reply(notice)
  end
  
  -- @dev Transfer single token notices
  -- @param from The address to be debited
  -- @param to The address to be credited
  -- @param id ID of the tokens to be transferred
  -- @param quantity Quantity of the tokens to be transferred
  -- @param msg For sending X-Tags
  function SemiFungibleTokensNotices.transferSingleNotices(from, to, id, quantity, msg)
    -- Prepare debit notice
    local debitNotice = {
      Action = 'Debit-Single-Notice',
      Recipient = to,
      TokenId = tostring(id),
      Quantity = tostring(quantity),
      Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " to " .. Colors.green .. to .. Colors.reset
    }
    -- Prepare credit notice
    local creditNotice = {
      Target = to,
      Action = 'Credit-Single-Notice',
      Sender = from,
      TokenId = tostring(id),
      Quantity = tostring(quantity),
      Data = Colors.gray .. "You received " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " from " .. Colors.green .. from .. Colors.reset
    }
    -- Forward X-Tags
    for tagName, tagValue in pairs(msg) do
      -- Tags beginning with "X-" are forwarded
      if string.sub(tagName, 1, 2) == "X-" then
        debitNotice[tagName] = tagValue
        creditNotice[tagName] = tagValue
      end
    end
    -- Send notices
    return { msg.reply(debitNotice), ao.send(creditNotice) }
  end
  
  -- @dev Transfer batch tokens notices
  -- @param from The address to be debited
  -- @param to The address to be credited
  -- @param ids IDs of the tokens to be transferred
  -- @param quantities Quantities of the tokens to be transferred
  -- @param msg For sending X-Tags
  function SemiFungibleTokensNotices.transferBatchNotices(from, to, ids, quantities, msg)
    -- Prepare debit notice
    local debitNotice = {
      Action = 'Debit-Batch-Notice',
      Recipient = to,
      TokenIds = json.encode(ids),
      Quantities = json.encode(quantities),
      Data = Colors.gray .. "You transferred batch to " .. Colors.green .. to .. Colors.reset
    }
    -- Prepare credit notice
    local creditNotice = {
      Target = to,
      Action = 'Credit-Batch-Notice',
      Sender = from,
      TokenIds = json.encode(ids),
      Quantities = json.encode(quantities),
      Data = Colors.gray .. "You received batch from " .. Colors.green .. from .. Colors.reset
    }
    -- Forward X-Tags
    for tagName, tagValue in pairs(msg) do
      -- Tags beginning with "X-" are forwarded
      if string.sub(tagName, 1, 2) == "X-" then
        debitNotice[tagName] = tagValue
        creditNotice[tagName] = tagValue
      end
    end
    -- Send notice
    return {msg.reply(debitNotice), ao.send(creditNotice)}
  end
  
  -- @dev Transfer error notice
  -- @param from The address to be debited
  -- @param id ID of the tokens to be transferred
  -- @param msg The message
  function SemiFungibleTokensNotices.transferErrorNotice(id, msg)
    return msg.reply({
      Action = 'Transfer-Error',
      ['Message-Id'] = msg.Id,
      ['Token-Id'] = id,
      Error = 'Insufficient Balance!'
    })
  end
  
  return SemiFungibleTokensNotices
  
  end
  
  _G.package.loaded["modules.semiFungibleTokensNotices"] = _loaded_mod_modules_semiFungibleTokensNotices()
  
-- module: "modules.semiFungibleTokens"
  local function _loaded_mod_modules_semiFungibleTokens()
  local ao = require('.ao')
  local json = require('json')
  local bint = require('.bint')(256)
  
  local SemiFungibleTokens = {}
  local SemiFungibleTokensMethods = require('modules.semiFungibleTokensNotices')
  
  -- Constructor for SemiFungibleTokens 
  function SemiFungibleTokens:new()
    -- This will store user semi-fungible tokens balances and metadata
    local obj = {
      name = '',
      ticker = '',
      logo = '',
      balancesById = {},  -- { id -> userId -> balance of semi-fungible tokens }
      totalSupplyById = {}, -- { id -> totalSupply of semi-fungible tokens }
      denomination = 12
    }
    setmetatable(obj, { __index = SemiFungibleTokensMethods })
    return obj
  end
  
  -- @dev Mint a quantity of a token with the given ID
  -- @param to The address that will own the minted token
  -- @param id ID of the token to be minted
  -- @param quantity Quantity of the token to be minted
  function SemiFungibleTokensMethods:mint(to, id, quantity, msg)
    assert(quantity, 'Quantity is required!')
    assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
  
    if not self.balancesById[id] then self.balancesById[id] = {} end
    if not self.balancesById[id][to] then self.balancesById[id][to] = "0" end
    if not self.totalSupplyById[id] then self.totalSupplyById[id] = "0" end
  
    self.balancesById[id][to] = tostring(bint.__add(self.balancesById[id][to], quantity))
    self.totalSupplyById[id] = tostring(bint.__add(self.totalSupplyById[id], quantity))
    -- Send notice
    return self.mintSingleNotice(to, id, quantity, msg)
  end
  
  -- @dev Batch mint quantities of tokens with the given IDs
  -- @param to The address that will own the minted token
  -- @param ids IDs of the tokens to be minted
  -- @param quantities Quantities of the tokens to be minted
  function SemiFungibleTokensMethods:batchMint(to, ids, quantities, msg)
    assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  
    for i = 1, #ids do
      -- @dev spacing to resolve text to code eval issue
      if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
      if not self.balancesById[ ids[i] ][to] then self.balancesById[ ids[i] ][to] = "0" end
      if not self.totalSupplyById[ ids[i] ] then self.totalSupplyById[ ids[i] ] = "0" end
  
      self.balancesById[ ids[i] ][to] = tostring(bint.__add(self.balancesById[ ids[i] ][to], quantities[i]))
      self.totalSupplyById[ ids[i] ] = tostring(bint.__add(self.totalSupplyById[ ids[i] ], quantities[i]))
    end
  
    -- Send notice
    return self.mintBatchNotice(to, ids, quantities, msg)
  end
  
  -- @dev Burn a quantity of a token with the given ID
  -- @param from The address that will burn the token
  -- @param id ID of the token to be burned
  -- @param quantity Quantity of the token to be burned
  function SemiFungibleTokensMethods:burn(from, id, quantity, msg)
    assert(bint.__lt(0, quantity), 'Quantity must be greater than zero!')
    assert(self.balancesById[id], 'Id must exist! ' .. id)
    assert(self.balancesById[id][from], 'User must hold token! :: ' .. id)
    assert(bint.__le(quantity, self.balancesById[id][from]), 'User must have sufficient tokens! ' .. id)
  
    -- Burn tokens
    self.balancesById[id][from] = tostring(bint.__sub(self.balancesById[id][from], quantity))
    self.totalSupplyById[id] = tostring(bint.__sub(self.totalSupplyById[id], quantity))
    -- Send notice
    return self.burnSingleNotice(from, id, quantity, msg)
  end
  
  -- @dev Batch burn quantities of tokens with the given IDs
  -- @param from The address that will burn the tokens
  -- @param ids IDs of the tokens to be burned
  -- @param quantities Quantities of the tokens to be burned
  -- @param msg For sending X-Tags
  function SemiFungibleTokensMethods:batchBurn(from, ids, quantities, msg)
    assert(#ids == #quantities, 'Ids and quantities must have the same lengths')
  
    for i = 1, #ids do
      assert(bint.__lt(0, quantities[i]), 'Quantity must be greater than zero!')
      assert(self.balancesById[ ids[i] ], 'Id must exist! ' .. ids[i])
      assert(self.balancesById[ ids[i] ][from], 'User must hold token! ' .. ids[i])
      assert(bint.__le(quantities[i], self.balancesById[ ids[i] ][from]), 'User must have sufficient tokens!')
    end
  
    local remainingBalances = {}
  
    -- Burn tokens
    for i = 1, #ids do
      self.balancesById[ ids[i] ][from] = tostring(bint.__sub(self.balancesById[ ids[i] ][from], quantities[i]))
      self.totalSupplyById[ ids[i] ] = tostring(bint.__sub(self.totalSupplyById[ ids[i] ], quantities[i]))
      remainingBalances[i] = self.balancesById[ ids[i] ][from]
    end
    -- Draft notice
    local notice = {
      Recipient = from,
      TokenIds = json.encode(ids),
      Quantities = json.encode(quantities),
      RemainingBalances = json.encode(remainingBalances),
      Action = 'Burn-Batch-Notice',
      Data = "Successfully burned batch"
    }
    -- Forward X-Tags
    for tagName, tagValue in pairs(msg) do
      -- Tags beginning with "X-" are forwarded
      if string.sub(tagName, 1, 2) == "X-" then
        notice[tagName] = tagValue
      end
    end
    -- Send notice
    return self.burnBatchNotice(notice, msg)
  end
  
  -- @dev Transfer a quantity of tokens with the given ID
  -- @param from The address to be debited
  -- @param recipient The address to be credited
  -- @param id ID of the tokens to be transferred
  -- @param quantity Quantity of the tokens to be transferred
  -- @param cast The boolean to silence transfer notifications
  -- @param msg For sending X-Tags
  function SemiFungibleTokensMethods:transferSingle(from, recipient, id, quantity, cast, msg)
    if not self.balancesById[id] then self.balancesById[id] = {} end
    if not self.balancesById[id][from] then self.balancesById[id][from] = "0" end
    if not self.balancesById[id][recipient] then self.balancesById[id][recipient] = "0" end
  
    local qty = bint(quantity)
    local balance = bint(self.balancesById[id][from])
    if bint.__le(qty, balance) then
      self.balancesById[id][from] = tostring(bint.__sub(balance, qty))
      self.balancesById[id][recipient] = tostring(bint.__add(self.balancesById[id][recipient], qty))
  
      -- Only send the notifications if the cast tag is not set
      if not cast then
        return self.transferSingleNotices(from, recipient, id, quantity, msg)
      end
    else
      return self.transferErrorNotice(id, msg)
    end
  end
  
  -- @dev Batch transfer quantities of tokens with the given IDs
  -- @param from The address to be debited
  -- @param recipient The address to be credited
  -- @param ids IDs of the tokens to be transferred
  -- @param quantities Quantities of the tokens to be transferred
  -- @param cast The boolean to silence transfer notifications
  -- @param msg For sending X-Tags
  function SemiFungibleTokensMethods:transferBatch(from, recipient, ids, quantities, cast, msg)
    local ids_ = {}
    local quantities_ = {}
  
    for i = 1, #ids do
      if not self.balancesById[ ids[i] ] then self.balancesById[ ids[i] ] = {} end
      if not self.balancesById[ ids[i] ][from] then self.balancesById[ ids[i] ][from] = "0" end
      if not self.balancesById[ ids[i] ][recipient] then self.balancesById[ ids[i] ][recipient] = "0" end
  
      local qty = bint(quantities[i])
      local balance = bint(self.balancesById[ ids[i] ][from])
  
      if bint.__le(qty, balance) then
        self.balancesById[ ids[i] ][from] = tostring(bint.__sub(balance, qty))
        self.balancesById[ ids[i] ][recipient] = tostring(bint.__add(self.balancesById[ ids[i] ][recipient], qty))
        table.insert(ids_, ids[i])
        table.insert(quantities_, quantities[i])
      else
        return self.transferErrorNotice(ids[i], msg)
      end
    end
  
    -- Only send the notifications if the cast tag is not set
    if not cast and #ids_ > 0 then
      return self.transferBatchNotices(from, recipient, ids_, quantities_, msg)
    end
  end
  
  function SemiFungibleTokensMethods:getBalance(from, recipient, tokenId)
    local bal = '0'
    -- If Id is found then cointinue
    if self.balancesById[tokenId] then
      -- If not Recipient is provided, then return the Senders balance
      if (recipient and self.balancesById[tokenId][recipient]) then
        bal = self.balancesById[tokenId][recipient]
      elseif self.balancesById[tokenId][from] then
        bal = self.balancesById[tokenId][from]
      end
    end
    -- return balance
    return bal
  end
  
  function SemiFungibleTokensMethods:getBatchBalance(recipients, tokenIds)
    assert(#recipients == #tokenIds, 'Recipients and TokenIds must have same lengths')
    local bals = {}
  
    for i = 1, #recipients do
      table.insert(bals, '0')
      if self.balancesById[ tokenIds[i] ] then
        if self.balancesById[ tokenIds[i] ][ recipients[i] ] then
          bals[i] = self.balancesById[ tokenIds[i] ][ recipients[i] ]
        end
      end
    end
  
    return bals
  end
  
  function SemiFungibleTokensMethods:getBalances(tokenId)
    local bals = {}
    if self.balancesById[tokenId] then
      bals = self.balancesById[tokenId]
    end
    -- return balances
    return bals
  end
  
  function SemiFungibleTokensMethods:getBatchBalances(tokenIds)
    local bals = {}
  
    for i = 1, #tokenIds do
      bals[ tokenIds[i] ] = {}
      if self.balancesById[ tokenIds[i] ] then
        bals[ tokenIds[i] ] = self.balancesById[ tokenIds[i] ]
      end
    end
    -- return balances
    return bals
  end
  
  return SemiFungibleTokens
  
  end
  
  _G.package.loaded["modules.semiFungibleTokens"] = _loaded_mod_modules_semiFungibleTokens()
  
  -- module: "modules.conditionalTokensNotices"
  local function _loaded_mod_modules_conditionalTokensNotices()
  local ao = require('.ao')
  local json = require('json')
  
  local ConditionalTokensNotices = {}
  
  -- @dev Emitted upon the successful preparation of a condition.
  -- @param sender The address of the account that prepared the condition.
  -- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
  -- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
  -- @param msg For sending msg.reply
  function ConditionalTokensNotices.conditionPreparationNotice(conditionId, outcomeSlotCount, msg)
    -- TODO: Decide if to be sent to user and/or Data Index
    return msg.reply({
      Action = "Condition-Preparation-Notice",
      ConditionId = conditionId,
      OutcomeSlotCount = tostring(outcomeSlotCount)
    })
  end
  
  -- @dev Emitted upon the successful condition resolution.
  -- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
  -- @param resolutionAgent The process assigned to report the result for the prepared condition.
  -- @param questionId An identifier for the question to be answered by the resolutionAgent.
  -- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
  -- @param payoutNumerators The payout numerators for each outcome slot.
  function ConditionalTokensNotices.conditionResolutionNotice(conditionId, resolutionAgent, questionId, outcomeSlotCount, payoutNumerators, msg)
    -- TODO: Decide if to be sent to user and/or Data Index
    return msg.reply({
      Action = "Condition-Resolution-Notice",
      ConditionId = conditionId,
      ResolutionAgent = resolutionAgent,
      QuestionId = questionId,
      OutcomeSlotCount = tostring(outcomeSlotCount),
      PayoutNumerators = json.encode(payoutNumerators)
    })
  end
  
  -- @dev Emitted when a position is successfully split.
  -- @param from The address of the account that split the position.
  -- @param collateralToken The address of the collateral token.
  -- @param conditionId The condition ID.
  -- @param quantity The quantity.
  -- @param msg For sending X-Tags
  function ConditionalTokensNotices.positionSplitNotice(from, collateralToken, conditionId, quantity, msg)
    local notice = {
      Action = "Split-Position-Notice",
      Process = ao.id,
      Stakeholder = from,
      CollateralToken = collateralToken,
      ConditionId = conditionId,
      Quantity = quantity
    }
    -- Forward tags
    for tagName, tagValue in pairs(msg) do
      -- Tags beginning with "X-" are forwarded
      if string.sub(tagName, 1, 2) == "X-" then
        notice[tagName] = tagValue
      end
    end
    -- Send notice | @dev ao.send vs msg.reply to ensure message is sent to user (not collateralToken)
    return msg.forward(from, notice)
  end
  
  
  -- @dev Emitted when positions are successfully merged.
  -- @param from The address of the account that merged the positions.
  -- @param conditionId The condition ID.
  -- @param quantity The quantity.
  function ConditionalTokensNotices.positionsMergeNotice(conditionId, quantity, msg)
    return msg.reply({
      Action = "Merge-Positions-Notice",
      ConditionId = conditionId, -- TODO: Check if this is needed
      Quantity = quantity
    })
  end
  
  -- @dev Emitted when a position is successfully redeemed.
  -- @param redeemer The address of the account that redeemed the position.
  -- @param collateralToken The address of the collateral token.
  -- @param conditionId The condition ID.
  -- @param payout The payout amount.
  function ConditionalTokensNotices.payoutRedemptionNotice(collateralToken, conditionId, payout, msg)
    -- TODO: Decide if to be sent to user and/or Data Index
    return msg.reply({
      Action = "Payout-Redemption-Notice",
      Process = ao.id,
      CollateralToken = collateralToken,
      ConditionId = conditionId,
      Payout = tostring(payout)
    })
  end
  
  return ConditionalTokensNotices
  
  end
  
  _G.package.loaded["modules.conditionalTokensNotices"] = _loaded_mod_modules_conditionalTokensNotices()

  -- module: "modules.conditionalTokens"
  local function _loaded_mod_modules_conditionalTokens()
  -- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
  local ao = require('.ao')
  local json = require('json')
  local bint = require('.bint')(256)
  local crypto = require('.crypto')
  local semiFungibleTokens = require('modules.semiFungibleTokens')
  
  local SemiFungibleTokens = {}
  local ConditionalTokens = {}
  local ConditionalTokensMethods = require('modules.conditionalTokensNotices')
  
  -- Constructor for ConditionalTokens 
  function ConditionalTokens:new()
    -- Initialize SemiFungibleTokens and store the object
    SemiFungibleTokens = semiFungibleTokens:new()
  
    -- Create a new ConditionalTokens object
    local obj = {
      -- SemiFungible Tokens
      tokens = SemiFungibleTokens,
      conditionId = '',
      outcomeSlotCount = nil,
      positionIds = {},
      payoutNumerators = {},
      payoutDenominator = {},
      -- Take Fee vars
      creatorFee = 0,
      creatorFeeTarget = '',
      protocolFee = 0,
      protocolFeeTarget = ''
    }
  
    -- Set metatable for method lookups from ConditionalTokensMethods, SemiFungibleTokensMethods, and ConditionalTokensHelpers
    setmetatable(obj, {
      __index = function(t, k)
        -- First, look up the key in ConditionalTokensMethods
        if ConditionalTokensMethods[k] then
          return ConditionalTokensMethods[k]
        -- Lastly, look up the key in the semiFungibleInstance methods
        elseif SemiFungibleTokens[k] then
          return SemiFungibleTokens[k]
        else
          return nil
        end
      end
    })
    return obj
  end
  
  -- @dev This function prepares a condition by initializing a payout vector associated with the condition.
  -- @param conditionId The condition's ID. This ID may be derived from the other three parameters via ``keccak256(abi.encodePacked(questionId, resolutionAgent, outcomeSlotCount))``.
  -- @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
  function ConditionalTokensMethods:prepareCondition(conditionId, outcomeSlotCount, msg)
    assert(self.payoutNumerators[conditionId] == nil, "condition already prepared")
    -- Initialize the payout vector associated with the condition.
    self.payoutNumerators[conditionId] = {}
    for _ = 1, outcomeSlotCount do
      table.insert(self.payoutNumerators[conditionId], 0)
    end
    -- Initialize the denominator to zero to indicate that the condition has not been resolved.
    self.payoutDenominator[conditionId] = 0
    -- Send the condition preparation notice.
    return self.conditionPreparationNotice(conditionId, outcomeSlotCount, msg)
  end
  
  -- @dev This function splits a position from collateral. This contract will attempt to transfer `amount` collateral from the message sender to itself. 
  -- If successful, `quantity` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert.
  -- @param from The initiator of the original Split-Position / Create-Position action message.
  -- @param collateralToken The address of the positions' backing collateral token.
  -- @param quantity The quantity of collateral or stake to split.
  -- @param msg Msg passed to retrieve x-tags
  function ConditionalTokensMethods:splitPosition(from, collateralToken, quantity, msg)
    assert(self.payoutNumerators[self.conditionId] and #self.payoutNumerators[self.conditionId] > 0, "Condition not prepared!")
    -- Create equal split positions.
    local quantities = {}
    for _ = 1, #self.positionIds do
      table.insert(quantities, quantity)
    end
    -- Mint the stake in the split target positions.
    SemiFungibleTokens:batchMint(from, self.positionIds, quantities, msg)
    -- Send notice.
    return self.positionSplitNotice(from, collateralToken, self.conditionId, quantity, msg)
  end
  
  -- @dev This function merges positions. If merging to the collateral, this contract will attempt to transfer `quantity` collateral to the message sender.
  -- Otherwise, this contract will burn `quantity` stake held by the message sender in the positions being merged worth of semi-fungible tokens.
  -- If successful, `quantity` stake will be minted in the merged position. If any of the transfers, mints, or burns fail, the transaction will revert.
  -- @param from The initiator of the original Merge-Positions action message.
  -- @param onBehalfOf The address that will receive the collateral.
  -- @param quantity The quantity of collateral or stake to merge.
  -- @param msg Msg passed to retrieve x-tags
  function ConditionalTokensMethods:mergePositions(from, onBehalfOf, quantity, isSell, msg)
    assert(self.payoutNumerators[self.conditionId] and #self.payoutNumerators[self.conditionId] > 0, "Condition not prepared!")
    -- Create equal merge positions.
    local quantities = {}
    for _ = 1, #self.positionIds do
      table.insert(quantities, quantity)
    end
    -- Burn equal quantiies from user positions.
    self.tokens:batchBurn(from, self.positionIds, quantities, msg)
    -- @dev below already handled within the sell method. 
    -- sell method w/ a different quantity and recipient.
    if not isSell then
      -- Return the collateral to the user.
      ao.send({
        Target = self.collateralToken,
        Action = "Transfer",
        Quantity = quantity,
        Recipient = onBehalfOf
      })
    end
    -- Send notice.
    return self.positionsMergeNotice(self.conditionId, quantity, msg)
  end
  
  -- @dev Called by the resolutionAgent for reporting results of conditions. Will set the payout vector for the condition with the ID `keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount))`, 
  -- where ResolutionAgent is the message sender, QuestionId is one of the parameters of this function, and OutcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
  -- @param QuestionId The question ID the oracle is answering for
  -- @param Payouts The oracle's answer
  function ConditionalTokensMethods:reportPayouts(questionId, payouts, msg)
    -- IMPORTANT, the payouts length accuracy is enforced because outcomeSlotCount is part of the hash.
    local outcomeSlotCount = #payouts
    assert(outcomeSlotCount > 1, "there should be more than one outcome slot")
    -- IMPORTANT, the resolutionAgent is enforced to be the sender because it's part of the hash.
    local conditionId = self.getConditionId(msg.From, questionId, tostring(outcomeSlotCount))
    assert(self.payoutNumerators[conditionId] and #self.payoutNumerators[conditionId] == outcomeSlotCount, "condition not prepared or found")
    assert(self.payoutDenominator[conditionId] == 0, "payout denominator already set")
    -- Set the payout vector for the condition.
    local den = 0
    for i = 1, outcomeSlotCount do
      local num = payouts[i]
      den = den + num
      assert(self.payoutNumerators[conditionId][i] == 0, "payout numerator already set")
      self.payoutNumerators[conditionId][i] = num
    end
    assert(den > 0, "payout is all zeroes")
    self.payoutDenominator[conditionId] = den
    -- Send the condition resolution notice.
    return self.conditionResolutionNotice(conditionId, msg.From, questionId, outcomeSlotCount, self.payoutNumerators[conditionId], msg)
  end
  
  -- @dev This function redeems positions. If redeeming to the collateral, this contract will attempt to transfer the payout to the message sender.
  -- Otherwise, this contract will burn the stake held by the message sender in the positions being redeemed worth of semi-fungible tokens.
  -- If successful, the payout will be minted in the parent position. If any of the transfers, mints, or burns fail, the transaction will revert.
  -- @param from The initiator of the original Redeem-Positions action message.
  -- @param collateralToken The address of the positions' backing collateral token.
  -- @param parentCollectionId The ID of the outcome collections common to the positions being redeemed and the parent position. May be null, in which only the collateral is shared.
  -- @param conditionId The ID of the condition to redeem on.
  -- @param indexSets An array of index sets representing the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
  function ConditionalTokensMethods:redeemPositions(msg)
    local den = self.payoutDenominator[self.conditionId]
    assert(den > 0, "result for condition not received yet")
    assert(self.payoutNumerators[self.conditionId] and #self.payoutNumerators[self.conditionId] > 0, "condition not prepared yet")
    local totalPayout = 0
    for i = 1, #self.positionIds do
      local positionId = self.positionIds[i]
      local payoutNumerator = self.payoutNumerators[self.conditionId][tonumber(positionId)]
  
      -- Get the stake to redeem.
      if not self.tokens.balancesById[positionId] then self.tokens.balancesById[positionId] = {} end
      if not self.tokens.balancesById[positionId][msg.From] then self.tokens.balancesById[positionId][msg.From] = "0" end
      local payoutStake = self.tokens.balancesById[positionId][msg.From]
      assert(bint.__lt(0, bint(payoutStake)), "no stake to redeem")
      -- Calculate the payout and burn position.
      totalPayout = math.floor(totalPayout + (payoutStake * payoutNumerator) / den)
      self:burn(msg.From, positionId, payoutStake, msg)
    end
    -- Return totla payout minus take fee.
    if totalPayout > 0 then
      totalPayout = math.floor(totalPayout)
      self:returnTotalPayoutMinusTakeFee(self.collateralToken, msg.From, totalPayout)
    end
    -- Send notice.
    return self.payoutRedemptionNotice(self.collateralToken, self.conditionId, totalPayout, msg)
  end
  
  -- @dev Gets the outcome slot count of a condition.
  -- @param ConditionId ID of the condition.
  -- @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
  function ConditionalTokensMethods:getOutcomeSlotCount(msg)
    assert(msg.Tags.ConditionId, "ConditionId is required!")
    return self.payoutNumerators[msg.Tags.ConditionId] and #self.payoutNumerators[msg.Tags.ConditionId] or 0
  end
  
  -- @dev Constructs a condition ID from a resolutionAgent, a question ID, and the outcome slot count for the question.
  -- @param ResolutionAgent The process assigned to report the result for the prepared condition.
  -- @param QuestionId An identifier for the question to be answered by the resolutionAgent.
  -- @param OutcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
  function ConditionalTokensMethods.getConditionId(resolutionAgent, questionId, outcomeSlotCount)
    return crypto.digest.keccak256(resolutionAgent .. questionId .. outcomeSlotCount).asHex()
  end
  
  function ConditionalTokensMethods:returnTotalPayoutMinusTakeFee(collateralToken, from, totalPayout)
    local protocolFee =  tostring(bint.ceil(bint.__div(bint.__mul(totalPayout, self.protocolFee), 1e4)))
    local creatorFee =  tostring(bint.ceil(bint.__div(bint.__mul(totalPayout, self.creatorFee), 1e4)))
    local takeFee = tostring(bint.__add(bint(creatorFee), bint(protocolFee)))
    local totalPayoutMinusFee = tostring(bint.__sub(totalPayout, bint(takeFee)))
    -- prepare txns
    local protocolFeeTxn = {
      Target = collateralToken,
      Action = "Transfer",
      Recipient = self.protocolFeeTarget,
      Quantity = protocolFee,
    }
    local creatorFeeTxn = {
      Target = collateralToken,
      Action = "Transfer",
      Recipient = self.creatorFeeTarget,
      Quantity = creatorFee,
    }
    local totalPayoutMinutTakeFeeTxn = {
      Target = collateralToken,
      Action = "Transfer",
      Recipient = from,
      Quantity = totalPayoutMinusFee
    }
    -- send txns
    return { ao.send(protocolFeeTxn), ao.send(creatorFeeTxn), ao.send(totalPayoutMinutTakeFeeTxn) }
  end
  
  return ConditionalTokens
  
  end
  
  _G.package.loaded["modules.conditionalTokens"] = _loaded_mod_modules_conditionalTokens()

  -- module: "modules.cpmmHelpers"
  local function _loaded_mod_modules_cpmmHelpers()
  local bint = require('.bint')(256)
  local ao = require('.ao')
  local json = require('json')
  
  local CPMMHelpers = {}
  
  -- Utility function: CeilDiv
  function CPMMHelpers.ceildiv(x, y)
    if x > 0 then
      return math.floor((x - 1) / y) + 1
    end
    return math.floor(x / y)
  end
  
  
  --@dev generates basic partition based on outcomesSlotCount
  function CPMMHelpers.getPositionIds(outcomeSlotCount)
    local positionIds = {}
    for i = 1, outcomeSlotCount do
      table.insert(positionIds, tostring(i))
    end
    return positionIds
  end
  
  -- @dev validates addFunding
  function CPMMHelpers:validateAddFunding(from, quantity, distribution)
    local error = false
    local errorMessage = ''
    -- Ensure distribution
    if not distribution then
      error = true
      errorMessage = 'X-Distribution is required!'
    elseif not error then
      if bint.iszero(bint(self.token.totalSupply)) then
        -- Ensure distribution is set across all position ids
        if #distribution ~= #self.tokens.positionIds then
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
        Target = self.tokens.collateralToken,
        Action = 'Transfer',
        Recipient = from,
        Quantity = quantity,
        Error = 'Add-Funding Error: ' .. errorMessage
      })
    end
    return not error
  end
  
  -- @dev validates removeFunding
  function CPMMHelpers:validateRemoveFunding(from, quantity)
    local error = false
    local errorMessage = ''
    -- Get balance
    local balance = self.token.balances[from] or '0'
    -- Check for errors
    if from == self.creatorFeeTarget and self.payoutDenominator[self.conditionId] and self.payoutDenominator[self.conditionId] == 0 then
      error = true
      errorMessage = 'Creator liquidity locked until market resolution!'
    elseif not bint.__le(bint(quantity), bint(balance)) then
      error = true
      errorMessage = 'Quantity must be less than balance!'
    end
    -- Return funds on error.
    if error then
      ao.send({
        Target = ao.id,
        Action = 'Transfer',
        Recipient = from,
        Quantity = quantity,
        Error = errorMessage
      })
    end
    return not error
  end
  
  -- @dev get pool balances
  function CPMMHelpers:getPoolBalances()
    -- Get poolBalances
    local selves = {}
    for _ = 1, #self.tokens.positionIds do
      table.insert(selves, ao.id)
    end
    local poolBalances = self.tokens:getBatchBalance(selves, self.tokens.positionIds)
    return poolBalances
  end
  
  return CPMMHelpers
  end
  
  _G.package.loaded["modules.cpmmHelpers"] = _loaded_mod_modules_cpmmHelpers()
  
  -- module: "modules.cpmmNotices"
  local function _loaded_mod_modules_cpmmNotices()
  local ao = require('.ao')
  local json = require('json')
  
  local CPMMNotices = {}
  
  function CPMMNotices.newMarketNotice(configurator, incentives, collateralToken, marketId, conditionId, positionIds, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
    return msg.reply({
      Action = "New-Market-Notice",
      MarketId = marketId,
      ConditionId = conditionId,
      Configurator = configurator,
      Incentives = incentives,
      CollateralToken = collateralToken,
      PositionIds = json.encode(positionIds),
      OutcomeSlotCount = tostring(outcomeSlotCount),
      LpFee = lpFee,
      CreatorFee = creatorFee,
      CreatorFeeTarget = creatorFeeTarget,
      ProtocolFee = protocolFee,
      ProtocolFeeTarget = protocolFeeTarget,
      Name = name,
      Ticker = ticker,
      Logo = logo,
      Data = "Successfully created market"
    })
  end
  
  function CPMMNotices.fundingAddedNotice(from, fundingAdded, mintAmount)
    return ao.send({
      Target = from,
      Action = "Funding-Added-Notice",
      FundingAdded = json.encode(fundingAdded),
      MintAmount = tostring(mintAmount),
      Data = "Successfully added funding"
    })
  end
  
  function CPMMNotices.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
    return ao.send({
      Target = from,
      Action = "Funding-Removed-Notice",
      SendAmounts = json.encode(sendAmounts),
      CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool),
      SharesToBurn = tostring(sharesToBurn),
      Data = "Successfully removed funding"
    })
  end
  
  function CPMMNotices.buyNotice(from, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
    return ao.send({
      Target = from,
      Action = "Buy-Notice",
      InvestmentAmount = tostring(investmentAmount),
      FeeAmount = tostring(feeAmount),
      PositionId = positionId,
      OutcomeTokensToBuy = tostring(outcomeTokensToBuy),
      Data = "Successful buy order"
    })
  end
  
  function CPMMNotices.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
    return ao.send({
      Target = from,
      Action = "Sell-Notice",
      ReturnAmount = tostring(returnAmount),
      FeeAmount = tostring(feeAmount),
      PositionId = positionId,
      OutcomeTokensToSell = tostring(outcomeTokensToSell),
      Data = "Successful sell order"
    })
  end
  
  function CPMMNotices.updateConfiguratorNotice(configurator, msg)
    return msg.reply({
      Action = "Configurator-Updated",
      Data = configurator
    })
  end
  
  function CPMMNotices.updateIncentivesNotice(incentives, msg)
    return msg.reply({
      Action = "Incentives-Updated",
      Data = incentives
    })
  end
  
  function CPMMNotices.updateTakeFeeNotice(creatorFee, protocolFee, takeFee, msg)
    return msg.reply({
      Action = "Take-Fee-Updated",
      CreatorFee = tostring(creatorFee),
      ProtocolFee = tostring(protocolFee),
      Data = tostring(takeFee)
    })
  end
  
  function CPMMNotices.updateProtocolFeeTargetNotice(protocolFeeTarget, msg)
    return msg.reply({
      Action = "Protocol-Fee-Target-Updated",
      Data = protocolFeeTarget
    })
  end
  
  function CPMMNotices.updateLogoNotice(logo, msg)
    return msg.reply({
      Action = "Logo-Updated",
      Data = logo
    })
  end
  
  return CPMMNotices
  end

  _G.package.loaded["modules.cpmmNotices"] = _loaded_mod_modules_cpmmNotices()

  -- module: "modules.cpmm"
  local function _loaded_mod_modules_cpmm()
  local json = require('json')
  local bint = require('.bint')(256)
  local ao = require('.ao')
  local utils = require(".utils")
  local token = require('modules.token')
  local conditionalTokens = require('modules.conditionalTokens')
  local CPMMHelpers = require('modules.cpmmHelpers')
  
  local CPMM = {}
  local CPMMMethods = require('modules.cpmmNotices')
  local LPToken = {}
  local ConditionalTokens = {}
  
  -- Constructor for CPMM 
  function CPMM:new()
    -- Initialize Tokens and store the object
    LPToken = token:new()
    ConditionalTokens = conditionalTokens:new()
    -- Create a new CPMM object
    local obj = {
      -- Market vars
      marketId = '',
      incentives = '',
      configurator = '',
      initialized = false,
      -- CPMM vars
      poolBalances = {},
      withdrawnFees = {},
      feePoolWeight = '0',
      totalWithdrawnFees = '0',
      -- ConditionalTokens vars
      tokens = ConditionalTokens,
      -- LP vars
      token = LPToken,
      lpFee = 0
    }
  
    -- Set metatable for method lookups
    setmetatable(obj, {
      __index = function(t, k)
        -- First, look up the key in CPMMMethods
        if CPMMMethods[k] then
          return CPMMMethods[k]
        -- Then, check in CPMMHelpers
        elseif CPMMHelpers[k] then
          return CPMMHelpers[k]
        -- Then, look up the key in the ConditionalTokens methods
        elseif ConditionalTokens[k] then
          return ConditionalTokens[k]
        -- Lastly, look up the key in the Config methods
        elseif Config[k] then
          return Config[k]
        else
          return nil
        end
      end
    })
    return obj
  end
  
  ---------------------------------------------------------------------------------
  -- FUNCTIONS --------------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Init
  function CPMMMethods:init(configurator, incentives, collateralToken, marketId, conditionId, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
    -- Generate Position Ids
    local positionIds = self.getPositionIds(tonumber(outcomeSlotCount))
    -- Set Conditional Tokens vars
    self.tokens.conditionId = conditionId
    self.tokens.positionIds = positionIds
    self.tokens.outcomeSlotCount = outcomeSlotCount
    self.tokens.collateralToken = collateralToken
    self.tokens.creatorFee = tonumber(creatorFee)
    self.tokens.creatorFeeTarget = creatorFeeTarget
    self.tokens.protocolFee = tonumber(protocolFee)
    self.tokens.protocolFeeTarget = protocolFeeTarget
    -- Set LP Token vars
    self.token.name = name
    self.token.ticker = ticker
    self.token.logo = logo
    -- Initialized
    self.marketId = marketId
    self.initialized = true
    self.configurator = configurator
    self.incentives = incentives
    self.lpFee = tonumber(lpFee)
    -- Prepare Condition
    self.tokens:prepareCondition(conditionId, outcomeSlotCount, msg)
    -- Init CPMM with market details
    return self.newMarketNotice(configurator, incentives, collateralToken, marketId, conditionId, positionIds, outcomeSlotCount, name, ticker, logo, lpFee, creatorFee, creatorFeeTarget, protocolFee, protocolFeeTarget, msg)
  end
  
  -- Add Funding 
  -- @dev: TODO: test the use of distributionHint to set the initial probability distribuiton
  -- @dev: TODO: test that adding subsquent funding does not alter the probability distribution
  function CPMMMethods:addFunding(from, onBehalfOf, addedFunds, distributionHint, msg)
    assert(bint.__lt(0, bint(addedFunds)), "funding must be non-zero")
    local sendBackAmounts = {}
    local poolShareSupply = self.token.totalSupply
    local mintAmount = '0'
  
    if bint.__lt(0, bint(poolShareSupply)) then
      -- Additional Liquidity 
      assert(#distributionHint == 0, "cannot use distribution hint after initial funding")
      -- Get poolBalances
      local poolBalances = self:getPoolBalances()
      -- Calculate poolWeight
      local poolWeight = 0
      for i = 1, #poolBalances do
        local balance = poolBalances[i]
        if bint.__lt(poolWeight, bint(balance)) then
          poolWeight = bint(balance)
        end
      end
      -- Calculate sendBackAmounts
      for i = 1, #poolBalances do
        local remaining = math.floor((addedFunds * poolBalances[i]) / poolWeight)
        sendBackAmounts[i] = addedFunds - remaining
      end
      -- Calculate mintAmount
      ---@diagnostic disable-next-line: param-type-mismatch
      mintAmount = tostring(math.floor(tostring(bint.__div(bint.__mul(addedFunds, poolShareSupply), poolWeight))))
    else
      -- Initial Liquidity
      if #distributionHint > 0 then
        local maxHint = 0
        for i = 1, #distributionHint do
          local hint = distributionHint[i]
          if maxHint < hint then
            maxHint = hint
          end
        end
        -- Calculate sendBackAmounts
        for i = 1, #distributionHint do
          local remaining = math.floor((addedFunds * distributionHint[i]) / maxHint)
          assert(remaining > 0, "must hint a valid distribution")
          sendBackAmounts[i] = addedFunds - remaining
        end
      end
      -- Calculate mintAmount
      mintAmount = tostring(addedFunds)
    end
    -- Mint Conditional Positions
    self.tokens:splitPosition(ao.id, self.tokens.collateralToken, addedFunds, msg)
    -- Mint LP Tokens
    self:mint(onBehalfOf, mintAmount, msg)
    -- Remove non-zero items before transfer-batch
    local nonZeroAmounts = {}
    local nonZeroPositionIds = {}
    for i = 1, #sendBackAmounts do
      if sendBackAmounts[i] > 0 then
        table.insert(nonZeroAmounts, tostring(math.floor(sendBackAmounts[i])))
        table.insert(nonZeroPositionIds, self.tokens.positionIds[i])
      end
    end
    -- Send back conditional tokens should there be an uneven distribution
    if #nonZeroAmounts ~= 0 then
      self.tokens:transferBatch(ao.id, onBehalfOf, nonZeroPositionIds, nonZeroAmounts, true, msg)
    end
    -- Transform sendBackAmounts to array of amounts added
    for i = 1, #sendBackAmounts do
      sendBackAmounts[i] = addedFunds - sendBackAmounts[i]
    end
    -- Send notice with amounts added
    return self.fundingAddedNotice(from, sendBackAmounts, mintAmount)
  end
  
  -- Remove Funding 
  function CPMMMethods:removeFunding(from, sharesToBurn, msg)
    assert(bint.__lt(0, bint(sharesToBurn)), "funding must be non-zero")
    -- Get poolBalances
    local poolBalances = self:getPoolBalances()
    -- Calculate sendAmounts
    local sendAmounts = {}
    for i = 1, #poolBalances do
      sendAmounts[i] = tostring(math.floor((poolBalances[i] * sharesToBurn) / self.token.totalSupply))
    end
    -- Calculate collateralRemovedFromFeePool
    local collateralRemovedFromFeePool = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
    self:burn(from, sharesToBurn, msg)
    local poolFeeBalance = ao.send({Target = self.tokens.collateralToken, Action = 'Balance'}).receive().Data
    collateralRemovedFromFeePool = tostring(math.floor(poolFeeBalance - collateralRemovedFromFeePool))
    -- Send collateralRemovedFromFeePool
    if bint(collateralRemovedFromFeePool) > 0 then
      ao.send({ Target = self.tokens.collateralToken, Action = "Transfer", Recipient=from, Quantity=collateralRemovedFromFeePool})
    end
    -- Send conditionalTokens amounts
    self.tokens:transferBatch(ao.id, from, self.tokens.positionIds, sendAmounts, false, msg)
    -- Send notice
    return self.fundingRemovedNotice(from, sendAmounts, collateralRemovedFromFeePool, sharesToBurn)
  end
  
  -- Calc Buy Amount 
  function CPMMMethods:calcBuyAmount(investmentAmount, positionId)
    assert(bint.__lt(0, investmentAmount), 'InvestmentAmount must be greater than zero!')
    assert(utils.includes(positionId, self.tokens.positionIds), 'PositionId must be valid!')
  
    local poolBalances = self:getPoolBalances()
    local investmentAmountMinusFees = investmentAmount - ((investmentAmount * self.lpFee) / 1e4) -- converts fee from basis points to decimal
    local buyTokenPoolBalance = poolBalances[tonumber(positionId)]
    local endingOutcomeBalance = buyTokenPoolBalance * 1e4
  
    for i = 1, #poolBalances do
      if not bint.__eq(bint(i), bint(positionId)) then
        local poolBalance = poolBalances[i]
        endingOutcomeBalance = CPMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance + investmentAmountMinusFees))
      end
    end
  
    assert(endingOutcomeBalance > 0, "must have non-zero balances")
    return tostring(bint.ceil(buyTokenPoolBalance + investmentAmountMinusFees - CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4)))
  end
  
  -- Calc Sell Amount
  function CPMMMethods:calcSellAmount(returnAmount, positionId)
    assert(bint.__lt(0, returnAmount), 'ReturnAmount must be greater than zero!')
    assert(utils.includes(positionId, self.tokens.positionIds), 'PositionId must be valid!')
  
    local poolBalances = self:getPoolBalances()
    local returnAmountPlusFees = CPMMHelpers.ceildiv(tonumber(returnAmount * 1e4), tonumber(1e4 - self.lpFee))
    local sellTokenPoolBalance = poolBalances[tonumber(positionId)]
    local endingOutcomeBalance = sellTokenPoolBalance * 1e4
  
    for i = 1, #poolBalances do
      if not bint.__eq(bint(i), bint(positionId)) then
        local poolBalance = poolBalances[i]
        assert(poolBalance - returnAmountPlusFees > 0, "PoolBalance must be greater than return amount plus fees!")
        endingOutcomeBalance = CPMMHelpers.ceildiv(tonumber(endingOutcomeBalance * poolBalance), tonumber(poolBalance - returnAmountPlusFees))
      end
    end
  
    assert(endingOutcomeBalance > 0, "must have non-zero balances")
    return tostring(bint.ceil(returnAmountPlusFees + CPMMHelpers.ceildiv(endingOutcomeBalance, 1e4) - sellTokenPoolBalance))
  end
  
  -- Buy 
  function CPMMMethods:buy(from, onBehalfOf, investmentAmount, positionId, minOutcomeTokensToBuy, msg)
    local outcomeTokensToBuy = self:calcBuyAmount(investmentAmount, positionId)
    assert(bint.__le(minOutcomeTokensToBuy, bint(outcomeTokensToBuy)), "Minimum outcome tokens not reached!")
    -- Calculate investmentAmountMinusFees.
    local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(investmentAmount, self.lpFee), 1e4)))
    self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
    local investmentAmountMinusFees = tostring(bint.__sub(investmentAmount, bint(feeAmount)))
    -- Split position through all conditions
    self.tokens:splitPosition(ao.id, self.tokens.collateralToken, investmentAmountMinusFees, msg)
    -- Transfer buy position to sender
    self.tokens:transferSingle(ao.id, from, positionId, outcomeTokensToBuy, false, msg)
    -- Send notice.
    return self.buyNotice(from, investmentAmount, feeAmount, positionId, outcomeTokensToBuy)
  end
  
  -- Sell 
  function CPMMMethods:sell(from, returnAmount, positionId, quantity, maxOutcomeTokensToSell, msg)
    -- Calculate outcome tokens to sell.
    local outcomeTokensToSell = self:calcSellAmount(returnAmount, positionId)
    assert(bint.__le(bint(outcomeTokensToSell), bint(maxOutcomeTokensToSell)), "Maximum sell amount exceeded!")
    -- Calculate returnAmountPlusFees.
    local feeAmount = tostring(bint.ceil(bint.__div(bint.__mul(returnAmount, self.lpFee), bint.__sub(1e4, self.lpFee))))
    self.feePoolWeight = tostring(bint.__add(bint(self.feePoolWeight), bint(feeAmount)))
    local returnAmountPlusFees = tostring(bint.__add(returnAmount, bint(feeAmount)))
    -- Check sufficient liquidity within the process or revert.
    local collataralBalance = ao.send({Target = self.tokens.collateralToken, Action = "Balance"}).receive().Data
    assert(bint.__le(bint(returnAmountPlusFees), bint(collataralBalance)), "Insufficient liquidity!")
    -- Check user balance and transfer outcomeTokensToSell to process before merge.
    local balance = self.tokens:getBalance(from, nil, positionId)
    assert(bint.__le(bint(quantity), bint(balance)), 'Insufficient balance!')
    self.tokens:transferSingle(from, ao.id, positionId, outcomeTokensToSell, true, msg)
    -- Merge positions through all conditions (burns returnAmountPlusFees).
    self.tokens:mergePositions(ao.id, '', returnAmountPlusFees, true, msg)
    -- Returns collateral to the user
    ao.send({
      Target = self.tokens.collateralToken,
      Action = "Transfer",
      Quantity = returnAmount,
      Recipient = from
    }).receive()
    -- Returns unburned conditional tokens to user 
    local unburned = tostring(bint.__sub(bint(quantity), bint(returnAmountPlusFees)))
    self.tokens:transferSingle(ao.id, from, positionId, unburned, true, msg)
    -- Send notice (Process continued via "SellOrderCompletionCollateralToken" and "SellOrderCompletionConditionalTokens" handlers)
    return self.sellNotice(from, returnAmount, feeAmount, positionId, outcomeTokensToSell)
  end
  
  -- Fees
  -- @dev Returns the total fees collected within the CPMM
  function CPMMMethods:collectedFees()
    return tostring(self.feePoolWeight - self.totalWithdrawnFees)
  end
  
  -- @dev Returns the fees withdrawable by the sender
  function CPMMMethods:feesWithdrawableBy(sender)
    local balance = self.token.balances[sender] or '0'
    local rawAmount = '0'
    if bint(self.token.totalSupply) > 0 then
      rawAmount = string.format('%.0f', (bint.__div(bint.__mul(bint(self:collectedFees()), bint(balance)), self.token.totalSupply)))
    end
  
    -- @dev max(rawAmount - withdrawnFees, 0)
    return tostring(bint.max(bint(bint.__sub(bint(rawAmount), bint(self.withdrawnFees[sender] or '0'))), 0))
  end
  
  -- @dev Withdraws fees to the sender
  function CPMMMethods:withdrawFees(sender, msg)
    local feeAmount = self:feesWithdrawableBy(sender)
    if bint.__lt(0, bint(feeAmount)) then
      self.withdrawnFees[sender] = feeAmount
      self.totalWithdrawnFees = tostring(bint.__add(bint(self.totalWithdrawnFees), bint(feeAmount)))
      msg.forward(self.tokens.collateralToken, {Action = 'Transfer', Recipient = sender, Quantity = feeAmount})
    end
    return feeAmount
  end
  
  -- @dev Updates fee accounting before token transfers
  function CPMMMethods:_beforeTokenTransfer(from, to, amount, msg)
    if from ~= nil then
      self:withdrawFees(from, msg)
    end
    local totalSupply = self.token.totalSupply
    local withdrawnFeesTransfer = totalSupply == '0' and amount or tostring(bint(bint.__div(bint.__mul(bint(self:collectedFees()), amount), totalSupply)))
  
    if from ~= nil and to ~= nil then
      self.withdrawnFees[from] = tostring(bint.__sub(bint(self.withdrawnFees[from] or '0'), withdrawnFeesTransfer))
      self.withdrawnFees[to] = tostring(bint.__add(bint(self.withdrawnFees[to] or '0'), withdrawnFeesTransfer))
    end
  end
  
  -- LP Tokens
  -- @dev See tokensMethods:mint & _beforeTokenTransfer
  function CPMMMethods:mint(to, quantity, msg)
    self:_beforeTokenTransfer(nil, to, quantity, msg)
    return self.token:mint(to, quantity, msg)
  end
  
  -- @dev See tokenMethods:burn & _beforeTokenTransfer
  function CPMMMethods:burn(from, quantity, msg)
    self:_beforeTokenTransfer(from, nil, quantity, msg)
    return self.token:burn(from, quantity, msg)
  end
  
  -- @dev See tokenMethods:transfer & _beforeTokenTransfer
  function CPMMMethods:transfer(from, recipient, quantity, cast, msg)
    self:_beforeTokenTransfer(from, recipient, quantity, msg)
    return self.token:transfer(from, recipient, quantity, cast, msg)
  end
  
  -- @dev updates configurator
  function CPMMMethods:updateConfigurator(configurator, msg)
    self.configurator = configurator
    return self.updateConfiguratorNotice(configurator, msg)
  end
  
  -- @dev updates incentives
  function CPMMMethods:updateIncentives(incentives, msg)
    self.incentives = incentives
    return self.updateIncentivesNotice(incentives, msg)
  end
  
  -- @dev Updates the take fee
  function CPMMMethods:updateTakeFee(creatorFee, protocolFee, msg)
    self.tokens.creatorFee = creatorFee
    self.tokens.protocolFee = protocolFee
    return self.updateTakeFeeNotice(creatorFee, protocolFee, creatorFee + protocolFee, msg)
  end
  
  -- @dev Updtes the protocol fee target
  function CPMMMethods:updateProtocolFeeTarget(target, msg)
    self.tokens.protocolFeeTarget = target
    return self.updateProtocolFeeTargetNotice(target, msg)
  end
  
  -- @dev Updtes the logo
  function CPMMMethods:updateLogo(logo, msg)
    self.token.logo = logo
    self.tokens.logo = logo
    return self.updateLogoNotice(logo, msg)
  end
  
  return CPMM
  end
  
  _G.package.loaded["modules.cpmm"] = _loaded_mod_modules_cpmm()
  
  -- module: "modules.sharedUtils"
  local function _loaded_mod_modules_sharedUtils()
  local sharedUtils = {}
  
  -- Function to validate if the extracted value is a valid JSON simple value
  local function isSimpleValue(value)
    -- Trim whitespace
    value = value:match("^%s*(.-)%s*$") or value
  
    -- Check for a quoted string: "someValue"
    if value:match('^"[^"]*"$') then
      return true
    end
  
    -- Check for a number (integer or float, optional minus sign): 123, -123, 123.45
    if value:match('^[-]?%d+%.?%d*$') then
      return true
    end
  
    -- Check for boolean
    if value == "true" or value == "false" then
      return true
    end
  
    return false
  end
  
  function sharedUtils.isValidKeyValueJSON(str)
    if type(str) ~= "string" then return false end
  
    -- Trim whitespace
    str = str:match("^%s*(.-)%s*$")
  
    -- Ensure it starts with `{` and ends with `}`
    local isObject = str:match("^%{%s*(.-)%s*%}$")
    if not isObject then return false end
  
    -- This pattern only extracts the key and the entire raw value
    local keyValuePattern = '^%s*"([^"]+)"%s*:%s*(.-)%s*$'
  
    -- Check all key-value pairs
    for keyValue in isObject:gmatch("[^,]+") do
      local key, rawValue = keyValue:match(keyValuePattern)
      if not key or not rawValue then
        return false
      end
  
      -- Now validate that rawValue is a valid JSON simple value
      if not isSimpleValue(rawValue) then
        return false
      end
    end
  
    return true
  end
  
  function sharedUtils.isJSONArray(str)
    if type(str) ~= "string" then return false end
  
    -- Trim whitespace
    str = str:match("^%s*(.-)%s*$")
  
    -- Ensure it starts with `[` and ends with `]`
    local isArray = str:match("^%[%s*(.-)%s*%]$")
    if not isArray then return false end
  
    -- Split the array elements and validate each one
    for value in isArray:gmatch("[^,]+") do
      value = value:match("^%s*(.-)%s*$") -- Trim whitespace around each value
      if not isSimpleValue(value) then
        return false
      end
    end
  
    return true
  end
  
  function sharedUtils.isValidArweaveAddress(address)
    return type(address) == "string" and #address == 43 and string.match(address, "^[%w-_]+$") ~= nil
  end
  
  return sharedUtils
  end
  
  _G.package.loaded["modules.sharedUtils"] = _loaded_mod_modules_sharedUtils()
  
  -- module: "modules.cpmmValidation"
  local function _loaded_mod_modules_cpmmValidation()
  local bint = require('.bint')(256)
  local utils = require('.utils')
  local sharedUtils = require('modules.sharedUtils')
  
  local cpmmValidation = {}
  
  local function validateAddress(recipient, tagName)
    assert(type(recipient) == 'string', tagName .. ' is required!')
    assert(sharedUtils.isValidArweaveAddress(recipient), tagName .. ' must be a valid Arweave address!')
  end
  
  local function validatePositionId(positionId, validPositionIds)
    assert(type(positionId) == 'string', 'PositionId is required!')
    assert(utils.includes(positionId, validPositionIds), 'Invalid positionId!')
  end
  
  local function validatePositiveInteger(quantity, tagName)
    assert(type(quantity) == 'string', tagName .. ' is required!')
    assert(tonumber(quantity), tagName .. ' must be a number!')
    assert(tonumber(quantity) > 0, tagName .. ' must be greater than zero!')
    assert(tonumber(quantity) % 1 == 0, tagName .. ' must be an integer!')
  end
  
  function cpmmValidation.init(msg, isInitialized)
    -- ownable.onlyOwner(msg) -- access control TODO: test after spawning is enabled
    assert(isInitialized == false, "Market already initialized!")
    assert(msg.Tags.MarketId, "MarketId is required!")
    assert(msg.Tags.ConditionId, "ConditionId is required!")
    validateAddress(msg.Tags.CollateralToken, "CollateralToken")
    validatePositiveInteger(msg.Tags.OutcomeSlotCount, "OutcomeSlotCount")
    local outcomeSlotCount = tonumber(msg.Tags.OutcomeSlotCount)
    -- Limit of 256 because we use a partition array that is a number of 256 bits.
    assert(outcomeSlotCount <= 256, "Too many outcome slots!")
    assert(outcomeSlotCount > 1, "There should be more than one outcome slot!")
    -- LP Token Parameters
    assert(msg.Tags.Name, "Name is required!")
    assert(msg.Tags.Ticker, "Ticker is required!")
    assert(msg.Tags.Logo, "Logo is required!")
    -- Fee Parameters
    validatePositiveInteger(msg.Tags.LpFee, "LpFee")
    validatePositiveInteger(msg.Tags.CreatorFee, "CreatorFee")
    validatePositiveInteger(msg.Tags.ProtocolFee, "ProtocolFee")
    validateAddress(msg.Tags.CreatorFeeTarget, "CreatorFeeTarget")
    validateAddress(msg.Tags.ProtocolFeeTarget, "ProtocolFeeTarget")
    -- Take Fee Capped at 1000 bps, ie. 10%
    assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Take Fee capped at 10%!')
    -- Admin Parameter
    validateAddress(msg.Tags.Configurator, "Configurator")
    -- Incentives
    validateAddress(msg.Tags.Incentives, "Incentives")
    -- @dev TODO: include "resolve-by" field to enable fallback resolution
  end
  
  function cpmmValidation.addFunding(msg)
    validatePositiveInteger(msg.Tags.Quantity, "Quantity")
    assert(msg.Tags['X-Distribution'], 'X-Distribution is required!')
    assert(sharedUtils.isJSONArray(msg.Tags['X-Distribution']), 'X-Distribution must be valid JSON Array!')
    -- @dev TODO: remove requirement for X-Distribution
  end
  
  function cpmmValidation.removeFunding(msg)
    validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  end
  
  function cpmmValidation.buy(msg, validPositionIds)
    validatePositionId(msg.Tags.PositionId, validPositionIds)
    validatePositiveInteger(msg.Tags.Quantity, "Quantity")
  end
  
  function cpmmValidation.sell(msg, validPositionIds)
    validatePositionId(msg.Tags.PositionId, validPositionIds)
    validatePositiveInteger(msg.Tags.Quantity, "Quantity")
    validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
    validatePositiveInteger(msg.Tags.MaxOutcomeTokensToSell, "MaxOutcomeTokensToSell")
  end
  
  function cpmmValidation.calcBuyAmount(msg, validPositionIds)
    validatePositionId(msg.Tags.PositionId, validPositionIds)
    validatePositiveInteger(msg.Tags.InvestmentAmount, "InvestmentAmount")
  end
  
  function cpmmValidation.calcSellAmount(msg, validPositionIds)
    validatePositionId(msg.Tags.PositionId, validPositionIds)
    validatePositiveInteger(msg.Tags.ReturnAmount, "ReturnAmount")
  end
  
  function cpmmValidation.updateConfigurator(msg, configurator)
    assert(msg.From == configurator, 'Sender must be configurator!')
    assert(msg.Tags.Configurator, 'Configurator is required!')
  end
  
  function cpmmValidation.updateIncentives(msg, configurator)
    assert(msg.From == configurator, 'Sender must be configurator!')
    assert(msg.Tags.Incentives, 'Incentives is required!')
  end
  
  function cpmmValidation.updateTakeFee(msg, configurator)
    assert(msg.From == configurator, 'Sender must be configurator!')
    assert(msg.Tags.CreatorFee, 'CreatorFee is required!')
    assert(tonumber(msg.Tags.CreatorFee), 'CreatorFee must be a number!')
    assert(tonumber(msg.Tags.CreatorFee) >= 0, 'CreatorFee must be greater than or equal to zero!')
    assert(tonumber(msg.Tags.CreatorFee) % 1 == 0, 'CreatorFee must be an integer!')
    assert(msg.Tags.ProtocolFee, 'ProtocolFee is required!')
    assert(tonumber(msg.Tags.ProtocolFee), 'ProtocolFee must be a number!')
    assert(tonumber(msg.Tags.ProtocolFee) >= 0, 'ProtocolFee must be greater than or equal to zero!')
    assert(tonumber(msg.Tags.ProtocolFee) % 1 == 0, 'ProtocolFee must be an integer!')
    assert(bint.__le(bint.__add(bint(msg.Tags.CreatorFee), bint(msg.Tags.ProtocolFee)), 1000), 'Net fee must be less than or equal to 1000 bps')
  end
  
  function cpmmValidation.updateProtocolFeeTarget(msg, configurator)
    assert(msg.From == configurator, 'Sender must be configurator!')
    assert(msg.Tags.ProtocolFeeTarget, 'ProtocolFeeTarget is required!')
  end
  
  function cpmmValidation.updateLogo(msg, configurator)
    assert(msg.From == configurator, 'Sender must be configurator!')
    assert(msg.Tags.Logo, 'Logo is required!')
  end
  
  return cpmmValidation
  end
  
  _G.package.loaded["modules.cpmmValidation"] = _loaded_mod_modules_cpmmValidation()
  
  -- module: "modules.tokenValidation"
  local function _loaded_mod_modules_tokenValidation()
  local sharedUtils = require('modules.sharedUtils')
  
  local tokenValidation = {}
  
  function tokenValidation.transfer(msg)
    assert(type(msg.Tags.Recipient) == 'string', 'Recipient is required!')
    assert(sharedUtils.isValidArweaveAddress(msg.Tags.Recipient), 'Recipient must be a valid Arweave address!')
    assert(type(msg.Tags.Quantity) == 'string', 'Quantity is required!')
    assert(tonumber(msg.Tags.Quantity), 'Quantity must be a number!')
    assert(tonumber(msg.Tags.Quantity) > 0, 'Quantity must be greater than zero!')
    assert(tonumber(msg.Tags.Quantity) % 1 == 0, 'Quantity must be an integer!')
  end
  
  return tokenValidation
  end
  
  _G.package.loaded["modules.tokenValidation"] = _loaded_mod_modules_tokenValidation()
  
  -- module: "modules.semiFungibleTokensValidation"
  local function _loaded_mod_modules_semiFungibleTokensValidation()
  local json = require("json")
  local bint = require('.bint')(256)
  local utils = require('.utils')
  local sharedUtils = require('modules.sharedUtils')
  
  local semiFungibleTokensValidation = {}
  
  local function validateRecipient(recipient)
    assert(type(recipient) == 'string', 'Recipient is required!')
    assert(sharedUtils.isValidArweaveAddress(recipient), 'Recipient must be a valid Arweave address!')
  end
  
  local function validateTokenId(tokenId, validTokenIds)
    assert(type(tokenId) == 'string', 'TokenId is required!')
    assert(utils.includes(tokenId, validTokenIds), 'Invalid tokenId!')
  end
  
  local function validateQuantity(quantity)
    assert(type(quantity) == 'string', 'Quantity is required!')
    assert(tonumber(quantity), 'Quantity must be a number!')
    assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
    assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
  end
  
  function semiFungibleTokensValidation.transferSingle(msg, validTokenIds)
    validateRecipient(msg.Tags.Recipient)
    validateTokenId(msg.Tags.TokenId, validTokenIds)
    validateQuantity(msg.Tags.Quantity)
  end
  
  function semiFungibleTokensValidation.transferBatch(msg, validTokenIds)
    validateRecipient(msg.Tags.Recipient)
    assert(type(msg.Tags.TokenIds) == 'string', 'TokenIds is required!')
    local tokenIds = json.decode(msg.Tags.TokenIds)
    assert(type(msg.Tags.Quantities) == 'string', 'Quantities is required!')
    local quantities = json.decode(msg.Tags.Quantities)
    assert(#tokenIds == #quantities, 'Input array lengths must match!')
    assert(#tokenIds > 0, "Input array length must be greater than zero!")
    for i = 1, #tokenIds do
      validateTokenId(tokenIds[i], validTokenIds)
      validateQuantity(quantities[i])
    end
  end
  
  function semiFungibleTokensValidation.balanceById(msg, validTokenIds)
    validateTokenId(msg.Tags.TokenId, validTokenIds)
  end
  
  function semiFungibleTokensValidation.balancesById(msg, validTokenIds)
    validateTokenId(msg.Tags.TokenId, validTokenIds)
  end
  
  function semiFungibleTokensValidation.batchBalance(msg, validTokenIds)
    assert(msg.Tags.Recipients, "Recipients is required!")
    local recipients = json.decode(msg.Tags.Recipients)
    assert(msg.Tags.TokenIds, "TokenIds is required!")
    local tokenIds = json.decode(msg.Tags.TokenIds)
    assert(#recipients == #tokenIds, "Input array lengths must match!")
    assert(#recipients > 0, "Input array length must be greater than zero!")
    for i = 1, #tokenIds do
      validateRecipient(recipients[i])
      validateTokenId(tokenIds[i], validTokenIds)
    end
  end
  
  function semiFungibleTokensValidation.batchBalances(msg, validTokenIds)
    assert(msg.Tags.TokenIds, "TokenIds is required!")
    local tokenIds = json.decode(msg.Tags.TokenIds)
    assert(#tokenIds > 0, "Input array length must be greater than zero!")
    for i = 1, #tokenIds do
      validateTokenId(tokenIds[i], validTokenIds)
    end
  end
  
  return semiFungibleTokensValidation
  end
  
  _G.package.loaded["modules.semiFungibleTokensValidation"] = _loaded_mod_modules_semiFungibleTokensValidation()
  
  -- module: "modules.conditionalTokensValidation"
  local function _loaded_mod_modules_conditionalTokensValidation()
  local sharedUtils = require('modules.sharedUtils')
  local json = require('json')
  local conditionalTokensValidation = {}
  
  local function validateQuantity(quantity)
    assert(type(quantity) == 'string', 'Quantity is required!')
    assert(tonumber(quantity), 'Quantity must be a number!')
    assert(tonumber(quantity) > 0, 'Quantity must be greater than zero!')
    assert(tonumber(quantity) % 1 == 0, 'Quantity must be an integer!')
  end
  
  local function validatePayouts(payouts)
    assert(payouts, "Payouts is required!")
    assert(sharedUtils.isJSONArray(payouts), "Payouts must be valid JSON Array!")
    for _, payout in ipairs(json.decode(payouts)) do
      assert(tonumber(payout), "Payouts item must be a number!")
    end
  end
  
  function conditionalTokensValidation.mergePositions(msg)
    validateQuantity(msg.Tags.Quantity)
  end
  
  function conditionalTokensValidation.reportPayouts(msg)
    assert(msg.Tags.QuestionId, "QuestionId is required!")
    validatePayouts(msg.Tags.Payouts)
  end
  
  return conditionalTokensValidation
  end
  
  _G.package.loaded["modules.conditionalTokensValidation"] = _loaded_mod_modules_conditionalTokensValidation()
  
  -- module: "modules.market"
  local function _loaded_mod_modules_market()
  -- reference: https://github.com/gnosis/conditional-tokens-contracts/blob/master/contracts/ConditionalTokens.sol
  local ao = require('.ao')
  local json = require('json')
  local bint = require('.bint')(256)
  local cpmm = require('modules.cpmm')
  local cpmmValidation = require('modules.cpmmValidation')
  local tokenValidation = require('modules.tokenValidation')
  local semiFungibleTokensValidation = require('modules.semiFungibleTokensValidation')
  local conditionalTokensValidation = require('modules.conditionalTokensValidation')
  ---------------------------------------------------------------------------------
  -- MARKET -----------------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  local Market = {}
  local MarketMethods = {}
  
  -- Constructor for Market 
  function Market:new()
    -- Create a new Market object
    local obj = {
      cpmm = cpmm:new()
    }
    setmetatable(obj, { __index = MarketMethods })
    return obj
  end
  
  ---------------------------------------------------------------------------------
  -- INFO HANDLER -----------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Info
  function MarketMethods:info(msg)
    msg.reply({
      Name = self.cpmm.token.name,
      Ticker = self.cpmm.token.ticker,
      Logo = self.cpmm.token.logo,
      Denomination = tostring(self.cpmm.token.denomination),
      ConditionId = self.cpmm.tokens.conditionId,
      PositionIds = json.encode(self.cpmm.tokens.positionIds),
      CollateralToken = self.cpmm.tokens.collateralToken,
      Configurator = self.cpmm.configurator,
      Incentives = self.cpmm.incentives,
      LpFee = tostring(self.cpmm.lpFee),
      LpFeePoolWeight = self.cpmm.feePoolWeight,
      LpFeeTotalWithdrawn = self.cpmm.totalWithdrawnFees,
      CreatorFee = tostring(self.cpmm.tokens.creatorFee),
      CreatorFeeTarget = self.cpmm.tokens.creatorFeeTarget,
      ProtocolFee = tostring(self.cpmm.tokens.protocolFee),
      ProtocolFeeTarget = self.cpmm.tokens.protocolFeeTarget
    })
  end
  
  ---------------------------------------------------------------------------------
  -- CPMM WRITE HANDLERS ----------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Init
  function MarketMethods:init(msg)
    cpmmValidation.init(msg, self.cpmm.initialized)
    self.cpmm:init(
      msg.Tags.Configurator,
      msg.Tags.Incentives,
      msg.Tags.CollateralToken,
      msg.Tags.MarketId,
      msg.Tags.ConditionId,
      tonumber(msg.Tags.OutcomeSlotCount),
      msg.Tags.Name,
      msg.Tags.Ticker,
      msg.Tags.Logo,
      msg.Tags.LpFee,
      msg.Tags.CreatorFee,
      msg.Tags.CreatorFeeTarget,
      msg.Tags.ProtocolFee,
      msg.Tags.ProtocolFeeTarget,
      msg)
  end
  
  -- Add Funding
  -- @dev called on credit-notice from collateralToken with X-Action == 'Add-Funding'
  function MarketMethods:addFunding(msg)
    cpmmValidation.addFunding(msg)
    local distribution = json.decode(msg.Tags['X-Distribution'])
    local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  
    -- @dev returns funding if invalid
    if self.cpmm:validateAddFunding(msg.Tags.Sender, msg.Tags.Quantity, distribution) then
      self.cpmm:addFunding(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, distribution, msg)
    end
  end
  
  -- Remove Funding
  -- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
  function MarketMethods:removeFunding(msg)
    cpmmValidation.removeFunding(msg)
    if self.cpmm:validateRemoveFunding(msg.Tags.Sender, msg.Tags.Quantity) then
      self.cpmm:removeFunding(msg.Tags.Sender, msg.Tags.Quantity, msg)
    end
  end
  
  -- Buy
  -- @dev called on credit-notice from collateralToken with X-Action == 'Buy'
  function MarketMethods:buy(msg)
    cpmmValidation.buy(msg, self.cpmm.positionIds)
    local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.Tags.Sender
  
    local error = false
    local errorMessage = ''
  
    local outcomeTokensToBuy = '0'
  
    if not msg.Tags['X-PositionId'] then
      error = true
      errorMessage = 'X-PositionId is required!'
    elseif not msg.Tags['X-MinOutcomeTokensToBuy'] then
      error = true
      errorMessage = 'X-MinOutcomeTokensToBuy is required!'
    else
      outcomeTokensToBuy = self.cpmm:calcBuyAmount(msg.Tags.Quantity, msg.Tags['X-PositionId'])
      if not bint.__le(bint(msg.Tags['X-MinOutcomeTokensToBuy']), bint(outcomeTokensToBuy)) then
        error = true
        errorMessage = 'minimum buy amount not reached'
      end
    end
  
    if error then
      -- Return funds and assert error
      ao.send({
        Target = ao.id,
        Action = 'Transfer',
        Recipient = msg.Tags.Sender,
        Quantity = msg.Tags.Quantity,
        Error = 'Buy Error: ' .. errorMessage
      })
      assert(false, errorMessage)
    else
      self.cpmm:buy(msg.Tags.Sender, onBehalfOf, msg.Tags.Quantity, msg.Tags['X-PositionId'], tonumber(msg.Tags['X-MinOutcomeTokensToBuy']), msg)
    end
  end
  
  -- Sell
  -- @dev refactoring as now within same process
  function MarketMethods:sell(msg)
    cpmmValidation.sell(msg, self.cpmm.positionIds)
    local outcomeTokensToSell = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
    assert(bint.__le(bint(outcomeTokensToSell), bint(msg.Tags.MaxOutcomeTokensToSell)), 'Maximum sell amount not sufficient!')
    self.cpmm:sell(msg.From, msg.Tags.ReturnAmount, msg.Tags.PositionId, msg.Tags.Quantity, tonumber(msg.Tags.MaxOutcomeTokensToSell), msg)
  end
  
  -- Withdraw Fees
  -- @dev Withdraws withdrawable fees to the message sender
  function MarketMethods:withdrawFees(msg)
    msg.reply({ Data = self.cpmm:withdrawFees(msg.From) })
  end
  
  ---------------------------------------------------------------------------------
  -- CPMM READ HANDLERS -----------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Calc Buy Amount
  function MarketMethods:calcBuyAmount(msg)
    cpmmValidation.calcBuyAmount(msg, self.cpmm.positionIds)
    local buyAmount = self.cpmm:calcBuyAmount(msg.Tags.InvestmentAmount, msg.Tags.PositionId)
    msg.reply({ Data = buyAmount })
  end
  
  -- -- Calc Sell Amount
  function MarketMethods:calcSellAmount(msg)
    cpmmValidation.calcSellAmount(msg, self.cpmm.positionIds)
    local sellAmount = self.cpmm:calcSellAmount(msg.Tags.ReturnAmount, msg.Tags.PositionId)
    msg.reply({ Data = sellAmount })
  end
  
  -- Collected Fees
  -- @dev Returns fees collected by the protocol that haven't been withdrawn
  function MarketMethods:collectedFees(msg)
    msg.reply({ Data = self.cpmm:collectedFees() })
  end
  
  -- Fees Withdrawable
  -- @dev Returns fees withdrawable by the message sender
  function MarketMethods:feesWithdrawable(msg)
    msg.reply({ Data = self.cpmm:feesWithdrawableBy(msg.From) })
  end
  
  ---------------------------------------------------------------------------------
  -- LP TOKEN WRITE HANDLERS ------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Transfer
  function MarketMethods:transfer(msg)
    tokenValidation.transfer(msg)
    self.cpmm:transfer(msg.From, msg.Tags.Recipient, msg.Tags.Quantity, msg.Tags.Cast, msg)
  end
  
  ---------------------------------------------------------------------------------
  -- LP TOKEN READ HANDLERS -------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Balance
  function MarketMethods:balance(msg)
    local bal = '0'
  
    -- If not Recipient is provided, then return the Senders balance
    if (msg.Tags.Recipient) then
      if (self.cpmm.token.balances[msg.Tags.Recipient]) then
        bal = self.cpmm.token.balances[msg.Tags.Recipient]
      end
    elseif msg.Tags.Target and self.cpmm.token.balances[msg.Tags.Target] then
      bal = self.cpmm.token.balances[msg.Tags.Target]
    elseif self.cpmm.token.balances[msg.From] then
      bal = self.cpmm.token.balances[msg.From]
    end
  
    return msg.reply({
      Balance = bal,
      Ticker = self.cpmm.token.ticker,
      Account = msg.Tags.Recipient or msg.From,
      Data = bal
    })
  end
  
  -- Balances
  function MarketMethods:balances(msg)
    return msg.reply({ Data = json.encode(self.cpmm.token.balances) })
  end
  
  -- Total Supply
  function MarketMethods:totalSupply(msg)
    return msg.reply({ Data = json.encode(self.cpmm.token.totalSupply) })
  end
  
  ---------------------------------------------------------------------------------
  -- CTF WRITE HANDLERS -----------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Merge Positions
  function MarketMethods:mergePositions(msg)
    conditionalTokensValidation.mergePositions(msg)
    local onBehalfOf = msg.Tags['X-OnBehalfOf'] or msg.From
    -- Check user balances
    local error = false
    local errorMessage = ''
    for i = 1, #self.cpmm.tokens.positionIds do
      if not self.cpmm.tokens.balancesById[self.cpmm.positionIds[i] ] then
        error = true
        errorMessage = "Invalid position! PositionId: " .. self.cpmm.positionIds[i]
      end
      if not self.cpmm.tokens.balancesById[self.cpmm.positionIds[i] ][msg.From] then
        error = true
        errorMessage = "Invalid user position! PositionId: " .. self.cpmm.positionIds[i]
      end
      if bint.__lt(bint(self.cpmm.tokens.balancesById[self.cpmm.positionIds[i] ][msg.From]), bint(msg.Tags.Quantity)) then
        error = true
        errorMessage = "Insufficient tokens! PositionId: " .. self.cpmm.positionIds[i]
      end
    end
    -- Revert with error or process merge.
    if error then
      return msg.reply({ Action = 'Error', Data = errorMessage })
    else
      return self.cpmm.tokens:mergePositions(msg.From, onBehalfOf, msg.Tags.Quantity, false, msg)
    end
  end
  
  -- Report Payouts
  function MarketMethods:reportPayouts(msg)
    conditionalTokensValidation.reportPayouts(msg)
    local payouts = json.decode(msg.Tags.Payouts)
    return self.cpmm.tokens:reportPayouts(msg.Tags.QuestionId, payouts, msg)
  end
  
  -- Redeem Positions
  function MarketMethods:redeemPositions(msg)
    return self.cpmm.tokens:redeemPositions(msg)
  end
  
  ---------------------------------------------------------------------------------
  -- CTF READ HANDLERS ------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Get Payout Numerators
  function MarketMethods:getPayoutNumerators(msg)
    local data = (self.cpmm.tokens.payoutNumerators[self.cpmm.conditionId] == nil) and
      nil or
      self.cpmm.tokens.payoutNumerators[self.cpmm.conditionId]
    return msg.reply({
      Action = "Payout-Numerators",
      ConditionId = self.cpmm.conditionId,
      Data = json.encode(data)
    })
  end
  
  -- Get Payout Denominator
  function MarketMethods:getPayoutDenominator(msg)
    return msg.reply({
      Action = "Payout-Denominator",
      ConditionId = self.cpmm.conditionId,
      Data = self.cpmm.tokens.payoutDenominator[self.cpmm.conditionId]
    })
  end
  
  ---------------------------------------------------------------------------------
  -- SEMI-FUNGIBLE TOKEN WRITE HANDLERS -------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Transfer Single
  function MarketMethods:transferSingle(msg)
    semiFungibleTokensValidation.transferSingle(msg, self.cpmm.tokens.positionIds)
    return self.cpmm.tokens:transferSingle(msg.From, msg.Tags.Recipient, msg.Tags.TokenId, msg.Tags.Quantity, msg.Tags.Cast, msg)
  end
  
  -- Transfer Batch
  function MarketMethods:transferBatch(msg)
    semiFungibleTokensValidation.transferBatch(msg, self.cpmm.tokens.positionIds)
    local tokenIds = json.decode(msg.Tags.TokenIds)
    local quantities = json.decode(msg.Tags.Quantities)
    return self.cpmm.tokens:transferBatch(msg.From, msg.Tags.Recipient, tokenIds, quantities, msg.Tags.Cast, msg)
  end
  
  ---------------------------------------------------------------------------------
  -- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Balance By Id
  function MarketMethods:balanceById(msg)
    semiFungibleTokensValidation.balanceById(msg, self.cpmm.tokens.positionIds)
    local account = msg.Tags.Recipient or msg.From
    local bal = self.cpmm:getBalance(msg.From, account, msg.Tags.TokenId)
    return msg.reply({
      Balance = bal,
      TokenId = msg.Tags.TokenId,
      Ticker = Ticker,
      Account = account,
      Data = bal
    })
  end
  
  -- Balances By Id
  function MarketMethods:balancesById(msg)
    semiFungibleTokensValidation.balancesById(msg, self.cpmm.tokens.positionIds)
    local bals = self.cpmm.tokens:getBalances(msg.Tags.TokenId)
    return msg.reply({ Data = bals })
  end
  
  -- Batch Balance (Filtered by users and ids)
  function MarketMethods:batchBalance(msg)
    semiFungibleTokensValidation.batchBalance(msg, self.cpmm.tokens.positionIds)
    local recipients = json.decode(msg.Tags.Recipients)
    local tokenIds = json.decode(msg.Tags.TokenIds)
    local bals = self.cpmm.tokens:getBatchBalance(recipients, tokenIds)
    return msg.reply({ Data = bals })
  end
  
  -- Batch Balances (Filtered by Ids, only)
  function MarketMethods:batchBalances(msg)
    semiFungibleTokensValidation.batchBalances(msg, self.cpmm.tokens.positionIds)
    local tokenIds = json.decode(msg.Tags.TokenIds)
    local bals = self.cpmm.tokens:getBatchBalances(tokenIds)
    return msg.reply({ Data = bals })
  end
  
  -- Balances All
  function MarketMethods:balancesAll(msg)
    return msg.reply({ Data = self.cpmm.tokens.balancesById })
  end
  
  ---------------------------------------------------------------------------------
  -- CONFIG HANDLERS --------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Update Configurator
  function MarketMethods:updateConfigurator(msg)
    cpmmValidation.updateConfigurator(msg, self.cpmm.configurator)
    return self.cpmm:updateConfigurator(msg.Tags.Configurator, msg)
  end
  
  -- Update Incentives
  function MarketMethods:updateIncentives(msg)
    cpmmValidation.updateIncentives(msg, self.cpmm.configurator)
    return self.cpmm:updateIncentives(msg.Tags.Incentives, msg)
  end
  
  -- Update Take Fee
  function MarketMethods:updateTakeFee(msg)
    cpmmValidation.updateTakeFee(msg, self.cpmm.configurator)
    return self.cpmm:updateTakeFee(tonumber(msg.Tags.CreatorFee), tonumber(msg.Tags.ProtocolFee), msg)
  end
  
  -- Update Protocol Fee Target
  function MarketMethods:updateProtocolFeeTarget(msg)
    cpmmValidation.updateProtocolFeeTarget(msg, self.cpmm.configurator)
    return self.cpmm:updateProtocolFeeTarget(msg.Tags.ProtocolFeeTarget, msg)
  end
  
  -- Update Logo
  function MarketMethods:updateLogo(msg)
    cpmmValidation.updateLogo(msg, self.cpmm.configurator)
    return self.cpmm:updateLogo(msg.Tags.Logo, msg)
  end
  
  ---------------------------------------------------------------------------------
  -- EVAL HANDLER -----------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Eval
  function MarketMethods:completeEval(msg)
    msg.forward('NRKvM8X3TqjGGyrqyB677aVbxgONo5fBHkbxbUSa_Ug', {
      Action = 'Eval-Completed',
      Data = 'Eval-Completed'
    })
  end
  
  return Market
  
  end
  
  _G.package.loaded["modules.market"] = _loaded_mod_modules_market()
  
  local ao = require('.ao')
  local market = require('modules.market')
  ---------------------------------------------------------------------------------
  -- MARKET -----------------------------------------------------------------------
  ---------------------------------------------------------------------------------
  Env = 'DEV'
  Version = '1.0.1'
  -- @dev Reset state while in DEV mode
  if not Market or Env == 'DEV' then Market = market:new() end
  -- @dev Expected LP Token namespace variables, set during `init`
  Name = ''
  Ticker = ''
  Logo = ''
  Denominator = nil
  ---------------------------------------------------------------------------------
  -- MATCHING ---------------------------------------------------------------------
  ---------------------------------------------------------------------------------
  -- CPMM
  local function isAddFunding(msg)
    if (
      msg.From == Market.cpmm.tokens.collateralToken and
      msg.Action == "Credit-Notice" and
      msg["X-Action"] == "Add-Funding"
    ) then
      return true
    else
      return false
    end
  end
  
  local function isRemoveFunding(msg)
    if (
      msg.From == ao.id and
      msg.Action == "Credit-Notice" and
      msg["X-Action"] == "Remove-Funding"
    ) then
      return true
    else
      return false
    end
  end
  
  local function isBuy(msg)
    if (
      msg.From == Market.cpmm.tokens.collateralToken and
      msg.Action == "Credit-Notice" and
      msg["X-Action"] == "Buy"
    ) then
      return true
    else
      return false
    end
  end
  
  ---------------------------------------------------------------------------------
  -- INFO HANDLER -----------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Info
  Handlers.add("Info", {Action = "Info"}, function(msg)
    Market:info(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- CPMM WRITE HANDLERS ----------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Init
  Handlers.add("Init", {Action = "Init"}, function(msg)
    Market:init(msg)
    -- Set LP Token namespace variables
    Name = Market.cpmm.token.name
    Ticker = Market.cpmm.token.ticker
    Logo = Market.cpmm.token.logo
    Denomination = Market.cpmm.token.denomination
  end)
  
  -- Add Funding
  Handlers.add('Add-Funding', isAddFunding, function(msg)
    Market:addFunding(msg)
  end)
  
  -- Remove Funding
  -- @dev called on credit-notice from ao.id with X-Action == 'Remove-Funding'
  Handlers.add("Remove-Funding", isRemoveFunding, function(msg)
    Market:removeFunding(msg)
  end)
  
  -- Buy
  -- @dev called on credit-notice from collateralToken with X-Action == 'Buy'
  Handlers.add("Buy", isBuy, function(msg)
    Market:buy(msg)
  end)
  
  -- Sell
  -- @dev refactoring as now within same process
  Handlers.add("Sell", {Action = "Sell"}, function(msg)
    Market:sell(msg)
  end)
  
  -- Withdraw Fees
  -- @dev Withdraws withdrawable fees to the message sender
  Handlers.add("Withdraw-Fees", {Action = "Withdraw-Fees"}, function(msg)
    Market:withdrawFees(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- CPMM READ HANDLERS -----------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Calc Buy Amount
  Handlers.add("Calc-Buy-Amount", {Action = "Calc-Buy-Amount"}, function(msg)
    Market:calcBuyAmount(msg)
  end)
  
  -- Calc Sell Amount
  Handlers.add("Calc-Sell-Amount", {Action = "Calc-Sell-Amount"}, function(msg)
    Market:calcSellAmount(msg)
  end)
  
  -- Collected Fees
  -- @dev Returns fees collected by the protocol that haven't been withdrawn
  Handlers.add("Collected-Fees", {Action = "Collected-Fees"}, function(msg)
    Market:collectedFees(msg)
  end)
  
  -- Fees Withdrawable
  -- @dev Returns fees withdrawable by the message sender
  Handlers.add("Fees-Withdrawable", {Action = "Fees-Withdrawable"}, function(msg)
    Market:feesWithdrawable(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- LP TOKEN WRITE HANDLERS ------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Transfer
  Handlers.add('Transfer', {Action = "Transfer"}, function(msg)
    Market:transfer(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- LP TOKEN READ HANDLERS -------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Balance
  Handlers.add('Balance', {Action = "Balance"}, function(msg)
    Market:balance(msg)
  end)
  
  -- Balances
  Handlers.add('Balances', {Action = "Balances"}, function(msg)
    Market:balances(msg)
  end)
  
  -- Total Supply
  Handlers.add('Total-Supply', {Action = "Total-Supply"}, function(msg)
    Market:totalSupply(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- CTF WRITE HANDLERS -----------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Merge Positions
  Handlers.add("Merge-Positions", {Action = "Merge-Positions"}, function(msg)
    Market:mergePositions(msg)
  end)
  
  -- Report Payouts
  Handlers.add("Report-Payouts", {Action = "Report-Payouts"}, function(msg)
    Market:reportPayouts(msg)
  end)
  
  -- Redeem Positions
  Handlers.add("Redeem-Positions", {Action = "Redeem-Positions"}, function(msg)
    Market:redeemPositions(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- CTF READ HANDLERS ------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Get Payout Numerators
  Handlers.add("Get-Payout-Numerators", {Action = "Get-Payout-Numerators"}, function(msg)
    Market:getPayoutNumerators(msg)
  end)
  
  -- Get Payout Denominator
  Handlers.add("Get-Payout-Denominator", {Action = "Get-Payout-Denominator"}, function(msg)
    Market:getPayoutDenominator(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- SEMI-FUNGIBLE TOKEN WRITE HANDLERS -------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Transfer Single
  Handlers.add('Transfer-Single', {Action = "Transfer-Single"}, function(msg)
    Market:transferSingle(msg)
  end)
  
  -- Transfer Batch
  Handlers.add('Transfer-Batch', {Action = "Transfer-Batch"}, function(msg)
    Market:transferBatch(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- SEMI-FUNGIBLE TOKEN READ HANDLERS --------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Balance By Id
  Handlers.add("Balance-By-Id", {Action = "Balance-By-Id"}, function(msg)
    Market:balanceById(msg)
  end)
  
  -- Balances By Id
  Handlers.add('Balances-By-Id', {Action = "Balances-By-Id"}, function(msg)
    Market:balancesById(msg)
  end)
  
  -- Batch Balance (Filtered by users and ids)
  Handlers.add("Batch-Balance", {Action = "Batch-Balance"}, function(msg)
    Market:batchBalance(msg)
  end)
  
  -- Batch Balances (Filtered by Ids, only)
  Handlers.add('Batch-Balances', {Action = "Batch-Balances"}, function(msg)
    Market:batchBalances(msg)
  end)
  
  -- Balances All
  Handlers.add('Balances-All', {Action = "Balances-All"}, function(msg)
    Market:balancesAll(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- CONFIG HANDLERS --------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Update Configurator
  Handlers.add('Update-Configurator', {Action = "Update-Configurator"}, function(msg)
    Market:updateConfigurator(msg)
  end)
  
  -- Update Incentives
  Handlers.add('Update-Incentives', {Action = "Update-Incentives"}, function(msg)
    Market:updateIncentives(msg)
  end)
  
  -- Update Take Fee Percentage
  Handlers.add('Update-Take-Fee', {Action = "Update-Take-Fee"}, function(msg)
    Market:updateTakeFee(msg)
  end)
  
  -- Update Protocol Fee Target
  Handlers.add('Update-Protocol-Fee-Target', {Action = "Update-Protocol-Fee-Target"}, function(msg)
    Market:updateProtocolFeeTarget(msg)
  end)
  
  -- Update Logo
  Handlers.add('Update-Logo', {Action = "Update-Logo"}, function(msg)
    Market:updateLogo(msg)
  end)
  
  ---------------------------------------------------------------------------------
  -- EVAL HANDLER -----------------------------------------------------------------
  ---------------------------------------------------------------------------------
  
  -- Eval
  Handlers.once("Complete-Eval", {Action = "Complete-Eval"}, function(msg)
    Market:completeEval(msg)
  end)
  
  -- @dev TODO: remove?
  ao.send({Target = ao.id, Action = 'Complete-Eval'})
  
  return "ok"
    
]===]