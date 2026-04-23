import { render, screen, within } from '@testing-library/react'
import { TemplatePicker } from '../TemplatePicker' // eslint-disable-line no-unused-vars

const baseTemplate = {
  id: 'chat',
  name: 'Chat Stack',
  description: 'Local LLM with chat UI.',
  icon: 'MessageSquare',
  services: ['llama-server', 'open-webui'],
  estimated_disk_gb: 12,
  tier_minimum: 'mid',
}

describe('TemplatePicker accessibility', () => {
  test('default (available) card uses an enabled button with the template name in its accessible name', () => {
    render(<TemplatePicker templates={[{ ...baseTemplate, _status: 'available' }]} />)

    const card = screen.getByRole('button', { name: /Chat Stack/i })
    expect(card).toBeEnabled()
    expect(card).toHaveAttribute('aria-disabled', 'false')
  })

  test('isApplied card renders the green "Applied" indicator and disables the button', () => {
    render(<TemplatePicker templates={[{ ...baseTemplate, _status: 'applied' }]} />)

    const card = screen.getByRole('button', { name: /Chat Stack/i })
    expect(card).toBeDisabled()
    expect(card).toHaveAttribute('aria-disabled', 'true')

    // The "Applied" caption is the screen-reader-friendly status carrier
    // (the adjacent green check is decorative / aria-hidden).
    expect(within(card).getByText(/Applied/i)).toBeInTheDocument()
  })

  test('inProgress card disables the button and renders the "Installing…" status text', () => {
    render(<TemplatePicker templates={[{ ...baseTemplate, _status: 'in_progress' }]} />)

    const card = screen.getByRole('button', { name: /Chat Stack/i })
    expect(card).toBeDisabled()
    expect(within(card).getByText(/Installing/i)).toBeInTheDocument()
  })

  test('hasErrors card disables the button and renders the "Has errors" status text', () => {
    render(<TemplatePicker templates={[{ ...baseTemplate, _status: 'has_errors' }]} />)

    const card = screen.getByRole('button', { name: /Chat Stack/i })
    expect(card).toBeDisabled()
    expect(within(card).getByText(/Has errors/i)).toBeInTheDocument()
  })

  test('decorative status icons (Loader2, AlertTriangle, Check, default Icon) carry aria-hidden="true"', () => {
    // Render one card per status so we exercise every branch of the icon
    // ternary. Decorative SVGs must be hidden from screen readers because
    // the adjacent text label ("Installing…", "Has errors", "Applied", or
    // the template name) is what carries the semantic meaning.
    const templates = [
      { ...baseTemplate, id: 'a', name: 'Available Card', _status: 'available' },
      { ...baseTemplate, id: 'b', name: 'In Progress Card', _status: 'in_progress' },
      { ...baseTemplate, id: 'c', name: 'Errors Card', _status: 'has_errors' },
      { ...baseTemplate, id: 'd', name: 'Applied Card', _status: 'applied' },
    ]
    const { container } = render(<TemplatePicker templates={templates} />)

    const svgs = container.querySelectorAll('svg')
    expect(svgs.length).toBeGreaterThan(0)
    // Status icons all sit inside the icon wrapper div with rounded-lg
    // class — we don't enforce that selector here, but every Lucide icon
    // rendered by the picker passes aria-hidden="true" so the assertion
    // can simply scan all SVGs.
    svgs.forEach(svg => {
      expect(svg).toHaveAttribute('aria-hidden', 'true')
    })
  })

  test('returns null when handed an empty template list (defensive)', () => {
    const { container } = render(<TemplatePicker templates={[]} />)
    expect(container.firstChild).toBeNull()
  })

  test('returns null when handed an undefined template list (defensive)', () => {
    const { container } = render(<TemplatePicker templates={undefined} />)
    expect(container.firstChild).toBeNull()
  })
})
