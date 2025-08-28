//
// For guidance on how to create filters see:
// https://prototype-kit.service.gov.uk/docs/filters
//

const govukPrototypeKit = require('govuk-prototype-kit')
const addFilter = govukPrototypeKit.views.addFilter

// Add your filters here

addFilter('split', (value, sep) => {
  if (typeof value !== 'string') return []
  return value.split(sep)
})

addFilter('trim', (value) => {
  if (typeof value !== 'string') return value
  return value.trim()
})
