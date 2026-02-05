# Life Encyclopedia

A SwiftUI iOS app that lets you explore historical events in the lives of notable people.

## Features

- **Home Tab**: View a list of recently generated people (stored in Supabase)
- **Create Tab**: Search for a person, verify they exist, and generate historical events using AI

## Architecture

```
life-encyclopedia/
├── ContentView.swift           # Main TabView with Home/Create tabs
├── Models/
│   └── Person.swift            # Data models for Person and HistoricalEvent
├── Services/
│   ├── APIConfig.swift         # API keys configuration
│   ├── TavilyService.swift     # Verify people via web search
│   ├── ClaudeService.swift     # Generate historical events via Claude AI
│   └── SupabaseService.swift   # Database CRUD operations
├── Views/
│   ├── HomeView.swift          # List of generated people
│   ├── CreateView.swift        # Search and verification flow
│   └── PersonDetailView.swift  # Swipeable event pages
└── DesignSystem/
    ├── Colors.swift            # Color extensions
    ├── Typography.swift        # Font styles
    └── Spacing.swift           # Layout constants
```

## Setup

### 1. API Keys

Edit `life-encyclopedia/Services/APIConfig.swift` with your credentials:

```swift
enum APIConfig {
    // Anthropic (Claude) - https://console.anthropic.com/
    static let anthropicAPIKey = "your-anthropic-key"
    
    // Tavily - https://tavily.com/
    static let tavilyAPIKey = "your-tavily-key"
    
    // Supabase - https://supabase.com/dashboard
    static let supabaseURL = "your-project-url"
    static let supabaseAnonKey = "your-anon-key"
}
```

### 2. Supabase Database

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to the SQL Editor
3. Run the contents of `supabase-schema.sql` to create the `people` table

### 3. Build & Run

Open `life-encyclopedia.xcodeproj` in Xcode and run on a simulator or device.

## How It Works

1. **Search**: Enter a person's name in the Create tab
2. **Verify**: Tavily searches the web to confirm the person exists
3. **Generate**: Claude AI researches and generates 10-15 historical events
4. **Browse**: Swipe left/right through events with dates and citations
5. **Save**: Store the person in Supabase for future viewing

## Tech Stack

- **SwiftUI** - UI framework
- **Tavily API** - Web search for person verification
- **Claude API** - AI-powered historical event generation
- **Supabase** - PostgreSQL database for persistence

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Active API keys for Anthropic, Tavily, and Supabase
