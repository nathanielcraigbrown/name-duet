let updateScheduled = false

function updateProgressTarget() {
  updateScheduled = false

  const progress = document.querySelector<HTMLElement>('.comparisonProgress')
  if (!progress) return

  const countElement = progress.querySelector<HTMLElement>('.progressCopy span')
  const labelElement = progress.querySelector<HTMLElement>('.progressCopy strong')
  const fillElement = progress.querySelector<HTMLElement>('.progressTrack span')
  const choicesElement = document.querySelector<HTMLElement>('.comparisonMeta span:first-child')
  if (!countElement || !labelElement || !fillElement || !choicesElement) return

  const current = Number.parseInt(choicesElement.textContent?.match(/\d+/)?.[0] ?? '', 10)
  if (!Number.isFinite(current)) return

  const target = current >= 600 ? 900 : 600
  const percent = Math.min(100, Math.round((current / target) * 100))
  const countText = `${current} / ${target}`
  const ariaText = `${current} of ${target} comparisons`
  const widthText = `${percent}%`

  let label = 'Learning your taste'
  if (current >= 900) label = 'Refined result reached'
  else if (current >= 600) label = 'Refining your expanded shortlist'
  else if (current >= 400) label = 'Expanded shortlist taking shape'
  else if (current >= 250) label = 'Shortlist taking shape'
  else if (current >= 150) label = 'Favorites emerging'

  if (countElement.textContent !== countText) countElement.textContent = countText
  if (labelElement.textContent !== label) labelElement.textContent = label
  if (fillElement.style.width !== widthText) fillElement.style.width = widthText
  if (progress.getAttribute('aria-label') !== ariaText) progress.setAttribute('aria-label', ariaText)
}

function scheduleProgressUpdate() {
  if (updateScheduled) return
  updateScheduled = true
  window.requestAnimationFrame(updateProgressTarget)
}

const progressObserver = new MutationObserver(scheduleProgressUpdate)
progressObserver.observe(document.body, { childList: true, subtree: true, characterData: true })
scheduleProgressUpdate()
