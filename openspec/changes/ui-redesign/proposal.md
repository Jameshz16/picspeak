# Proposal: PicSpeak UI Redesign

## Problem Statement

PicSpeak actualmente usa un diseño **Neo-Brutalism** (colores eléctricos, sombras duras, bordes negros) que no refleja la identidad visual que la diseñadora UI definió. La app necesita migrar a un nuevo design system **"Soft Blue"** — más limpio, suave y profesional.

## Target Users

Usuarios de PicSpeak que aprenden inglés escaneando objetos. La nueva UI busca ser más acogedora y profesional, mejorando la experiencia de aprendizaje.

## Proposed Solution

### 1. Nuevo Design System "Soft Blue"

**Colores:**

- Primary Text: `#263D69` (navy)
- Accent Blue: `#B0CCFF` (botones, bordes)
- Light Blue: `#DAE7FF` (headers, nav)
- Accent Gold: `#FFEEC9` (decorativo)
- Background: `#FFFFFF`

**Tipografía:**

- Font: **LINE Seed JP** (Regular 400, Bold 700)
- Reemplaza Lexend (headlines) + Inter (body)

**Forma:**

- Border radius: `8px` (primary), `3px` (secondary)
- Borders: `2px solid #B0CCFF`
- Shadows: Soft drop-shadow (no hard offset)

### 2. Nuevas Animaciones "Soft Blue"

Reemplazar animaciones Neo-Brutalism por versiones suaves:

| Neo-Brutalism | Soft Blue |
| --------------- | ----------- |
| `NbPressable` (sink hard) | `SbPressable` (scale 0.97 + soft shadow) |
| `NbPopIn` (overshoot) | `SbFadeIn` (smooth fade + subtle scale) |
| `NbBounce` (infinito) | `SbPulse` (subtle pulse para CTAs) |
| `NbLoadingBlock` (cuadrado salta) | `SbLoadingDots` (3 dots wave) |
| `nbHardRouteTransition` (slide overshoot) | `SbRouteTransition` (smooth slide + fade) |
| `NbTypewriter` | `SbTypewriter` (más suave, sin cursor parpadeante) |

### 3. Migración de Pantallas (15)

Orden sugerido (por dependencia):

1. `theme.dart` — Design tokens centrales
2. `nb_animations.dart` → `sb_animations.dart` — Nuevas animaciones
3. `app_shell.dart` — Bottom navigation
4. `router.dart` — Transiciones de ruta
5-15. Pantallas individuales (login, register, camera, result, categories, settings, history, flashcards, stats, premium, onboarding)

### 4. Nueva Pantalla: Galería

Crear implementación de Galería basada en `Galeria.pdf`.

## Non-Goals

- No cambiar lógica de negocio
- No modificar Firebase/RevenueCat integration
- No alterar features existentes (pronunciación, frases, SRS)
- No cambiar idioma de la UI (sigue en español neutral)

## Success Criteria

- [ ] Todas las pantallas migradas al nuevo design system
- [ ] LINE Seed JP implementada correctamente
- [ ] Nuevas animaciones Soft Blue funcionando
- [ ] Galería implementada
- [ ] Sin regresiones visuales en ninguna pantalla
- [ ] Tests pasan (los que existen)

## Risks

| Risk | Mitigation |
| ------ | ------------ |
| LINE Seed JP no disponible en Google Fonts | Verificar disponibilidad; fallback a Inter |
| Pantallas con tokens hardcodeados | Migración gradual, screen por screen |
| Onboarding con animaciones custom complejas | Evaluar si EyePainter/blur necesitan rework |

## Estimated Scope

- **Archivos a modificar**: ~18-20
- **Líneas estimadas**: ~800-1200 (review workload: HIGH)
- **PR strategy**: Chained PRs recomendado (400 líneas budget)
