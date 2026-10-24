# Design Engineering — Emil Kowalski's UI/UX Philosophy (Flutter Adaptation)

## Core Philosophy
- Taste is trained, not innate. Study why the best interfaces feel the way they do.
- Unseen details compound into something stunning.
- Beauty is leverage — good defaults and animations are real differentiators.

## Animation Decision Framework (Flutter)

### 1. Should this animate at all?
| Frequency | Decision |
|---|---|
| 100+ times/day (keyboard shortcuts, toggles) | No animation. Ever. |
| Tens of times/day (hover, list navigation) | Remove or drastically reduce |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare/first-time (onboarding, celebrations) | Can add delight |

### 2. Easing Rules
- **Entering** → `Curves.easeOut` or custom decelerate (starts fast, feels responsive)
- **Moving/morphing on screen** → `Curves.easeInOutCubicEmphasized`
- **Hover/color change** → `Curves.ease`
- **Constant motion** → `Curves.linear`
- **Never use** `Curves.easeIn` for UI animations — feels sluggish
- Use custom cubic curves: `Cubic(0.23, 1, 0.32, 1)` for strong ease-out

### 3. Duration Guide
| Element | Duration |
|---|---|
| Button press feedback | 100-160ms |
| Tooltips, small popovers | 125-200ms |
| Dropdowns, selects | 150-250ms |
| Modals, drawers, bottom sheets | 200-500ms |
| Marketing/explanatory | Can be longer |

### 4. Never animate from scale(0)
- Start from scale 0.9+ combined with opacity
- Nothing in the real world disappears completely

### 5. Buttons must feel responsive
- Add scale(0.97) on press for instant feedback
- Use haptics on meaningful interactions

### 6. Spring Animations
- Use for drag interactions, gestures, elements that should feel "alive"
- Keep bounce subtle (0.1-0.3)
- Springs maintain velocity when interrupted

## Design Principles
- Use semi-transparent shadows instead of solid borders where possible
- Cards should have subtle borders with low opacity (0.08-0.12)
- Consistent spacing using the design token system
- Use color with intention — muted backgrounds, vibrant accents
- Every interactive element needs visual feedback
