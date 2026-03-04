# AGENTS.md

Guidelines for AI coding agents working in the **Hanas Data Platform** documentation repository.

---

## Project Overview

This is a technical documentation site for the Hanas Data Lakehouse Platform, built with **Docusaurus 3.9** (TypeScript). The site covers 7 data layers: Ingestion → Storage → Processing → Data Model → Governance → Federation → System Management, plus AI Services.

**Repository layout:**
```
hanas_docs/
├── website/               # Docusaurus project (primary source)
│   ├── docs/              # All documentation content (Markdown/MDX)
│   │   ├── 00-overview/   # Architecture, objectives, glossary
│   │   ├── 01-ingestion/  # NiFi, Kafka
│   │   ├── 02-storage/    # MinIO, Iceberg
│   │   ├── 03-processing/ # Airflow, Spark
│   │   ├── 04-data-model/ # dbt, Data Vault 2.0
│   │   ├── 05-governance/ # DataHub
│   │   ├── 06-federation/ # Dremio
│   │   ├── 07-system-management/ # OpenObserve
│   │   ├── 08-infrastructure/    # Kubernetes, DC-DR
│   │   ├── 09-security/   # Ranger, HashiCorp Vault
│   │   ├── 10-training/   # Training materials
│   │   ├── 11-maintenance/# SLA, maintenance processes
│   │   ├── 12-ai-service/ # Dify, vLLM, Langfuse
│   │   ├── 13-visualization/
│   │   ├── 14-orchestration/
│   │   └── guides/        # Quickstart, tutorials, examples
│   ├── src/               # React/TSX components and pages
│   │   ├── components/    # Reusable UI components
│   │   ├── pages/         # Landing page (index.tsx)
│   │   └── theme/         # Docusaurus theme overrides
│   ├── static/            # Static assets (images, robots.txt)
│   ├── docusaurus.config.ts
│   ├── sidebars.ts
│   ├── tsconfig.json
│   └── package.json
├── docs/                  # Mirror/backup of website/docs
├── in_progress/           # Draft documentation
├── .github/workflows/     # CI/CD pipeline
├── Dockerfile
└── docker-compose.yml
```

---

## Build / Dev / Lint Commands

All commands run from `website/` (requires **Node.js ≥ 20**).

```bash
# Install dependencies
cd website && npm install

# Start local dev server (hot reload) at http://localhost:3000
npm start

# Build static site into website/build/
npm run build

# Type-check TypeScript (no emit)
npm run typecheck

# Serve the built site locally
npm run serve

# Clear Docusaurus cache (fixes stale build issues)
npm run clear

# Docusaurus CLI passthrough
npm run docusaurus -- --help
```

**Docker (alternative dev workflow):**
```bash
# Dev server with hot reload at http://localhost:3000
docker-compose --profile dev up docs-dev

# Production build at http://localhost:80
docker-compose --profile prod up -d docs-prod
```

**No test framework is configured.** There are no Jest/Vitest/Playwright tests. Validation is done via `npm run typecheck` + `npm run build`.

**CI pipeline** (`.github/workflows/ci-cd.yml`) runs:
1. `npm ci` → `npm run typecheck` → `npm run build` on every push/PR to `main`/`develop`
2. Docker build & push on merge
3. Deploy to staging (`develop` branch) or production (semver tags)

---

## Documentation File Conventions

Each service follows a consistent page structure. When creating or editing docs:

**Standard page set per service** (e.g., `website/docs/01-ingestion/apache-nifi/`):
```
README.md          # Overview, comparison table, architecture diagram
installation.md    # System requirements, step-by-step K8s install
configuration.md   # Config files, environment variables, tuning
user-guide.md      # Common operations with examples
best-practices.md  # Production recommendations
version-info.md    # Version compatibility matrix
```

**Markdown frontmatter** — Use Docusaurus frontmatter only when needed (e.g., `sidebar_position`, `slug`). Main `README.md` of each section uses:
```markdown
---
sidebar_position: 0
slug: /section-name
---
```
Most sub-pages omit frontmatter entirely (Docusaurus infers from filename).

**Language**: All documentation content is **Vietnamese** (default locale: `vi`). Code blocks, command examples, and technical terms remain in English. Comments in shell scripts are in Vietnamese.

**Mermaid diagrams**: Enabled globally. Use ```` ```mermaid ```` fenced blocks freely for architecture diagrams, sequence diagrams, and flowcharts.

**Tables**: Preferred for comparison matrices (`|---|---|` style). No alignment padding required.

---

## TypeScript / React Code Style

Config: `tsconfig.json` extends `@docusaurus/tsconfig`. No explicit ESLint or Prettier configs — follow patterns from existing source files.

### Imports
```typescript
// React import is explicit in components
import React from 'react';                          // component files
import React, { useState, useCallback, useRef } from 'react'; // when using hooks

// Type-only imports use inline type keyword
import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';
import type { WrapperProps } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// Docusaurus path aliases
import Layout from '@theme/Layout';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import styles from './styles.module.css';           // CSS modules
import HeroSection from '@site/src/components/HeroSection'; // cross-component imports
```

### Component patterns
```typescript
// Functional components with explicit return type
export default function Home(): ReactNode { ... }
export default function CaseStudySection(): React.JSX.Element { ... }

// Named function components as const
const NewsletterForm: React.FC = () => { ... };

// Props interfaces — PascalCase, defined inline or above component
interface ArchitectureLayer {
  id: string;
  name: string;
  technologies: string[];
}

// Generic React props via WrapperProps (for theme overrides)
type Props = WrapperProps<typeof ContentType>;
```

### Naming conventions
- **Files/Directories**: `PascalCase` for component directories (`HeroSection/`, `TechStackSection/`), lowercase `index.tsx` entry point inside each
- **Component names**: PascalCase (`HeroSection`, `CTABanner`)
- **CSS modules**: `styles.module.css` in same directory as component
- **Interfaces**: PascalCase with descriptive names (`TechItem`, `FeatureCard`)
- **Type aliases**: PascalCase (`TabId`)
- **Constants/data arrays**: camelCase (`footerColumns`, `technologies`, `layers`)
- **Environment/config variables**: UPPER_SNAKE_CASE

### CSS Modules
```css
/* Use camelCase class names in module files */
.heroSection { ... }
.animateIn { ... }
.gradientText { ... }
```

### Inline SVGs
Prefer inline SVG icon components with `aria-hidden="true"`, `currentColor` stroke, standardized viewBox `0 0 24 24`. Size via explicit `width`/`height` props (typically `20` or `32`).

### Docusaurus config (`docusaurus.config.ts`)
Use `satisfies Preset.Options` and `satisfies Preset.ThemeConfig` for type-safe config objects. Export as `export default config`.

---

## Sidebars (`sidebars.ts`)

Sidebars use the object-based `SidebarsConfig` type. Doc IDs are **path-relative without numeric prefixes** (Docusaurus strips the `XX-` folder prefix):

```typescript
// Folder: website/docs/01-ingestion/apache-nifi/installation.md
// Doc ID: 'ingestion/apache-nifi/installation'   ✅
// NOT:    '01-ingestion/apache-nifi/installation' ❌
```

When adding a new page, add its doc ID to `sidebars.ts` in the correct category. Use `collapsed: true` for service categories (consistent with existing entries).

---

## Key Constraints

- **No tests to run** — validate with `npm run typecheck` and `npm run build`
- **No ESLint / Prettier config** — match style of surrounding files exactly
- **onBrokenLinks: 'warn'** — broken internal links are warnings, not errors, but fix them anyway
- **Blog is disabled** — do not add blog posts
- **Vietnamese content** — all user-facing text in docs must be in Vietnamese; code stays English
- **Node ≥ 20 required** — do not use Node 18 syntax or features deprecated in 20+
- **React 19** — project uses React 19; avoid patterns deprecated in React 19
- **Never commit `website/build/`** — it's generated; `.gitignore` excludes it
- **`in_progress/` folder** — draft content not yet published; do not add to sidebars

---

## Common Tasks

**Add a new doc page:**
1. Create `website/docs/<section>/<service>/<page>.md`
2. Add the doc ID to `website/sidebars.ts` in the appropriate category
3. Run `npm run build` to verify no broken links

**Add a new React component:**
1. Create `website/src/components/<ComponentName>/index.tsx` + `styles.module.css`
2. Import with `@site/src/components/<ComponentName>`
3. Run `npm run typecheck` to validate

**Fix a build error:**
```bash
cd website
npm run clear   # clear stale cache first
npm run build   # full build with error output
```
