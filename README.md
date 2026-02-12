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

The app reads credentials from environment variables at runtime.

Create/update a local `.env` (already gitignored) in the project root:

```bash
ANTHROPIC_API_KEY=your-anthropic-key
TAVILY_API_KEY=your-tavily-key
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

Then ensure these values are injected into your Xcode run environment (for example via your Scheme or local xcconfig setup).

### 2. Supabase Database

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to the SQL Editor
3. Run the contents of `supabase-schema.sql` to create the `people` table

### 3. Build & Run

Open `life-encyclopedia.xcodeproj` in Xcode and run on a simulator or device.

## Verify Supabase Connection

Before debugging app behavior, confirm the DB connection details:

1. `SUPABASE_URL` exactly matches your project URL in the Supabase dashboard.
2. `SUPABASE_ANON_KEY` is copied from the same project as that URL.
3. A direct REST call to `people` succeeds:

```bash
curl "$SUPABASE_URL/rest/v1/people?select=id,name&limit=5" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

If this call fails with 401/403/404, the app will fail similarly until URL/key or RLS policies are corrected.

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
