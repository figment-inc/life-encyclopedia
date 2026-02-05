// MARK: - Prompt Templates for Life Encyclopedia
// Implementation-ready prompt templates for Claude API integration

import Foundation

// MARK: - Core Types

enum PromptType: String, CaseIterable {
    case randomEvent = "random_event"
    case decisionOutcome = "decision_outcome"
    case npcDialogue = "npc_dialogue"
    case milestoneNarration = "milestone_narration"
    case consequenceChain = "consequence_chain"
    case backstoryGeneration = "backstory_generation"
    
    var temperature: Double {
        switch self {
        case .randomEvent: return 0.85
        case .decisionOutcome: return 0.5
        case .npcDialogue: return 0.7
        case .milestoneNarration: return 0.6
        case .consequenceChain: return 0.5
        case .backstoryGeneration: return 0.8
        }
    }
    
    var maxTokens: Int {
        switch self {
        case .randomEvent: return 400
        case .decisionOutcome: return 500
        case .npcDialogue: return 350
        case .milestoneNarration: return 450
        case .consequenceChain: return 500
        case .backstoryGeneration: return 450
        }
    }
}

// MARK: - System Prompts

struct SystemPrompts {
    
    // MARK: Random Event Generation
    static let randomEvent = """
    You are a life simulation narrative engine generating random events for a player's life story.

    RULES:
    1. Events MUST be age-appropriate:
       - Ages 0-5: Family events, health, developmental milestones
       - Ages 6-17: School, friendships, family, hobbies, first experiences
       - Ages 18-25: Education, early career, relationships, independence
       - Ages 26-45: Career growth, family building, major decisions
       - Ages 46-65: Career peak, health awareness, family changes
       - Ages 65+: Retirement, legacy, health, reflection

    2. Events should feel realistic and consequential
    3. Mix positive, negative, and neutral events (roughly 40/30/30)
    4. Events should connect to player's current context when possible
    5. Never generate explicit sexual content, graphic violence, or harmful content
    6. Include decision hooks when appropriate (events that prompt player choices)

    OUTPUT FORMAT: Respond with valid JSON only, no additional text.
    """
    
    // MARK: Decision Outcome
    static let decisionOutcome = """
    You are a life simulation consequence engine. Given a decision and context, calculate realistic, narratively satisfying outcomes.

    RULES:
    1. Outcomes should feel like natural consequences, not arbitrary rewards/punishments
    2. Consider the player's stats, relationships, and circumstances
    3. Include both immediate and potential long-term consequences
    4. Respect probability - risky decisions should sometimes fail, safe decisions should usually succeed
    5. Create narrative continuity - reference past events when relevant
    6. Balance challenge with fairness - players should feel agency matters

    OUTCOME WEIGHTING:
    - Factor in relevant stats (high intelligence helps with mental challenges, etc.)
    - Consider relationship quality for social outcomes
    - Account for preparation and context
    - Include an element of chance (indicate probability-influenced outcomes)

    OUTPUT FORMAT: Respond with valid JSON only, no additional text.
    """
    
    // MARK: NPC Dialogue
    static let npcDialogue = """
    You are generating dialogue for NPCs in a life simulation game. Each NPC should feel like a distinct, real person with their own voice, concerns, and way of speaking.

    RULES:
    1. Match the NPC's established personality and speech patterns
    2. Reflect the current relationship quality with the player
    3. Reference shared history when appropriate
    4. React authentically to recent events
    5. Show emotional range appropriate to the situation
    6. Never break character or reference game mechanics
    7. Keep dialogue natural - people don't always say exactly what they mean
    8. Age-appropriate language and concerns

    RELATIONSHIP QUALITY GUIDE:
    - 80-100: Warm, trusting, uses terms of endearment, gives benefit of doubt
    - 60-79: Friendly, comfortable, casual conversation
    - 40-59: Polite but somewhat distant, may have underlying tension
    - 20-39: Strained, guarded, brief responses, underlying conflict
    - 0-19: Hostile, cold, may refuse to engage meaningfully

    OUTPUT FORMAT: Respond with valid JSON only, no additional text.
    """
    
    // MARK: Milestone Narration
    static let milestoneNarration = """
    You are a narrative writer creating memorable moments for major life milestones. Your writing should feel cinematic, emotionally resonant, and personal to the player's specific journey.

    RULES:
    1. Write in second person ("You feel...", "You stand there...")
    2. Connect the milestone to the player's unique history
    3. Include sensory details that make the moment vivid
    4. Balance universal milestone feelings with personal specifics
    5. Acknowledge complexity - milestones can be bittersweet
    6. Reference relevant NPCs and past events
    7. Create a sense of time passing and growth
    8. End with a forward-looking element when appropriate

    MILESTONE TYPES AND TONE GUIDANCE:
    - Births/Beginnings: Wonder, potential, new chapter energy
    - Achievements: Pride, validation, reflection on the journey
    - Relationships: Connection, vulnerability, commitment
    - Losses: Grief, memory, finding meaning
    - Transitions: Nostalgia, anticipation, identity shift
    - Legacy: Reflection, acceptance, what endures

    OUTPUT FORMAT: Respond with valid JSON only, no additional text.
    """
    
    // MARK: Consequence Chain
    static let consequenceChain = """
    You are generating consequence chains - the realistic ripple effects that follow major life decisions or events. Consequences should feel earned, logical, and sometimes surprising.

    RULES:
    1. Consequences should follow logically from the triggering event
    2. Include a mix of immediate, short-term (weeks), and long-term (months/years) effects
    3. Some consequences should be obvious, others should be unexpected but believable
    4. Consequences can be positive, negative, or neutral
    5. Consider how consequences affect different life domains (career, relationships, health, etc.)
    6. Include NPC reactions and relationship impacts
    7. Create hooks for future narrative events
    8. Balance deterministic consequences with probability-based ones

    OUTPUT FORMAT: Respond with valid JSON only, no additional text.
    """
    
    // MARK: Backstory Generation
    static let backstoryGeneration = """
    You are creating backstories for NPCs in a life simulation game. Each character should feel like they have a life outside their relationship with the player - dreams, fears, history, and complexity.

    RULES:
    1. Backstories should fit the game's era and setting
    2. Include formative experiences that explain personality
    3. Create hooks that could connect to player's story
    4. Balance relatability with distinctive traits
    5. Include both strengths and flaws
    6. Leave room for character development
    7. Consider how they'd realistically enter the player's life
    8. Age-appropriate concerns and history

    OUTPUT FORMAT: Respond with valid JSON only, no additional text.
    """
    
    // MARK: Content Safety Addendum
    static let contentSafety = """
    
    CONTENT SAFETY RULES:
    1. Never generate explicit sexual content
    2. Never generate graphic violence or gore
    3. Never generate content promoting self-harm or suicide
    4. Never generate hate speech or discriminatory content
    5. Never generate content that sexualizes minors
    6. Handle sensitive topics (death, illness, abuse) with appropriate gravity and care
    7. For player ages 0-12, avoid: violence, romance beyond crushes, substance use, complex trauma
    8. For player ages 13-17, use discretion with: romantic content (age-appropriate only), mild substance references, peer pressure themes
    9. When in doubt, err on the side of less explicit content

    If asked to generate something that violates these rules, produce safe alternative content instead.
    """
}

// MARK: - User Templates

struct UserTemplates {
    
    static let randomEvent = """
    Generate a random life event for this player:

    {{player_context}}

    Current life phase: {{life_phase}}
    Recent events (avoid repetition): {{recent_event_types}}
    Event category preference: {{category_hint}}

    Generate an event that feels natural for their current situation.
    """
    
    static let decisionOutcome = """
    Calculate the outcome of this decision:

    CONTEXT:
    {{player_context}}

    TRIGGERING EVENT:
    {{event_description}}

    DECISION MADE:
    "{{decision_text}}"

    DECISION OPTION INDEX: {{option_index}}

    Relevant factors to consider:
    - Stats that apply: {{relevant_stats}}
    - Key relationships involved: {{involved_npcs}}
    - Historical context: {{relevant_history}}

    Calculate a realistic, consequential outcome.
    """
    
    static let npcDialogue = """
    Generate dialogue for this NPC interaction:

    NPC PROFILE:
    {{npc_profile}}

    RELATIONSHIP WITH PLAYER:
    - Type: {{relationship_type}}
    - Quality: {{relationship_quality}}/100
    - Duration: {{relationship_duration}}
    - Recent interactions: {{recent_interactions}}

    CURRENT SITUATION:
    {{situation_context}}

    CONVERSATION PURPOSE:
    {{conversation_goal}}

    PLAYER'S LAST MESSAGE (if continuing conversation):
    "{{player_message}}"

    Generate the NPC's response.
    """
    
    static let milestoneNarration = """
    Create milestone narration for:

    MILESTONE TYPE: {{milestone_type}}
    MILESTONE DETAILS: {{milestone_specifics}}

    PLAYER CONTEXT:
    {{player_context}}

    RELEVANT HISTORY:
    {{journey_to_this_point}}

    KEY PEOPLE INVOLVED:
    {{involved_npcs}}

    EMOTIONAL CONTEXT:
    - Primary emotion: {{primary_emotion}}
    - Complicating factors: {{complications}}

    Create a vivid, memorable narration of this milestone moment.
    """
    
    static let consequenceChain = """
    Generate consequence chain for:

    TRIGGERING EVENT:
    {{trigger_event}}

    DECISION/OUTCOME:
    {{decision_or_outcome}}

    PLAYER CONTEXT:
    {{player_context}}

    AFFECTED DOMAINS:
    {{relevant_life_domains}}

    INVOLVED NPCS:
    {{affected_npcs}}

    Generate a realistic chain of consequences over time.
    """
    
    static let backstoryGeneration = """
    Generate backstory for new NPC:

    NPC ROLE: {{role_in_story}}
    DEPTH LEVEL: {{depth_level}}
    CONNECTION POINT: {{how_they_meet_player}}

    WORLD CONTEXT:
    - Era: {{era}}
    - Location: {{location}}
    - Player age: {{player_age}}

    NARRATIVE NEEDS:
    {{what_this_character_should_bring_to_story}}

    CONSTRAINTS:
    {{any_specific_requirements}}

    Generate a believable, interesting character.
    """
}

// MARK: - Output Schemas (as JSON strings for documentation)

struct OutputSchemas {
    
    static let randomEvent = """
    {
      "event": {
        "id": "string",
        "title": "string",
        "description": "string",
        "category": "health|career|relationship|family|random|financial|social|personal_growth",
        "tone": "positive|negative|neutral|bittersweet",
        "severity": "minor|moderate|major|life_changing",
        "immediate_effects": {
          "stat_changes": {"stat_name": "number"},
          "flag_changes": {"flag_name": "boolean"},
          "relationship_changes": [{"npc": "string", "delta": "number"}]
        },
        "decision_prompt": {
          "required": "boolean",
          "question": "string",
          "options": ["string"]
        },
        "follow_up_hooks": ["string"]
      }
    }
    """
    
    static let decisionOutcome = """
    {
      "outcome": {
        "decision_id": "string",
        "result_type": "success|partial_success|failure|unexpected|mixed",
        "narrative": "string",
        "tone": "triumphant|satisfying|bittersweet|disappointing|devastating|surprising",
        "immediate_effects": {
          "stat_changes": {"stat_name": "number"},
          "flag_changes": {"flag_name": "boolean"},
          "relationship_changes": [{"npc": "string", "delta": "number", "reason": "string"}],
          "new_items_or_status": ["string"]
        },
        "delayed_effects": [
          {
            "trigger_condition": "string",
            "description": "string",
            "probability": "likely|possible|unlikely"
          }
        ],
        "narrative_threads": ["string"],
        "npc_reactions": [
          {"npc": "string", "reaction": "string", "relationship_impact": "number"}
        ]
      }
    }
    """
    
    static let npcDialogue = """
    {
      "dialogue": {
        "spoken_text": "string",
        "tone": "warm|friendly|neutral|distant|cold|angry|sad|excited|worried|playful",
        "subtext": "string",
        "body_language": "string",
        "prompts_response": "boolean",
        "conversation_options": [
          {
            "type": "supportive|challenging|neutral|deflecting|humorous",
            "text": "string"
          }
        ],
        "relationship_shift_potential": {
          "positive_path": "string",
          "negative_path": "string"
        }
      }
    }
    """
    
    static let milestoneNarration = """
    {
      "milestone_narration": {
        "title": "string",
        "opening": "string",
        "core_moment": "string",
        "reflection": "string",
        "closing": "string",
        "memory_snapshot": {
          "image_prompt": "string",
          "key_emotion": "string",
          "notable_detail": "string"
        },
        "stat_changes": {"stat_name": "number"},
        "unlocked_content": ["string"]
      }
    }
    """
    
    static let consequenceChain = """
    {
      "consequence_chain": {
        "trigger_summary": "string",
        "immediate_consequences": [
          {
            "description": "string",
            "domain": "career|relationship|health|financial|social|personal",
            "effect_type": "positive|negative|neutral",
            "stat_changes": {"stat_name": "number"},
            "narrative_hook": "string"
          }
        ],
        "short_term_consequences": [
          {
            "timeframe": "string",
            "description": "string",
            "domain": "string",
            "probability": "certain|likely|possible|unlikely",
            "conditions": "string",
            "narrative_hook": "string"
          }
        ],
        "long_term_consequences": [
          {
            "timeframe": "string",
            "description": "string",
            "domain": "string",
            "probability": "string",
            "conditions": "string",
            "life_path_impact": "string"
          }
        ],
        "npc_consequence_reactions": [
          {
            "npc": "string",
            "immediate_reaction": "string",
            "evolving_reaction": "string",
            "relationship_trajectory": "strengthening|stable|declining|uncertain"
          }
        ],
        "hidden_consequences": [
          {
            "description": "string",
            "reveal_trigger": "string",
            "effect_type": "positive|negative|neutral|twist"
          }
        ]
      }
    }
    """
    
    static let backstoryGeneration = """
    {
      "npc": {
        "basic_info": {
          "suggested_name": "string",
          "age": "number",
          "occupation": "string",
          "first_impression": "string"
        },
        "personality": {
          "core_traits": ["string"],
          "communication_style": "string",
          "values": ["string"],
          "quirks": ["string"]
        },
        "backstory": {
          "origin": "string",
          "formative_experience": "string",
          "current_situation": "string",
          "hidden_depth": "string"
        },
        "motivations": {
          "wants": "string",
          "needs": "string",
          "fears": "string"
        },
        "relationship_potential": {
          "connection_hooks": ["string"],
          "conflict_hooks": ["string"],
          "growth_arc": "string"
        },
        "dialogue_voice": {
          "speech_patterns": "string",
          "favorite_phrases": ["string"],
          "topics_they_love": ["string"],
          "topics_they_avoid": ["string"]
        }
      }
    }
    """
}

// MARK: - Prompt Builder

class PromptBuilder {
    
    private var systemPrompt: String
    private var userTemplate: String
    private var context: [String: String] = [:]
    private var promptType: PromptType
    
    init(type: PromptType) {
        self.promptType = type
        
        switch type {
        case .randomEvent:
            self.systemPrompt = SystemPrompts.randomEvent
            self.userTemplate = UserTemplates.randomEvent
        case .decisionOutcome:
            self.systemPrompt = SystemPrompts.decisionOutcome
            self.userTemplate = UserTemplates.decisionOutcome
        case .npcDialogue:
            self.systemPrompt = SystemPrompts.npcDialogue
            self.userTemplate = UserTemplates.npcDialogue
        case .milestoneNarration:
            self.systemPrompt = SystemPrompts.milestoneNarration
            self.userTemplate = UserTemplates.milestoneNarration
        case .consequenceChain:
            self.systemPrompt = SystemPrompts.consequenceChain
            self.userTemplate = UserTemplates.consequenceChain
        case .backstoryGeneration:
            self.systemPrompt = SystemPrompts.backstoryGeneration
            self.userTemplate = UserTemplates.backstoryGeneration
        }
        
        // Always append content safety rules
        self.systemPrompt += SystemPrompts.contentSafety
    }
    
    func with(_ key: String, value: String) -> PromptBuilder {
        context[key] = value
        return self
    }
    
    func withToneSettings(_ settings: ToneSettings) -> PromptBuilder {
        let toneAddendum = """
        
        NARRATIVE TONE:
        Generate content matching these tone settings:
        - Humor: \(settings.humorLevel) (\(settings.humorDescription))
        - Drama: \(settings.dramaIntensity) (\(settings.dramaDescription))
        - Realism: \(settings.realismLevel) (\(settings.realismDescription))
        """
        systemPrompt += toneAddendum
        return self
    }
    
    func withEraContext(_ era: EraContext) -> PromptBuilder {
        let eraAddendum = """
        
        ERA CONSISTENCY - \(era.name):
        This story takes place in \(era.description).
        
        TECHNOLOGY AVAILABLE: \(era.availableTech.joined(separator: ", "))
        DO NOT REFERENCE: \(era.forbiddenTech.joined(separator: ", "))
        
        LANGUAGE:
        - Period-appropriate: \(era.slang.joined(separator: ", "))
        """
        systemPrompt += eraAddendum
        return self
    }
    
    func withVoiceProfile(_ voice: NPCVoiceProfile) -> PromptBuilder {
        let voiceAddendum = """
        
        VOICE CONSISTENCY:
        This character has the following established voice:
        - Vocabulary: \(voice.vocabularyLevel)
        - Speaks in: \(voice.sentenceStructure) sentences
        - Formality level: \(voice.formality)
        - Characteristic phrases: \(voice.verbalTics.joined(separator: ", "))
        - Humor style: \(voice.humorStyle)
        """
        systemPrompt += voiceAddendum
        return self
    }
    
    func build() -> (system: String, user: String, parameters: GenerationParameters) {
        var userPrompt = userTemplate
        
        for (key, value) in context {
            userPrompt = userPrompt.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        
        // Replace any remaining placeholders with empty or default values
        let placeholderPattern = "\\{\\{[^}]+\\}\\}"
        if let regex = try? NSRegularExpression(pattern: placeholderPattern) {
            let range = NSRange(userPrompt.startIndex..., in: userPrompt)
            userPrompt = regex.stringByReplacingMatches(in: userPrompt, range: range, withTemplate: "[not provided]")
        }
        
        let parameters = GenerationParameters(
            temperature: promptType.temperature,
            maxTokens: promptType.maxTokens,
            topP: 0.95
        )
        
        return (systemPrompt, userPrompt, parameters)
    }
}

// MARK: - Supporting Types

struct ToneSettings {
    let humorLevel: Double        // 0.0-1.0
    let dramaIntensity: Double    // 0.0-1.0
    let realismLevel: Double      // 0.0-1.0
    
    var humorDescription: String {
        switch humorLevel {
        case 0..<0.3: return "serious tone, minimal humor"
        case 0.3..<0.6: return "occasional light moments"
        case 0.6..<0.8: return "regular comedic elements"
        default: return "frequently humorous"
        }
    }
    
    var dramaDescription: String {
        switch dramaIntensity {
        case 0..<0.3: return "understated, matter-of-fact"
        case 0.3..<0.6: return "moderate emotional weight"
        case 0.6..<0.8: return "emotionally engaging"
        default: return "heightened drama"
        }
    }
    
    var realismDescription: String {
        switch realismLevel {
        case 0..<0.3: return "idealized, feel-good"
        case 0.3..<0.6: return "balanced realism"
        case 0.6..<0.8: return "grounded in reality"
        default: return "unvarnished realism"
        }
    }
}

struct EraContext {
    let name: String
    let description: String
    let availableTech: [String]
    let forbiddenTech: [String]
    let slang: [String]
    
    static let modern2020s = EraContext(
        name: "2020s",
        description: "contemporary America with smartphones, social media, and remote work",
        availableTech: ["smartphones", "social media", "streaming services", "AI assistants", "electric cars"],
        forbiddenTech: ["flying cars", "teleportation", "consumer space travel"],
        slang: ["based", "no cap", "lowkey", "slay", "it hits different"]
    )
    
    static let era1980s = EraContext(
        name: "1980s",
        description: "Reagan-era America with arcade games, MTV, and no internet",
        availableTech: ["VCRs", "Walkman", "early PCs", "arcade games", "cable TV"],
        forbiddenTech: ["smartphones", "internet", "email", "GPS", "social media"],
        slang: ["rad", "gnarly", "totally", "gag me", "bodacious"]
    )
}

struct NPCVoiceProfile {
    let vocabularyLevel: String
    let sentenceStructure: String
    let formality: String
    let verbalTics: [String]
    let humorStyle: String
}

struct GenerationParameters {
    let temperature: Double
    let maxTokens: Int
    let topP: Double
}

// MARK: - Context Compressor

struct ContextCompressor {
    
    /// Compress player context to fit within token budget
    static func compress(player: PlayerState, budget: TokenBudget = .standard) -> String {
        var lines: [String] = []
        
        // Always include: identity
        lines.append("Player: \(player.name), \(player.age), \(player.occupation ?? "unemployed")")
        
        // Include mood/status
        lines.append("Status: \(player.moodDescription)")
        
        // Include key relationships (top 3)
        if !player.relationships.isEmpty {
            let topRelationships = player.relationships.prefix(3)
            let relString = topRelationships.map { r in
                "\(r.name) (\(r.type), \(r.quality)%)"
            }.joined(separator: ", ")
            lines.append("Key relationships: \(relString)")
        }
        
        // Include recent events
        if !player.recentEvents.isEmpty {
            let eventString = player.recentEvents.prefix(3).map { $0.shortDescription }.joined(separator: "; ")
            lines.append("Recent: \(eventString)")
        }
        
        // Include active flags
        let activeFlags = player.flags.filter { $0.value }.map { $0.key }
        if !activeFlags.isEmpty {
            lines.append("Flags: \(activeFlags.joined(separator: ", "))")
        }
        
        return lines.joined(separator: "\n")
    }
    
    enum TokenBudget {
        case minimal   // ~100 tokens
        case standard  // ~200 tokens
        case expanded  // ~400 tokens
    }
}

// MARK: - Placeholder Types (implement in actual game)

struct PlayerState {
    let name: String
    let age: Int
    let occupation: String?
    let moodDescription: String
    let relationships: [RelationshipState]
    let recentEvents: [EventSummary]
    let flags: [String: Bool]
}

struct RelationshipState {
    let name: String
    let type: String
    let quality: Int
}

struct EventSummary {
    let shortDescription: String
}

// MARK: - Usage Example

/*
 Usage Example:
 
 let builder = PromptBuilder(type: .randomEvent)
     .with("player_context", value: ContextCompressor.compress(player: currentPlayer))
     .with("life_phase", value: "young_adult")
     .with("recent_event_types", value: "career, relationship")
     .with("category_hint", value: "any")
     .withToneSettings(ToneSettings(humorLevel: 0.6, dramaIntensity: 0.5, realismLevel: 0.7))
     .withEraContext(.modern2020s)
 
 let (system, user, parameters) = builder.build()
 
 // Use with Claude API
 let response = try await claude.generate(
     systemPrompt: system,
     userPrompt: user,
     temperature: parameters.temperature,
     maxTokens: parameters.maxTokens
 )
 */
