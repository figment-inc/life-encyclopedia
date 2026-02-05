# Life Encyclopedia: UX Quick Reference Card

> One-page reference for implementing the mobile UI/UX design system

---

## Thumb Zone Layout

```
┌───────────────────────────────┐
│      GLANCEABLE (Status)      │  ← Stats bar, age, name
│         eye zone              │
├───────────────────────────────┤
│                               │
│       READABLE (Content)      │  ← Narrative text
│         natural focus         │
│                               │
├───────────────────────────────┤
│      INTERACTIVE (Actions)    │  ← Choices, buttons
│         thumb zone            │
└───────────────────────────────┘
```

---

## Spacing & Sizing

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 4pt | Tight inline spacing |
| `xs` | 8pt | Within components |
| `sm` | 12pt | Between small elements |
| `md` | 16pt | Standard padding |
| `lg` | 24pt | Between sections |
| `xl` | 32pt | Major sections |
| `xxl` | 48pt | Screen margins (iPad) |

**Touch Targets**: Minimum 44×44pt always

**Corner Radius**: 4/8/12/16/20pt (xs/sm/md/lg/xl)

---

## Color Usage

| Semantic | Light | Dark | Usage |
|----------|-------|------|-------|
| Primary | #2563EB | #3B82F6 | Brand, CTAs |
| Success | #10B981 | #34D399 | Positive outcomes |
| Warning | #F59E0B | #FBBF24 | Caution |
| Danger | #EF4444 | #F87171 | Negative outcomes |

**Stat Value Colors**:
- 0-20: Red (critical)
- 21-40: Orange (poor)
- 41-60: Yellow (average)
- 61-80: Green (good)
- 81-100: Blue (excellent)

---

## Typography

| Style | Size | Weight | Design | Usage |
|-------|------|--------|--------|-------|
| Display | 57pt | Bold | Rounded | Splash only |
| Headline | 24-32pt | Semibold | Default | Screen titles |
| Title | 16-22pt | Medium | Default | Section headers |
| **Narrative** | 17pt | Regular | **Serif** | Story text |
| Body | 15-17pt | Regular | Default | UI text |
| Caption | 12-14pt | Medium | Default | Supporting text |

**Line spacing for narrative**: 8pt (1.5× leading)

---

## Key Components

### Choice Card
```
┌─────────────────────────────────┐
│ 💬 "Action title"               │  ← Emoji + quoted action
│    Consequence hint             │  ← Secondary text
│    ❤️ +Health  😊 -Happy        │  ← Optional stat hints
└─────────────────────────────────┘
Height: 64-100pt | Padding: 16pt | Radius: 12pt
```

### Stats Bar
```
◀ Name, Age     ❤️82  🧠71  ⭐58  😊45
```
Height: 44pt | Background: ultraThinMaterial

### Action Bar
```
[Timeline]    [▲ AGE UP ▲]    [Relationships]
```
Height: 84pt (includes safe area)

---

## Gestures

| Gesture | Action |
|---------|--------|
| Tap | Select, navigate |
| Double tap | Quick confirm |
| Long press | Preview, context menu |
| Swipe up | Reveal stats dashboard |
| Swipe L/R | Browse choices |
| Edge swipe | Go back (iOS standard) |
| Pull down | Refresh (spectator mode) |

---

## Haptics

| Event | Pattern |
|-------|---------|
| Selection | Light impact |
| Confirm choice | Medium impact |
| Age up | Heavy impact |
| Positive result | Success notification |
| Negative result | Warning notification |
| Milestone | Double tap pattern |
| Error | Error notification |

---

## Loading States

```
1. Choice selected → Card pulses, others fade
2. Processing (0-500ms) → Button spinner
3. Waiting (500ms-3s) → Skeleton shimmer
4. Streaming → Typewriter or fade-in
5. Complete → New choices stagger in (0.1s each)
```

**Timeout (>5s)**: Show "Taking longer..." + retry

---

## Accessibility Checklist

- [ ] All interactive elements: 44×44pt minimum
- [ ] All elements: Accessibility labels
- [ ] Color: Never sole information carrier
- [ ] Contrast: 4.5:1 for text, 3:1 for UI
- [ ] Dynamic Type: Support up to .accessibility3
- [ ] Reduce Motion: Provide alternatives
- [ ] VoiceOver: Logical focus order

---

## Navigation Structure

```
Tab Bar (5 tabs):
├── 🌍 Discover → Feed, Search, Categories
├── 📖 Story → Main game loop (default)
├── ➕ New Life → Sheet modal (not tab content)
├── 👤 Profile → My characters, Legacy tree
└── ⚙️ Settings → Preferences
```

**Sheets**: Stats dashboard, Relationships, Timeline (70-100% height)

**Modals**: Search, Character creation flow

---

## Deep Links

```
life-encyclopedia://character/{id}
life-encyclopedia://character/{id}/timeline
life-encyclopedia://discover
life-encyclopedia://discover/category/{category}
life-encyclopedia://create
```

---

## iOS 17+ Features

| Feature | Usage |
|---------|-------|
| TipKit | First-time hints for choices, stats, discovery |
| Live Activities | Character has pending event |
| Widgets | Quick stats (small/medium) |
| Dynamic Island | Milestone achieved, decision waiting |
| StandBy | Age + life stage display |

---

## Animation Timing

| Type | Duration | Easing |
|------|----------|--------|
| Quick feedback | 0.15s | Spring |
| Standard transition | 0.3s | Spring |
| Content change | 0.25s | EaseInOut |
| Dramatic moment | 0.6s | EaseInOut |
| Stagger delay | 0.05-0.1s | Per item |

**Reduce Motion**: Replace with .opacity/.none

---

## Key Files Structure

```
/life-encyclopedia
├── /Views
│   ├── GameView.swift           ← Main game loop
│   ├── DiscoveryView.swift      ← Social feed
│   ├── ProfileView.swift        ← User's characters
│   └── SettingsView.swift
├── /Components
│   ├── ChoiceCard.swift
│   ├── StatsBar.swift
│   ├── NarrativeView.swift
│   ├── ActionBar.swift
│   ├── CharacterCard.swift
│   └── TimelineView.swift
├── /DesignSystem
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   ├── Haptics.swift
│   └── Icons.swift
└── /ViewModels
    ├── GameViewModel.swift
    └── DiscoveryViewModel.swift
```
