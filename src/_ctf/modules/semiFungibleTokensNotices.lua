local ao = require('.ao')
local json = require('json')

local SemiFungibleTokensNotices = {}

-- @dev Mint single token notice
-- @param to The address that will own the minted token
-- @param id ID of the token to be minted
-- @param quantity Quantity of the token to be minted
function SemiFungibleTokensNotices:mintSingleNotice(to, id, quantity)
  print("ao send mintSingleNotice")
  ao.send({
    Target = to,
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
function SemiFungibleTokensNotices:mintBatchNotice(to, ids, quantities)
  ao.send({
    Target = to,
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
function SemiFungibleTokensNotices:burnSingleNotice(holder, id, quantity)
  ao.send({
    Target = holder,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Burn-Single-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  })
end

-- @dev Burn batch tokens notice
-- @param notice The prepared notice to be sent
function SemiFungibleTokensNotices:burnBatchNotice(notice)
  ao.send(notice)
end

-- @dev Transfer single token notices
-- @param from The address to be debited
-- @param to The address to be credited
-- @param id ID of the tokens to be transferred
-- @param quantity Quantity of the tokens to be transferred
-- @param msg For sending X-Tags
function SemiFungibleTokensNotices:transferSingleNotices(from, to, id, quantity, msg)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Single-Notice',
    Recipient = to,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Data = Colors.gray .. "You transferred " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.gray .. " to " .. Colors.green .. to .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      debitNotice[tagName] = tagValue
    end
  end
  -- Send notice
  msg.reply(debitNotice)

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
      creditNotice[tagName] = tagValue
    end
  end
  -- Send notice
  ao.send(creditNotice)
end

-- @dev Transfer batch tokens notices
-- @param from The address to be debited
-- @param to The address to be credited
-- @param ids IDs of the tokens to be transferred
-- @param quantities Quantities of the tokens to be transferred
-- @param msg For sending X-Tags
function SemiFungibleTokensNotices:transferBatchNotices(from, to, ids, quantities, msg)
  -- Prepare debit notice
  local debitNotice = {
    Action = 'Debit-Batch-Notice',
    Recipient = to,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Data = Colors.gray .. "You transferred batch to " .. Colors.green .. to .. Colors.reset
  }
  -- Forward X-Tags
  for tagName, tagValue in pairs(msg) do
    -- Tags beginning with "X-" are forwarded
    if string.sub(tagName, 1, 2) == "X-" then
      debitNotice[tagName] = tagValue
    end
  end
  -- Send notice
  msg.reply(debitNotice)

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
      creditNotice[tagName] = tagValue
    end
  end
  -- Send notice
  ao.send(creditNotice)
end

-- @dev Transfer error notice
-- @param from The address to be debited
-- @param id ID of the tokens to be transferred
-- @param msg The message
function SemiFungibleTokensNotices:transferErrorNotice(id, msg)
  msg.reply({
    Action = 'Transfer-Error',
    ['Message-Id'] = msg.Id,
    ['Token-Id'] = id,
    Error = 'Insufficient Balance!'
  })
end

return SemiFungibleTokensNotices
