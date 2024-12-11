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
	add = function()
		return true
	end,
	once = function()
		return true
	end,
	utils = {
		reply = function()
			return true
		end,
		hasMatchingTag = function()
			return true
		end,
	},
}

-- _G.crypto = {
--   digest = {
--     keccak256 = function(input)
--       return {
--         asHex = function() return input end
--       }
--     end
--   }
-- }

-- Force reload modules that may have been cached
package.loaded["modules.configurator"] = nil
package.loaded["crypto"] = nil

print("Setup global ao mocks successfully...")
