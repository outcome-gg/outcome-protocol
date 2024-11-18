local ao = require('.ao')

local TokensNotices = {}

function TokensNotices.mintNotice(recipient, quantity)
  ao.send({
    Target = recipient,
    Quantity = tostring(quantity),
    Action = 'Mint-Notice',
    Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

function TokensNotices.burnNotice(holder, quantity)
  ao.send({
    Target = holder,
    Quantity = tostring(quantity),
    Action = 'Burn-Notice',
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.reset
  })
end

function TokensNotices.transferNotices(debitNotice, creditNotice)
  -- Send Debit-Notice to the Sender
  ao.send(debitNotice)
  -- Send Credit-Notice to the Recipient
  ao.send(creditNotice)
end

function TokensNotices.transferErrorNotice(sender, msgId)
  ao.send({
    Target = sender,
    Action = 'Transfer-Error',
    ['Message-Id'] = msgId,
    Error = 'Insufficient Balance!'
  })
end

return TokensNotices