# Spec: PicSpeak UI Redesign — Soft Blue Design System

## 1. Design Token Migration Map

### 1.1 Colors

```
NbColors (Neo-Brutalism)  →  SbColors (Soft Blue)
─────────────────────────────────────────────────
primary (#2E5BFF)         →  primary (#263D69)       // Navy - text, logos
secondary (#9D50FF)       →  accentBlue (#B0CCFF)    // Light blue - buttons, borders
tertiary (#FF3DAB)        →  accentGold (#FFEEC9)    // Cream - decorative
outline (#0F0F0F)         →  outline (#B0CCFF)       // Blue borders instead of black
surface (#FAF8FF)         →  surface (#FFFFFF)       // Pure white
surfaceBright (#FFFFFF)   →  surfaceBright (#FFFFFF) // Same
onSurface (#12141D)       →  onSurface (#263D69)     // Navy text
error (#E5484D)           →  error (#E5484D)         // Same
```

### 1.2 New Accent Colors

```dart
class SbColors {
  // Primary
  static const Color primaryText = Color(0xFF263D69);  // Navy
  static const Color accentBlue  = Color(0xFFB0CCFF);  // Light blue
  static const Color lightBlue   = Color(0xFFDAE7FF);  // Very light blue
  
  // Gold accents
  static const Color accentGold       = Color(0xFFFFEEC9);  // Cream
  static const Color accentGoldDark   = Color(0xFF946E1C);  // Dark gold
  static const Color accentGoldLight  = Color(0xFFFFF0CF);  // Light cream
  static const Color accentGoldMedium = Color(0xFFFADA93);  // Medium gold
  
  // Interactive
  static const Color activeBlue = Color(0xFF3970DF);  // Active states
  static const Color darkBlue   = Color(0xFF1C4694);  // Hover/emphasis
  
  // Neutrals
  static const Color background = Color(0xFFFFFFFF);
  static const Color divider    = Color(0xFFD9D9D9);
}
```

### 1.3 Shadows

```
NbShadows (Neo-Brutalism)  →  SbShadows (Soft Blue)
────────────────────────────────────────────────────
hard (4px offset, 0 blur)  →  soft (0px offset, 8px blur, 4% opacity)
pressed (2px offset)       →  pressed (0px offset, 4px blur, 2% opacity)
```

### 1.4 Border Radius

```
NbRadius  →  SbRadius
──────────────────────
xs (4px)  →  secondary (3px)   // Inputs
sm (8px)  →  primary (8px)     // Buttons, cards
md (12px) →  medium (12px)     // Large cards
lg (16px) →  large (16px)      // Modals
full      →  full (9999)       // Pills
```

### 1.5 Typography

```
Current: Lexend 800 (headlines) + Inter 500/700 (body)
New:     LINE Seed JP 400 (body) + LINE Seed JP 700 (headlines/labels)
```

**Mapping:**

- `displayLarge` → LINE Seed JP 700, 48px
- `displayMedium` → LINE Seed JP 700, 32px
- `headlineLarge` → LINE Seed JP 700, 24px
- `headlineMedium` → LINE Seed JP 700, 20px
- `bodyLarge` → LINE Seed JP 400, 18px
- `bodyMedium` → LINE Seed JP 400, 16px
- `labelLarge` → LINE Seed JP 700, 14px

---

## 2. Component Specifications

### 2.1 Buttons

**Primary Button:**

```
Background:    #B0CCFF
Text:          #263D69
Border:        none
Radius:        8px
Height:        51px
Shadow:        soft (0, 8px blur, #263D69 at 4%)
Pressed:       scale(0.97) + shadow reduce
Font:          LINE Seed JP 700, 16px
```

**Secondary Button:**

```
Background:    #FFFFFF
Text:          #263D69
Border:        2px solid #B0CCFF
Radius:        8px
Height:        51px
Shadow:        none
Font:          LINE Seed JP 700, 16px
```

### 2.2 Inputs

```
Background:    #FFFFFF
Border:        2px solid #B0CCFF
Radius:        3px
Height:        51px
Label:         #494444 (LINE Seed JP 400, 14px)
Focus border:  #3970DF
Error border:  #E5484D
```

### 2.3 Cards

```
Background:    #FFFFFF
Border:        2px solid #B0CCFF
Radius:        3px
Shadow:        none (or very subtle)
Padding:       16px
```

### 2.4 Bottom Navigation

```
Background:    #DAE7FF
Height:        61px
Active icon:   #3970DF
Inactive icon: #263D69 at 50%
Label:         LINE Seed JP 700, 12px
```

### 2.5 AppBar / Header

```
Background:    #DAE7FF at 38% opacity
Height:        ~111px (varies)
Title:         #263D69 (LINE Seed JP 700, 20px)
Border bottom: none (soft gradient transition)
```

---

## 3. Animation Specifications

### 3.1 SbPressable (replaces NbPressable)

```dart
// Tap down: scale 0.97 + shadow reduce
// Tap up: scale 1.0 + shadow restore
// Duration: 150ms
// Curve: Curves.easeOutCubic
```

### 3.2 SbFadeIn (replaces NbPopIn)

```dart
// Fade from 0 to 1
// Scale from 0.95 to 1.0
// Duration: 300ms
// Curve: Curves.easeOut
// No overshoot (smooth)
```

### 3.3 SbPulse (replaces NbBounce)

```dart
// Subtle scale pulse: 1.0 → 1.02 → 1.0
// Duration: 2000ms per cycle
// Curve: Curves.easeInOut
// For CTAs only (not infinite bounce)
```

### 3.4 SbLoadingDots (replaces NbLoadingBlock)

```dart
// 3 dots in a row
// Each dot scales up/down in sequence
// Duration: 600ms per dot
// Color: #B0CCFF
```

### 3.5 SbRouteTransition (replaces nbHardRouteTransition)

```dart
// Slide from right (offset: Offset(1.0, 0.0) → Offset.zero)
// Fade simultaneously
// Duration: 250ms
// Curve: Curves.easeOutCubic
// No overshoot
```

### 3.6 SbTypewriter (replaces NbTypewriter)

```dart
// Character by character reveal
// Duration: 50ms per character
// Cursor: subtle fade (no blink)
// Color: #263D69
```

---

## 4. File Migration Plan

### Phase 1: Foundation (PR1)

| File | Action |
| ------ | -------- |
| `lib/app/theme.dart` | Rewrite: NbColors → SbColors, new theme |
| `lib/app/sb_animations.dart` | Create: New animation widgets |
| `pubspec.yaml` | Add: LINE Seed JP font dependency |
| `lib/app/app_shell.dart` | Update: Bottom nav styling |

### Phase 2: Auth (PR2)

| File | Action |
| ------ | -------- |
| `features/auth/presentation/login_screen.dart` | Migrate to SbColors + SbPressable |
| `features/auth/presentation/register_screen.dart` | Migrate to SbColors + SbPressable |
| `features/onboarding/presentation/onboarding_screen.dart` | Migrate (complex animations) |

### Phase 3: Core (PR3)

| File | Action |
| ------ | -------- |
| `features/camera/presentation/camera_screen.dart` | Migrate |
| `features/object_recognition/presentation/result_screen.dart` | Migrate |
| `features/categories/presentation/category_screen.dart` | Migrate |

### Phase 4: Secondary (PR4)

| File | Action |
| ------ | -------- |
| `features/app_settings/presentation/settings_screen.dart` | Migrate |
| `features/word_history/presentation/history_screen.dart` | Migrate |
| `features/flashcard_review/presentation/flashcard_review_screen.dart` | Migrate |
| `features/stats/presentation/stats_screen.dart` | Migrate |
| `features/premium/presentation/paywall_screen.dart` | Migrate |

### Phase 5: New (PR5)

| File | Action |
| ------ | -------- |
| `features/gallery/presentation/gallery_screen.dart` | Create new |
| `features/gallery/data/gallery_repository.dart` | Create new |
| `lib/app/router.dart` | Add gallery route |

---

## 5. Migration Pattern

For each screen:

1. **Replace imports**: `nb_animations.dart` → `sb_animations.dart`
2. **Replace colors**: `NbColors.xxx` → `SbColors.xxx`
3. **Replace widgets**: `NbPressable` → `SbPressable`, etc.
4. **Replace shadows**: `NbShadows.hard` → `SbShadows.soft`
5. **Replace radius**: `NbRadius.xs` → `SbRadius.secondary`
6. **Update text styles**: Use `Theme.of(context).textTheme` (inherits LINE Seed JP)
7. **Remove hardcoded borders**: Black → Blue
8. **Test**: Visual regression check

---

## 6. Non-Functional Requirements

- **Dark mode**: Must maintain support (SbColors dark variant)
- **Accessibility**: Contrast ratios ≥ 4.5:1 for text
- **Performance**: No animation jank (60fps target)
- **Backward compatible**: No breaking API changes
