function makeSparklinePath(values, opts = {}) {
  const width = opts.width ?? 120
  const height = opts.height ?? 24
  const pad = opts.padding ?? 2

  if (!Array.isArray(values) || values.length === 0) return ''
  if (values.length === 1) {
    // Single point: draw a small flat line
    const y = Math.round(height / 2)
    return `M ${pad},${y} L ${width - pad},${y}`
  }

  const min = Math.min(...values)
  const max = Math.max(...values)
  const range = max - min || 1 // avoid divide by zero

  const innerW = width - pad * 2
  const innerH = height - pad * 2
  const stepX = values.length > 1 ? innerW / (values.length - 1) : innerW

  const points = values.map((v, i) => {
    const x = pad + i * stepX
    // invert y so higher values are higher on the sparkline
    const norm = (v - min) / range
    const y = pad + (1 - norm) * innerH
    return [x, y]
  })

  const path = points.map(([x, y], i) => `${i === 0 ? 'M' : 'L'} ${x.toFixed(1)},${y.toFixed(1)}`).join(' ')
  return path
}

module.exports = { makeSparklinePath }

