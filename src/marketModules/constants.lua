--[[
=========================================================
Part of the Outcome codebase © 2025. All Rights Reserved.
See market.lua for full license details.
=========================================================
]]

local constants = {}
local json = require('json')

-- Market Config
constants.marketConfig = {
  configurator = "b9hj1yVw3eWGIggQgJxRDj1t8SZFCezctYD-7U5nYFk",
  dataIndex = "rXSAUKwZhJkIBTIEyBl1rf8Gtk_88RKQFsx5JvDOwlE",
  collateralToken = "jAyJBNpuSXmhn9lMMfwDR60TfIPANXI6r-f3n9zucYU",
  resolutionAgent = "bbGGz7atKMl8kWJVdn4H_dgHfQrgduSjLimuMle_uHw",
  creator = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  question = "Liquid Ops oUSDC interest reaches 8% in March",
  rules = "Where we're going, we don't need rules",
  category = "Finance",
  sucategory = "Interest Rates",
  positionIds = json.encode({"1","2"}),
  name = "Mock Spawn Market",
  ticker = 'MSM',
  denomination = 12,
  logo = "https://test.com/logo.png",
  logos = json.encode({"https://test.com/logo.png", "https://test.com/logo.png"}),
  lpFee = "100",
  creatorFee = "250",
  creatorFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0",
  protocolFee = "250",
  protocolFeeTarget = "m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0"
}

return constants