return {
  allow_defined = true,
  exclude_files = {
      "spec/",
      "src/_*",
      "src/agents",
      "src/crypto",
      "src/scripts",
      "src/ao.lua",
      "src/utils.lua",
      "src/*/utils.lua",
      "src/*/dbAdmin.lua",
      "src/marketFactoryModules/marketProcessCodeV2.lua"
  },
  globals = {
      "Handlers",
      "ao",
      "Colors"
  },
  max_line_length = 185
}
