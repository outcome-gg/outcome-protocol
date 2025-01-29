--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See semiFungibleTokens.lua for full license details.
=========================================================
]]

-- local ao = require('.ao')
local json = require('json')

local SemiFungibleTokensNotices = {}

--- Mint single notice
--- @param to string The address that will own the minted token
--- @param id string The ID of the token to be minted
--- @param quantity string The quantity of the token to be minted
--- @param msg Message The message received
--- @return Message The mint notice
function SemiFungibleTokensNotices.mintSingleNotice(to, id, quantity, msg)
  return msg.reply({
    Recipient = to,
    TokenId = tostring(id),
    Quantity = tostring(quantity),
    Action = 'Mint-Single-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(id) .. Colors.reset
  })
end

--- Mint batch notice
--- @param to string The address that will own the minted tokens
--- @param ids table<string> The IDs of the tokens to be minted
--- @param quantities table<string> The quantities of the tokens to be minted
--- @param msg Message The message received
--- @return Message The batch mint notice
function SemiFungibleTokensNotices.mintBatchNotice(to, ids, quantities, msg)
  return msg.reply({
    Recipient = to,
    TokenIds = json.encode(ids),
    Quantities = json.encode(quantities),
    Action = 'Mint-Batch-Notice',
    Data = "Successfully minted batch"
  })
end

--- Burn single notice
--- @param from string The address that will burn the token
--- @param id string The ID of the token to be burned
--- @param quantity string The quantity of the token to be burned
--- @param msg Message The message received
--- @return Message The burn notice
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

--- Burn batch notice
--- @param notice Message The prepared notice to be sent
--- @param msg Message The message received
--- @return Message The burn notice
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

--- Transfer single token notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param id string The ID of the token to be transferred
--- @param quantity string The quantity of the token to be transferred
--- @param msg Message The message received
--- @return table<Message> The debit and credit transfer notices
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

--- Transfer batch tokens notices
--- @param from string The address to be debited
--- @param to string The address to be credited
--- @param ids table<string> The IDs of the tokens to be transferred
--- @param quantities table<string> The quantities of the tokens to be transferred
--- @param msg Message The message received
--- @return table<Message> The debit and credit batch transfer notices
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

--- Transfer error notice
--- @param id string The ID of the token to be transferred
--- @param msg Message The message received
--- @return Message The transfer error notice
function SemiFungibleTokensNotices.transferErrorNotice(id, msg)
  return msg.reply({
    Action = 'Transfer-Error',
    ['Message-Id'] = msg.Id,
    ['Token-Id'] = id,
    Error = 'Insufficient Balance!'
  })
end

return SemiFungibleTokensNotices
