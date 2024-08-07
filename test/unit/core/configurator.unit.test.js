import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../../aos.helper.js'
import fs from 'node:fs'

/* 
 * LOAD MODULE
 */
test('load configurator module', async () => {
  const code = fs.readFileSync('./src/core/configurator.lua', 'utf-8')
  const result = await Send({
    Action: 'Eval',
    Data: `
      local function _load() 
        ${code}
      end
      _G.package.loaded["configurator"] = _load()
      return "ok"
    `
  })
  assert.equal(result.Output.data.output, "ok")
})
