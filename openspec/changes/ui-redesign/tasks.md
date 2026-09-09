# Tasks: PicSpeak UI Redesign — Implementation Plan

## Review Workload Forecast

- **Total estimated lines**: ~1,000-1,200
- **Budget**: 400 lines/PR
- **Chained PRs recommended**: Yes
- **PR count**: 5
- **Risk level**: High (full UI overhaul)

---

## PR1: Foundation (Theme + Animations)

### Task 1.1: Add LINE Seed JP font

- [ ] Add `line_seed_fonts` or Google Fonts dependency to `pubspec.yaml`
- [ ] Verify font loads correctly on Android/iOS

### Task 1.2: Create SbColors class

- [ ] Create `lib/app/sb_colors.dart` with all Soft Blue color tokens
- [ ] Include primary, accent, gold, interactive, neutral colors
- [ ] Add dark mode variants

### Task 1.3: Create SbShadows class

- [ ] Define soft shadow (0 offset, 8px blur, 4% opacity)
- [ ] Define pressed shadow (0 offset, 4px blur, 2% opacity)

### Task 1.4: Create SbRadius class

- [ ] Define secondary (3px), primary (8px), medium (12px), large (16px), full (9999)

### Task 1.5: Rewrite theme.dart

- [ ] Replace NbColors with SbColors
- [ ] Update ColorScheme (light + dark)
- [ ] Update TextTheme with LINE Seed JP
- [ ] Update all component themes (buttons, inputs, cards, etc.)
- [ ] Keep ThemeModeNotifier API unchanged

### Task 1.6: Create sb_animations.dart

- [ ] `SbPressable` — scale 0.97 on press, soft shadow
- [ ] `SbFadeIn` — fade + scale 0.95→1.0, 300ms
- [ ] `SbPulse` — subtle scale pulse for CTAs
- [ ] `SbLoadingDots` — 3 dots wave animation
- [ ] `SbRouteTransition` — slide + fade, 250ms
- [ ] `SbTypewriter` — character reveal, soft cursor

### Task 1.7: Update app_shell.dart

- [ ] Update BottomNavigationBar to use SbColors.lightBlue background
- [ ] Update active/inactive icon colors
- [ ] Update label typography

### Task 1.8: Update router.dart

- [ ] Replace `nbHardRouteTransition` with `SbRouteTransition`
- [ ] Test all route transitions

**Estimated lines**: ~350-400

---

## PR2: Auth Screens

### Task 2.1: Migrate login_screen.dart

- [ ] Replace `NbColors` → `SbColors`
- [ ] Replace `NbPressable` → `SbPressable`
- [ ] Replace `NbRadius` → `SbRadius`
- [ ] Replace `NbShadows` → `SbShadows`
- [ ] Update input decoration (blue borders)
- [ ] Update button styles (blue background)
- [ ] Remove black borders
- [ ] Visual test

### Task 2.2: Migrate register_screen.dart

- [ ] Same migration pattern as login
- [ ] Update password validation UI
- [ ] Visual test

### Task 2.3: Migrate onboarding_screen.dart

- [ ] Replace colors and animations
- [ ] Evaluate EyePainter custom painter — update colors if needed
- [ ] Evaluate blur reveal animation — keep or simplify
- [ ] Update pulse animation to SbPulse
- [ ] Visual test

**Estimated lines**: ~300-350

---

## PR3: Core Screens

### Task 3.1: Migrate camera_screen.dart

- [ ] Replace NbColors → SbColors
- [ ] Update FAB styling (blue background)
- [ ] Update overlay colors
- [ ] Visual test

### Task 3.2: Migrate result_screen.dart

- [ ] Replace all Nb references
- [ ] Update FloatingLabel card styling
- [ ] Update ScanLineOverlay colors
- [ ] Update NbTypewriter → SbTypewriter
- [ ] Update badge chips
- [ ] Visual test

### Task 3.3: Migrate category_screen.dart

- [ ] Replace Nb references
- [ ] Update NbPopIn → SbFadeIn
- [ ] Update card styles (blue borders)
- [ ] Update badge colors
- [ ] Visual test

**Estimated lines**: ~350-400

---

## PR4: Secondary Screens

### Task 4.1: Migrate settings_screen.dart

- [ ] Replace Nb references
- [ ] Update section headers
- [ ] Update toggle/switch colors
- [ ] Visual test

### Task 4.2: Migrate history_screen.dart

- [ ] Replace Nb references
- [ ] Update NbPopIn → SbFadeIn
- [ ] Update list item cards
- [ ] Visual test

### Task 4.3: Migrate flashcard_review_screen.dart

- [ ] Replace Nb references
- [ ] Update card flip animation colors
- [ ] Update button styles
- [ ] Visual test

### Task 4.4: Migrate stats_screen.dart

- [ ] Replace Nb references
- [ ] Update chart/graph colors
- [ ] Update stat cards
- [ ] Visual test

### Task 4.5: Migrate paywall_screen.dart

- [ ] Replace Nb references
- [ ] Update premium badge styling (gold accents)
- [ ] Update CTA button
- [ ] Visual test

**Estimated lines**: ~350-400

---

## PR5: Galería (New Screen)

### Task 5.1: Create gallery data layer

- [ ] Create `features/gallery/data/gallery_repository.dart`
- [ ] Define model for gallery items (scanned objects history with images)
- [ ] Implement local storage (Firestore or local)

### Task 5.2: Create gallery UI

- [ ] Create `features/gallery/presentation/gallery_screen.dart`
- [ ] Grid layout with scanned object thumbnails
- [ ] Tap to view detail
- [ ] Filter by category
- [ ] Empty state

### Task 5.3: Add gallery route

- [ ] Update `router.dart` with `/gallery` route
- [ ] Update bottom navigation (if gallery replaces or adds to nav)
- [ ] Test navigation flow

### Task 5.4: Visual QA

- [ ] Verify matches Galeria.pdf design
- [ ] Test on different screen sizes
- [ ] Test empty state

**Estimated lines**: ~250-300

---

## Summary

| PR | Scope | Est. Lines | Risk |
| ---- | ------- | ------------ | ------ |
| PR1 | Foundation (theme + animations + nav) | 350-400 | Medium |
| PR2 | Auth screens (login, register, onboarding) | 300-350 | Low |
| PR3 | Core screens (camera, result, categories) | 350-400 | Medium |
| PR4 | Secondary screens (5 screens) | 350-400 | Low |
| PR5 | Galería (new screen) | 250-300 | Medium |
| **Total** | | **1,600-1,850** | |

---

## Dependencies

```
PR1 (Foundation) ← PR2 (Auth) ← PR3 (Core) ← PR4 (Secondary)
                                            ← PR5 (Galería)
```

PR5 can run in parallel with PR4 after PR3 is complete.
