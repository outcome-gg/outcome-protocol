import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../aos.helper.js'
import fs from 'node:fs'

/* 
 * LOAD MODULE
 */
test('load amm module', async () => {
  const code = fs.readFileSync('./src/market/amm.lua', 'utf-8')
  const result = await Send({
    Action: 'Eval',
    Data: `
      local function _load() 
        ${code}
      end
      _G.package.loaded["amm"] = _load()
      return "ok"
    `
  })
  assert.equal(result.Output.data.output, "ok")
})
