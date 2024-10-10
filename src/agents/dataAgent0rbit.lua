local json = require('json')
_0rbit = require("0rbit")

--[[
    FUNCTIONS
]]

local function onResponse(msg)
  print("Response: " .. json.encode(msg))
end

--[[
    HANDLERS
]]

-- @dev Handler for sending a GET request
-- @param Url The URL to sentd the GET request to
Handlers.add('Get-Request', Handlers.utils.hasMatchingTag('Action', 'Get-Request'), function (msg)
  assert(msg.Tags.Url, "No URL provided")
  _0rbit.sendGetRequest(msg.Tags.Url)
end)

-- @dev Handler for sending a POST request
-- @param Url The URL to sentd the POST request to
-- @param Body The body of the POST request
Handlers.add('Post-Request', Handlers.utils.hasMatchingTag('Action', 'Post-Request'), function(msg)
  assert(msg.Tags.Url, "No URL provided")
  assert(msg.Tags.Body, "No Body provided")
  _0rbit.sendPostRequest(msg.Tags.Url, msg.Tags.Body)
end)

-- @dev Handler for receiving a response
-- @param msg The response message
-- @param onResponse The callback function to be called when a response is received
Handlers.add('Receive-Response', Handlers.utils.hasMatchingTag('Action', 'Receive-Response'), function(msg)
  _0rbit.receiveResponse(msg, onResponse)
end)

-- @dev Handler for getting the 0RBT balance of the process.
Handlers.add('Get-Balance', Handlers.utils.hasMatchingTag('Action', 'Get-Balance'), function()
  _0rbit.getBalance()
end)