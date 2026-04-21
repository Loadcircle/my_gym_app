## Style Prompt
Dark, cinematic gym energy. Screenshots of GymVault fill the frame — raw and real, not mocked up. Huge Bebas Neue captions slam in word by word with a bounce. The palette matches the app: near-black canvas, orange fire accent, warm white type. Every transition is a quick zoom-through or push slide — high energy, never decorative. The viewer should feel the weight of every rep.

## Colors
- `#0D0D0D` — background (near-black, warm tint)
- `#F0EDE8` — foreground (warm white, not pure)
- `#FF5E14` — accent (gym orange, matches app FAB/badge)
- `#FF9A00` — highlight orange (brighter, used on stats/numbers)
- `#1C1C1C` — surface (card/overlay bg)

## Typography
- **Bebas Neue** — all captions, headlines, CTA. ALLCAPS. 100-220px. Letter-spacing -0.02em. The ONE expressive voice.
- **Barlow Condensed** — secondary labels, taglines, sub-captions. 700 weight. 36-48px. Letter-spacing 0.15em. Recedes behind Bebas.

## Motion Rules
- Caption entrances: `back.out(2.5)` scale from 0.6 → 1. Fast (0.2-0.3s). Bounce is intentional.
- Scene transitions: zoom-through (outgoing scales 1→1.08 + fades) or push-slide (x offset).
- Ken Burns on screenshots: slow scale 1.05→1.0 or 1.0→1.05 over 4s. Subtle, adds life.
- Ambient glow: `sine.inOut` breathe. Slow (2-3s). Never distracting.

## What NOT to Do
- No gradient text (`background-clip: text`). Captions are solid white or solid orange.
- No neon cyan/purple AI-default palettes. This is orange and dark, period.
- No gentle fades on caption entrances — gym content slams. Use back.out with overshoot.
- No thin fonts or elegant serifs. This is weight-room energy.
- No empty scenes — every screenshot has a Ken Burns motion, every scene has decorative depth.
