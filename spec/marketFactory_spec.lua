require("luacov")
local cpmm = require("modules.cpmm")
local token = require("modules.token")
local tokens = require("modules.conditionalTokens")
local json = require("json")

local admin = ""

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("#marketFactory", function()
  before_each(function()
    -- set admin
    admin = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0"
	end)

  it("should get info", function()
    -- get info
    -- local info = Handlers.process(msgInfo)
    -- assert correct response
    -- assert.are.same({
    --   Admin = admin,
    --   Delay = delay,
    --   Staged = json.encode(staged)
    -- }, info)
  end)
end)