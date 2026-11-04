# Narrow-screen and enlarged-text limitations

This is an evidence report, not a new layout change. The current implementation is intact.

## Confirmed: Home dashboard, 320 × 844, 200% text

See [comparison 20](comparisons/20-web-home-large-text-320-comparison.png), captured in Chrome with device pixel ratio 1 and identical fixture data, appearance and text scaling.

| Element | Before: Geist | After: Inter | Consequence |
|---|---|---|---|
| Personalized Tagalog greeting, `Magandang umaga, Gb!` | Three lines: `Maganda` / `ng umaga,` / `Gb!` | Four lines: `Maganda` / `ng` / `umaga,` / `Gb!` | The long word splits in both versions; Inter's glyph widths add a line under the same width, size and weight constraints. |
| Date, `WEDNESDAY, NOVEMBER 4` | Two lines | Two lines | Expected wrapping at the enlarged size; not a newly introduced clipping defect. |
| Hero section, including `YOUR NEXT CHAPTER` and `Find your next opportunity.` | Starts higher in the initial viewport | Starts lower because the greeting takes another line | Less hero content is visible above the floating dock in the initial screenshot. This is reflow, not evidence by itself that the rest of the text is permanently clipped. |
| Bottom navigation: Home, Discover, Tracker, Profile | Two-row dock | Two-row dock | Existing accessibility adaptation remains active. The dock takes more vertical space than at 100% text; it is not a migration defect. |

The greeting still uses the approved display weight 700, size 28, height 1.15 and tracking −0.5 before system scaling. The dashboard ListView retains its 20-pixel horizontal padding; the hero's stacked content retains an additional 20 pixels on either side. No font-size reduction, scaling clamp, new truncation rule or geometry adjustment was introduced to conceal the wrapping.

The affected screen is `StudentDashboardScreen` (Home). The elements are `_buildDateAndGreeting` and `_buildMascotHeroSection`. The shared dock belongs to `HomeScreen` and also serves Discover, Tracker and Profile; this particular 200% screenshot only demonstrates it on Home.

## Other existing narrow-layout constraints

The scholarship card keeps its existing two-line scholarship-title limit and ellipsis. Long names can therefore truncate when the available width is insufficient; this limit was not added by the migration. The 320/390-pixel scholarship-card comparisons use a long accented title at **100%**, not 200%, so they must not be described as enlarged-text validation.

Provider/admin, onboarding, authentication and error-state PNGs in this package are also at 100% text. Existing enlarged-text widget tests were run during implementation, but these screenshots do not prove that every element on every screen survives all accessibility sizes or physical-device settings.

## Review boundary

The confirmed narrow/enlarged-text limitation is the Home greeting's word split and increased vertical reflow. No additional screen-specific enlarged-text failures are claimed from these captures. Native iOS, Android and Safari rendering remain pending, so platform-specific wrapping cannot yet be confirmed. This report does not treat a successful test run as proof of exhaustive visual accessibility coverage.

No correction was made while preparing this review package, as requested. Any later layout correction should be reviewed separately against this evidence while retaining the approved font family, weights and accessible scaling.
