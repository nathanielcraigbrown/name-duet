function updateProgressTarget() {
  const progress = document.querySelector<HTMLElement>('.comparisonProgress')
  if (!progress) return

  const countElement = progress.querySelector<HTMLElement>('.progressCopy span')
  const labelElement = progress.querySelector<HTMLElement>('.progressCopy strong')
  const fillElement = progress.querySelector<HTMLElement>('.progressTrack span')
  if (!countElement || !labelElement || !fillElement) return

  const current = Number.parseInt(countElement.textContent?.split('/')[0]?.trim() ?? '0', 10)
  if (!Number.isFinite(current)) return

  const target = current >= 600 ? 900 : 600
  const percent = Math.min(100, Math.round((current / target) * 100))

  countElement.textContent = `${current} / ${target}`
  fillElement.style.width = `${percent}%`
  progress.setAttribute('aria-label', `${current} of ${target} comparisons`)

  if (current >= 900) labelElement.textContent = 'Refined result reached'
  else if (current >= 600) labelElement.textContent = 'Refining your expanded shortlist'
  else if (current >= 400) labelElement.textContent = 'Expanded shortlist taking shape'
  else if (current >= 250) labelElement.textContent = 'Shortlist taking shape'
  else if (current >= 150) labelElement.textContent = 'Favorites emerging'
  else labelElement.textContent = 'Learning your taste'
}

const progressObserver = new MutationObserver(() => updateProgressTarget())
progressObserver.observe(document.body, { childList: true, subtree: true, characterData: true })
updateProgressTarget()
