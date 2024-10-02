local ao = require('.ao')

local DLOBNotices = {}

function DLOBNotices.addFundsNotice(sender, quantity, xAction, xData)
  -- Send notice
  ao.send({
    Target = sender,
    Action = 'Funds-Added',
    Quantity = quantity,
    Data = 'Successfully added funds'
  })
  -- Forward Order(s)
  if xAction and xData then
    if xAction == 'Process-Order' then
      ao.send({
        Target = ao.id,
        Action = 'Process-Order',
        Sender = sender,
        Data = xData
      })
    elseif xAction == 'Process-Orders' and xData then
      ao.send({
        Target = ao.id,
        Action = 'Process-Orders',
        Sender = sender,
        Data = xData
      })
    end
  end
end

function DLOBNotices.addSharesNotice(sender, quantity, xAction, xData)
  -- Send notice
  ao.send({
    Target = sender,
    Action = 'Shares-Added',
    Quantity = quantity,
    Data = 'Successfully added shares'
  })
  -- Forward Order(s)
  if xAction and xData then
    if xAction == 'Process-Order' then
      ao.send({
        Target = ao.id,
        Action = 'Process-Order',
        Sender = sender,
        Data = xData
      })
    elseif xAction == 'Process-Orders' and xData then
      ao.send({
        Target = ao.id,
        Action = 'Process-Orders',
        Sender = sender,
        Data = xData
      })
    end
  end
end

function DLOBNotices.withdrawFundsNotice(sender, quantity, success, message)
  if not success then
    -- Send error notice and stop
    ao.send({
      Target = sender,
      Action = 'Withdraw-Funds-Error',
      Data = message
    })
    return
  end
  -- Send notice
  ao.send({
    Target = sender,
    Action = 'Funds-Withdrawn',
    Quantity = quantity,
    Data = message
  })
end

function DLOBNotices.withdrawSharesNotice(sender, quantity, success, message)
  if not success then
    -- Send error notice and stop
    ao.send({
      Target = sender,
      Action = 'Withdraw-Shares-Error',
      Data = message
    })
    return
  end
  -- Send notice
  ao.send({
    Target = sender,
    Action = 'Shares-Withdrawn',
    Quantity = quantity,
    Data = message
  })
end

return DLOBNotices
