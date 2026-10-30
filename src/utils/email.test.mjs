import { test } from 'node:test'
import assert from 'node:assert/strict'
import { emailValida, suggerisciEmail } from './email.js'

test('formato dell\'indirizzo', () => {
  assert.equal(emailValida('rob@libero.it'), true)
  assert.equal(emailValida(' rob@libero.it '), true)
  assert.equal(emailValida('rob@libero'), false)
  assert.equal(emailValida('rob libero.it'), false)
  assert.equal(emailValida(''), false)
  assert.equal(emailValida(null), false)
})

test('refusi nei domini comuni', () => {
  assert.equal(suggerisciEmail('maria@gmial.com'), 'maria@gmail.com')
  assert.equal(suggerisciEmail('maria@gmail.con'), 'maria@gmail.com')
  assert.equal(suggerisciEmail('maria@libero.ti'), 'maria@libero.it')
  assert.equal(suggerisciEmail('maria@hotmial.it'), 'maria@hotmail.it')
  assert.equal(suggerisciEmail('Maria.Rossi@Yaho.it'), 'Maria.Rossi@yahoo.it')
})

test('nessun suggerimento quando non serve', () => {
  assert.equal(suggerisciEmail('maria@gmail.com'), null)
  assert.equal(suggerisciEmail('maria@GMAIL.COM'), null)
  assert.equal(suggerisciEmail('maria@vivaio-rossi.it'), null)
  assert.equal(suggerisciEmail('maria@unifi.it'), null)
  assert.equal(suggerisciEmail('maria@'), null)
  assert.equal(suggerisciEmail('maria'), null)
  assert.equal(suggerisciEmail('maria@pm.me'), null)
  assert.equal(suggerisciEmail('maria@tin.it'), null)
})
