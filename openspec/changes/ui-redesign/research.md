# Research: PicSpeak UI Redesign — Design System Extraction

## New Design Style: "Soft Blue"

Cambio radical del Neo-Brutalism actual a un estilo limpio, suave y moderno.

---

## 🎨 Color Palette

### Primary Colors

| Token | Hex | Uso | Frecuencia |
| ------- | ----- | ----- | ------------ |
| `primaryText` | `#263D69` | Texto principal, logos, títulos | 124 uses |
| `secondaryText` | `#494444` | Texto secundario, labels | 19 uses |
| `accentBlue` | `#B0CCFF` | Botones, bordes de input, estados activos | 46 uses |
| `lightBlue` | `#DAE7FF` | Fondo de header, bottom nav, áreas claras | 12 uses |

### Accent Colors

| Token | Hex | Uso |
| ------- | ----- | ----- |
| `accentGold` | `#FFEEC9` | Fondo decorativo, acentos cálidos (33% opacity) |
| `accentGoldDark` | `#946E1C` | Texto dorado, badges premium |
| `accentGoldLight` | `#FFF0CF` | Fondos suaves dorados |
| `accentGoldMedium` | `#FADA93` | Acentos dorados medios |

### Interactive Colors

| Token | Hex | Uso |
|-------|-----|-----|
| `activeBlue` | `#3970DF` | Estados activos, seleccionados |
| `darkBlue` | `#1C4694` | Hover states, énfasis |

### Neutral Colors

| Token | Hex | Uso |
|-------|-----|-----|
| `background` | `#FFFFFF` | Fondo principal |
| `divider` | `#D9D9D9` | Separadores, bordes neutrales |

---

## 📐 Border Radius

| Tamaño | Valor | Uso |
| -------- | ------- | ----- |
| **Primary** | `8px` | Botones, cards principales, contenedores (32 uses) |
| **Secondary** | `3px` | Inputs, campos de texto (24 uses) |
| **Small** | `4px` | Elementos pequeños, badges (9 uses) |
| **Medium** | `5px` | Elementos medianos (5 uses) |

---

## ✏️ Stroke / Borders

| Grosor | Uso |
|--------|-----|
| `2px` | Bordes de inputs, cards (estándar) |
| `0.5px` | Bordes sutiles, separadores |

---

## 📝 Typography

- **Primary text color**: `#263D69` (dark navy)
- **Secondary text color**: `#494444` (dark gray)
- **Accent/placeholder**: `#B0CCFF` (light blue)
- **Font family**: **LINE Seed JP** (LINE Corporation)
  - Disponible en Google Fonts
  - Variantes: Regular, Bold
  - Estilo: Moderno, limpio, legible

---

## 🧩 Component Patterns

### Inputs

- Background: `white`
- Border: `2px solid #B0CCFF`
- Radius: `3px`
- Height: ~51px

### Buttons (Primary)

- Background: `#B0CCFF`
- Radius: `8px`
- Height: ~51px
- Shadow: filter effect (drop-shadow)

### Cards

- Background: `white`
- Border: `2px solid #B0CCFF`
- Radius: `3px`

### Bottom Navigation

- Background: `#DAE7FF`
- Height: ~61px
- Active icon: `#3970DF`

### Header

- Background: `#DAE7FF` (38% opacity)
- Height: ~111px

### Decorative Elements

- Wave/curve shapes with `#FFEEC9` (cream) at 33% opacity
- Used in login, register, inicio screens

---

## 🔄 Migration Impact: Neo-Brutalism → Soft Blue

### What Changes

| Elemento | Neo-Brutalism (actual) | Soft Blue (nuevo) |
| ---------- | ---------------------- | ------------------- |
| **Primary color** | `#2E5BFF` (Electric Blue) | `#263D69` (Dark Navy) |
| **Secondary** | `#9D50FF` (Purple) | `#B0CCFF` (Light Blue) |
| **Accent** | `#FF3DAB` (Hot Pink) | `#FFEEC9` (Cream Gold) |
| **Borders** | 2px black `#0F0F0F` | 2px `#B0CCFF` light blue |
| **Shadows** | Hard offset (4px,0 blur) | Soft drop-shadow |
| **Radius** | 4-16px (mixed) | 8px primary, 3px secondary |
| **Headlines font** | Lexend 800 | TBD (likely Inter or similar) |
| **Body font** | Inter 500/700 | TBD |
| **Animations** | NbPressable sink, NbPopIn, NbBounce | TBD (likely softer transitions) |

### Files to Migrate

1. `lib/app/theme.dart` — Design tokens centrales
2. `lib/app/nb_animations.dart` — Animaciones (remove/refactor)
3. `lib/app/app_shell.dart` — Bottom navigation
4. `lib/app/router.dart` — Route transitions
5. `features/auth/presentation/login_screen.dart`
6. `features/auth/presentation/register_screen.dart`
7. `features/camera/presentation/camera_screen.dart`
8. `features/object_recognition/presentation/result_screen.dart`
9. `features/categories/presentation/category_screen.dart`
10. `features/app_settings/presentation/settings_screen.dart`
11. `features/word_history/presentation/history_screen.dart`
12. `features/flashcard_review/presentation/flashcard_review_screen.dart`
13. `features/stats/presentation/stats_screen.dart`
14. `features/premium/presentation/paywall_screen.dart`
15. `features/onboarding/presentation/onboarding_screen.dart`

### New Screen Needed

- **Galería** (`Galeria.pdf`) — No existe implementación actual

---

## Next Steps

1. ✅ Design system extracted from SVGs
2. → Create proposal (sdd-proposal)
3. → Create spec (sdd-spec)
4. → Create design document (sdd-design)
5. → Break into tasks (sdd-tasks)
