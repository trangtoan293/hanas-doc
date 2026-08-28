# DESIGN.md — Enterprise AI Platform Website

> Design direction extracted from the provided reference clip and adapted into an implementation-ready specification for an enterprise **AI / Agent Platform** website.
>
> The goal is to reproduce the **design language, rhythm, hierarchy, and interaction style**, not to make a pixel-for-pixel clone of the reference site.

---

## 1. Design Intent

The website should feel like a premium enterprise technology company working in AI, data, infrastructure, and intelligent automation.

The visual impression must be:

- Calm, precise, technical, trustworthy.
- Minimal rather than decorative.
- Premium but not luxury/fashion.
- Enterprise-ready rather than startup-playful.
- Strong contrast between large white editorial sections and a few dark cinematic sections.
- Visual storytelling driven by architecture diagrams, product UI, abstract data/AI imagery, and real product use cases.

### Core principle

**Whitespace communicates confidence. Dark surfaces communicate intelligence. Structured cards communicate capability.**

Avoid a noisy SaaS landing-page look with excessive gradients, neon borders, icon grids, shadows, badges, and competing CTAs.

---

# 2. Visual DNA From the Reference

The reference uses a very consistent visual system:

1. A clean white canvas for most content.
2. Dark blue-black gradient panels for hero, CTA, and footer.
3. Large rounded containers instead of many small floating cards.
4. Editorial two-column layouts with generous empty space.
5. Image cards with rounded corners and muted cinematic imagery.
6. Sparse use of accent color.
7. Horizontal card collections for case studies.
8. Bento-style capability blocks.
9. Lightweight pill controls for filters/tabs.
10. FAQ accordion near the bottom of the page.
11. Thin dividers, subtle borders, almost no heavy shadows.
12. Motion is slow, soft, and tied to scroll rather than flashy transitions.

This design system should be followed across the entire site.

---

# 3. Brand Direction

## 3.1 Personality

The website should communicate:

- Intelligence
- Systems thinking
- Reliability
- Scalability
- Governance
- Enterprise readiness
- Technical depth
- Business outcome orientation

The site should not look like an experimental AI lab or crypto landing page.

## 3.2 Suggested brand vocabulary

Use short, confident statements such as:

- Build AI that can operate at enterprise scale.
- From data to agents, governed end to end.
- One platform for enterprise AI execution.
- Turn enterprise intelligence into action.
- Build. Govern. Observe. Scale.

Avoid overly promotional copy such as:

- Revolutionary
- Game-changing
- The world's best
- Unleash infinite AI power

---

# 4. Color System

The reference is primarily monochrome with cool blue-black visual moments.

Use the following semantic tokens.

```css
:root {
  --bg-page: #F7F8F8;
  --bg-surface: #FFFFFF;
  --bg-soft: #F0F3F5;

  --text-primary: #111418;
  --text-secondary: #697078;
  --text-muted: #969DA5;
  --text-on-dark: #F7F9FB;
  --text-on-dark-muted: #AEB8C2;

  --border-soft: #E5E8EA;
  --border-dark: rgba(255,255,255,0.12);

  --navy-950: #07111C;
  --navy-900: #0C1723;
  --navy-850: #122131;
  --navy-800: #172A3E;

  --accent-blue: #6C93B4;
  --accent-blue-soft: #C8D9E8;

  --success: #58A67B;
}
```

### Dark gradient

Use dark gradients only for strong narrative sections.

```css
background:
  radial-gradient(circle at 75% 70%, rgba(68, 104, 136, 0.35), transparent 42%),
  radial-gradient(circle at 20% 15%, rgba(36, 65, 91, 0.24), transparent 38%),
  linear-gradient(145deg, #08111B 0%, #0E1B29 55%, #152B40 100%);
```

### Rules

- Do not use saturated electric blue as the dominant color.
- Do not use multiple rainbow gradients.
- Do not use glowing borders on every component.
- Dark sections should occupy approximately 20–30% of the total homepage visual area.
- White space should remain dominant.

---

# 5. Typography

The reference relies on clean modern sans-serif typography.

Recommended implementation:

```txt
Primary: Geist Sans
Fallback: Inter, Helvetica Neue, Arial, sans-serif
Mono: Geist Mono
```

## Type scale

```css
--font-display-xl: clamp(3.5rem, 7vw, 7rem);
--font-display-lg: clamp(2.8rem, 5vw, 5.2rem);
--font-h1: clamp(2.6rem, 4.6vw, 4.8rem);
--font-h2: clamp(2rem, 3vw, 3.25rem);
--font-h3: clamp(1.4rem, 2vw, 2rem);
--font-body-lg: 1.125rem;
--font-body: 1rem;
--font-small: 0.875rem;
--font-caption: 0.75rem;
```

## Typography behavior

- Main headings: 500–600 weight.
- Body: 400–450 weight.
- Buttons/nav: 500.
- Use slightly tight heading tracking: `-0.025em` to `-0.04em`.
- Body line-height: `1.55–1.7`.
- Heading line-height: `0.98–1.12`.
- Keep large headings short: ideally 1–3 lines.

### Example hero

```txt
Enterprise AI,
built to operate.
```

Supporting paragraph should be no more than ~2–3 lines on desktop.

---

# 6. Layout System

## 6.1 Global page

```txt
Desktop max content width: 1440px
Normal content width: 1200–1280px
Reading width: 640–760px
Page gutters desktop: 40–64px
Tablet: 28–32px
Mobile: 18–24px
```

Suggested utility:

```css
.site-container {
  width: min(100% - 48px, 1280px);
  margin-inline: auto;
}
```

## 6.2 Section rhythm

The reference site feels premium largely because of vertical spacing.

```txt
Large desktop section gap: 160–220px
Normal section gap: 120–160px
Mobile section gap: 80–104px
Internal block gap: 32–64px
```

Never compress the homepage into dense rows of content.

## 6.3 Grid

Desktop:

```txt
12-column grid
24–32px gutters
```

Common layouts:

- 5 / 7 split
- 4 / 8 split
- 6 / 6 split
- full-width feature surface
- asymmetric bento grid

---

# 7. Corner Radius & Borders

The reference consistently uses soft geometry.

```css
--radius-sm: 10px;
--radius-md: 16px;
--radius-lg: 24px;
--radius-xl: 32px;
--radius-pill: 999px;
```

Recommended usage:

- Button: pill.
- Small cards: 14–18px.
- Image cards: 18–24px.
- Large dark section / architecture stage: 24–32px.

Borders:

```css
border: 1px solid var(--border-soft);
```

Avoid strong drop shadows.

If depth is needed:

```css
box-shadow: 0 16px 50px rgba(18, 30, 42, 0.06);
```

Use only on large surfaces, not every card.

---

# 8. Header / Navigation

The header should be lightweight and approximately 72–84px high on desktop.

## Structure

```txt
[Brand]
        Platform
        Solutions
        Architecture
        Use Cases
        Resources
                              [GitHub optional] [Contact / Book demo]
```

Recommended final nav for this AI platform:

```txt
Platform
Solutions
Architecture
Developers
Resources
Company
```

Primary CTA:

```txt
Book a demo
```

or

```txt
Talk to us
```

## Behavior

- Sticky after user scrolls beyond hero top.
- White / translucent surface.
- `backdrop-filter: blur(14px)`.
- Add a very subtle bottom border while sticky.
- Do not make header visually dominant.

Mobile:

- Brand left.
- Menu icon right.
- CTA can live inside full-screen menu.

---

# 9. Homepage Information Architecture

The homepage should follow this order.

```txt
01 Hero
02 Trust / Enterprise proof
03 Platform value proposition
04 Platform architecture
05 Core platform capabilities
06 AI Gateway / Agent Runtime / Model Runtime
07 Delivery / adoption approach
08 Why this platform / bento benefits
09 Use cases / proven outcomes
10 Observability, governance & security
11 FAQ
12 Final CTA
13 Footer
```

The structure intentionally mirrors the narrative rhythm in the reference while adapting the content to an enterprise AI platform.

---

# 10. Section 01 — Hero

## Purpose

Create a high-impact opening without clutter.

## Visual

Large dark navy gradient container inside the white page canvas.

Suggested dimensions desktop:

```txt
height: 700–820px
radius: 28–32px
```

The dark panel should feel cinematic, with very subtle moving light/noise/particles.

## Content

Centered content.

Eyebrow:

```txt
ENTERPRISE AI PLATFORM
```

Heading example:

```txt
Build enterprise AI
that can actually operate.
```

Alternative:

```txt
From data to agents,
governed end to end.
```

Supporting line:

```txt
A unified platform to build, connect, govern and operate AI agents across enterprise data, models and tools.
```

CTA pair:

```txt
[Explore the platform] [View architecture →]
```

Bottom micro label:

```txt
Scroll to explore ↓
```

## Background details

Allowed:

- faint particle field
- subtle grid
- blurred radial light
- abstract vector network
- small line fragments moving slowly

Forbidden:

- strong animated blobs
- matrix rain
- flashy neon circuits
- giant robot artwork
- stock image of humanoid AI

---

# 11. Section 02 — Trust / Enterprise Proof

Reference pattern: quiet logo strip after a major story block.

Structure:

```txt
Trusted technologies / Built on open standards

[Kafka] [Kubernetes] [Milvus] [LiteLLM] [Langfuse] [Airflow] ...
```

If customer logos are unavailable, use technology ecosystem logos.

Visual:

- monochrome logos
- opacity around 40–55%
- no colored brand logos by default
- horizontal marquee can move extremely slowly

Optional statement:

```txt
Designed for hybrid and private enterprise environments.
```

---

# 12. Section 03 — Platform Value Proposition

Use the same editorial 2-column style seen in the reference.

## Layout

Left:

- abstract platform visual / architecture detail

Right:

- eyebrow
- large heading
- paragraph
- text CTA

Example:

```txt
PLATFORM OVERVIEW

Turn fragmented AI experiments
into an enterprise AI system.

Instead of every application independently connecting to models,
data and tools, the platform provides a governed runtime layer that
standardizes how AI workloads are built and operated.

Explore platform →
```

## Image direction

Prefer:

- abstract system diagram
- data mesh / agent network
- macro close-up of architecture graphic
- dimensional nodes

Avoid generic business stock photography.

---

# 13. Section 04 — Architecture Story

This should be one of the website's signature sections.

## Desktop composition

A large white or soft-gray panel with architecture diagram.

Top-left heading:

```txt
One architecture.
Every AI workload.
```

Architecture layers:

```txt
AI Applications
      ↓
API Gateway
      ↓
Agent Runtime
      ↓
AI Gateway
      ↓
Model Runtime

Supporting layers:
- Knowledge / Retrieval Platform
- Tool / MCP Platform
- Governance
- Security
- Observability
```

## Interaction

On hover or scroll focus:

- active layer gets stronger contrast
- connecting line animates
- adjacent description appears

Do not make this a complex draggable diagram on the homepage.

The diagram should remain understandable within 5 seconds.

## Mobile

Stack architecture vertically.

Do not shrink a desktop diagram until text becomes unreadable.

---

# 14. Section 05 — Capability Explorer

The reference includes a lightweight list/navigation style section.

Use this to introduce platform capabilities.

## Layout

Left column: vertical capability list.

```txt
Agent Runtime
AI Gateway
Knowledge Platform
Model Runtime
Tool / MCP Platform
Governance
Observability
```

Right column: selected capability detail.

Example selected state:

```txt
AI Gateway

A centralized control plane for model access, routing,
policy enforcement, quota, cost and guardrails.

Typical services
LiteLLM · Model Router · Guardrails · Usage Metering
```

## Interaction

- Hover selects on desktop after 150ms.
- Click locks selection.
- Keyboard accessible.
- Active text uses `text-primary`; inactive uses `text-muted`.
- Right panel fades/slides 8–12px during change.

No heavy tab borders.

---

# 15. Section 06 — Core Platform Layers

This is a three- or four-card visual sequence inspired by the vertically stacked image panels in the reference.

Recommended sequence:

### 01 Agent Runtime

```txt
Build, execute and manage production agents.
```

Services:

```txt
Agent orchestration
State & memory
Workflow runtime
Human-in-the-loop
Agent API
```

### 02 AI Gateway

```txt
Standardize access to every model.
```

Services:

```txt
Authentication
Routing
Quota
Cost controls
Guardrails
Fallback
Caching
```

### 03 Knowledge & Tools

```txt
Ground agents in enterprise context.
```

Services:

```txt
Hybrid retrieval
Vector search
Reranking
MCP servers
Enterprise APIs
Knowledge governance
```

### 04 Model Runtime

```txt
Operate open and proprietary models on one platform.
```

Services:

```txt
vLLM / SGLang
GPU inference
Autoscaling
Model registry
Private deployment
```

## Visual behavior

Each platform layer gets:

- one large atmospheric image or abstract diagram
- large number: `01`, `02`, etc.
- concise text

Do not place 20 small icons inside each card.

---

# 16. Section 07 — Delivery Approach

Reference pattern: large text on left, vertical image cards on right.

Use a 3-phase enterprise adoption story.

Heading:

```txt
A practical path from
AI idea to production.
```

### Phase 01 — Discover

```txt
Identify high-value use cases, data constraints and governance requirements.
```

### Phase 02 — Build

```txt
Prototype agents on shared runtime, knowledge and model services.
```

### Phase 03 — Scale

```txt
Standardize security, observability, cost and lifecycle management.
```

Visual:

Three large cinematic cards stacked vertically or horizontally.

Use abstract technology imagery rather than literal stock teamwork photos.

---

# 17. Section 08 — Why This Platform / Bento Grid

This section should closely follow the reference's bento rhythm.

Suggested 6 blocks:

```txt
Outcome-driven architecture
Enterprise governance by default
Model independence
Reusable agent building blocks
Private & hybrid deployment
Full-stack observability
```

## Grid example desktop

```txt
┌───────────────────────┬──────────┬──────────┐
│ Outcome-driven        │Governance│ Model    │
│ 2 cols wide           │          │ freedom  │
├────────────┬──────────┴──────────┼──────────┤
│ Reusable   │ Hybrid / private   │Observe   │
│ agents     │ 2 cols wide        │          │
└────────────┴─────────────────────┴──────────┘
```

Mix:

- dark photographic cards
- one pale blue card
- one diagram card
- one light surface

This gives visual variety while preserving a restricted palette.

## Card content

Keep text at bottom-left.

Title: 18–22px.

Description: no more than 2 lines.

---

# 18. Section 09 — Use Cases / Proven Outcomes

Reference pattern: horizontal cards with cinematic full-bleed imagery.

Heading:

```txt
Built for real
enterprise workflows.
```

Cards could include:

```txt
Intelligent Operations
Enterprise Knowledge Assistant
Data Analyst Agent
Customer Service Agent
Coding Assistant
Risk & Compliance Assistant
```

Each card:

```txt
Category pill
Title
One-line business outcome
Image / abstract art
```

Example:

```txt
DATA & ANALYTICS

Data Analyst Agent

Turn natural-language questions into governed analysis across enterprise data.
```

## Interaction

- Desktop horizontal scroll / drag.
- Mouse wheel can remain page scroll; do not hijack scrolling.
- Arrow navigation optional.
- Cards reveal 4th/5th item partially to indicate more content.
- `scroll-snap-type: x mandatory` on mobile.

---

# 19. Section 10 — Governance / Security / Observability

Use an editorial split section rather than an icon grid.

Heading:

```txt
Control every AI interaction.
```

Three categories:

### Governance

```txt
Policy
Prompt / model registry
Approval workflow
Lineage
Auditability
```

### Security

```txt
Authentication
Authorization
PII protection
Secrets
Network isolation
```

### Observability

```txt
Langfuse
Tracing
Latency
Token / GPU usage
Cost
Agent execution telemetry
```

Visualize a trace flowing through:

```txt
Application → Agent → Retrieval / Tool → Model → Response
```

Use subtle animated dots on the path.

---

# 20. Section 11 — FAQ

Reference pattern: title/contact box on left, accordion on right.

## Left

```txt
FAQ

Still have a question?
Talk to our platform team.

[Contact us]
```

## Right

Suggested questions:

```txt
Can this platform run on-premise?
Can we use multiple LLM providers?
How does the platform integrate with our existing data platform?
Do we need Kubernetes?
How are agents governed and audited?
Can existing RAG applications migrate to the platform?
How is model cost tracked?
Does the platform support private open-source models?
```

## Interaction

- Plus icon → rotate to close state.
- Only one question open by default.
- Animate height 220–300ms.
- No giant borders around each row.
- Use thin separators.

---

# 21. Section 12 — Final CTA

Use a dark gradient panel similar to the hero.

Heading example:

```txt
Ready to make AI
an enterprise capability?
```

Supporting:

```txt
Start with one use case. Build on a platform designed to scale to the next hundred.
```

CTA:

```txt
[Talk to our team →]
```

Optional secondary CTA:

```txt
View architecture
```

Keep this block large and cinematic.

---

# 22. Footer

The reference footer is integrated into a dark gradient surface.

Recommended layout:

```txt
[Logo]

Platform        Resources       Company        Contact
Architecture    Documentation   About          Email
AI Gateway      Case Studies    Careers        LinkedIn
Agent Runtime   Blog            Security       GitHub
Knowledge       FAQ

© 2026 Company. All rights reserved.                Back to top ↑
```

Footer text should remain small and restrained.

No oversized newsletter section unless business needs it.

---

# 23. Component Library

Build reusable components rather than hardcoding sections.

Suggested structure:

```txt
components/
  layout/
    Container.tsx
    Section.tsx
    Grid.tsx

  navigation/
    Header.tsx
    MobileMenu.tsx

  ui/
    Button.tsx
    Pill.tsx
    Eyebrow.tsx
    SectionHeader.tsx
    Divider.tsx
    Accordion.tsx

  visual/
    GradientPanel.tsx
    AbstractNetwork.tsx
    ArchitectureDiagram.tsx
    TechnologyMarquee.tsx

  cards/
    CapabilityCard.tsx
    BentoCard.tsx
    UseCaseCard.tsx
    ImageFeatureCard.tsx

  sections/
    Hero.tsx
    TrustStrip.tsx
    PlatformOverview.tsx
    Architecture.tsx
    CapabilityExplorer.tsx
    PlatformLayers.tsx
    DeliveryApproach.tsx
    BenefitsBento.tsx
    UseCases.tsx
    Governance.tsx
    FAQ.tsx
    FinalCTA.tsx
    Footer.tsx
```

---

# 24. Button System

Three variants only.

## Primary dark

```txt
Dark background
White text
Pill shape
```

## Secondary outline

```txt
Transparent
1px neutral border
Dark text
```

## Text link

```txt
Label →
```

### Button sizing

```txt
Height: 44–48px
Horizontal padding: 18–24px
Text: 14–15px
```

### Hover

Primary:

```txt
scale: 1 → 1.015
background lightens slightly
arrow translates 2–4px
```

Duration: 180–220ms.

Do not use dramatic glow effects.

---

# 25. Motion System

Motion should reinforce clarity and premium quality.

Recommended library:

```txt
Framer Motion / Motion for React
```

or native CSS where possible.

## 25.1 Scroll reveal

```txt
opacity: 0 → 1
translateY: 18px → 0
blur: 4px → 0 optional
```

Duration:

```txt
500–800ms
```

Easing:

```css
cubic-bezier(0.22, 1, 0.36, 1)
```

## 25.2 Stagger

Cards:

```txt
60–100ms between children
```

Do not animate every single line of body text.

## 25.3 Dark gradient motion

Background lights can slowly drift over 10–20 seconds.

The motion should be nearly subconscious.

## 25.4 Architecture diagram

When entering viewport:

```txt
1. Layer labels fade in.
2. Main path draws vertically.
3. Supporting platform nodes appear.
4. Small data pulse travels along path.
```

Total sequence: 1.2–1.8 seconds.

Do not loop aggressively.

## 25.5 Reduced motion

Always support:

```css
@media (prefers-reduced-motion: reduce)
```

Disable non-essential animation.

---

# 26. Image Direction

The website imagery should look curated as one system.

Preferred visual themes:

- enterprise data environments
- abstract network topology
- dimensional nodes
- dark data centers
- blurred motion
- architectural lighting
- abstract machine perception
- information geometry
- soft maps / graphs / mesh

Image characteristics:

```txt
Muted colors
Cool tone
Deep navy / gray
High contrast focal subject
Minimal visual clutter
```

Avoid:

- smiling corporate meeting stock photos
- robots shaking hands
- blue hologram hands
- obvious AI-generated people
- rainbow AI brains
- excessive code screenshots

---

# 27. Architecture Diagram Visual Style

Architecture graphics are a key brand asset and must follow the same visual language.

## Design

- white or pale-blue canvas
- 1px neutral borders
- dark primary labels
- muted secondary labels
- minimal icons
- rounded 16–20px module cards
- generous spacing
- directional arrows with strong hierarchy

## Platform colors

Do not use one random color per service.

Instead:

```txt
Core runtime = dark navy
Gateway = blue-gray
Knowledge / data = pale blue
Tools = cool gray
Governance / security / observability = light neutral
```

Service logos may be displayed in monochrome or their original colors at reduced visual prominence.

---

# 28. Responsive Design

## Desktop ≥ 1200px

- Full editorial grid.
- Large dark hero surface.
- Bento grid asymmetric.
- Horizontal use-case rail.

## Tablet 768–1199px

- 2-column sections can remain two-column if readable.
- Bento converts to 2-column.
- Reduce section spacing ~20%.
- Heading sizes scale via `clamp()`.

## Mobile ≤ 767px

Important rules:

1. Every section becomes linear and intentional.
2. Do not preserve desktop whitespace literally.
3. Dark hero radius reduces to 20px.
4. Hero height uses content, min-height ~620px.
5. Architecture diagram becomes vertical stack.
6. Capability explorer becomes accordion/tabs.
7. Bento becomes 1 column or selective 2-column mini-grid.
8. Horizontal use cases use snap scroll.
9. Minimum touch target = 44px.
10. Body text never below 15px.

---

# 29. Accessibility

Minimum requirements:

- WCAG AA contrast.
- Semantic heading hierarchy.
- Keyboard-accessible nav, tabs, accordion and sliders.
- Visible focus states.
- Alt text for meaningful imagery.
- Decorative images use empty alt.
- Do not encode information using color only.
- Respect reduced motion.
- Buttons must use `<button>`; navigation uses `<a>`.

Focus style:

```css
outline: 2px solid rgba(79, 120, 157, 0.8);
outline-offset: 3px;
```

---

# 30. Implementation Recommendation

Recommended stack:

```txt
Next.js 15+
React
TypeScript
Tailwind CSS
Motion / Framer Motion
Lucide icons
Geist font
```

Optional:

```txt
Lenis — only if smooth scrolling is truly needed
Three.js — avoid unless a specific hero visual requires it
```

The site should still feel premium without WebGL.

---

# 31. Tailwind Theme Direction

Suggested tokens:

```ts
// tailwind.config / CSS variables
colors: {
  page: '#F7F8F8',
  surface: '#FFFFFF',
  soft: '#F0F3F5',
  ink: '#111418',
  muted: '#697078',
  line: '#E5E8EA',
  navy: {
    950: '#07111C',
    900: '#0C1723',
    850: '#122131',
    800: '#172A3E',
  }
}
```

Use custom spacing values where needed rather than forcing all sections into default Tailwind spacing.

---

# 32. Page Width / Visual Framing

An important characteristic of the reference is that major dark sections often appear as a contained "stage" inside a larger light page.

Reproduce this feeling with:

```txt
White page
  ↓
Large centered rounded stage
  ↓
Content inside stage
```

Do not make every section full-bleed edge-to-edge.

Recommended width pattern:

```txt
Page = 100%
Main stage = 92–94% viewport, max 1440px
Inner content = 80–88% of stage
```

This framing is one of the most important elements of the design language.

---

# 33. Content Density Rules

For a premium result:

- One major idea per viewport.
- Do not show all platform details on homepage.
- Maximum 4–6 bullets per feature block.
- Maximum 3 CTAs visible in one viewport.
- Avoid more than 6 cards in a static grid.
- Use progressive disclosure for technical depth.

Homepage explains **why and how the platform fits together**.

Dedicated platform pages explain detailed features.

---

# 34. Dedicated Platform Pages

The homepage should link to deeper pages.

Recommended information architecture:

```txt
/platform
  /agent-runtime
  /ai-gateway
  /knowledge-platform
  /model-runtime
  /tool-mcp-platform
  /governance-observability

/solutions
  /enterprise-rag
  /data-analyst-agent
  /customer-service
  /coding-agent
  /operations-agent

/architecture
/resources
/company
/contact
```

Individual pages must reuse the same visual system and should not introduce a new design language.

---

# 35. Homepage Wireframe

```txt
┌─────────────────────────────────────────────────────────────┐
│ NAV                                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────── DARK HERO ───────────────────────────┐   │
│   │                                                      │   │
│   │           Enterprise AI, built to operate.           │   │
│   │                                                      │   │
│   │         [Explore Platform] [Architecture →]          │   │
│   │                                                      │   │
│   └──────────────────────────────────────────────────────┘   │
│                                                             │
│             TECHNOLOGY / CUSTOMER LOGO STRIP                │
│                                                             │
│  ┌──────────────┐   PLATFORM OVERVIEW                       │
│  │ Abstract AI  │   Turn fragmented AI experiments          │
│  │ visual       │   into an enterprise AI system.           │
│  └──────────────┘                                           │
│                                                             │
│            LARGE PLATFORM ARCHITECTURE SECTION              │
│                                                             │
│  CAPABILITY LIST             ACTIVE CAPABILITY DETAIL       │
│                                                             │
│  Platform Layers / product story                            │
│                                                             │
│  DELIVERY APPROACH            [visual][visual][visual]       │
│                                                             │
│                    BENTO BENEFITS                           │
│                                                             │
│  Built for real enterprise workflows                       │
│  [CASE][CASE][CASE][CASE →]                                 │
│                                                             │
│  GOVERNANCE / SECURITY / OBSERVABILITY                      │
│                                                             │
│  FAQ                       ACCORDION                         │
│                                                             │
│   ┌──────────────── FINAL DARK CTA ─────────────────────┐    │
│   │ Make AI an enterprise capability.                  │    │
│   └────────────────────────────────────────────────────┘    │
│                                                             │
│                      DARK FOOTER                            │
└─────────────────────────────────────────────────────────────┘
```

---

# 36. Design Anti-Patterns — Do Not Do These

Do not:

- Fill the page with blue gradients.
- Put every service inside its own tiny bordered card.
- Use dozens of colorful icons.
- Animate every component.
- Use glassmorphism everywhere.
- Use giant glowing text.
- Create a cyberpunk visual style.
- Make architecture diagrams too detailed for marketing pages.
- Use 4–5 different font families.
- Use more than one primary CTA style.
- Add carousels that auto-scroll quickly.
- Hide important content behind animation.
- Use dark background for the entire website.

---

# 37. Quality Bar / Acceptance Criteria

Before shipping, compare the implementation against these criteria.

## Visual

- [ ] Page is visually dominated by white / light neutral surfaces.
- [ ] Hero and final CTA use restrained navy gradient surfaces.
- [ ] Major surfaces use large rounded corners.
- [ ] Spacing feels intentionally generous.
- [ ] Typography is clear and editorial.
- [ ] No section looks visually overcrowded.
- [ ] Imagery shares one coherent cool-toned art direction.
- [ ] Architecture graphics match the rest of the brand.

## UX

- [ ] User understands the product category within 5 seconds.
- [ ] User understands the architecture within 30 seconds.
- [ ] Primary CTA appears in header, hero and final CTA only.
- [ ] Platform capabilities have progressive disclosure.
- [ ] Horizontal cards work with touch and keyboard.
- [ ] FAQ is keyboard accessible.

## Motion

- [ ] Motion is subtle and not distracting.
- [ ] No scroll hijacking.
- [ ] Reduced-motion preference is respected.
- [ ] Initial page content is visible without waiting for animations.

## Responsive

- [ ] No desktop architecture diagram is simply scaled down on mobile.
- [ ] No horizontal text overflow.
- [ ] Tap targets ≥ 44px.
- [ ] Mobile section rhythm remains spacious.

## Performance

Target:

```txt
LCP < 2.5s
CLS < 0.1
INP < 200ms
Lighthouse Performance > 90 where practical
```

- [ ] Images use `next/image` or equivalent optimization.
- [ ] Hero animation does not block first paint.
- [ ] Video backgrounds are avoided unless essential.
- [ ] Lazy-load below-the-fold imagery.

---

# 38. AI Coding Agent Instructions

When this file is used as context for an AI coding assistant, follow these rules strictly:

1. Do not invent a new visual style.
2. Reuse the design tokens defined in this document.
3. Prefer fewer, larger components over many small cards.
4. Keep the homepage visually light and spacious.
5. Use dark navy surfaces only as narrative anchors.
6. Preserve consistent corner radius and spacing.
7. Use motion only when it communicates hierarchy or state.
8. Architecture must be a first-class visual element.
9. Enterprise trust and clarity are more important than visual novelty.
10. If uncertain between a simpler and more decorative solution, choose the simpler solution.

---

# 39. Suggested First Implementation Sprint

Build in this order:

```txt
1. Design tokens + typography
2. Header / container / section primitives
3. Hero dark stage
4. Platform overview
5. Architecture section
6. Capability explorer
7. Bento benefits
8. Use-case horizontal rail
9. FAQ
10. Final CTA + footer
11. Responsive pass
12. Motion pass
13. Performance / accessibility pass
```

Do not start with animation before layout and typography are correct.

---

# 40. Final Design Summary

The intended website should look like a **modern enterprise AI infrastructure brand** rather than a generic AI SaaS product.

Its strongest visual characteristics are:

```txt
Editorial whitespace
+ cinematic navy stages
+ precise typography
+ architecture-led storytelling
+ restrained bento layouts
+ premium technical imagery
+ subtle motion
+ enterprise credibility
```

When implemented correctly, the website should feel calm enough for executives while still containing enough technical structure to earn credibility with architects, engineering teams, and AI practitioners.
