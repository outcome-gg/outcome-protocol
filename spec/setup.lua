package.path =
	"./src/configurator/?.lua;" ..
	"./src/configurator/modules/?.lua;" ..
	"./src/market/?.lua;" ..
	"./src/market/modules/?.lua;" ..
	"./src/?.lua;" ..
	package.path

_G.ao = {
	send = function(val)
		return val
	end,
	id = "test",
}

_G.Handlers = {
  registered = {},
  add = function(name, condition, callback)
    table.insert(_G.Handlers.registered, {
      name = name,
      condition = condition,
      callback = callback
    })
    return true
  end,
	once = function()
		return true
	end,
  process = function(msg)
    for _, handler in ipairs(_G.Handlers.registered) do
      if handler.condition(msg) then
        return handler.callback(msg)
      end
    end
    error("No matching handler found for message")
  end,
  utils = {
    hasMatchingTag = function(key, value)
      return function(msg)
        return msg.Tags[key] == value
      end
    end,
    reply = function(msg)
      print("Replying:", msg)
      return msg
    end
  }
}

_G.Colors = {
	red = "",
	blue = "",
	green = "",
	gray = "",
	reset = "",
}

-- Force reload modules that may have been cached
package.loaded["modules.configurator"] = nil
package.loaded["modules.tokenNotices"] = nil
package.loaded["modules.tokenValidation"] = nil
package.loaded["crypto"] = nil

print("Setup global ao mocks successfully...")
