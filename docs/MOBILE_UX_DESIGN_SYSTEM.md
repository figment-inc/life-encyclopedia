# Life Encyclopedia: Complete Mobile UI/UX Design System

> iOS 17+ SwiftUI Design for LLM-Powered Life Simulation

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Navigation Architecture](#navigation-architecture)
3. [Core Game Loop Screen](#core-game-loop-screen)
4. [Character Discovery (Social Feature)](#character-discovery)
5. [Key Screens Design](#key-screens-design)
6. [Design System](#design-system)
7. [Interaction Design](#interaction-design)
8. [iOS 17+ Features](#ios-17-features)
9. [Accessibility](#accessibility)
10. [SwiftUI Implementation](#swiftui-implementation)

---

## 1. Design Philosophy

### Core Principles

```
THUMB-FIRST DESIGN
├── Primary actions in thumb zone (bottom 1/3)
├── Navigation controls bottom-anchored
├── Reading content in natural eye zone (middle)
└── Status information at top (glanceable)

ONE-HANDED PLAY
├── 95% of gameplay achievable with one thumb
├── Swipe gestures for navigation
├── No precision targeting required
└── Large touch targets (minimum 44pt)

NARRATIVE IMMERSION
├── Text is primary content (LLM narratives)
├── Minimal chrome, maximum story space
├── Seamless loading states
└── Context-preserving transitions

GLANCEABLE INFORMATION
├── Stats visible at a glance
├── Progress always clear
├── No cognitive overload
└── Progressive disclosure
```

### Visual Language

```
AESTHETIC: "Digital Memoir"
├── Clean, editorial typography
├── Soft, organic color palette
├── Subtle paper/book textures (optional)
├── Photography-inspired portraits
└── Life timeline as visual metaphor

MOOD BY LIFE STAGE:
├── Infancy: Warm pastels, rounded corners, soft
├── Childhood: Bright, playful, storybook
├── Teen: Vibrant, social media aesthetic
├── Adult: Professional, sophisticated
├── Senior: Warm, nostalgic, dignified
└── Elder: Peaceful, soft focus, serene
```

---

## 2. Navigation Architecture

### Primary Navigation: Tab Bar

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                    [Screen Content]                     │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   🌍        📖        ➕        👤        ⚙️           │
│ Discover   Story   New Life   Profile   Settings       │
│                                                         │
└─────────────────────────────────────────────────────────┘

TAB FUNCTIONS:
├── Discover: Browse other players' characters (social)
├── Story: Active character gameplay (main loop)
├── New Life: Create new character (modal)
├── Profile: Your characters, stats, legacy tree
└── Settings: Preferences, account, accessibility
```

### Navigation Hierarchy

```
DISCOVER (Tab 1)
├── Recently Viewed (horizontal scroll)
├── Trending Now (grid)
├── Categories (filter chips)
│   ├── Rising Stars
│   ├── Life in Progress
│   ├── Elder Wisdom
│   ├── Dramatic Lives
│   └── Similar to You
├── Character Detail (push)
│   ├── Full Timeline (sheet)
│   └── Relationship Map (sheet)
└── Search (modal)

STORY (Tab 2)
├── Character Selector (if multiple)
├── Main Game Loop
│   ├── Stats Dashboard (sheet, swipe up)
│   ├── Relationships (sheet)
│   ├── Timeline (sheet)
│   └── Event Detail (modal)
└── Age Up Confirmation (alert)

PROFILE (Tab 3)
├── My Characters (list)
├── Character Detail (push)
├── Legacy Tree (full screen)
├── Achievements (sheet)
└── Statistics (sheet)

SETTINGS (Tab 4)
├── Account
├── Notifications
├── Appearance (dark mode, etc.)
├── Accessibility
├── About
└── Support
```

### Gesture Navigation

```
GLOBAL GESTURES:
├── Edge swipe left: Go back (standard iOS)
├── Pull down: Refresh (where applicable)
├── Long press on character: Quick preview
└── Pinch on timeline: Zoom time scale

GAME SCREEN GESTURES:
├── Swipe up: Reveal stats dashboard
├── Swipe left/right: Browse choices
├── Double tap choice: Confirm selection
├── Shake device: Randomize choice (optional fun)

TAB BAR GESTURES:
├── Double tap tab: Scroll to top
└── Long press Story tab: Quick switch characters
```

### Deep Linking Structure

```
life-encyclopedia://
├── /character/{id}                    → View character
├── /character/{id}/timeline           → Character timeline
├── /character/{id}/event/{event_id}   → Specific event
├── /discover                          → Discovery feed
├── /discover/trending                 → Trending section
├── /discover/category/{category}      → Filtered view
├── /profile                           → User profile
└── /create                            → New character flow

SHARE LINKS:
"Check out this life: life-encyclopedia://character/abc123"
→ Opens character in spectator mode
→ Prompts app install if not installed (Universal Links)
```

---

## 3. Core Game Loop Screen

### Main Layout

```
┌─────────────────────────────────────────────────────────┐
│ ◀ Sarah Chen, 16        ❤️ 82  🧠 71  ⭐ 58  😊 45     │ ← Stats Bar
├─────────────────────────────────────────────────────────┤
│                                                         │
│                    [Character Art]                      │ ← Optional
│                        or                               │
│                   [Stage Icon/Mood]                     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  It's prom season. Your best friend Jess just got      │
│  asked by the guy you liked. She doesn't know          │
│  about your crush.                                     │
│                                                         │ ← Narrative
│  Jess is practically glowing as she tells you about    │    Area
│  Derek's elaborate promposal in the cafeteria.         │
│  Everyone cheered. Your smile feels frozen.            │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 💬 "Tell Jess the truth"                          │ │
│  │    Risk friendship for authenticity               │ │ ← Choice 1
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 😊 "Be happy for her"                             │ │
│  │    Hide your feelings, support her                │ │ ← Choice 2
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 💪 "Go solo and own it"                           │ │
│  │    Show up alone with confidence                  │ │ ← Choice 3
│  └───────────────────────────────────────────────────┘ │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [Timeline]    [▲ Age Up]    [Relationships]           │ ← Action Bar
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Component Specifications

#### Stats Bar (Compact Header)

```
COMPONENT: StatsBar
PURPOSE: Show vital stats at a glance without leaving game

LAYOUT:
┌─────────────────────────────────────────────────────────┐
│ ◀        Sarah Chen, 16        ❤️82 🧠71 ⭐58 😊45     │
└─────────────────────────────────────────────────────────┘

STRUCTURE:
├── Back button (if viewing other's character)
├── Name + Age (tappable → full profile)
├── Dynamic stat indicators (varies by life stage)
│   ├── Infancy: ❤️ Health, 👶 Bond
│   ├── Child: ❤️ Health, 🧠 Intel, ⭐ Popular, 📚 Grades
│   ├── Teen: ❤️ Health, 🧠 Intel, ⭐ Popular, 😊 Happy
│   ├── Adult: ❤️ Health, 💼 Career, 💰 Wealth, 💑 Romance
│   └── Senior: ❤️ Health, 🏆 Legacy, ☮️ Peace, 💕 Family

INTERACTIONS:
├── Tap stat: Tooltip with full value + trend
├── Tap name: Open full stats dashboard
├── Long press: Expanded stats overlay
└── Swipe down from bar: Pull open dashboard

VISUAL:
├── Height: 44pt (minimum touch target)
├── Background: Material blur (ultraThinMaterial)
├── Stats: Colored by value (green/yellow/red)
├── Trend arrows: ↑↓→ next to values when changing
└── Animate stat changes with spring animation

SWIFTUI:
```swift
struct StatsBar: View {
    let character: Character
    @State private var showDashboard = false
    
    var body: some View {
        HStack {
            if character.isSpectating {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                }
            }
            
            Button(action: { showDashboard = true }) {
                Text("\(character.name), \(character.age)")
                    .font(.headline)
            }
            
            Spacer()
            
            StatPills(stats: character.primaryStats)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showDashboard) {
            StatsDashboard(character: character)
        }
    }
}
```

#### Narrative Area

```
COMPONENT: NarrativeView
PURPOSE: Display LLM-generated story content

LAYOUT:
├── Scrollable text area
├── Estimated reading time indicator (optional)
├── Fade gradient at bottom (if more content)
└── Typography optimized for readability

TYPOGRAPHY:
├── Font: System Serif (New York) or San Francisco
├── Size: Dynamic Type, base 17pt
├── Line height: 1.5
├── Max width: 580pt (readable line length)
├── Paragraphs: 16pt spacing

LOADING STATES (LLM Response ~1-3s):

State 1: Skeleton UI
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  ████████████████████████████████████████              │
│  ████████████████████████████████                      │
│  ██████████████████████████████████████████            │
│                                                         │
│  ████████████████████████████                          │
│  ██████████████████████████████████████                │
│                                                         │
└─────────────────────────────────────────────────────────┘

State 2: Typing Indicator (while streaming)
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  It's prom season. Your best friend Jess just got      │
│  asked by|                                              │
│          ▋ ← Blinking cursor                           │
│                                                         │
└─────────────────────────────────────────────────────────┘

State 3: Complete (fade in smoothly)

INTERACTIONS:
├── Scroll: Natural scroll within area
├── Tap: (reserved for future - annotations?)
├── Long press text: Copy option
└── Pull down: Replay last event animation (optional)

ANIMATIONS:
├── Text appears: Typewriter effect (optional, configurable)
├── Skeleton: Shimmer animation
├── Transition: CrossDissolve between states
└── Scroll hint: Subtle bounce at bottom

SWIFTUI:
```swift
struct NarrativeView: View {
    let narrative: String
    let isLoading: Bool
    let isStreaming: Bool
    
    var body: some View {
        ScrollView {
            if isLoading {
                SkeletonText(lines: 6)
                    .shimmer()
            } else {
                Text(narrative)
                    .font(.system(.body, design: .serif))
                    .lineSpacing(8)
                    .padding()
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if isStreaming {
                TypingIndicator()
            }
        }
    }
}
```

#### Choice Cards

```
COMPONENT: ChoiceCard
PURPOSE: Present player decisions clearly

LAYOUT:
┌─────────────────────────────────────────────────────────┐
│ 💬 "Tell Jess the truth"                               │
│    Risk friendship for authenticity                    │
│    ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈             │
│    👫 -Risk  💪 +Brave  😊 ±Happy                      │ ← Optional hints
└─────────────────────────────────────────────────────────┘

STRUCTURE:
├── Icon: Emoji representing choice theme
├── Title: Action in quotes (what you'll do)
├── Subtitle: Consequence hint
├── Stat hints: (optional, based on settings)
└── Selection indicator

SIZING:
├── Min height: 64pt
├── Max height: 100pt
├── Padding: 16pt all sides
├── Corner radius: 12pt
├── Touch target: Full card

STATES:
├── Default: Subtle border, card background
├── Pressed: Scale 0.98, darker background
├── Selected: Accent border, checkmark
├── Disabled: 50% opacity (loading)
└── Hover (iPad): Elevated shadow

INTERACTIONS:
├── Tap: Select choice (highlight, don't confirm)
├── Double tap: Select + confirm immediately
├── Swipe left/right: Navigate between choices
├── Long press: Show detailed consequences (sheet)
└── Haptic: Light impact on selection

ANIMATIONS:
├── Press: Scale spring animation (duration: 0.15)
├── Selection: Border draw animation
├── Appearance: Stagger fade-in (0.1s delay each)
└── Loading: Pulse animation on selected card

SWIFTUI:
```swift
struct ChoiceCard: View {
    let choice: Choice
    let isSelected: Bool
    let onSelect: () -> Void
    
    @GestureState private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(choice.emoji)
                    Text(choice.title)
                        .font(.headline)
                }
                
                Text(choice.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if showStatHints {
                    StatHintRow(hints: choice.statHints)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
```

#### Action Bar

```
COMPONENT: ActionBar
PURPOSE: Primary game controls in thumb zone

LAYOUT:
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  📜 Timeline    [▲ AGE UP ▲]    👥 Relationships       │
│                                                         │
└─────────────────────────────────────────────────────────┘

STRUCTURE:
├── Left: Timeline button (history)
├── Center: Age Up button (primary CTA)
├── Right: Relationships button
└── Height: 84pt (safe area + 44pt + padding)

AGE UP BUTTON:
├── Size: 120pt × 44pt
├── Style: Prominent, filled accent color
├── State: Disabled until choice selected
├── Label: "Age Up" or "Continue" or "Live This Year"
└── Haptic: Medium impact on tap

INTERACTIONS:
├── Age Up: Confirm choice, advance game
├── Timeline: Sheet from bottom (70% height)
├── Relationships: Sheet from bottom (70% height)
└── All buttons: Minimum 44pt touch target

SWIFTUI:
```swift
struct ActionBar: View {
    let canProgress: Bool
    let onAgeUp: () -> Void
    let onTimeline: () -> Void
    let onRelationships: () -> Void
    
    var body: some View {
        HStack {
            Button("Timeline", systemImage: "clock.arrow.circlepath") {
                onTimeline()
            }
            .labelStyle(.titleAndIcon)
            
            Spacer()
            
            Button(action: onAgeUp) {
                Label("Age Up", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canProgress)
            
            Spacer()
            
            Button("People", systemImage: "person.2") {
                onRelationships()
            }
            .labelStyle(.titleAndIcon)
        }
        .padding()
        .background(.bar)
    }
}
```

### LLM Loading States

```
LOADING PATTERN: Progressive Disclosure

1. CHOICE SELECTED (0ms)
   └── Selected card pulses, others fade
   └── Haptic: Light impact

2. SENDING TO LLM (0-500ms)
   └── Age Up button shows spinner
   └── "Processing..." label
   └── Selected card shows checkmark

3. WAITING FOR RESPONSE (500ms-3000ms)
   └── Narrative area shows skeleton
   └── Skeleton shimmer animation
   └── Show progress ring if >2s

4. STREAMING RESPONSE (when available)
   └── Typewriter effect (optional)
   └── Or: Fade in complete text
   └── Choices fade out during transition

5. NEW SITUATION READY
   └── New narrative fades in
   └── New choices stagger in (0.1s each)
   └── Age counter animates if year changed
   └── Stat changes animate in header

TIMEOUT HANDLING (>5s):
└── Show "Taking longer than usual..."
└── Offer retry button
└── Don't lose selected choice
```

---

## 4. Character Discovery (Social Feature)

### Discovery Feed Layout

```
┌─────────────────────────────────────────────────────────┐
│         🔍                    Discover                  │
├─────────────────────────────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐               │
│ │ 👤  │ │ 👤  │ │ 👤  │ │ 👤  │ │ 👤  │ ← Recently    │
│ │Maya │ │Jake │ │Emma │ │Luis │ │Aiden│   Viewed      │
│ │ 34  │ │ 16  │ │ 72  │ │ 8  │ │ 45  │   (scroll →)  │
│ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘               │
├─────────────────────────────────────────────────────────┤
│ [🔥Hot] [⭐Rising] [🎭Drama] [👴Wisdom] [🔄Similar]    │ ← Filter Chips
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Trending Now                                           │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Photo]  Marcus Williams, 28                    │   │
│  │          Just got promoted to VP after...       │   │ ← Feature
│  │          🔥 4.2K views  ⏰ 2h ago               │   │   Card
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────┐ ┌─────────────────────┐   │
│  │ Sofia, 16               │ │ Robert, 67          │   │
│  │ Just had first kiss     │ │ Reunited with...    │   │ ← Grid
│  │ 🔥 892  👁️ Teen        │ │ 🔥 1.1K 👁️ Senior  │   │
│  └─────────────────────────┘ └─────────────────────┘   │
│                                                         │
│  ┌─────────────────────────┐ ┌─────────────────────┐   │
│  │ baby Lily, 1            │ │ Chen, 42            │   │
│  │ Said first word!        │ │ Midlife crisis...   │   │
│  │ 🔥 234  👁️ Baby        │ │ 🔥 567  👁️ Adult   │   │
│  └─────────────────────────┘ └─────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Recently Viewed Carousel

```
COMPONENT: RecentlyViewedCarousel
PURPOSE: Quick access to recently browsed characters

LAYOUT:
├── Horizontal scroll
├── Circular avatars with name/age below
├── Subtle live indicator for active characters
└── Max visible: 6-8 items

CARD SIZE:
├── Avatar: 60pt diameter
├── Spacing: 12pt
├── Total height: 100pt

STATES:
├── Default: Avatar + name
├── Active: Green dot (character recently updated)
├── Your character: Blue ring
├── Deceased: Subtle memorial treatment (sepia?)

INTERACTIONS:
├── Tap: Navigate to character detail
├── Long press: Quick preview popup
└── Scroll: Horizontal momentum scroll

SWIFTUI:
```swift
struct RecentlyViewedCarousel: View {
    let characters: [CharacterPreview]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(characters) { character in
                    NavigationLink(value: character) {
                        VStack(spacing: 4) {
                            CharacterAvatar(character: character, size: 60)
                                .overlay(alignment: .bottomTrailing) {
                                    if character.isActive {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 12, height: 12)
                                            .offset(x: 2, y: 2)
                                    }
                                }
                            
                            Text(character.firstName)
                                .font(.caption)
                            Text("\(character.age)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
```

### Character Preview Card

```
COMPONENT: CharacterCard
PURPOSE: Display character summary for discovery

LAYOUT (Grid Item):
┌─────────────────────────┐
│  [Avatar/Photo Area]    │ ← 1:1 aspect ratio
│      Maya Chen          │
│                         │
├─────────────────────────┤
│  Maya Chen, 28          │ ← Name, Age
│  Just got engaged...    │ ← Latest event (1 line)
│  🔥 1.2K  ⏰ 5m ago     │ ← Views, recency
└─────────────────────────┘

LAYOUT (Featured Card):
┌─────────────────────────────────────────────────────────┐
│  [Photo]  │  Marcus Williams, 28                       │
│   Area    │  Career milestone: Just got promoted to    │
│           │  VP after only 3 years at the company...   │
│  (square) │  🔥 4.2K views  ⏰ 2h ago  📈 Trending    │
└─────────────────────────────────────────────────────────┘

SIZING:
├── Grid: (screen width - 48) / 2 = ~170pt width
├── Featured: Full width - 32pt margins
├── Corner radius: 12pt
├── Shadow: subtle (y: 2, blur: 8, opacity: 0.1)

VISUAL ELEMENTS:
├── Life stage badge (color coded)
├── View count with fire emoji
├── Recency indicator
├── Trending badge (if applicable)
└── Memorial badge (if deceased)

INTERACTIONS:
├── Tap: Navigate to full character view
├── Long press: Quick preview (name, stats, recent events)
└── 3D Touch/Haptic Touch: Same as long press

SWIFTUI:
```swift
struct CharacterCard: View {
    let character: CharacterPreview
    let style: CardStyle // .grid or .featured
    
    var body: some View {
        NavigationLink(value: character) {
            VStack(alignment: .leading, spacing: 8) {
                // Avatar area
                CharacterAvatarView(character: character)
                    .aspectRatio(style == .featured ? 16/9 : 1, contentMode: .fill)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        LifeStageBadge(stage: character.lifeStage)
                            .padding(8)
                    }
                
                // Info area
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(character.name), \(character.age)")
                        .font(.headline)
                    
                    Text(character.latestEventSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(style == .featured ? 2 : 1)
                    
                    HStack {
                        Label("\(character.viewCount.formatted(.compact))", 
                              systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Text(character.lastActivity, style: .relative)
                            .foregroundStyle(.secondary)
                        
                        if character.isTrending {
                            Label("Trending", systemImage: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.green)
                        }
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

### Spectator Mode vs. Active Play

```
SPECTATOR MODE (Viewing someone else's character):
┌─────────────────────────────────────────────────────────┐
│ ◀ Back        Marcus Williams, 28        👁️ Watching  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [Same narrative view as active play]                  │
│                                                         │
│  Marcus just got the call. He's been promoted to VP.   │
│  His wife Sarah screams with joy when he tells her...  │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  What would YOU choose?          [👁️ 4,231 watching]  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 🎉 Celebrate big                            [32%] │ │
│  └───────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 🤝 Thank your team first                    [45%] │ │
│  └───────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 😰 Worry about imposter syndrome            [23%] │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [Timeline]    [See Full Story]    [Relationships]     │
│                                                         │
└─────────────────────────────────────────────────────────┘

SPECTATOR FEATURES:
├── Read-only timeline browsing
├── Vote on "what would you do" (non-binding)
├── See community vote percentages
├── View relationship web
├── Cannot make choices for character
└── "Watch" to get notifications when updated

VISUAL DIFFERENCES:
├── "Watching" badge in header
├── Choice cards show vote percentages
├── No "Age Up" button (replaced with "See Full Story")
├── Subtle different accent color
└── "This is [Owner]'s story" badge
```

### Search and Filtering

```
SEARCH MODAL:
┌─────────────────────────────────────────────────────────┐
│  🔍 Search characters...                           ✕   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  FILTERS                                                │
│                                                         │
│  Life Stage                                             │
│  [Baby] [Child] [Teen] [YA] [Adult] [Mid] [Senior]     │
│                                                         │
│  Age Range                                              │
│  |●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●|                   │
│  0                                100                   │
│                                                         │
│  Status                                                 │
│  [○ All] [● Alive] [○ Deceased]                        │
│                                                         │
│  Traits                                                 │
│  [Athletic] [Academic] [Creative] [Social] [Rebel]     │
│                                                         │
│  Sort By                                                │
│  [Recently Active ▼]                                    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│              [Show X Results]                           │
└─────────────────────────────────────────────────────────┘

SEARCH FEATURES:
├── Name search (fuzzy matching)
├── Filter chips (multi-select)
├── Age range slider
├── Life stage quick filters
├── Sort options (recent, trending, age, legacy)
└── Save search as preset
```

---

## 5. Key Screens Design

### Character Creation Flow

```
FLOW: 5-step wizard with progress indicator

STEP 1: BASICS
┌─────────────────────────────────────────────────────────┐
│                    Create Your Life                     │
│                    ● ○ ○ ○ ○                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                     [Avatar Preview]                    │
│                        (animated)                       │
│                                                         │
│  What's your name?                                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │ First name                                      │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Last name                                       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Gender                                                 │
│  [♂ Male]  [♀ Female]  [⚧ Non-binary]  [? Other]      │
│                                                         │
│                    [🎲 Randomize All]                   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                       [Next →]                          │
└─────────────────────────────────────────────────────────┘

STEP 2: ORIGIN
- Country/Region selection (affects available events)
- Time period (modern, or future expansion)
- Starting socioeconomic status

STEP 3: FAMILY
- Parent generation (optional quick setup)
- Siblings (0-4)
- Family dynamics preset or custom

STEP 4: TRAITS (Swipeable Cards)
┌─────────────────────────────────────────────────────────┐
│                    Choose Your Nature                   │
│                    ○ ○ ○ ● ○                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│     Swipe to choose starting personality traits         │
│                                                         │
│           ← Keep                    Discard →           │
│                                                         │
│         ┌─────────────────────────────────┐             │
│         │                                 │             │
│         │         🧠 CURIOUS              │             │
│         │                                 │             │
│         │    You always want to know      │             │
│         │    how things work              │             │
│         │                                 │             │
│         │    +Intelligence growth         │             │
│         │    +Learning events             │             │
│         │    -Sometimes get in trouble    │             │
│         │                                 │             │
│         └─────────────────────────────────┘             │
│                                                         │
│         Selected: Curious, Shy (2/3)                    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    [← Back] [Next →]                    │
└─────────────────────────────────────────────────────────┘

STEP 5: PREVIEW & CONFIRM
- Full character summary
- Randomize button for each section
- "Begin Life" primary CTA

INTERACTIONS:
├── Swipe between steps (with confirmation for data loss)
├── Swipe cards for trait selection
├── Shake to randomize current field
└── Haptic feedback on selections
```

### Stats Dashboard (Sheet)

```
┌─────────────────────────────────────────────────────────┐
│  ━━━━━━━━━━                                            │ ← Drag indicator
│                                                         │
│         [Avatar]                                        │
│       Sarah Chen                                        │
│      Age 16 • Teen                                      │
│    Born: Jan 15, 2010                                   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  PHYSICAL                                               │
│  ┌────────────┬────────────┬────────────┐              │
│  │   ❤️ 82    │   💪 75    │   ✨ 68    │              │
│  │  Health    │  Fitness   │   Looks    │              │
│  │    ↑2      │    ↑5      │    ↑1      │              │
│  └────────────┴────────────┴────────────┘              │
│                                                         │
│  MENTAL                                                 │
│  ┌────────────┬────────────┬────────────┐              │
│  │   🧠 71    │   😊 45    │   😰 62    │              │
│  │   Intel    │  Happiness │   Stress   │              │
│  │    ↑3      │    ↓8      │    ↑15     │              │
│  └────────────┴────────────┴────────────┘              │
│                                                         │
│  SOCIAL                                                 │
│  ┌────────────┬────────────┬────────────┐              │
│  │   ⭐ 58    │   💕 32    │   📚 B+    │              │
│  │ Popularity │  Romance   │   Grades   │              │
│  │    ↑12     │    →       │    ↑       │              │
│  └────────────┴────────────┴────────────┘              │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  LIFE PROGRESS                                          │
│  |████████░░░░░░░░░░░░░░░░░░░░| 16/80 years            │
│                                                         │
│  Current Stage: Teen (15-17)                            │
│  Actions this year: 3/8                                 │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                  [View Full Profile]                    │
└─────────────────────────────────────────────────────────┘

STAT CARD INTERACTIONS:
├── Tap: Expand with history graph
├── Swipe left/right: Compare to average
└── Long press: Detailed breakdown

STAT VALUE COLORS:
├── 0-20: Red (critical)
├── 21-40: Orange (poor)
├── 41-60: Yellow (average)
├── 61-80: Green (good)
└── 81-100: Blue (excellent)

TREND INDICATORS:
├── ↑ Green: Improving
├── ↓ Red: Declining
├── → Gray: Stable
└── Number shows change since last year
```

### Relationship Management

```
RELATIONSHIPS SHEET:
┌─────────────────────────────────────────────────────────┐
│  ━━━━━━━━━━                                            │
│                     Relationships                       │
├─────────────────────────────────────────────────────────┤
│  [Family] [Friends] [Romantic] [Other]                 │ ← Segment control
├─────────────────────────────────────────────────────────┤
│                                                         │
│  FAMILY                                                 │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [👩]  Mom (Linda Chen)                     ❤️ 72 │   │
│  │       "Worried about your grades"               │   │
│  │       ████████████████░░░░░░░░                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [👨]  Dad (Michael Chen)                   ❤️ 65 │   │
│  │       "Proud of your soccer skills"             │   │
│  │       █████████████░░░░░░░░░░░                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [👦]  Brother (Tommy Chen, 12)             ❤️ 45 │   │
│  │       "Annoying but loves you"                  │   │
│  │       ████████░░░░░░░░░░░░░░░                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  FRIENDS                                                │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [👧] Jess Martinez (Best Friend)           ❤️ 85 │   │
│  │      "Going to prom with Derek..."              │   │
│  │      ██████████████████████░░░                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘

RELATIONSHIP CARD DETAIL (on tap):
┌─────────────────────────────────────────────────────────┐
│                    [Close Button]                       │
│                                                         │
│                     [Avatar]                            │
│                 Jess Martinez                           │
│              Best Friend • Met Age 6                    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  RELATIONSHIP STATS                                     │
│                                                         │
│  Trust         ████████████████████░░  85              │
│  Closeness     ██████████████████░░░░  78              │
│  History       ███████████████████████  10 years       │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  RECENT INTERACTIONS                                    │
│                                                         │
│  • Told you about Derek asking her (Age 16)            │
│  • Supported you at soccer finals (Age 15)             │
│  • Fought about the party incident (Age 14)            │
│  • Met at summer camp (Age 6)                          │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  PERSONALITY TRAITS                                     │
│  [Loyal] [Outgoing] [Sensitive] [Fashion-forward]      │
│                                                         │
├─────────────────────────────────────────────────────────┤
│             [View Full History Together]                │
└─────────────────────────────────────────────────────────┘
```

### Timeline/History Browser

```
TIMELINE VIEW:
┌─────────────────────────────────────────────────────────┐
│  ━━━━━━━━━━                    [Filter ▼]              │
│                     Your Story                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  AGE 16 — TEEN                                    ▼     │
│  │                                                      │
│  ├─● Prom drama with Jess                    📅 Today  │
│  │   "Found out Jess is going with Derek"              │
│  │   [Relationship] [Drama] [Social]                   │
│  │                                                      │
│  ├─● Made varsity soccer                     📅 3d ago │
│  │   "Hard work paid off - starting forward!"          │
│  │   [Achievement] [Sports] [Milestone]                │
│  │                                                      │
│  ├─● Failed math test                        📅 1w ago │
│  │   "Didn't study enough, mom is upset"               │
│  │   [School] [Grades] [Family]                        │
│  │                                                      │
│  AGE 15 — TEEN                                    ▼     │
│  │                                                      │
│  ├─● Got rejected by Derek                   📅 ...    │
│  │   "Asked him to movies, he said no"                 │
│  │   [Romance] [Rejection]                             │
│  │                                                      │
│  ├─○ First day of high school                📅 ...    │ ← Milestone
│  │   ⭐ MILESTONE                                      │
│  │   "Nervous but excited for new chapter"             │
│  │                                                      │
│  ...                                                    │
│                                                         │
│  AGE 6 — CHILDHOOD                               ▶     │ ← Collapsed
│                                                         │
│  AGE 0-5 — EARLY YEARS                           ▶     │ ← Collapsed
│                                                         │
└─────────────────────────────────────────────────────────┘

FILTER OPTIONS:
├── Event type (Milestone, Random, Choice)
├── Category (Family, Romance, Career, Health, etc.)
├── Mood (Positive, Negative, Neutral)
├── Characters involved
└── Year range

INTERACTIONS:
├── Tap event: Expand to full detail
├── Tap year header: Collapse/expand
├── Swipe event left: Add to favorites/highlights
├── Pull down: Refresh if viewing other's character
└── Pinch: Zoom timeline scale
```

### Settings Screen

```
┌─────────────────────────────────────────────────────────┐
│                       Settings                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ACCOUNT                                                │
│  ┌─────────────────────────────────────────────────┐   │
│  │ [Avatar]  John Doe                              │   │
│  │           john@email.com                    >   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  GAME                                                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Show stat hints on choices              [====●] │   │
│  │ Auto-advance year                       [●====] │   │
│  │ Typing effect for narrative             [====●] │   │
│  │ Confirm before age up                   [====●] │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  NOTIFICATIONS                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Character updates (watched)             [====●] │   │
│  │ Milestone reminders                     [====●] │   │
│  │ Social interactions                     [●====] │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  APPEARANCE                                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Theme                               [System ▼] │   │
│  │ Text size                           [Medium ▼] │   │
│  │ Reduce animations                       [●====] │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ACCESSIBILITY                                     >    │
│  PRIVACY                                           >    │
│  HELP & SUPPORT                                    >    │
│  ABOUT                                             >    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              [Sign Out]                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Version 1.0.0 (Build 42)                              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 6. Design System

### Color Palette

```swift
// MARK: - Semantic Colors

extension Color {
    // Primary brand colors
    static let brandPrimary = Color("BrandPrimary")      // Deep blue: #2563EB
    static let brandSecondary = Color("BrandSecondary")  // Warm orange: #F59E0B
    
    // Semantic colors
    static let success = Color("Success")     // Green: #10B981
    static let warning = Color("Warning")     // Amber: #F59E0B
    static let danger = Color("Danger")       // Red: #EF4444
    static let info = Color("Info")           // Blue: #3B82F6
    
    // Stat colors (for values 0-100)
    static let statCritical = Color.danger    // 0-20
    static let statPoor = Color.warning       // 21-40
    static let statAverage = Color.yellow     // 41-60
    static let statGood = Color.success       // 61-80
    static let statExcellent = Color.info     // 81-100
    
    // Life stage colors
    static let stageInfancy = Color(hex: "#FDF2F8")      // Soft pink
    static let stageChildhood = Color(hex: "#FEF9C3")    // Sunny yellow
    static let stageTween = Color(hex: "#DBEAFE")        // Light blue
    static let stageTeen = Color(hex: "#E0E7FF")         // Indigo tint
    static let stageYoungAdult = Color(hex: "#D1FAE5")   // Fresh green
    static let stageAdult = Color(hex: "#F3F4F6")        // Neutral gray
    static let stageMiddleAge = Color(hex: "#FEF3C7")    // Warm amber
    static let stageSenior = Color(hex: "#EDE9FE")       // Soft purple
    static let stageElder = Color(hex: "#F5F5F4")        // Warm white
    
    // Surface colors (adapt to dark mode automatically)
    static let surfacePrimary = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    static let surfaceGrouped = Color(.systemGroupedBackground)
    static let surfaceCard = Color(.secondarySystemGroupedBackground)
}

// MARK: - Dark Mode Support

// All colors should have light/dark variants in Assets.xcassets:
/*
 BrandPrimary
 ├── Any Appearance: #2563EB (Blue)
 └── Dark Appearance: #3B82F6 (Lighter blue)
 
 Success
 ├── Any Appearance: #10B981
 └── Dark Appearance: #34D399
 
 Danger
 ├── Any Appearance: #EF4444
 └── Dark Appearance: #F87171
*/
```

### Typography Scale

```swift
// MARK: - Typography

extension Font {
    // Display (for splash, major headings)
    static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
    
    // Headlines
    static let headlineLarge = Font.system(size: 32, weight: .semibold)
    static let headlineMedium = Font.system(size: 28, weight: .semibold)
    static let headlineSmall = Font.system(size: 24, weight: .semibold)
    
    // Titles (for screen titles, section headers)
    static let titleLarge = Font.system(size: 22, weight: .medium)
    static let titleMedium = Font.system(size: 16, weight: .medium)
    static let titleSmall = Font.system(size: 14, weight: .medium)
    
    // Body (for narrative text)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .serif)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .serif)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .serif)
    
    // Labels (for UI elements)
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
    
    // Narrative-specific
    static let narrativeText = Font.system(.body, design: .serif)
    static let choiceTitle = Font.system(size: 17, weight: .semibold)
    static let choiceSubtitle = Font.system(size: 14, weight: .regular)
}

// MARK: - Dynamic Type Support

extension View {
    func narrativeStyle() -> some View {
        self
            .font(.system(.body, design: .serif))
            .lineSpacing(8)
            .dynamicTypeSize(.xSmall ... .accessibility3)
    }
}
```

### Spacing System

```swift
// MARK: - Spacing

enum Spacing {
    /// 4pt - Tight spacing (between related elements)
    static let xxs: CGFloat = 4
    
    /// 8pt - Small spacing (within components)
    static let xs: CGFloat = 8
    
    /// 12pt - Compact spacing (between small elements)
    static let sm: CGFloat = 12
    
    /// 16pt - Default spacing (standard padding)
    static let md: CGFloat = 16
    
    /// 24pt - Large spacing (between sections)
    static let lg: CGFloat = 24
    
    /// 32pt - Extra large spacing (major sections)
    static let xl: CGFloat = 32
    
    /// 48pt - Screen margins on large screens
    static let xxl: CGFloat = 48
    
    // Component-specific
    static let cardPadding: CGFloat = 16
    static let buttonPadding: CGFloat = 12
    static let listItemPadding: CGFloat = 12
    static let screenHorizontal: CGFloat = 16
    static let screenVertical: CGFloat = 20
}

// MARK: - Corner Radius

enum CornerRadius {
    static let xs: CGFloat = 4    // Small chips, badges
    static let sm: CGFloat = 8    // Buttons, small cards
    static let md: CGFloat = 12   // Standard cards
    static let lg: CGFloat = 16   // Large cards, sheets
    static let xl: CGFloat = 20   // Modal corners
    static let full: CGFloat = 999 // Circular/pill shape
}
```

### Component Library

```swift
// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.buttonPadding)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "")
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - Cards

struct GameCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(Spacing.cardPadding)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// MARK: - Stat Display

struct StatPill: View {
    let emoji: String
    let value: Int
    let trend: Trend
    
    enum Trend {
        case up, down, stable
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(emoji)
                .font(.caption)
            Text("\(value)")
                .font(.caption.monospacedDigit())
            if trend != .stable {
                Image(systemName: trend == .up ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                    .foregroundStyle(trend == .up ? .green : .red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Chips/Tags

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.surfaceSecondary)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Avatar

struct CharacterAvatar: View {
    let character: CharacterPreview
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(character.lifeStage.color.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(character.initials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.2), lineWidth: 2)
            }
    }
}

// MARK: - Loading States

struct SkeletonText: View {
    let lines: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<lines, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 16)
                    .frame(maxWidth: index == lines - 1 ? 200 : .infinity)
            }
        }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}
```

### SF Symbols Usage

```swift
// MARK: - Icon System

enum GameIcon {
    // Stats
    static let health = "heart.fill"
    static let fitness = "figure.run"
    static let looks = "sparkles"
    static let intelligence = "brain.head.profile"
    static let happiness = "face.smiling.fill"
    static let stress = "exclamationmark.triangle.fill"
    static let popularity = "star.fill"
    static let romance = "heart.circle.fill"
    static let money = "dollarsign.circle.fill"
    static let career = "briefcase.fill"
    static let education = "graduationcap.fill"
    static let legacy = "trophy.fill"
    
    // Navigation
    static let discover = "globe"
    static let story = "book.fill"
    static let newLife = "plus.circle.fill"
    static let profile = "person.crop.circle"
    static let settings = "gearshape.fill"
    
    // Actions
    static let ageUp = "arrow.up.circle.fill"
    static let timeline = "clock.arrow.circlepath"
    static let relationships = "person.2.fill"
    static let back = "chevron.left"
    static let close = "xmark"
    static let expand = "chevron.down"
    static let collapse = "chevron.up"
    
    // Status
    static let trending = "flame.fill"
    static let watching = "eye.fill"
    static let views = "chart.line.uptrend.xyaxis"
    static let recent = "clock.fill"
    static let milestone = "star.circle.fill"
    
    // Life stages
    static let baby = "figure.and.child.holdinghands"
    static let child = "figure.child"
    static let teen = "figure.wave"
    static let adult = "figure.stand"
    static let senior = "figure.walk"
    
    // Events
    static let positive = "hand.thumbsup.fill"
    static let negative = "hand.thumbsdown.fill"
    static let neutral = "minus.circle.fill"
    static let dramatic = "exclamationmark.bubble.fill"
}
```

---

## 7. Interaction Design

### Touch Targets

```
MINIMUM SIZES:
├── Buttons: 44pt × 44pt (Apple HIG)
├── Tappable cards: Full card area
├── List items: Full row height (≥44pt)
├── Icon buttons: 44pt diameter hit area
└── Text links: 44pt vertical padding

SPACING BETWEEN TARGETS:
├── Minimum: 8pt between adjacent targets
├── Recommended: 12-16pt for comfort
└── Dense layouts: Use 8pt with clear boundaries
```

### Gesture Vocabulary

```
TAP:
├── Primary selection
├── Navigation
├── Toggle states
└── Confirm actions

DOUBLE TAP:
├── Quick confirm (choice + age up)
├── Zoom/fit content
└── Like/favorite

LONG PRESS:
├── Quick preview (character cards)
├── Context menu
├── Reveal additional options
└── Start drag operation

SWIPE LEFT/RIGHT:
├── Navigate between choices
├── Switch tabs (within content)
├── Archive/delete (list items)
└── Reveal actions

SWIPE UP:
├── Reveal more content
├── Open dashboard/sheet
└── Dismiss to close

SWIPE DOWN:
├── Dismiss sheet/modal
├── Pull to refresh
└── Close keyboard

PINCH:
├── Timeline zoom
├── Image zoom
└── Font size adjustment (accessibility)

EDGE SWIPE:
├── Left edge: System back gesture
└── Right edge: Reserved (avoid)
```

### Haptic Feedback Patterns

```swift
// MARK: - Haptic Feedback

enum GameHaptics {
    // MARK: - Selection Feedback
    
    /// Light tap for selections, toggles
    static func selection() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Medium tap for confirming choices
    static func confirm() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success - stat increase, achievement
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Warning - stat decrease, danger choice
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    /// Error - failed action, blocked choice
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    // MARK: - Game-specific
    
    /// Age up confirmation - satisfying heavy tap
    static func ageUp() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    /// Milestone achieved - double tap pattern
    static func milestone() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
    }
    
    /// Death event - slow heavy pattern
    static func death() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                generator.impactOccurred(intensity: 1.0 - Double(i) * 0.3)
            }
        }
    }
}

// MARK: - SwiftUI Integration (iOS 17+)

extension View {
    func gameHaptic(_ type: GameHaptics.Type, trigger: some Equatable) -> some View {
        self.sensoryFeedback(.impact, trigger: trigger)
    }
}
```

### Animation Guidelines

```swift
// MARK: - Animation Presets

extension Animation {
    // Quick feedback (button press, selection)
    static let quick = Animation.spring(duration: 0.15)
    
    // Standard transitions
    static let standard = Animation.spring(duration: 0.3)
    
    // Smooth content changes
    static let smooth = Animation.easeInOut(duration: 0.25)
    
    // Dramatic moments (milestones, death)
    static let dramatic = Animation.easeInOut(duration: 0.6)
    
    // Stagger children
    static func stagger(index: Int, delay: Double = 0.05) -> Animation {
        Animation.spring(duration: 0.3).delay(Double(index) * delay)
    }
}

// MARK: - Transitions

extension AnyTransition {
    // Choice cards appearing
    static var choiceAppear: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }
    
    // Narrative text change
    static var narrativeChange: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.98))
    }
    
    // Screen transitions
    static var screenPush: AnyTransition {
        .move(edge: .trailing)
    }
}

// MARK: - Animation Rules

/*
DO:
✓ Use spring animations for interactive elements
✓ Keep durations under 0.5s for UI feedback
✓ Use consistent timing across similar elements
✓ Stagger list item animations (0.05-0.1s delay)
✓ Match animation to physical metaphor

DON'T:
✗ Animate more than 3 elements simultaneously
✗ Use animations longer than 1s (except celebrations)
✗ Block user input during animations
✗ Animate text content changes (use crossfade)
✗ Use bouncy springs for navigation
*/
```

### Pull-to-Refresh Behaviors

```swift
// MARK: - Refresh Patterns

// Discovery feed - refresh trending/recent
RefreshableScrollView {
    DiscoveryFeed()
} onRefresh: {
    await viewModel.refreshFeed()
}

// Character view (spectating) - check for updates
RefreshableScrollView {
    CharacterView(character: character)
} onRefresh: {
    await viewModel.checkForUpdates()
}

// Timeline - reload full history (rarely needed)
// Note: Most content is local, refresh is for spectating

// MARK: - Custom Pull Indicator

struct GameRefreshControl: View {
    let isRefreshing: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
            } else {
                Image(systemName: "arrow.down")
            }
            Text(isRefreshing ? "Updating..." : "Pull to refresh")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

---

## 8. iOS 17+ Features

### TipKit for Onboarding

```swift
// MARK: - Game Tips

import TipKit

// First time seeing choices
struct ChoiceTip: Tip {
    var title: Text {
        Text("Make Your Choice")
    }
    
    var message: Text? {
        Text("Tap a choice to select it, then tap 'Age Up' to see what happens. Your decisions shape your story!")
    }
    
    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }
}

// Stats dashboard hint
struct StatsTip: Tip {
    var title: Text {
        Text("Check Your Stats")
    }
    
    var message: Text? {
        Text("Swipe up or tap the stats bar to see your full character profile and how your choices affect you.")
    }
    
    var image: Image? {
        Image(systemName: "chart.bar.fill")
    }
    
    var rules: [Rule] {
        #Rule(Self.$hasPlayedThreeTurns) {
            $0 == true
        }
    }
    
    @Parameter
    static var hasPlayedThreeTurns: Bool = false
}

// Discovery feature
struct DiscoverTip: Tip {
    var title: Text {
        Text("Explore Other Lives")
    }
    
    var message: Text? {
        Text("See how other players are living their characters' lives. You might find inspiration—or drama!")
    }
    
    var image: Image? {
        Image(systemName: "globe")
    }
}

// Spectator voting
struct VoteTip: Tip {
    var title: Text {
        Text("What Would You Do?")
    }
    
    var message: Text? {
        Text("When watching others, you can vote on choices to see how the community would decide.")
    }
    
    var image: Image? {
        Image(systemName: "checkmark.circle")
    }
}

// MARK: - Tip Presentation

struct GameView: View {
    let choiceTip = ChoiceTip()
    
    var body: some View {
        VStack {
            // ... narrative content ...
            
            ChoicesView()
                .popoverTip(choiceTip, arrowEdge: .top)
        }
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
    }
}
```

### Live Activities for Background Events

```swift
// MARK: - Live Activity for Character Updates

import ActivityKit

struct CharacterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var characterName: String
        var age: Int
        var lastEvent: String
        var emoji: String
    }
    
    var characterId: String
}

// Widget UI
struct CharacterLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CharacterActivityAttributes.self) { context in
            // Lock screen / banner
            HStack {
                VStack(alignment: .leading) {
                    Text(context.state.characterName)
                        .font(.headline)
                    Text("Age \(context.state.age)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(context.state.emoji)
                    .font(.largeTitle)
            }
            .padding()
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.characterName)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Age \(context.state.age)")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.lastEvent)
                        .font(.caption)
                }
            } compactLeading: {
                Text(context.state.emoji)
            } compactTrailing: {
                Text("\(context.state.age)")
            } minimal: {
                Text(context.state.emoji)
            }
        }
    }
}

// MARK: - Usage

// Start activity when character has pending event
func startCharacterActivity(for character: Character) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    
    let attributes = CharacterActivityAttributes(characterId: character.id)
    let state = CharacterActivityAttributes.ContentState(
        characterName: character.name,
        age: character.age,
        lastEvent: "A decision awaits...",
        emoji: "🤔"
    )
    
    do {
        let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil),
            pushType: .token
        )
    } catch {
        print("Failed to start activity: \(error)")
    }
}
```

### Widgets for Quick Stats

```swift
// MARK: - Home Screen Widget

import WidgetKit

struct CharacterWidgetEntry: TimelineEntry {
    let date: Date
    let character: CharacterSummary
}

struct CharacterWidget: Widget {
    let kind: String = "CharacterWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CharacterProvider()) { entry in
            CharacterWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Character Status")
        .description("Keep track of your character's life.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct CharacterWidgetView: View {
    let entry: CharacterWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallCharacterWidget(character: entry.character)
        case .systemMedium:
            MediumCharacterWidget(character: entry.character)
        case .accessoryCircular:
            // Apple Watch / Lock Screen
            ZStack {
                AccessoryWidgetBackground()
                VStack {
                    Text("\(entry.character.age)")
                        .font(.title.bold())
                    Text(entry.character.lifeStageEmoji)
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(entry.character.name)
                    .font(.headline)
                Text("Age \(entry.character.age) • \(entry.character.lifeStage)")
                    .font(.caption)
            }
        default:
            EmptyView()
        }
    }
}

struct SmallCharacterWidget: View {
    let character: CharacterSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(character.lifeStageEmoji)
                    .font(.title)
                Spacer()
                Text("\(character.age)")
                    .font(.title2.bold())
            }
            
            Text(character.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(character.lastEventSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Spacer()
            
            // Mini stat bar
            HStack(spacing: 4) {
                Label("\(character.health)", systemImage: "heart.fill")
                    .foregroundStyle(.red)
                Label("\(character.happiness)", systemImage: "face.smiling")
                    .foregroundStyle(.yellow)
            }
            .font(.caption2)
        }
        .padding()
    }
}
```

### Dynamic Island Integration

```swift
// MARK: - Dynamic Island Scenarios

/*
DYNAMIC ISLAND USE CASES:

1. MILESTONE ACHIEVED
   Compact: 🎉 + "Milestone!"
   Expanded: Full achievement display with stats

2. WAITING FOR DECISION
   Compact: Character emoji + "..."
   Expanded: Current situation summary + tap to continue

3. CHARACTER DEATH
   Compact: 🕊️ + Age
   Expanded: Memorial summary + legacy score

4. SOMEONE WATCHING YOUR CHARACTER
   Compact: 👁️ + viewer count
   Expanded: "[Name] is watching [Character]"
*/

// Implementation is same as Live Activities (see above)
// Key is updating the ContentState appropriately
```

### StandBy Mode Support

```swift
// MARK: - StandBy Mode Widget

// StandBy uses Lock Screen widgets (accessory family)
// Create compelling views for bedside/desk display

struct StandByCharacterWidget: View {
    let character: CharacterSummary
    
    var body: some View {
        VStack(spacing: 12) {
            // Large age display
            Text("\(character.age)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Name and life stage
            VStack(spacing: 4) {
                Text(character.name)
                    .font(.title3)
                Text(character.lifeStage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Key stat
            HStack {
                Image(systemName: "heart.fill")
                Text("\(character.health)%")
            }
            .font(.caption)
            .foregroundStyle(.red)
        }
    }
}

// Register for .accessoryRectangular in supportedFamilies
// StandBy will scale appropriately
```

---

## 9. Accessibility

### VoiceOver Support

```swift
// MARK: - Accessibility Labels

// Choice cards
ChoiceCard(choice: choice)
    .accessibilityLabel("\(choice.title). \(choice.subtitle)")
    .accessibilityHint("Double tap to select this choice")
    .accessibilityAddTraits(.isButton)

// Stats bar
StatsBar(character: character)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("""
        \(character.name), age \(character.age). 
        Health \(character.health). 
        Intelligence \(character.intelligence). 
        Happiness \(character.happiness).
    """)

// Narrative text
NarrativeView(text: narrative)
    .accessibilityLabel(narrative)
    .accessibilityAddTraits(.isStaticText)

// Timeline events
TimelineEvent(event: event)
    .accessibilityLabel("""
        Age \(event.age). \(event.title). 
        \(event.description). 
        Categories: \(event.categories.joined(separator: ", "))
    """)

// Character cards (discovery)
CharacterCard(character: character)
    .accessibilityLabel("""
        \(character.name), age \(character.age), 
        \(character.lifeStage). 
        \(character.viewCount) views. 
        Last active \(character.lastActivity, style: .relative).
    """)
    .accessibilityHint("Double tap to view this character's story")

// MARK: - Custom Actions

ChoiceCard(choice: choice)
    .accessibilityAction(named: "View consequences") {
        showConsequenceSheet = true
    }
    .accessibilityAction(named: "Select and confirm") {
        selectAndConfirm(choice)
    }

// MARK: - Grouping

// Group related stats
HStack {
    StatPill(...)
    StatPill(...)
    StatPill(...)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Stats: Health 82, Intelligence 71, Happiness 45")
```

### Dynamic Type Scaling

```swift
// MARK: - Dynamic Type Support

// Set size limits to prevent layout breakage
Text(narrative)
    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    // Allows up to Accessibility Large 2

// Use scalable spacing
@ScaledMetric(relativeTo: .body) var spacing: CGFloat = 16
@ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 24

// Adapt layouts for larger sizes
@Environment(\.dynamicTypeSize) var typeSize

var body: some View {
    if typeSize >= .accessibility1 {
        // Stack vertically for very large text
        VStack(alignment: .leading, spacing: spacing) {
            statContent
        }
    } else {
        // Normal horizontal layout
        HStack(spacing: spacing) {
            statContent
        }
    }
}

// MARK: - Minimum Text Size Guidelines

/*
MINIMUM SIZES (before scaling):
├── Body text: 17pt
├── Secondary text: 14pt  
├── Captions: 12pt (avoid smaller)
├── Stat values: 14pt
└── Button labels: 17pt

All text should use Dynamic Type (.body, .caption, etc.)
rather than fixed sizes when possible.
*/
```

### Reduced Motion Alternatives

```swift
// MARK: - Motion Sensitivity

@Environment(\.accessibilityReduceMotion) var reduceMotion

// Animation replacement
func transitionAnimation() -> Animation {
    reduceMotion ? .none : .spring(duration: 0.3)
}

// Choice appearance
ForEach(choices.indices, id: \.self) { index in
    ChoiceCard(choice: choices[index])
        .transition(reduceMotion ? .opacity : .slide)
        .animation(reduceMotion ? .none : .stagger(index: index))
}

// Loading state
if reduceMotion {
    // Static loading indicator
    ProgressView()
} else {
    // Animated shimmer
    SkeletonText(lines: 5).shimmer()
}

// Haptics (respect settings automatically)
// UIFeedbackGenerator respects system accessibility settings

// Typewriter effect
if !reduceMotion && settings.typewriterEnabled {
    TypewriterText(narrative)
} else {
    Text(narrative)
}

// MARK: - Reduce Motion Settings

/*
WHEN REDUCE MOTION IS ON:
├── Replace spring animations with instant/linear
├── Disable parallax effects
├── Use opacity transitions instead of movement
├── Disable typewriter text effect
├── Use static loading indicators
├── Keep haptics (user-controlled separately)
└── Remove decorative animations
*/
```

### Color Contrast Requirements

```swift
// MARK: - Color Contrast

/*
WCAG 2.1 Requirements:
├── Normal text: 4.5:1 minimum contrast ratio
├── Large text (18pt+): 3:1 minimum
├── UI components: 3:1 minimum
└── Decorative elements: No requirement

OUR IMPLEMENTATION:
├── Primary text on background: 7:1 (exceeds AA)
├── Secondary text: 4.5:1 (meets AA)
├── Stat colors on card backgrounds: Tested for 3:1
├── Interactive elements: Clear visual boundaries
└── Don't rely on color alone for information
*/

// Color-blind safe stat indicators
struct StatIndicator: View {
    let value: Int
    let trend: Trend
    
    var body: some View {
        HStack {
            // Value always visible
            Text("\(value)")
                .font(.headline)
            
            // Color + shape + label
            Group {
                switch trend {
                case .up:
                    Label("Improving", systemImage: "arrow.up")
                        .foregroundStyle(.green)
                case .down:
                    Label("Declining", systemImage: "arrow.down")
                        .foregroundStyle(.red)
                case .stable:
                    Label("Stable", systemImage: "minus")
                        .foregroundStyle(.secondary)
                }
            }
            .labelStyle(.iconOnly)
            .font(.caption)
        }
    }
}

// High contrast mode support
@Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

var body: some View {
    if differentiateWithoutColor {
        // Add patterns/borders in addition to color
        StatCard()
            .overlay(patternForStatLevel(stat.level))
    } else {
        StatCard()
    }
}
```

### Accessibility Quick Reference

```
CHECKLIST FOR EVERY SCREEN:

[ ] All interactive elements have accessibility labels
[ ] All images have descriptions (or are decorative)
[ ] Touch targets are minimum 44×44pt
[ ] Focus order is logical
[ ] No information conveyed by color alone
[ ] Text contrast meets 4.5:1 (or 3:1 for large)
[ ] Content scales with Dynamic Type
[ ] Animations respect Reduce Motion
[ ] Custom actions for complex interactions
[ ] Tested with VoiceOver enabled

TESTING PROCESS:
1. Enable VoiceOver, navigate entire flow
2. Enable Reduce Motion, verify no jarring effects
3. Set Dynamic Type to Accessibility XL, check layout
4. Check color contrast with Accessibility Inspector
5. Test with Switch Control briefly
```

---

## 10. SwiftUI Implementation

### App Structure

```swift
// MARK: - App Entry Point

@main
struct LifeEncyclopediaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var characterManager = CharacterManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(characterManager)
                .task {
                    // Configure tips
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DiscoveryView()
                .tabItem {
                    Label("Discover", systemImage: GameIcon.discover)
                }
                .tag(AppTab.discover)
            
            StoryView()
                .tabItem {
                    Label("Story", systemImage: GameIcon.story)
                }
                .tag(AppTab.story)
            
            // New Life is a sheet, not a tab destination
            Color.clear
                .tabItem {
                    Label("New Life", systemImage: GameIcon.newLife)
                }
                .tag(AppTab.newLife)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: GameIcon.profile)
                }
                .tag(AppTab.profile)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: GameIcon.settings)
                }
                .tag(AppTab.settings)
        }
        .onChange(of: appState.selectedTab) { _, newValue in
            if newValue == .newLife {
                appState.showNewLifeSheet = true
                // Reset to previous tab
                appState.selectedTab = appState.previousTab
            } else {
                appState.previousTab = newValue
            }
        }
        .sheet(isPresented: $appState.showNewLifeSheet) {
            CharacterCreationFlow()
        }
    }
}
```

### Core Game Loop Implementation

```swift
// MARK: - Main Game View

struct StoryView: View {
    @EnvironmentObject var characterManager: CharacterManager
    @StateObject private var gameViewModel = GameViewModel()
    
    @State private var selectedChoice: Choice?
    @State private var showStatsDashboard = false
    @State private var showRelationships = false
    @State private var showTimeline = false
    
    var body: some View {
        NavigationStack {
            if let character = characterManager.activeCharacter {
                GameScreenView(
                    character: character,
                    viewModel: gameViewModel,
                    selectedChoice: $selectedChoice,
                    showStatsDashboard: $showStatsDashboard,
                    showRelationships: $showRelationships,
                    showTimeline: $showTimeline
                )
            } else {
                NoCharacterView()
            }
        }
    }
}

struct GameScreenView: View {
    let character: Character
    @ObservedObject var viewModel: GameViewModel
    @Binding var selectedChoice: Choice?
    @Binding var showStatsDashboard: Bool
    @Binding var showRelationships: Bool
    @Binding var showTimeline: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Stats header
            StatsBar(character: character)
                .onTapGesture {
                    showStatsDashboard = true
                }
            
            // Main content
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Narrative area
                    NarrativeSection(
                        narrative: viewModel.currentNarrative,
                        isLoading: viewModel.isLoadingNarrative,
                        isStreaming: viewModel.isStreaming
                    )
                    
                    // Choices
                    if !viewModel.isLoadingNarrative {
                        ChoicesSection(
                            choices: viewModel.currentChoices,
                            selectedChoice: $selectedChoice
                        )
                    }
                }
                .padding()
            }
            .refreshable {
                // Only for spectator mode
                if viewModel.isSpectating {
                    await viewModel.checkForUpdates()
                }
            }
            
            // Bottom action bar
            ActionBar(
                canProgress: selectedChoice != nil && !viewModel.isProcessing,
                isProcessing: viewModel.isProcessing,
                onAgeUp: {
                    guard let choice = selectedChoice else { return }
                    Task {
                        await viewModel.makeChoice(choice)
                        selectedChoice = nil
                    }
                },
                onTimeline: { showTimeline = true },
                onRelationships: { showRelationships = true }
            )
        }
        .sheet(isPresented: $showStatsDashboard) {
            StatsDashboard(character: character)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRelationships) {
            RelationshipsSheet(relationships: character.relationships)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTimeline) {
            TimelineSheet(events: character.timeline)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
```

### View Models

```swift
// MARK: - Game View Model

@MainActor
class GameViewModel: ObservableObject {
    @Published var currentNarrative: String = ""
    @Published var currentChoices: [Choice] = []
    @Published var isLoadingNarrative: Bool = false
    @Published var isStreaming: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isSpectating: Bool = false
    
    private let llmService: LLMService
    private let characterService: CharacterService
    
    init(llmService: LLMService = .shared, characterService: CharacterService = .shared) {
        self.llmService = llmService
        self.characterService = characterService
    }
    
    func loadCurrentSituation(for character: Character) async {
        isLoadingNarrative = true
        
        do {
            let situation = try await llmService.generateSituation(for: character)
            
            withAnimation(.smooth) {
                currentNarrative = situation.narrative
                currentChoices = situation.choices
                isLoadingNarrative = false
            }
        } catch {
            // Handle error - show retry
            isLoadingNarrative = false
        }
    }
    
    func makeChoice(_ choice: Choice) async {
        isProcessing = true
        GameHaptics.confirm()
        
        do {
            // Send choice to LLM, get result
            let result = try await llmService.processChoice(choice)
            
            // Animate stat changes
            await characterService.applyStatChanges(result.statChanges)
            
            // Success haptic for positive outcomes
            if result.isPositive {
                GameHaptics.success()
            } else {
                GameHaptics.warning()
            }
            
            // Load next situation
            await loadCurrentSituation(for: characterService.currentCharacter!)
            
        } catch {
            GameHaptics.error()
            isProcessing = false
        }
    }
    
    func checkForUpdates() async {
        // For spectator mode - check if character has new events
    }
}
```

### Reusable Components

```swift
// MARK: - Narrative Section

struct NarrativeSection: View {
    let narrative: String
    let isLoading: Bool
    let isStreaming: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if isLoading {
                SkeletonText(lines: 6)
                    .shimmer()
            } else {
                Text(narrative)
                    .narrativeStyle()
                    .transition(.narrativeChange)
            }
            
            if isStreaming {
                TypingIndicator()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth, value: isLoading)
    }
}

// MARK: - Choices Section

struct ChoicesSection: View {
    let choices: [Choice]
    @Binding var selectedChoice: Choice?
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                ChoiceCard(
                    choice: choice,
                    isSelected: selectedChoice?.id == choice.id,
                    onSelect: {
                        withAnimation(.quick) {
                            selectedChoice = choice
                        }
                        GameHaptics.selection()
                    }
                )
                .transition(reduceMotion ? .opacity : .choiceAppear)
                .animation(reduceMotion ? .none : .stagger(index: index), value: choices.count)
            }
        }
    }
}

// MARK: - Action Bar

struct ActionBar: View {
    let canProgress: Bool
    let isProcessing: Bool
    let onAgeUp: () -> Void
    let onTimeline: () -> Void
    let onRelationships: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onTimeline) {
                Label("Timeline", systemImage: GameIcon.timeline)
            }
            .labelStyle(.iconOnly)
            .frame(width: 44, height: 44)
            
            Spacer()
            
            Button(action: onAgeUp) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: GameIcon.ageUp)
                    }
                    Text("Age Up")
                }
                .font(.headline)
                .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canProgress || isProcessing)
            .sensoryFeedback(.impact(weight: .heavy), trigger: canProgress)
            
            Spacer()
            
            Button(action: onRelationships) {
                Label("People", systemImage: GameIcon.relationships)
            }
            .labelStyle(.iconOnly)
            .frame(width: 44, height: 44)
        }
        .padding()
        .background(.bar)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotCount == index ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever()
                        .delay(Double(index) * 0.15),
                        value: dotCount
                    )
            }
        }
        .onAppear {
            dotCount = 1
        }
    }
}
```

### Navigation Coordinator

```swift
// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .story
    @Published var previousTab: AppTab = .story
    @Published var showNewLifeSheet: Bool = false
    @Published var navigationPath = NavigationPath()
    
    // Deep linking
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == "life-encyclopedia" else {
            return
        }
        
        let pathComponents = components.path.split(separator: "/").map(String.init)
        
        switch pathComponents.first {
        case "character":
            if let characterId = pathComponents.dropFirst().first {
                // Navigate to character
                selectedTab = .discover
                navigationPath.append(CharacterDestination(id: characterId))
            }
        case "discover":
            selectedTab = .discover
            if let category = pathComponents.dropFirst().first {
                navigationPath.append(DiscoveryCategory(rawValue: category) ?? .trending)
            }
        case "create":
            showNewLifeSheet = true
        default:
            break
        }
    }
}

enum AppTab: String, Hashable {
    case discover
    case story
    case newLife
    case profile
    case settings
}

// MARK: - Navigation Destinations

struct CharacterDestination: Hashable {
    let id: String
}

enum DiscoveryCategory: String, Hashable {
    case trending
    case rising
    case drama
    case wisdom
    case similar
}
```

### Data Models

```swift
// MARK: - Core Models

struct Character: Identifiable, Codable {
    let id: String
    var name: String
    var age: Int
    var gender: Gender
    var lifeStage: LifeStage
    
    // Stats
    var health: Int
    var fitness: Int
    var looks: Int
    var intelligence: Int
    var happiness: Int
    var stress: Int
    var popularity: Int
    var romance: Int
    var money: Double
    var careerLevel: Int
    var education: Int
    var legacyScore: Int
    
    // Relationships
    var relationships: [Relationship]
    
    // Timeline
    var timeline: [TimelineEvent]
    
    // Computed properties
    var isAlive: Bool { health > 0 }
    var primaryStats: [StatSummary] {
        lifeStage.relevantStats.map { stat in
            StatSummary(type: stat, value: value(for: stat))
        }
    }
}

struct Choice: Identifiable, Codable {
    let id: String
    let emoji: String
    let title: String
    let subtitle: String
    let statHints: [StatHint]?
}

struct StatHint: Codable {
    let stat: StatType
    let direction: Direction
    let magnitude: Magnitude
    
    enum Direction: String, Codable {
        case up, down, variable
    }
    
    enum Magnitude: String, Codable {
        case small, medium, large
    }
}

struct TimelineEvent: Identifiable, Codable {
    let id: String
    let age: Int
    let title: String
    let description: String
    let categories: [String]
    let mood: EventMood
    let isMilestone: Bool
    let date: Date
}

struct Relationship: Identifiable, Codable {
    let id: String
    let npcId: String
    let npcName: String
    let type: RelationshipType
    var level: Int // -100 to 100
    var trust: Int // 0 to 100
    let metAtAge: Int
    var lastInteraction: String
}

enum LifeStage: String, Codable, CaseIterable {
    case infancy, earlyChildhood, childhood, tween, teen
    case youngAdult, adult, middleAge, senior, elder
    
    var relevantStats: [StatType] {
        switch self {
        case .infancy: return [.health, .parentBond]
        case .earlyChildhood: return [.health, .intelligence, .happiness]
        case .childhood: return [.health, .intelligence, .popularity, .grades]
        case .tween: return [.health, .intelligence, .popularity, .happiness]
        case .teen: return [.health, .intelligence, .popularity, .happiness, .romance]
        case .youngAdult: return [.health, .career, .money, .romance]
        case .adult: return [.health, .career, .money, .marriage]
        case .middleAge: return [.health, .legacy, .money, .happiness]
        case .senior: return [.health, .legacy, .peace, .family]
        case .elder: return [.health, .peace, .legacy]
        }
    }
    
    var color: Color {
        switch self {
        case .infancy: return .stageInfancy
        case .earlyChildhood: return .stageChildhood
        case .childhood: return .stageChildhood
        case .tween: return .stageTween
        case .teen: return .stageTeen
        case .youngAdult: return .stageYoungAdult
        case .adult: return .stageAdult
        case .middleAge: return .stageMiddleAge
        case .senior: return .stageSenior
        case .elder: return .stageElder
        }
    }
}
```

---

## Appendix A: Screen Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              SCREEN FLOWS                                     │
└──────────────────────────────────────────────────────────────────────────────┘

ONBOARDING (First Launch)
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Welcome │ →  │  Name   │ →  │ Gender  │ →  │ Traits  │ →  │ Confirm │ → GAME
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘

MAIN GAME LOOP
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  ┌──────────┐                                                               │
│  │Situation │ ← LLM generates based on character state                      │
│  │(Narrative)│                                                              │
│  └────┬─────┘                                                               │
│       │                                                                     │
│       ▼                                                                     │
│  ┌──────────┐     Select      ┌──────────┐    Confirm     ┌──────────┐     │
│  │ Choices  │ ──────────────→ │ Selected │ ─────────────→ │ Age Up   │     │
│  │ (2-4)    │                 │  Choice  │                │(Process) │     │
│  └──────────┘                 └──────────┘                └────┬─────┘     │
│       │                                                        │           │
│       │ View                                                   │           │
│       ▼                                                        ▼           │
│  ┌──────────┐                                            ┌──────────┐      │
│  │  Stats   │ (Sheet)                                    │  Result  │      │
│  │Dashboard │                                            │(Animated)│      │
│  └──────────┘                                            └────┬─────┘      │
│       │                                                        │           │
│       │ View                                                   │           │
│       ▼                                                        │           │
│  ┌──────────┐                                                  │           │
│  │Relations │ (Sheet)                                          │           │
│  └──────────┘                                                  │           │
│       │                                                        │           │
│       │ View                                                   │           │
│       ▼                                                        │           │
│  ┌──────────┐                                                  │           │
│  │ Timeline │ (Sheet)                                          │           │
│  └──────────┘                                                  │           │
│                                                                │           │
│       └────────────────────────────────────────────────────────┘           │
│                           (Loop back to new Situation)                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

DISCOVERY FLOW
┌──────────┐    Tap Card    ┌──────────┐    View      ┌──────────┐
│Discovery │ ─────────────→ │Character │ ──────────→ │ Timeline │
│  Feed    │                │  Detail  │             │  (Full)  │
└──────────┘                └────┬─────┘             └──────────┘
     │                           │
     │ Search                    │ Vote on
     ▼                           ▼ choices
┌──────────┐               ┌──────────┐
│  Search  │               │Spectator │
│  Modal   │               │  View    │
└──────────┘               └──────────┘
```

---

## Appendix B: Key Metrics to Track

```
USER ENGAGEMENT:
├── Session duration
├── Actions per session
├── Choices per minute
├── Return rate (daily/weekly)
└── Character completion rate

UI PERFORMANCE:
├── LLM response time (target <3s)
├── Frame rate during animations
├── App launch time
├── Memory usage
└── Crash rate

FEATURE USAGE:
├── Discovery tab visits
├── Characters viewed per session
├── Relationships sheet opens
├── Timeline scroll depth
└── Widget engagement

ACCESSIBILITY:
├── VoiceOver session percentage
├── Dynamic Type sizes used
├── Reduce Motion enabled
└── High Contrast enabled
```

---

*This design system provides a complete foundation for building the Life Encyclopedia iOS app. All components are designed for iOS 17+ with SwiftUI, prioritizing mobile-first interaction, accessibility, and seamless LLM integration.*
