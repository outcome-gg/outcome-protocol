--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See tokens.lua for full license details.
=========================================================
]]

-- local ao = require('.ao') @dev required for unit tests?
local TokenNotices = {}

--- Mint notice
--- @param recipient string The address that will own the minted tokens
--- @param quantity string The quantity of tokens to mint
--- @param expectReply boolean Whether to use `msg.reply` or `ao.send`
--- @param msg Message The message received
--- @return Message The mint notice
function TokenNotices.mintNotice(recipient, quantity, expectReply, msg)
  local notice = {
    Recipient = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  }
  -- Send notice
  if expectReply then return msg.reply(notice) end
  notice.Target = msg.From
  return ao.send(notice)
end

--- Burn notice
--- @param quantity string The quantity of tokens to burn
--- @param expectReply boolean Whether to use `msg.reply` or `ao.send`
--- @param msg Message The message received
--- @return Message The burn notice
function TokenNotices.burnNotice(quantity, expectReply, msg)
  local notice = {
    Target = msg.Sender and msg.Sender or msg.From,
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  }
  -- Send notice
  if expectReply then return msg.reply(notice) end
  notice.Target =  msg.Sender and msg.Sender or msg.From
  return ao.send(notice)
end

--- Transfer notices
--- @param debitNotice Message The notice to send the spender
--- @param creditNotice Message The notice to send the receiver
--- @param recipient string The address that will receive the tokens
--- @param expectReply boolean Whether to use `msg.reply` or `ao.send`
--- @param msg Message The mesage received
--- @return table<Message> The transfer notices
function TokenNotices.transferNotices(debitNotice, creditNotice, recipient, expectReply, msg)
  if expectReply then return { msg.reply(debitNotice), msg.forward(recipient, creditNotice) } end
  debitNotice.Target = msg.From
  creditNotice.Target = recipient
  return { ao.send(debitNotice), ao.send(creditNotice) }
end

--- Transfer error notice
--- @param msg Message The mesage received
--- @return Message The transfer error notice
function TokenNotices.transferErrorNotice(msg)
  return msg.reply({
    Action = 'Transfer-Error',
    ['Message-Id'] = msg.Id,
    Error = 'Insufficient Balance!'
  })
end

return TokenNotices