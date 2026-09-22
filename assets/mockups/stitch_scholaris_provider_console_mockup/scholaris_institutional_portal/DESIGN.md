---
name: Scholaris Institutional Portal
colors:
  surface: '#f9f9f7'
  surface-dim: '#dadad8'
  surface-bright: '#f9f9f7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f4f2'
  surface-container: '#eeeeec'
  surface-container-high: '#e8e8e6'
  surface-container-highest: '#e2e3e1'
  on-surface: '#1a1c1b'
  on-surface-variant: '#404942'
  inverse-surface: '#2f3130'
  inverse-on-surface: '#f1f1ef'
  outline: '#707971'
  outline-variant: '#c0c9c0'
  surface-tint: '#306948'
  primary: '#00351c'
  on-primary: '#ffffff'
  primary-container: '#0f4d2e'
  on-primary-container: '#82bd95'
  inverse-primary: '#98d4ab'
  secondary: '#7a5900'
  on-secondary: '#ffffff'
  secondary-container: '#febf2c'
  on-secondary-container: '#6e4f00'
  tertiary: '#0c2e50'
  on-tertiary: '#ffffff'
  tertiary-container: '#274567'
  on-tertiary-container: '#96b3db'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b3f1c6'
  primary-fixed-dim: '#98d4ab'
  on-primary-fixed: '#002110'
  on-primary-fixed-variant: '#145131'
  secondary-fixed: '#ffdea3'
  secondary-fixed-dim: '#fabc28'
  on-secondary-fixed: '#261900'
  on-secondary-fixed-variant: '#5d4200'
  tertiary-fixed: '#d2e4ff'
  tertiary-fixed-dim: '#abc9f2'
  on-tertiary-fixed: '#001c38'
  on-tertiary-fixed-variant: '#2b486b'
  background: '#f9f9f7'
  on-background: '#1a1c1b'
  surface-variant: '#e2e3e1'
typography:
  headline-xl:
    fontFamily: Montserrat
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Montserrat
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Montserrat
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
  headline-sm:
    fontFamily: Montserrat
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  body-lg:
    fontFamily: Open Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Open Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Open Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Open Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Open Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Open Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1.5rem
  margin: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style
The design system powers an institutional scholarship provider management console designed for Philippine educational trusts, government agencies, non-governmental organizations, and academic benefactors. The emotional tone balances civic prestige, administrative rigor, and modern operational clarity. 

The aesthetic adheres to **Corporate / Modern** institutional architecture with crisp, high-contrast dashboard motifs. It trades generic SaaS ephemerality for rooted civic authority, featuring dense tabular records, high-contrast badge systems, modular card rows, and crisp linear demarcations suited for complex applicant tracking and disbursement audits.

## Colors
The palette is rooted in Filipino civic tradition and institutional trustworthiness:

- **Primary (`#0F4D2E` — Bridge Green):** Conveys stability, prosperity, and state stewardship. Used for primary calls-to-action, key active navigation anchors, and dominant branding elements.
- **Sidebar Dark (`#0A321E`):** A deep evergreen foundation for permanent desktop navigation chrome, establishing grounding contrast against the light canvas.
- **Secondary (`#F1B41E` — Golden Opportunity):** An optimistic golden yellow reserved for priority calls-to-action, pending verification states, and highlighted metric indicators.
- **Tertiary (`#1B3A5C` — Civic Navy):** Used for data visualization series, deep data categorization badges, and secondary analytical navigation.
- **Danger / Coral (`#FF6F59`):** Reserved for deadline lapses, disqualifications, and destructive administrative actions.
- **Neutral Canvas (`#FAFAF8`):** An ivory-tinted, warm clinical background designed to reduce glare during heavy clerical review.
- **Surfaces & Borders:** Inner cards sit on clean `#FFFFFF` with precise `#E5E7EB` architectural boundaries.

## Typography
Typographic scale leverages **Montserrat** for geometric, authoritative, and legible institutional titling (replacing Poppins for sharper professional presence and dense numeric-alphanumeric tracking) and **Open Sans** for humanistic, neutral body copy and microdata.

Display headings prioritize tight tracking (`-0.02em`) to deliver structured presence in dashboard headers. Numerical values, financial disbursements, and tabular applicant IDs rendered in body sizes should enforce proportional lining figures for aligned readability across data tables.

## Layout & Spacing
The layout follows a multi-panel workspace architecture:
- **Persistent Sidebar Navigation:** Fixed 260px wide dark container (`#0A321E`) for core institutional controls.
- **Main Operational Canvas:** Fluid 12-column grid system bounded inside a fluid canvas with 32px (`2rem`) margins on desktop.
- **Form Factors & Breakpoints:**
  - **Desktop (>= 1280px):** Permanent 260px sidebar, 12-column grid, 24px gutters, 32px canvas margins.
  - **Tablet (768px – 1279px):** Collapsed icon-only sidebar (72px), 8-column grid, 16px gutters, 24px margins.
  - **Mobile (< 768px):** Off-canvas drawer navigation, single-column reflow, 16px gutters, 16px canvas margins. Tabular card rows collapse into vertical stack records.

## Elevation & Depth
Visual structure relies on **low-contrast outlines** complemented by **subtle ambient shadows** rather than high-elevation z-planes. This reinforces institutional structure and keeps dense data legible without blurred distraction:

- **Level 0 (Canvas):** `#FAFAF8` base backdrop.
- **Level 1 (Card & Content Modules):** Pure `#FFFFFF` fill with a `1px solid #E5E7EB` perimeter outline and an ambient shadow: `0 1px 3px rgba(10, 50, 30, 0.04), 0 1px 2px rgba(10, 50, 30, 0.02)`.
- **Level 2 (Hover & Active States):** `0 4px 6px -1px rgba(10, 50, 30, 0.07), 0 2px 4px -2px rgba(10, 50, 30, 0.05)`, border shifts subtly to `#D1D5DB`.
- **Level 3 (Modals, Overlays, Dropdowns):** `0 10px 15px -3px rgba(10, 50, 30, 0.1), 0 4px 6px -4px rgba(10, 50, 30, 0.06)` with a crisp `1px solid #D1D5DB` edge.

## Shapes
The shape language uses **Soft** geometry (`0.25rem` / `4px` default radius) to emphasize programmatic reliability and structured data governance. 

- **Inputs, Buttons, Badges, Table Rows:** `rounded` (`4px` / `0.25rem`).
- **Cards, Filter Bars, Data Panels:** `rounded-lg` (`8px` / `0.5rem`).
- **Modal Viewports & Presentation Frames:** `rounded-xl` (`12px` / `0.75rem`).
- **Status Badges & Avatar Containers:** Standardize on functional micro-radii (`4px`) rather than pills, maintaining an executive editorial tone throughout data lists.

## Components

### Buttons
- **Primary:** Solid `#0F4D2E` background, `#FFFFFF` text, `4px` radius, 40px height for standard controls (`12px 20px` padding), `label-lg` typography. Hover: `#0A321E`. Focus: 2px offset ring in `#F1B41E`.
- **Secondary (Golden Accent):** `#F1B41E` fill with `#0A321E` bold text for immediate actions (e.g., "Award Grant", "Approve Cohort"). Hover: `#D99F16`.
- **Outline / Neutral:** `#FFFFFF` background, `1px solid #D1D5DB`, `#1B3A5C` text. Hover: `#F3F4F6`.
- **Destructive:** Borderless or solid `#FF6F59` fill with `#FFFFFF` text for rejection or revocation pipelines.

### Chips & Status Badges
- High-contrast, micro-padded (`2px 8px`), `label-sm` uppercase text, `4px` corner radius.
- **Approved / Active:** Soft green tint (`#E7F3EC`) with `#0F4D2E` text and `1px solid #C4E2D1`.
- **Pending / Action Needed:** Soft gold tint (`#FEF7E6`) with `#8F6400` text and `1px solid #FCDFA0`.
- **Under Review:** Soft navy tint (`#E8EEF5`) with `#1B3A5C` text and `1px solid #C5D5E8`.
- **Disqualified / Inactive:** Soft coral tint (`#FFEBE8`) with `#C53320` text and `1px solid #FFC2BA`.

### Card Rows & Data Lists
- Scholarship applicant rows arranged as discrete white modules (`#FFFFFF`) with `1px solid #E5E7EB` borders.
- Hover transition introduces a `1px solid #0F4D2E` left-accent indicator border and elevation level 2.
- Data displays group student metadata into 4 standardized columns: Scholar Details, Academic Program / GWA, Funding Tier, and Application Status Action.

### Input Fields & Controls
- **Inputs:** 40px field height, `#FFFFFF` surface, `1px solid #D1D5DB`, `12px 14px` padding. Focus transitions border to `#0F4D2E` with a `3px` glow ring tinted at `rgba(15, 77, 46, 0.15)`.
- **Checkboxes & Radios:** `16px x 16px`, `2px` border radius on checkboxes. Checked state uses solid `#0F4D2E` fill with white check glyph.

### Browser Frame Mockup & Presentation Shell
- Top window title bar styled in `#F3F4F6` with subtle traffic light controls (`#E5E7EB` or muted gray dots), bounded by an outer `1px solid #E5E7EB` casing.
- Window chrome features an institutional URL indicator bar displaying breadcrumbs (e.g., `console.scholaris.ph / providers / batch-2025-cycle-1`).