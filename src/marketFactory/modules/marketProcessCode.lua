return [[
Name = FooBar

Handlers.add("Info", {Action = "Info"}, function(msg)
  msg.reply({
    Name = Name,
  })
end)
]]