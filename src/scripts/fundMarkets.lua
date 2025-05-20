-- local constants = require('scripts.constants')

-- local FundMarkets = {}

-- function FundMarkets:run(env, msg)
--   assert(env, 'env is required')
--   assert(env == "DEV" or env == "PROD", 'env must be dev or prod')
--   local dataIndex = constants[env].dataIndex

--   local openMarkets = ao.send({
--     Target = dataIndex,
--     Action = "Query",
--     Data = "SELECT * FROM Markets WHERE status = 'open';",
--   }).receive()

--   -- openMarkets to list
--   local fundedMarkets = ao.send({
--     Target = dataIndex,
--     Action = "Query",
--     Data = "SELECT * FROM Fundings WHERE market IN '{list}';",
--   }).receive()

--   -- get the open markets that are not funded

--   -- for each of them send funding..

--   return msg.reply({ Action = 'Init-Markets-Script-Notice', Env = env, MessageIds = msg.Id })
-- end


-- return InitMarkets

-- "["BYpv4btjBwNDEYkvf6l7QGtomk9e54A1-tXQil8_Xhk","5uiLkgtVOAxmn0r8bCC6kkgH9SeDgM1NUp44J8o2HDc","3w53Y4bvz8I8HVuzrR-2J7Wi7YKm7sDUgh8jZoTJRhM","lEWnkydt6w0tvoUGS55wCpXvSj3QO9JZYGZN1KdoNkU","bvG_rl08PafatfX_LxfyX4iNmufNPyr08XGUbUTEgOQ","yY4MJ8ZUqa0eSCNXcJC7S5xneXIbPAq4LV4kpDeu73M","s5zmuH4rIofUiAIjnbPFT_4dlMahqRTgye3zRlEzqS8","9Pbtgsi4iTOpCj-WwxHf24BBycXv9_aVfQxuNOFn3oY","3VmywPG4NwUJV3ULio2G5iGMI_jrmQlaw5x9FFLyyPU","UgTIwRR_Q7R6YvcETheEAYPtmL91GWTlXxs75wPYkjo","XWeLQ14vJj3uSdL5xdyf_5JFj1KFmjOCfBB0Gmoo_-U","JmGS8ujmnGzmsztcf-RYiLEHkbd76AVBedLREdiGulw","ODY4j5H1DNX7ot4BGhby_DUgk7BoBMNFUz4xy2it_0k","gQ7sZb5VGjyVQhWPYT8DYMb9Ij6G_S_8VJx3ZytotHs","kDdF_C6iaaDpMkUFWWRvw7z68u53ua9CEieyQO1RMPc","xeo8rjRAJA8pQxRAcqSFk0LTSLI8qYvfnZHqgoWWEgo","wDl8yv-lEayCDwJOmOloo2h87qm4N0sPX9FflcBCxrI"]"