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