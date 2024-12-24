local ao = require('.ao')

local TokenNotices = {}

--- Mint notice
--- @param recipient string The address that will own the minted tokens
--- @param quantity string The quantity of tokens to mint
--- @param msg Message The message received
--- @return Message The mint notice
function TokenNotices.mintNotice(recipient, quantity, msg)
  return msg.reply({
    Recipient = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

--- Burn notice
--- @param quantity string The quantity of tokens to burn
--- @param msg Message The message received
--- @return Message The burn notice
function TokenNotices.burnNotice(quantity, msg)
  return msg.reply({
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

--- Transfer notices
--- @param debitNotice Message The notice to send the spender
--- @param creditNotice Message The notice to send the receiver
--- @param msg Message The mesage received
--- @return table<Message> The transfer notices
function TokenNotices.transferNotices(debitNotice, creditNotice, msg)
  return { msg.reply(debitNotice), ao.send(creditNotice) }
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