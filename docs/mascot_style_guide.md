# Scholaris Mascot Style Reference & Generation Guide

Standing style-reference specification to maintain visual consistency across all mascot assets and future pose generation prompts.

---

## Visual Formula & Specifications

- **Art Style**: Flat-vector cartoon sticker, bold black outline, soft flat shading, big-eyed friendly proportions.
- **Locked Palette** (Never introduce new colors):
  - **Forest Green**: `#0F4D2E` (Growth, Learning, Future)
  - **Gold Yellow**: `#F1B41E` (Opportunity, Success, Hope)
  - **Navy Blue**: `#1B3A5C` (Trust, Stability, Support)
  - **Coral**: `#FF6F59` (Energy, Passion, You)
  - **Warm White**: `#FAF8F4` (Clarity, Space, Possibility)
- **Locked Outfit Base**:
  - Green zip-hoodie with gold trim
  - White shirt
  - Navy pants
  - White/green sneakers
  - Navy backpack
  - Green graduation cap with gold tassel

---

## Signature Differentiators

*Never alter these signature differentiators when generating character variants:*

### Aris (Boy Mascot)
- Unzipped hoodie exposing white inner shirt
- Pushed-up / forearm sleeves
- Backpack strap pin / patch
- Spiky messy anime/cartoon hair
- Navy wristband

### Aria (Girl Mascot)
- Fitted zipped hoodie
- Single-strap backpack carry
- Gold ribbon hair accessory
- Playful twin-tails hairstyle

---

## Poses & Journey Stages

### Core Expressions
1. **Hero / Welcome**: Upright friendly stance with warm smile, welcoming the student.
2. **Happy**: Joyful squinty eyes, smiling brightly with big dreams.
3. **Determined**: Confident forward gaze with fists or focused determination, taking real progress.
4. **Thinking**: Hand to chin in thoughtful reflection, asking better questions.
5. **Celebrating**: Arms up in triumph with victory fists, beaming mouth, and joy sparkles.
6. **Curious**: Inquisitive head tilt with open eyes, eager to learn.

### The Student Journey Stages
1. **Student**: Casual school day pose with navy backpack and relaxed stance ("Learning today. Building tomorrow.").
2. **Applicant**: Holding documents / application folder and phone ("Taking the next step.").
3. **Scholar**: Holding stack of heavy textbooks ("Growing knowledge. Creating impact.").
4. **Graduate**: Wearing academic graduation gown with yellow collar stole, holding diploma scroll ("Not the end. Just the beginning.").

### Turnaround Views
- **Front**: Direct front view for turnarounds and scale reference.
- **Side**: Profile view showing backpack depth and posture.
- **Back**: Rear view showing backpack straps, hood, and cap back.

---

## Prompt Template for Future Mascot Generation

When generating additional poses or variants, paste the following prompt block verbatim:

```text
Style: flat-vector cartoon sticker, bold black outline, soft flat shading, big-eyed friendly proportions
Locked palette: Forest Green #0F4D2E, Gold Yellow #F1B41E, Navy Blue #1B3A5C, Coral #FF6F59, Warm White #FAF8F4 — never introduce new colors
Locked outfit base: green zip-hoodie w/ gold trim, white shirt, navy pants, white/green sneakers, navy backpack, green grad cap w/ gold tassel
Signature differentiators:
- If Aris (boy): unzipped hoodie + forearm sleeves + strap pin/patch + messy hair + wristband
- If Aria (girl): fitted hoodie + single-strap carry + gold ribbon + twin-tails
Character: [Aris / Aria]
Pose / Expression needed: [Specify exact pose, e.g., jumping with joy, holding a magnifying glass, pointing up]
Canvas & Export requirements: pure transparent PNG background, true edge isolation, consistent character scale to existing assets (centered on 512x512 canvas, 375px character height for expressions, 430px for journey).
Constraint: match art style of existing Scholaris mascot assets exactly — do not reinterpret proportions, color codes, or outline weight.
```
