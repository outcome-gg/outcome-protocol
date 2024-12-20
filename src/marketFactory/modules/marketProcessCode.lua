return [[
Name = FooBar
return "ok"

Handlers.add("Info", {Action = "Info"}, function(msg)
  msg.reply({
    Name = Name,
  })
end)
]]