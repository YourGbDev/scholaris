---
name: Scholaris Sequoia
colors:
  surface: '#faf9fe'
  surface-dim: '#dad9df'
  surface-bright: '#faf9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f8'
  surface-container: '#eeedf3'
  surface-container-high: '#e9e7ed'
  surface-container-highest: '#e3e2e7'
  on-surface: '#1a1b1f'
  on-surface-variant: '#404942'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f1f0f5'
  outline: '#707971'
  outline-variant: '#c0c9c0'
  surface-tint: '#306948'
  primary: '#00351c'
  on-primary: '#ffffff'
  primary-container: '#0f4d2e'
  on-primary-container: '#82bd95'
  inverse-primary: '#98d4ab'
  secondary: '#0058bc'
  on-secondary: '#ffffff'
  secondary-container: '#0070eb'
  on-secondary-container: '#fefcff'
  tertiary: '#442600'
  on-tertiary: '#ffffff'
  tertiary-container: '#623a00'
  on-tertiary-container: '#f99a00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b3f1c6'
  primary-fixed-dim: '#98d4ab'
  on-primary-fixed: '#002110'
  on-primary-fixed-variant: '#145131'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a41'
  on-secondary-fixed-variant: '#004493'
  tertiary-fixed: '#ffddbb'
  tertiary-fixed-dim: '#ffb868'
  on-tertiary-fixed: '#2b1700'
  on-tertiary-fixed-variant: '#673d00'
  background: '#faf9fe'
  on-background: '#1a1b1f'
  surface-variant: '#e3e2e7'
typography:
  display:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.022em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.021em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.019em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.019em
  headline-sm:
    fontFamily: Inter
    fontSize: 19px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.015em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.011em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: -0.006em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: -0.008em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: -0.002em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.25rem
  gutter-mobile: 0.75rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system translates the institutional prestige of higher education and scholarship funding into the refined, tactile, and translucent idioms of modern Apple desktop and tablet interfaces (macOS Sequoia and iPadOS). It eliminates bureaucratic academic clutter in favor of an effortless, high-trust spatial experience. The interface balances institutional authority with native fluidity, evoking absolute precision, clarity, and academic aspiration.

The design movement synthesizes modern Corporate/Human Interface Design with precise Glassmorphism. Structural planes use authentic macOS-inspired materials—translucent vibration surfaces, hairline specular keylines, squircle geometry, and deep layered optical relief. The atmosphere is quiet and distraction-free: chrome retreats into translucent blurs, foregrounding complex academic dossiers, research metrics, and scholarship disbursement lifecycles.

## Colors

The palette grounds Apple’s neutral framework in the dignified heritage of Scholaris Forest Green.

- **Primary (`#0F4D2E`):** Academic deep forest green. Deployed selectively for primary commitment actions, high-tier status badges, verified institution badges, and active state highlights within navigation rails.
- **Secondary (`#007AFF`):** Apple System Blue. Directs actionable utility, interactive inline hypermedia, metadata filters, and platform-level navigational markers.
- **Tertiary (`#FF9F0A`):** System Amber. Signals conditional states, application deadlines, review flags, and pending verifications.
- **Neutral (`#8E8E93`):** System Gray benchmark for inactive controls, secondary iconography, and intermediate structural borders.

### Canvas & Surface Hierarchy
- **Base Canvas:** `#F5F5F7` (Apple System Light Gray canvas background).
- **Secondary Translucent Canvas:** `rgba(251, 251, 253, 0.8)` with backdrop blur for secondary panels and sidebars.
- **Surface Elevation (Cards & Modals):** `#FFFFFF` with ultra-fine border definition.
- **Text & Content Tone:** Primary typography rests at `#1D1D1F` for supreme optical contrast; secondary descriptive metadata rests at `#86868B`.
- **System Accents:** Success and disbursement indicators utilize Apple Emerald (`#34C759`).

## Typography

Typography mirrors the mechanical legibility and strict tracking matrices of Apple’s SF Pro Display and Text engine, rendered through Inter. The scale relies on tightened negative tracking across larger display sizes to achieve an intentional, tailored appearance, transitioning to neutral tracking at caption levels for legibility across metrics, data sheets, and documentation.

- **Display & Large Headlines:** Reserved for scholarship portal titles, endowment amounts, and milestone grant approvals. Tight tracking (`-0.022em`) and bold weight simulate Apple's high-impact hero headings.
- **Section & Card Headlines (`headline-sm`, `headline-md`):** Delineate academic portfolios, application checklists, and tabular data groupings.
- **Body (`body-lg`, `body-md`):** Balanced for dense institutional guidelines, essay prompt evaluations, and programmatic descriptions.
- **Labels & Captions (`label-md`, `label-sm`):** Rendered in Medium and Semibold weights; uppercase treatment is restricted strictly to `label-sm` when designating status badges, institutional codes, or micro-metadata tags.

## Layout & Spacing

The interface employs a unified multi-pane application layout derived from macOS Sequoia, structured through an integrated 12-column adaptive fluid grid.

### Layout Philosophy & Structure
- **Three-Pane Architecture (Desktop):** Collapsible translucent navigation sidebar (fixed 260px width), master selection or filter stream (span 4 columns), and detail dossier viewport (span 8 columns).
- **iPadOS Dual Split (Tablet):** Off-canvas dynamic sidebar with persistent split-screen content and inspector panel.
- **Single Canvas Navigation (Mobile):** Stack-based slide transition anchored by a floating translucent bottom bar or top utility bar.

### Grid Rhythm & Adapting Breakpoints
- **Desktop (1024px+):** Fluid 12 columns with `margin` of 2rem (32px) and column `gutter` of 1.25rem (20px). Titlebars sit at a persistent 52px height containing inline window-style search inputs and action pills.
- **Tablet (768px - 1023px):** Fluid 8 columns with 1.5rem exterior margins and 1rem gutters. Inspector tools fold into modal sheets.
- **Mobile (<768px):** Fluid 4 columns with `margin-mobile` of 1rem (16px) and `gutter-mobile` of 0.75rem (12px). Layout strips multi-column offsets into vertical vertical card clusters.

## Elevation & Depth

Visual depth is achieved through Apple-standard optical layering, realistic material physical behavior, translucent refraction, and specular ambient lighting rather than heavy drop shadows.

### Material & Surface Layers
- **Vibrancy Layer 0 (Window Canvas):** Solid `#F5F5F7` system gray base canvas.
- **Vibrancy Layer 1 (Translucent Panes & Sidebars):** `rgba(245, 245, 247, 0.75)` supported by `backdrop-filter: blur(24px) saturate(180%)`. Bordered on the trailing edge by a hairline separator: `1px solid rgba(0, 0, 0, 0.08)`.
- **Vibrancy Layer 2 (Raised Content Cards):** Opaque `#FFFFFF` surfaces inset with an ultra-subtle perimeter stroke: `1px solid rgba(0, 0, 0, 0.05)`.
- **Vibrancy Layer 3 (Floating Overlays & Popovers):** `rgba(255, 255, 255, 0.88)` backed by `backdrop-filter: blur(32px)`.

### Ambient Shadow Scales
- **Surface Rest:** `0 1px 2px rgba(0, 0, 0, 0.04), 0 0 0 1px rgba(0, 0, 0, 0.03)` (hairline depth bounding).
- **Card Rest:** `0 2px 8px rgba(0, 0, 0, 0.04), 0 1px 2px rgba(0, 0, 0, 0.02)`.
- **Card Hover / Active Focus:** `0 12px 24px -4px rgba(0, 0, 0, 0.08), 0 4px 8px -2px rgba(0, 0, 0, 0.03)`.
- **Modals & Command Sheets:** `0 24px 48px -12px rgba(0, 0, 0, 0.18), 0 0 1px rgba(0, 0, 0, 0.15)`.

## Shapes

The design system standardizes on Apple's continuous-curve corner geometries (squircles), dispensing with circular-arc corners to maintain visual continuity with macOS and iPadOS surfaces.

- **Primary Cards and Panels:** `rounded-2xl` (1rem / 16px continuous squircle), giving content containers an organic frame.
- **Interactive Controls (Inputs, Buttons, Menus):** `rounded-lg` (0.5rem / 8px continuous curvature) aligning with macOS control geometry.
- **Pills, Filters, and Segmented Pickers:** Fully rounded continuous caps (`9999px`) for segmented switches, contextual status tags, and inline category indicators.
- **Modals and Floating Dialogs:** `rounded-2xl` or `rounded-3xl` (1.5rem / 24px) with high-density edge definition.

## Components

### Buttons
- **Primary:** Solid Scholaris Forest Green (`#0F4D2E`) fill, white text, subtle specular top inner highlight (`inset 0 1px 0 rgba(255,255,255,0.2)`), `rounded-lg`, medium weight, height 36px (desktop) / 44px (touch).
- **Secondary / Glass:** `rgba(0, 0, 0, 0.04)` fill with `1px solid rgba(0, 0, 0, 0.08)`, `#1D1D1F` text. Active hover shifts to `rgba(0, 0, 0, 0.07)`.
- **Tertiary / Destructive / Utility:** Unbordered transparent button styling with System Blue (`#007AFF`) or System Red text, transforming on hover to soft tinted backgrounds.

### Cards
- Constructed with `#FFFFFF` or `rgba(255, 255, 255, 0.85)` (when over media/canvases).
- Bound by `1px solid rgba(0, 0, 0, 0.06)`, `rounded-2xl`, internal padding of `space-lg` (24px).
- Internal card headers combine metadata chip, title, and action ellipsis in a horizontal alignment.

### Chips & Badges
- Continuous squircle capsules (`9999px`).
- **Verified / Merit Tier:** Light green surface (`#E8F5E9` or `rgba(15, 77, 46, 0.08)`) with `#0F4D2E` typography and leading 6px circular indicator.
- **Deadline Critical:** Amber surface (`#FFF8E1`) paired with `#FF9F0A` text.
- **Neutral System Tags:** `#F2F2F7` surface with `#86868B` text.

### Segmented Controls & Pickers
- Recessed pill housing with `rgba(0, 0, 0, 0.05)` fill and `rounded-xl` boundary.
- Active item displays an elevated white pill (`#FFFFFF`) with `shadow-sm` (`0 1px 3px rgba(0,0,0,0.1)`), transitioning with smooth spring easing.

### Input Fields & Search Bars
- Inset field styling: `rgba(0, 0, 0, 0.03)` base with border `1px solid rgba(0, 0, 0, 0.1)`.
- Height: 34px (desktop density), 42px (mobile).
- Focused state: `#FFFFFF` fill with an Apple-style focus ring (`0 0 0 3px rgba(15, 77, 46, 0.25)` and border `#0F4D2E`).
- Integrated magnifying glass glyph prefixed with `#86868B` tone.

### Checkboxes & Toggle Switches
- **Checkboxes:** Standard 16x16px rounded-md squircle with `1px solid rgba(0, 0, 0, 0.2)`. Active checked state fills `#0F4D2E` with a white checkmark.
- **Switches:** Classic macOS 38x22px capsule switch with a floating white knob, sliding from inactive gray (`#E5E5EA`) to Forest Green (`#0F4D2E`).

### Specialized Domain Components
- **Unified Titlebar:** 52px macOS translucent toolbar containing navigation history carats, view segments, live grant counters, and integrated profile anchors.
- **Sidebar Rail:** Left-aligned 260px container with monochrome icons (20px) transitioning to `#0F4D2E` when active, surrounded by an active pill-shaped background (`rgba(15, 77, 46, 0.1)`).
- **Scholarship Progress Meter:** 6px rounded track (`rgba(0, 0, 0, 0.06)`) with a Forest Green linear gradient fill representing document verification and financial aid steps.