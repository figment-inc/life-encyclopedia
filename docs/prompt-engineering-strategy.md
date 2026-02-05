# Life Encyclopedia: LLM Prompt Engineering Strategy

## Overview

This document defines the complete prompt engineering architecture for Life Encyclopedia, an LLM-powered life simulation game where players experience a life from birth to death, with Claude generating all narrative content, events, and NPC interactions.

---

## Table of Contents

1. [Context Injection Strategy](#1-context-injection-strategy)
2. [Core Prompt Templates](#2-core-prompt-templates)
3. [Consistency Mechanisms](#3-consistency-mechanisms)
4. [Quality Control](#4-quality-control)
5. [Parameter Recommendations](#5-parameter-recommendations)
6. [Implementation Patterns](#6-implementation-patterns)

---

## 1. Context Injection Strategy

### 1.1 Compact Context Format

Use a structured, token-efficient format for injecting game state:

```
PLAYER_CONTEXT:
├── identity: {name, age, gender, era, location}
├── stats: {health:0-100, happiness:0-100, wealth:0-100, intelligence:0-100, charisma:0-100}
├── status: {occupation, relationship_status, living_situation}
├── traits: [list of personality traits]
├── recent_events: [last 3-5 significant events]
├── active_relationships: [{name, type, quality:0-100, recent_interaction}]
└── flags: {has_children, is_employed, is_healthy, etc.}
```

### 1.2 Priority Ordering by Prompt Type

| Prompt Type | Priority 1 | Priority 2 | Priority 3 | Priority 4 |
|-------------|-----------|-----------|-----------|-----------|
| Random Event | age, location, occupation | recent_events | relationships | stats |
| Decision Outcome | decision_context, stats | traits | relationships | recent_events |
| NPC Dialogue | npc_profile, relationship | recent_interaction | player_mood | shared_history |
| Milestone | milestone_type, age | career_history | relationships | achievements |
| Consequence Chain | trigger_event, stats | relationships | flags | recent_events |
| Backstory | world_era, connection_point | player_context | narrative_needs | available_roles |

### 1.3 Context Compression Examples

**Full context (expensive):**
```json
{
  "player": {
    "name": "Alex Chen",
    "age": 25,
    "occupation": "Software Developer",
    "company": "TechCorp",
    "salary": 85000,
    "years_employed": 2,
    "happiness": 65,
    "health": 80,
    "relationships": [
      {"name": "Sam", "type": "romantic_partner", "duration_months": 18, "quality": 75},
      {"name": "Jordan", "type": "best_friend", "duration_years": 10, "quality": 90}
    ],
    "recent_events": [
      {"type": "work", "description": "Received negative performance review", "days_ago": 3},
      {"type": "relationship", "description": "Had argument with Sam about work-life balance", "days_ago": 1}
    ]
  }
}
```

**Compressed context (token-efficient):**
```
P:Alex,25,M|dev@TechCorp,2y,$85k|H:80,Joy:65|R:Sam(partner,18mo,75%),Jordan(bff,10y,90%)|Recent:bad_review(-3d),argument_sam(-1d)
```

**Recommended: Structured compact (balance):**
```yaml
player: Alex Chen, 25, software developer
mood: stressed (recent: bad review, relationship tension)
key_relationships:
  - Sam (partner, 18mo, strained)
  - Jordan (best friend, solid)
flags: employed, in_relationship, no_children
```

---

## 2. Core Prompt Templates

### 2.1 Random Event Generation

```
PROMPT NAME: random_event_generator
PURPOSE: Generate contextually appropriate random life events
TOKEN ESTIMATE: ~400 input / ~300 output
TEMPERATURE: 0.8-0.9 (high variety)
MAX_TOKENS: 400
```

**System Prompt:**
```
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
```

**User Template:**
```
Generate a random life event for this player:

{{player_context}}

Current life phase: {{life_phase}}
Recent events (avoid repetition): {{recent_event_types}}
Event category preference: {{category_hint}} (or "any")

Generate an event that feels natural for their current situation.
```

**Output Schema:**
```json
{
  "event": {
    "id": "string (unique identifier)",
    "title": "string (short, punchy title)",
    "description": "string (2-3 sentences, second person)",
    "category": "enum: health|career|relationship|family|random|financial|social|personal_growth",
    "tone": "enum: positive|negative|neutral|bittersweet",
    "severity": "enum: minor|moderate|major|life_changing",
    "immediate_effects": {
      "stat_changes": {"stat_name": delta},
      "flag_changes": {"flag_name": boolean},
      "relationship_changes": [{"npc": "name", "delta": number}]
    },
    "decision_prompt": {
      "required": boolean,
      "question": "string (if required)",
      "options": ["option1", "option2", "option3"]
    },
    "follow_up_hooks": ["potential future event triggers"]
  }
}
```

**Few-Shot Examples:**

```json
// Example 1: Young adult, career event
{
  "event": {
    "id": "evt_unexpected_opportunity",
    "title": "An Unexpected Email",
    "description": "You check your inbox to find a message from a recruiter at a company you've always admired. They found your portfolio online and want to discuss a senior position. The salary would be almost double what you make now, but it would mean relocating across the country.",
    "category": "career",
    "tone": "positive",
    "severity": "major",
    "immediate_effects": {
      "stat_changes": {"happiness": 10},
      "flag_changes": {},
      "relationship_changes": []
    },
    "decision_prompt": {
      "required": true,
      "question": "How do you respond to the recruiter?",
      "options": [
        "Express strong interest and schedule a call",
        "Politely decline - you're happy where you are",
        "Ask for more details before committing to anything"
      ]
    },
    "follow_up_hooks": ["job_interview_arc", "relocation_decision", "career_advancement"]
  }
}

// Example 2: Child, school event
{
  "event": {
    "id": "evt_school_project",
    "title": "The Science Fair",
    "description": "Your teacher announces that the annual science fair is coming up. You'll need to pick a project and work on it over the next few weeks. Your classmates are already buzzing with ideas.",
    "category": "personal_growth",
    "tone": "neutral",
    "severity": "minor",
    "immediate_effects": {
      "stat_changes": {},
      "flag_changes": {"has_active_project": true},
      "relationship_changes": []
    },
    "decision_prompt": {
      "required": true,
      "question": "What kind of science project do you want to do?",
      "options": [
        "Build a volcano - classic and impressive",
        "Study plant growth - requires patience but teaches a lot",
        "Create a simple robot - challenging but exciting"
      ]
    },
    "follow_up_hooks": ["science_fair_result", "new_hobby_discovery", "academic_recognition"]
  }
}

// Example 3: Senior, health event
{
  "event": {
    "id": "evt_health_checkup",
    "title": "The Doctor's Visit",
    "description": "During your routine checkup, your doctor notices your blood pressure is higher than last time. She recommends some lifestyle changes and wants to see you again in three months.",
    "category": "health",
    "tone": "negative",
    "severity": "moderate",
    "immediate_effects": {
      "stat_changes": {"health": -5, "happiness": -5},
      "flag_changes": {"health_concern_active": true},
      "relationship_changes": []
    },
    "decision_prompt": {
      "required": true,
      "question": "How do you respond to the doctor's advice?",
      "options": [
        "Take it seriously - start exercising and eating better",
        "Make some small changes but don't overhaul your lifestyle",
        "Decide you'll deal with it later"
      ]
    },
    "follow_up_hooks": ["health_improvement", "health_decline", "lifestyle_change_arc"]
  }
}
```

---

### 2.2 Decision Outcome Calculation

```
PROMPT NAME: decision_outcome_calculator
PURPOSE: Calculate realistic consequences of player decisions
TOKEN ESTIMATE: ~350 input / ~400 output
TEMPERATURE: 0.4-0.6 (moderate consistency)
MAX_TOKENS: 500
```

**System Prompt:**
```
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
```

**User Template:**
```
Calculate the outcome of this decision:

CONTEXT:
{{player_context}}

TRIGGERING EVENT:
{{event_description}}

DECISION MADE:
"{{decision_text}}"

DECISION OPTION INDEX: {{option_index}} (for tracking)

Relevant factors to consider:
- Stats that apply: {{relevant_stats}}
- Key relationships involved: {{involved_npcs}}
- Historical context: {{relevant_history}}

Calculate a realistic, consequential outcome.
```

**Output Schema:**
```json
{
  "outcome": {
    "decision_id": "string (links to original event)",
    "result_type": "enum: success|partial_success|failure|unexpected|mixed",
    "narrative": "string (2-4 sentences describing what happens, second person)",
    "tone": "enum: triumphant|satisfying|bittersweet|disappointing|devastating|surprising",
    "immediate_effects": {
      "stat_changes": {"stat_name": delta},
      "flag_changes": {"flag_name": boolean},
      "relationship_changes": [{"npc": "name", "delta": number, "reason": "string"}],
      "new_items_or_status": ["string"]
    },
    "delayed_effects": [
      {
        "trigger_condition": "string (when this activates)",
        "description": "string (what might happen)",
        "probability": "enum: likely|possible|unlikely"
      }
    ],
    "narrative_threads": ["strings (story hooks for future events)"],
    "npc_reactions": [
      {"npc": "name", "reaction": "string (brief description)", "relationship_impact": number}
    ]
  }
}
```

**Few-Shot Examples:**

```json
// Example 1: Accepting job opportunity (with relocation)
{
  "outcome": {
    "decision_id": "evt_unexpected_opportunity",
    "result_type": "success",
    "narrative": "You schedule the call, and it goes even better than expected. Your experience perfectly matches what they're looking for, and they fast-track you through the interview process. Three weeks later, you're signing an offer letter for nearly double your current salary. The only catch: you need to move within two months.",
    "tone": "satisfying",
    "immediate_effects": {
      "stat_changes": {"happiness": 15, "wealth": 25},
      "flag_changes": {"pending_relocation": true, "employed": true},
      "relationship_changes": [
        {"npc": "Sam", "delta": -10, "reason": "Worried about the relationship surviving long distance"}
      ],
      "new_items_or_status": ["job_offer_pending"]
    },
    "delayed_effects": [
      {
        "trigger_condition": "When relocation happens",
        "description": "Relationship with Sam will face a critical test",
        "probability": "likely"
      },
      {
        "trigger_condition": "3 months into new job",
        "description": "New job honeymoon period ends, reality sets in",
        "probability": "likely"
      }
    ],
    "narrative_threads": ["relocation_arc", "long_distance_relationship", "new_city_adjustment", "career_growth"],
    "npc_reactions": [
      {"npc": "Sam", "reaction": "Happy for you but clearly anxious about what this means for your relationship", "relationship_impact": -10},
      {"npc": "Jordan", "reaction": "Excited and supportive, already planning to visit you in the new city", "relationship_impact": 5}
    ]
  }
}

// Example 2: Science fair project - robot choice (child, challenging option)
{
  "outcome": {
    "decision_id": "evt_school_project",
    "result_type": "partial_success",
    "narrative": "You dive into building a robot, watching tutorials and gathering supplies. It's harder than you expected, and the night before the fair, the arm mechanism still won't work right. You stay up late with your parent's help and get it mostly working. At the fair, the judges are impressed by your ambition, even though the robot only works about half the time.",
    "tone": "bittersweet",
    "immediate_effects": {
      "stat_changes": {"intelligence": 5, "happiness": 5},
      "flag_changes": {"has_active_project": false, "discovered_interest_robotics": true},
      "relationship_changes": [
        {"npc": "Parent", "delta": 5, "reason": "Bonded over late night project help"}
      ],
      "new_items_or_status": ["honorable_mention_ribbon"]
    },
    "delayed_effects": [
      {
        "trigger_condition": "Next school year",
        "description": "Teacher remembers your ambitious project, may offer advanced opportunities",
        "probability": "possible"
      }
    ],
    "narrative_threads": ["robotics_interest", "perseverance_lesson", "academic_path"],
    "npc_reactions": [
      {"npc": "Teacher", "reaction": "Praises your creativity and willingness to take on a challenge", "relationship_impact": 10}
    ]
  }
}
```

---

### 2.3 NPC Dialogue Generation

```
PROMPT NAME: npc_dialogue_generator
PURPOSE: Generate contextual, character-consistent NPC dialogue
TOKEN ESTIMATE: ~300 input / ~250 output
TEMPERATURE: 0.7 (natural variety with consistency)
MAX_TOKENS: 350
```

**System Prompt:**
```
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
```

**User Template:**
```
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
```

**Output Schema:**
```json
{
  "dialogue": {
    "spoken_text": "string (what the NPC says)",
    "tone": "enum: warm|friendly|neutral|distant|cold|angry|sad|excited|worried|playful",
    "subtext": "string (what they're really feeling/thinking but not saying)",
    "body_language": "string (brief physical description)",
    "prompts_response": boolean,
    "conversation_options": [
      {
        "type": "enum: supportive|challenging|neutral|deflecting|humorous",
        "text": "string (suggested player response)"
      }
    ],
    "relationship_shift_potential": {
      "positive_path": "string (what could improve things)",
      "negative_path": "string (what could make things worse)"
    }
  }
}
```

**Few-Shot Examples:**

```json
// Example 1: Partner (Sam) discussing relocation news, strained relationship
{
  "dialogue": {
    "spoken_text": "So you already said yes. You scheduled the call, you went through the interviews, and now you're telling me about it like... like I'm just supposed to be happy for you? I *am* happy for you, Alex. I just... I thought we made decisions like this together.",
    "tone": "sad",
    "subtext": "Feeling blindsided and unimportant, worried this reveals a deeper pattern in the relationship",
    "body_language": "Arms crossed, looking out the window, voice carefully controlled",
    "prompts_response": true,
    "conversation_options": [
      {
        "type": "supportive",
        "text": "You're right. I should have talked to you first. I got caught up in the excitement, but that's not an excuse."
      },
      {
        "type": "challenging",
        "text": "I didn't think I needed permission to pursue my career. This is a huge opportunity."
      },
      {
        "type": "neutral",
        "text": "Nothing is decided yet. I wanted to see if it was even real before getting us both worked up about it."
      },
      {
        "type": "deflecting",
        "text": "Can we talk about this later? I just got some big news and I wanted to share it with you."
      }
    ],
    "relationship_shift_potential": {
      "positive_path": "Acknowledging Sam's feelings and committing to deciding together could strengthen trust",
      "negative_path": "Dismissing the concern or being defensive could confirm Sam's fear of being deprioritized"
    }
  }
}

// Example 2: Best friend (Jordan) offering support, strong relationship
{
  "dialogue": {
    "spoken_text": "Dude. DUDE. This is incredible! I knew that portfolio revamp would pay off. Okay, wait, tell me everything - what's the role, what's the company culture like, and most importantly, does the new city have good tacos? This is critical information.",
    "tone": "excited",
    "subtext": "Genuinely thrilled for their friend, also processing that distance will change the friendship",
    "body_language": "Leaning forward, gesturing enthusiastically, occasional glances that betray a hint of bittersweetness",
    "prompts_response": true,
    "conversation_options": [
      {
        "type": "humorous",
        "text": "Asking the real questions. I'll add 'taco reconnaissance' to my relocation checklist."
      },
      {
        "type": "supportive",
        "text": "It feels surreal. I'm excited but also terrified. What if I'm not actually ready for this?"
      },
      {
        "type": "neutral",
        "text": "It's a senior developer role. The team seems great from what I can tell, but I still have a lot to figure out."
      }
    ],
    "relationship_shift_potential": {
      "positive_path": "Sharing vulnerability and including Jordan in the excitement deepens the bond",
      "negative_path": "Being dismissive or not recognizing the friendship impact could create unspoken distance"
    }
  }
}

// Example 3: Parent checking in on child after science fair
{
  "dialogue": {
    "spoken_text": "Hey kiddo, how are you feeling about the science fair? I know you were hoping for first place, but I have to say - I've never seen anyone work as hard as you did on that robot. The judges noticed too. Sometimes the things we learn matter more than the ribbons we win.",
    "tone": "warm",
    "subtext": "Proud of the effort, wants to help process any disappointment in a healthy way",
    "body_language": "Sitting on the edge of the bed, making eye contact, speaking gently",
    "prompts_response": true,
    "conversation_options": [
      {
        "type": "supportive",
        "text": "Thanks, Mom/Dad. I guess I learned a lot, even if the robot didn't work perfectly."
      },
      {
        "type": "challenging",
        "text": "But I wanted to win. Everyone else's projects worked better than mine."
      },
      {
        "type": "neutral",
        "text": "Yeah. I still think I could make it better if I had more time."
      }
    ],
    "relationship_shift_potential": {
      "positive_path": "Accepting the comfort and sharing feelings strengthens parent-child bond",
      "negative_path": "Shutting down or lashing out could create distance"
    }
  }
}
```

---

### 2.4 Life Milestone Narration

```
PROMPT NAME: milestone_narrator
PURPOSE: Create memorable, emotionally resonant narration for major life events
TOKEN ESTIMATE: ~250 input / ~350 output
TEMPERATURE: 0.6 (quality consistency with some creativity)
MAX_TOKENS: 450
```

**System Prompt:**
```
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
```

**User Template:**
```
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
```

**Output Schema:**
```json
{
  "milestone_narration": {
    "title": "string (milestone title for save file/memory)",
    "opening": "string (scene-setting, sensory details, 2-3 sentences)",
    "core_moment": "string (the milestone itself, emotionally resonant, 3-4 sentences)",
    "reflection": "string (what this means, connection to past, 2-3 sentences)",
    "closing": "string (forward-looking or conclusive note, 1-2 sentences)",
    "memory_snapshot": {
      "image_prompt": "string (description for potential illustration)",
      "key_emotion": "string (one word)",
      "notable_detail": "string (specific memorable element)"
    },
    "stat_changes": {"stat_name": delta},
    "unlocked_content": ["any new features, locations, or mechanics unlocked"]
  }
}
```

**Few-Shot Examples:**

```json
// Example 1: Graduation milestone
{
  "milestone_narration": {
    "title": "Commencement Day",
    "opening": "The gymnasium smells like floor polish and too many flower bouquets. Your cap keeps sliding forward, and somewhere in the sea of folding chairs, you know Jordan is holding a handmade sign that's probably embarrassing. The morning light streams through the high windows, catching the dust motes floating above rows of families craning their necks to find their graduates.",
    "core_moment": "When they call your name, your legs move on autopilot. The walk across that stage feels both endless and instantaneous. You think about the late nights, the moments you almost quit, the professor who believed in you when you didn't believe in yourself. The diploma is lighter than you expected. The handshake is firm. The applause is a wave of sound that carries something heavier: the weight of becoming someone new.",
    "reflection": "Four years ago, you walked onto this campus unsure of everything. You've failed exams and aced others, made friends and lost touch with some, discovered passions you didn't know you had. The person receiving this diploma isn't the same one who started. That's the whole point.",
    "closing": "You toss your cap with everyone else, watching it arc toward the ceiling. Somewhere in that sea of flying squares is your past. It's time to catch your future.",
    "memory_snapshot": {
      "image_prompt": "Graduate in cap and gown, sunlit gymnasium, crowd blurred in background, moment of catching thrown cap",
      "key_emotion": "accomplishment",
      "notable_detail": "Jordan's embarrassing handmade sign"
    },
    "stat_changes": {"happiness": 20, "intelligence": 5},
    "unlocked_content": ["career_opportunities_expanded", "alumni_network_access"]
  }
}

// Example 2: Birth of first child
{
  "milestone_narration": {
    "title": "First Light",
    "opening": "The hospital room is too bright, then too dark, then too bright again. Everything has the soft focus of exhaustion and adrenaline. Sam's hand hasn't left yours in hours - or maybe minutes? Time stopped making sense somewhere around 3 AM.",
    "core_moment": "And then there's crying, but it's not Sam, it's not you - it's this tiny, furious voice announcing itself to the world. They place her on Sam's chest and she goes quiet, like she's been looking for this exact spot her whole life (which, in a way, she has). You lean in close and she opens her eyes - unfocused, impossible blue, somehow ancient and brand new simultaneously. In this moment, everything you were before becomes a prologue. This is chapter one of something different.",
    "reflection": "You think about your own parents, about the moments they must have had like this one. You understand something now that you couldn't have before. All those choices, all those sacrifices, they started here - in a room just like this, with a feeling just like this.",
    "closing": "She wraps her entire hand around your finger. It's the smallest gesture. It's everything.",
    "memory_snapshot": {
      "image_prompt": "Close-up of newborn's hand grasping adult finger, soft hospital lighting, intimate focus",
      "key_emotion": "awe",
      "notable_detail": "The impossible blue of her eyes"
    },
    "stat_changes": {"happiness": 30, "health": -10},
    "unlocked_content": ["parenting_mechanics", "family_planning_options", "new_relationship_type_child"]
  }
}

// Example 3: Retirement milestone (bittersweet)
{
  "milestone_narration": {
    "title": "The Last Commute",
    "opening": "Your desk is empty for the first time in twenty-three years. The surface is slightly discolored where your keyboard used to be, a ghost of routine. Someone has brought a cake. Someone always brings a cake.",
    "core_moment": "They gather in the conference room - some faces you hired, some you mentored, some whose names you should remember but don't. The speeches are kind and slightly too long. You tell the story about your first day, the one where you got stuck in the elevator for two hours. Everyone laughs. The plaque is heavier than expected. When you walk out the front door for the last time, your badge beeps red instead of green. Just like that, you're a visitor in a place that shaped half your life.",
    "reflection": "You think about the projects that mattered and the ones that didn't, the promotions and the setbacks, the colleagues who became friends and the ones who stayed colleagues. Would you do it again? Mostly, yes. Would you do it differently? Definitely. That's probably the honest answer for everyone.",
    "closing": "The drive home takes the same forty minutes it always has. Tomorrow, you won't make this drive. You're not sure yet what you'll do instead. For the first time in decades, that uncertainty feels like freedom.",
    "memory_snapshot": {
      "image_prompt": "Empty office desk with visible wear marks, afternoon light, single box of belongings",
      "key_emotion": "bittersweet",
      "notable_detail": "The discolored spot where the keyboard lived"
    },
    "stat_changes": {"happiness": 10, "wealth": -5},
    "unlocked_content": ["retirement_activities", "legacy_projects", "volunteer_opportunities"]
  }
}
```

---

### 2.5 Consequence Chain Generation

```
PROMPT NAME: consequence_chain_generator
PURPOSE: Generate ripple effects from significant decisions/events
TOKEN ESTIMATE: ~300 input / ~400 output
TEMPERATURE: 0.5 (logical consistency with narrative variety)
MAX_TOKENS: 500
```

**System Prompt:**
```
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

CONSEQUENCE TYPES:
- Direct: Immediate, obvious results
- Indirect: Second-order effects, butterfly effects
- Social: How others perceive/react to the change
- Internal: How the player character grows or changes
- Systemic: How the change affects life structure (routine, finances, etc.)

OUTPUT FORMAT: Respond with valid JSON only, no additional text.
```

**User Template:**
```
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
```

**Output Schema:**
```json
{
  "consequence_chain": {
    "trigger_summary": "string (brief description of cause)",
    "immediate_consequences": [
      {
        "description": "string",
        "domain": "enum: career|relationship|health|financial|social|personal",
        "effect_type": "enum: positive|negative|neutral",
        "stat_changes": {"stat_name": delta},
        "narrative_hook": "string (brief future event setup)"
      }
    ],
    "short_term_consequences": [
      {
        "timeframe": "string (e.g., '2 weeks later', '1 month later')",
        "description": "string",
        "domain": "enum: career|relationship|health|financial|social|personal",
        "probability": "enum: certain|likely|possible|unlikely",
        "conditions": "string (what needs to happen for this to trigger)",
        "narrative_hook": "string"
      }
    ],
    "long_term_consequences": [
      {
        "timeframe": "string (e.g., '6 months later', '2 years later')",
        "description": "string",
        "domain": "enum",
        "probability": "enum",
        "conditions": "string",
        "life_path_impact": "string (how this shapes overall trajectory)"
      }
    ],
    "npc_consequence_reactions": [
      {
        "npc": "string",
        "immediate_reaction": "string",
        "evolving_reaction": "string (how feelings might change over time)",
        "relationship_trajectory": "enum: strengthening|stable|declining|uncertain"
      }
    ],
    "hidden_consequences": [
      {
        "description": "string (consequence player might not see coming)",
        "reveal_trigger": "string (when/how this becomes apparent)",
        "effect_type": "enum: positive|negative|neutral|twist"
      }
    ]
  }
}
```

**Few-Shot Example:**

```json
// Example: Accepting job offer and relocating
{
  "consequence_chain": {
    "trigger_summary": "Accepted senior developer role requiring relocation across the country",
    "immediate_consequences": [
      {
        "description": "Salary nearly doubles, providing financial security and new opportunities",
        "domain": "financial",
        "effect_type": "positive",
        "stat_changes": {"wealth": 25},
        "narrative_hook": "New purchasing power creates lifestyle decisions"
      },
      {
        "description": "Must give notice at current job, changing daily routine and colleague relationships",
        "domain": "career",
        "effect_type": "neutral",
        "stat_changes": {},
        "narrative_hook": "Goodbye moments with work friends"
      },
      {
        "description": "Relationship with Sam enters uncertain territory - will it survive the distance?",
        "domain": "relationship",
        "effect_type": "negative",
        "stat_changes": {"happiness": -5},
        "narrative_hook": "The 'what are we going to do' conversation"
      }
    ],
    "short_term_consequences": [
      {
        "timeframe": "2 weeks later",
        "description": "The logistics of moving become overwhelming - packing, planning, saying goodbyes",
        "domain": "personal",
        "probability": "certain",
        "conditions": "None - happens automatically",
        "narrative_hook": "Moving day chaos event"
      },
      {
        "timeframe": "1 month later",
        "description": "First day at new job brings imposter syndrome despite earned position",
        "domain": "career",
        "probability": "likely",
        "conditions": "Relocation completes successfully",
        "narrative_hook": "Proving yourself in new environment arc"
      },
      {
        "timeframe": "6 weeks later",
        "description": "Long-distance relationship with Sam either strengthens through intentional communication or strains from absence",
        "domain": "relationship",
        "probability": "certain",
        "conditions": "Depends on player choices about maintaining connection",
        "narrative_hook": "Relationship crossroads decision"
      }
    ],
    "long_term_consequences": [
      {
        "timeframe": "6 months later",
        "description": "Career trajectory accelerates - new skills, bigger network, leadership opportunities",
        "domain": "career",
        "probability": "likely",
        "conditions": "Performing well at new job",
        "life_path_impact": "Opens doors to executive track or entrepreneurship"
      },
      {
        "timeframe": "1 year later",
        "description": "New city becomes home - local friendships form, neighborhood becomes familiar",
        "domain": "social",
        "probability": "likely",
        "conditions": "Making effort to build local connections",
        "life_path_impact": "Identity shifts to new location, old home becomes 'where I'm from'"
      },
      {
        "timeframe": "2 years later",
        "description": "The move either proved to be the making of this life chapter or a mistake that needs correction",
        "domain": "personal",
        "probability": "certain",
        "conditions": "Cumulative effect of all intervening choices",
        "life_path_impact": "Major life satisfaction inflection point"
      }
    ],
    "npc_consequence_reactions": [
      {
        "npc": "Sam",
        "immediate_reaction": "Hurt but trying to be supportive, emotional volatility",
        "evolving_reaction": "Either grows into independence and reunion appreciation, or resentment builds",
        "relationship_trajectory": "uncertain"
      },
      {
        "npc": "Jordan",
        "immediate_reaction": "Excited but will miss daily friendship",
        "evolving_reaction": "Friendship adapts to distance, quality over quantity",
        "relationship_trajectory": "stable"
      },
      {
        "npc": "Current Boss",
        "immediate_reaction": "Disappointed to lose talent but professionally supportive",
        "evolving_reaction": "Becomes valuable network connection",
        "relationship_trajectory": "stable"
      }
    ],
    "hidden_consequences": [
      {
        "description": "The developer who takes over your old position struggles, making former colleagues appreciate what you did",
        "reveal_trigger": "Casual conversation with old colleague 3 months later",
        "effect_type": "positive"
      },
      {
        "description": "Sam, left with more independence, discovers a new passion or makes a significant personal change",
        "reveal_trigger": "During a visit or video call",
        "effect_type": "twist"
      }
    ]
  }
}
```

---

### 2.6 Character Backstory Generation

```
PROMPT NAME: backstory_generator
PURPOSE: Create rich, contextual backstories for new NPCs
TOKEN ESTIMATE: ~200 input / ~350 output
TEMPERATURE: 0.8 (creative variety)
MAX_TOKENS: 450
```

**System Prompt:**
```
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

CHARACTER DEPTH LEVELS:
- Core NPCs (family, partners, close friends): Deep backstory, complex motivations
- Regular NPCs (coworkers, neighbors, recurring): Moderate backstory, clear personality
- Minor NPCs (one-time encounters): Light backstory, single defining trait

OUTPUT FORMAT: Respond with valid JSON only, no additional text.
```

**User Template:**
```
Generate backstory for new NPC:

NPC ROLE: {{role_in_story}}
DEPTH LEVEL: {{core|regular|minor}}
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
```

**Output Schema:**
```json
{
  "npc": {
    "basic_info": {
      "suggested_name": "string",
      "age": number,
      "occupation": "string",
      "first_impression": "string (how they come across initially)"
    },
    "personality": {
      "core_traits": ["3-5 defining characteristics"],
      "communication_style": "string (how they talk/express themselves)",
      "values": ["what matters most to them"],
      "quirks": ["1-2 distinctive habits or characteristics"]
    },
    "backstory": {
      "origin": "string (where they come from)",
      "formative_experience": "string (what shaped them)",
      "current_situation": "string (where they are in life now)",
      "hidden_depth": "string (something not immediately apparent)"
    },
    "motivations": {
      "wants": "string (conscious goals)",
      "needs": "string (deeper need they may not recognize)",
      "fears": "string (what they avoid or worry about)"
    },
    "relationship_potential": {
      "connection_hooks": ["ways they could bond with player"],
      "conflict_hooks": ["potential sources of friction"],
      "growth_arc": "string (how relationship could evolve)"
    },
    "dialogue_voice": {
      "speech_patterns": "string (distinctive language traits)",
      "favorite_phrases": ["1-2 characteristic expressions"],
      "topics_they_love": ["subjects they light up about"],
      "topics_they_avoid": ["subjects that make them uncomfortable"]
    }
  }
}
```

**Few-Shot Examples:**

```json
// Example 1: Core NPC - Potential romantic interest
{
  "npc": {
    "basic_info": {
      "suggested_name": "Riley Park",
      "age": 26,
      "occupation": "Physical Therapist",
      "first_impression": "Warm but slightly guarded, like someone who's learned to be careful with their optimism"
    },
    "personality": {
      "core_traits": ["empathetic", "practical", "quietly stubborn", "self-deprecating humor", "fiercely loyal"],
      "communication_style": "Listens more than talks, asks thoughtful questions, uses humor to deflect from serious topics about themselves",
      "values": ["authenticity", "helping others heal", "showing up consistently", "earned trust over quick intimacy"],
      "quirks": ["Always carries a book but rarely finishes them", "Makes playlists for specific moods/situations"]
    },
    "backstory": {
      "origin": "Grew up in a military family, moved every 2-3 years until college",
      "formative_experience": "Parents' divorce during senior year of high school taught them that even stable-looking things can fall apart",
      "current_situation": "Building a career they love, has a small but tight friend group, recently got out of a two-year relationship that ended amicably but left questions",
      "hidden_depth": "Secretly writes poetry but has never shown anyone; struggles with feeling 'too much' emotionally"
    },
    "motivations": {
      "wants": "To build something lasting - career, relationships, a place that feels like home",
      "needs": "To learn that vulnerability isn't weakness and not everyone leaves",
      "fears": "Investing in something/someone and having it disappear, being seen as too intense"
    },
    "relationship_potential": {
      "connection_hooks": ["Shared appreciation for quiet moments", "Both navigating career growth", "Complementary communication styles"],
      "conflict_hooks": ["Riley's guardedness vs. player's need for emotional access", "Different comfort levels with commitment timelines"],
      "growth_arc": "From guarded acquaintance to trusted partner, learning to stay even when it's hard"
    },
    "dialogue_voice": {
      "speech_patterns": "Thoughtful pauses, occasional literary references, deflects compliments with jokes",
      "favorite_phrases": ["That tracks", "I mean, fair", "Tell me more about that"],
      "topics_they_love": ["Books they're reading", "Interesting patients (anonymized)", "Music deep cuts"],
      "topics_they_avoid": ["Their parents", "Their ex", "Future planning beyond 6 months"]
    }
  }
}

// Example 2: Regular NPC - New coworker
{
  "npc": {
    "basic_info": {
      "suggested_name": "Marcus Webb",
      "age": 34,
      "occupation": "Senior Product Manager (new hire)",
      "first_impression": "Confident bordering on cocky, but backs it up with competence"
    },
    "personality": {
      "core_traits": ["ambitious", "direct", "competitive", "unexpectedly generous with knowledge"],
      "communication_style": "Fast-talking, uses a lot of business jargon, but can code-switch to casual",
      "values": ["Results", "Meritocracy", "Keeping promises"],
      "quirks": ["Always has the latest tech gadget", "Surprisingly good at remembering personal details about coworkers"]
    },
    "backstory": {
      "origin": "Grew up lower-middle class, first in family to get a college degree",
      "formative_experience": "Got passed over for promotion at last job for someone with better 'connections' - vowed never again",
      "current_situation": "Taking this job as a strategic career move, determined to prove himself quickly",
      "hidden_depth": "Sends money home to parents every month; competitive exterior hides deep family loyalty"
    },
    "motivations": {
      "wants": "To become a VP by 40",
      "needs": "To feel like he earned his place, not just that he took it",
      "fears": "Being seen as someone who got lucky rather than worked hard"
    },
    "relationship_potential": {
      "connection_hooks": ["Could become valuable ally/mentor", "Shared work ethic creates mutual respect"],
      "conflict_hooks": ["Might compete for same opportunities", "His directness could clash with player's style"],
      "growth_arc": "From competitor to collaborator as mutual respect develops"
    },
    "dialogue_voice": {
      "speech_patterns": "Declarative sentences, rare hedging, occasional sports metaphors",
      "favorite_phrases": ["Let's bottom-line this", "I don't disagree", "What's our win condition here?"],
      "topics_they_love": ["Career strategy", "Industry trends", "College basketball"],
      "topics_they_avoid": ["His background before college", "Past workplace conflicts"]
    }
  }
}
```

---

## 3. Consistency Mechanisms

### 3.1 Character Voice Maintenance

**Voice Profile Structure:**
```json
{
  "character_voice_profile": {
    "character_id": "string",
    "speech_patterns": {
      "vocabulary_level": "enum: simple|moderate|sophisticated|technical",
      "sentence_structure": "enum: short_direct|varied|complex_flowing",
      "formality": "enum: casual|balanced|formal",
      "emotional_expression": "enum: reserved|moderate|expressive"
    },
    "verbal_tics": ["characteristic phrases or words they use"],
    "topics_they_engage_with": ["subjects that animate them"],
    "topics_they_avoid": ["subjects they deflect from"],
    "humor_style": "enum: dry|playful|sarcastic|none|self_deprecating",
    "conflict_style": "enum: confrontational|avoidant|diplomatic|passive_aggressive",
    "example_dialogue": [
      {"context": "string", "line": "string"}
    ]
  }
}
```

**Voice Consistency System Prompt Addition:**
```
VOICE CONSISTENCY RULES:
This character has the following established voice:
- Vocabulary: {{vocabulary_level}}
- Speaks in: {{sentence_structure}} sentences
- Formality level: {{formality}}
- Characteristic phrases: {{verbal_tics}}
- Humor style: {{humor_style}}

Reference examples:
{{example_dialogue}}

Maintain these patterns while responding naturally to the current situation.
```

### 3.2 World State Awareness

**World State Context Block:**
```
WORLD STATE:
Current date: {{game_date}}
Era: {{era}} (affects available technology, social norms, slang)
Location: {{current_location}}
Economic conditions: {{economy_state}}
Season: {{season}}
Recent world events: {{relevant_world_events}}

PLAYER'S WORLD:
Home: {{living_situation}}
Workplace: {{work_environment}}
Social circle: {{social_network_summary}}
Recent significant events: {{recent_major_events}}
Active storylines: {{ongoing_narrative_threads}}
```

### 3.3 Tone Calibration System

**Tone Settings (configurable per player):**
```json
{
  "tone_settings": {
    "humor_level": 0.0-1.0,      // 0 = serious, 1 = frequently comedic
    "drama_intensity": 0.0-1.0,  // 0 = understated, 1 = dramatic
    "realism_level": 0.0-1.0,    // 0 = idealized, 1 = harsh realism
    "pacing": 0.0-1.0,           // 0 = slow/contemplative, 1 = fast/eventful
    "content_darkness": 0.0-1.0  // 0 = lighthearted, 1 = explores difficult themes
  }
}
```

**Tone Injection Prompt:**
```
NARRATIVE TONE:
Generate content matching these tone settings:
- Humor: {{humor_level}} ({{humor_description}})
- Drama: {{drama_intensity}} ({{drama_description}})
- Realism: {{realism_level}} ({{realism_description}})

Example calibration:
- At humor 0.7+: Include witty observations, comedic timing in descriptions
- At drama 0.8+: Heighten emotional stakes, use evocative language
- At realism 0.8+: Include mundane details, imperfect outcomes, complexity
```

### 3.4 Era/Cultural Consistency

**Era Context Definitions:**

```json
{
  "era_profiles": {
    "1950s_america": {
      "technology": ["rotary phones", "radio", "early TV", "no computers"],
      "social_norms": ["formal gender roles", "less diversity visibility", "career paths more limited"],
      "slang": ["swell", "golly", "dreamboat", "going steady"],
      "forbidden_anachronisms": ["cell phones", "internet references", "modern social concepts"],
      "event_types_available": ["post-war optimism events", "cold war anxiety", "suburban expansion"],
      "career_options": "{{era_specific_careers}}",
      "relationship_norms": "{{era_specific_norms}}"
    },
    "1980s_america": {
      "technology": ["early personal computers", "VCRs", "arcade games", "no internet"],
      "social_norms": ["career focus", "yuppie culture", "evolving gender roles"],
      "slang": ["rad", "gnarly", "totally", "gag me"],
      "forbidden_anachronisms": ["smartphones", "social media", "streaming"],
      "event_types_available": ["economic boom events", "MTV culture", "cold war ending"],
      "career_options": "{{era_specific_careers}}",
      "relationship_norms": "{{era_specific_norms}}"
    },
    "2020s_america": {
      "technology": ["smartphones ubiquitous", "social media", "AI emerging", "remote work"],
      "social_norms": ["diverse family structures", "fluid career paths", "mental health awareness"],
      "slang": ["current internet slang - use sparingly"],
      "forbidden_anachronisms": ["future tech not yet invented"],
      "event_types_available": ["pandemic effects", "social movements", "tech disruption"],
      "career_options": "{{era_specific_careers}}",
      "relationship_norms": "{{era_specific_norms}}"
    }
  }
}
```

**Era Consistency System Prompt:**
```
ERA CONSISTENCY - {{era_name}}:
This story takes place in {{era_description}}.

TECHNOLOGY AVAILABLE: {{available_tech}}
TECHNOLOGY FORBIDDEN: {{forbidden_tech}}

SOCIAL CONTEXT:
- Workplace norms: {{workplace_norms}}
- Relationship norms: {{relationship_norms}}
- Common concerns: {{era_concerns}}

LANGUAGE:
- Period-appropriate slang: {{slang_examples}}
- Avoid modern terms: {{anachronistic_terms}}

When generating content, maintain era authenticity while remaining engaging for modern players.
```

---

## 4. Quality Control

### 4.1 Output Validation Logic

**JSON Schema Validation (Swift Implementation Reference):**
```swift
struct EventValidation {
    static func validate(_ event: GeneratedEvent) -> ValidationResult {
        var errors: [String] = []
        
        // Required fields check
        if event.title.isEmpty { errors.append("Missing title") }
        if event.description.isEmpty { errors.append("Missing description") }
        if !EventCategory.allCases.contains(event.category) { 
            errors.append("Invalid category") 
        }
        
        // Content checks
        if event.description.count < 50 { 
            errors.append("Description too short") 
        }
        if event.description.count > 500 { 
            errors.append("Description too long") 
        }
        
        // Age appropriateness check
        if containsInappropriateContent(event.description, forAge: playerAge) {
            errors.append("Content not age-appropriate")
        }
        
        // Logical consistency checks
        if event.immediateEffects.statChanges.values.contains(where: { abs($0) > 30 }) {
            errors.append("Stat change too extreme")
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}
```

**Content Quality Rubric:**
```
QUALITY CRITERIA:

1. RELEVANCE (1-5)
   - Does the content fit the player's current context?
   - Does it make sense given their age/situation?

2. ENGAGEMENT (1-5)
   - Is the writing compelling and interesting?
   - Does it create emotional investment?

3. CONSISTENCY (1-5)
   - Does it match established character voices?
   - Is it era-appropriate?
   - Does it align with game tone settings?

4. ACTIONABILITY (1-5)
   - Does it give the player meaningful choices?
   - Are consequences clear?

5. ORIGINALITY (1-5)
   - Does it feel fresh, not formulaic?
   - Does it avoid repetition with recent content?

MINIMUM THRESHOLD: Average 3.0 across all criteria
REGENERATE IF: Any criterion below 2.0
```

### 4.2 Fallback Prompts

**Fallback Strategy Hierarchy:**

```
LEVEL 1: Retry with simplified prompt
- Reduce context to essentials
- Add explicit structural constraints
- Lower temperature by 0.2

LEVEL 2: Use template-based fallback
- Pre-written event templates with variable slots
- Fill slots using simpler extraction prompts
- Maintain game progression with generic but valid content

LEVEL 3: Graceful degradation
- Use cached similar events with context adjustment
- Display generic placeholder with apology
- Queue for async regeneration
```

**Fallback Event Templates:**
```json
{
  "fallback_events": {
    "career_positive": {
      "title": "A Good Day at Work",
      "description": "Something goes well at your job today. Your {{supervisor_or_coworker}} notices your contribution and you feel a sense of accomplishment.",
      "category": "career",
      "tone": "positive",
      "severity": "minor",
      "stat_changes": {"happiness": 5}
    },
    "relationship_neutral": {
      "title": "Quality Time",
      "description": "You spend some time with {{relationship_name}}. Nothing dramatic happens, but it's nice to connect.",
      "category": "relationship", 
      "tone": "neutral",
      "severity": "minor",
      "stat_changes": {}
    },
    "random_minor": {
      "title": "An Ordinary Day",
      "description": "Life continues at its usual pace. Sometimes the most peaceful days are the ones where nothing much happens.",
      "category": "random",
      "tone": "neutral", 
      "severity": "minor",
      "stat_changes": {}
    }
  }
}
```

### 4.3 Content Filtering Integration

**Pre-Generation Filter (System Prompt Addition):**
```
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
```

**Post-Generation Filter Check:**
```swift
struct ContentFilter {
    static let flaggedPatterns = [
        // Add regex patterns for concerning content
    ]
    
    static let topicSensitivity: [String: AgeRange] = [
        "death": .allAges,        // Handle at any age, but gently for young
        "divorce": .ages8Plus,     // Can appear for older children
        "dating": .ages13Plus,     // Teen and up
        "alcohol": .ages15Plus,    // Older teen and up
        "substances": .ages18Plus  // Adult only
    ]
    
    static func check(_ content: String, playerAge: Int) -> FilterResult {
        // Pattern matching
        // Topic appropriateness
        // Tone analysis
        // Return .pass, .modify(suggestions), or .reject(reason)
    }
}
```

### 4.4 A/B Testing Approach

**Prompt Variant Structure:**
```json
{
  "prompt_experiment": {
    "experiment_id": "event_gen_v2_test",
    "hypothesis": "Adding specific word count guidance improves output consistency",
    "variants": {
      "control": {
        "system_prompt_delta": "",
        "user_template_delta": ""
      },
      "treatment_a": {
        "system_prompt_delta": "Descriptions should be exactly 2-3 sentences, approximately 40-60 words.",
        "user_template_delta": ""
      },
      "treatment_b": {
        "system_prompt_delta": "",
        "user_template_delta": "\n\nProvide a description of 40-60 words."
      }
    },
    "metrics": [
      "output_length_consistency",
      "quality_rubric_score",
      "user_engagement_proxy"
    ],
    "traffic_split": {"control": 34, "treatment_a": 33, "treatment_b": 33},
    "minimum_samples": 1000
  }
}
```

**Metrics Collection:**
```swift
struct PromptExperimentMetrics {
    let experimentId: String
    let variantId: String
    let promptType: String
    let generationTimeMs: Int
    let inputTokens: Int
    let outputTokens: Int
    let qualityScore: Double?       // Human evaluation when available
    let validationPassed: Bool
    let regenerationsRequired: Int
    let userInteractionMetrics: UserInteraction?  // Did they engage with the content?
}
```

---

## 5. Parameter Recommendations

### 5.1 Temperature Settings by Prompt Type

| Prompt Type | Temperature | Reasoning |
|-------------|-------------|-----------|
| Random Event Generation | 0.8-0.9 | High variety needed, creative freedom |
| Decision Outcome | 0.4-0.6 | Needs logical consistency, some creativity |
| NPC Dialogue | 0.7 | Natural variation while maintaining voice |
| Life Milestone | 0.6 | Quality consistency with creative description |
| Consequence Chain | 0.5 | Logical flow critical, moderate creativity |
| Backstory Generation | 0.8 | Creative character creation |
| Fallback/Recovery | 0.3 | Maximum reliability |

### 5.2 Token Budget Guidelines

| Generation Type | Max Input Tokens | Max Output Tokens | Notes |
|----------------|------------------|-------------------|-------|
| Random Event | 500 | 400 | Compress context aggressively |
| Decision Outcome | 600 | 500 | Include decision context |
| NPC Dialogue | 400 | 350 | Single exchange focus |
| Life Milestone | 400 | 450 | Rich output needed |
| Consequence Chain | 500 | 500 | Complex output structure |
| Backstory | 300 | 450 | Minimal context, rich output |

### 5.3 Additional Parameters

```json
{
  "generation_parameters": {
    "random_event": {
      "temperature": 0.85,
      "max_tokens": 400,
      "top_p": 0.95,
      "frequency_penalty": 0.3,  // Reduce repetitive phrasing
      "presence_penalty": 0.2    // Encourage topic diversity
    },
    "decision_outcome": {
      "temperature": 0.5,
      "max_tokens": 500,
      "top_p": 0.9,
      "frequency_penalty": 0.1,
      "presence_penalty": 0.1
    },
    "npc_dialogue": {
      "temperature": 0.7,
      "max_tokens": 350,
      "top_p": 0.9,
      "frequency_penalty": 0.2,
      "presence_penalty": 0.1
    },
    "milestone_narration": {
      "temperature": 0.6,
      "max_tokens": 450,
      "top_p": 0.95,
      "frequency_penalty": 0.3,
      "presence_penalty": 0.2
    }
  }
}
```

---

## 6. Implementation Patterns

### 6.1 Prompt Assembly Pipeline

```swift
protocol PromptBuilder {
    var systemPrompt: String { get }
    var userTemplate: String { get }
    var outputSchema: String { get }
    
    func build(with context: GameContext) -> PromptPayload
}

struct RandomEventPromptBuilder: PromptBuilder {
    func build(with context: GameContext) -> PromptPayload {
        let systemPrompt = buildSystemPrompt(
            basePrompt: Self.baseSystemPrompt,
            contentFilters: context.contentFilters,
            toneSettings: context.toneSettings,
            eraContext: context.era
        )
        
        let userPrompt = Self.userTemplate
            .replacing("{{player_context}}", with: context.compressedPlayerContext)
            .replacing("{{life_phase}}", with: context.currentLifePhase.description)
            .replacing("{{recent_event_types}}", with: context.recentEventTypes.joined(", "))
            .replacing("{{category_hint}}", with: context.categoryHint ?? "any")
        
        return PromptPayload(
            system: systemPrompt,
            user: userPrompt,
            parameters: Self.defaultParameters
        )
    }
}
```

### 6.2 Response Processing Pipeline

```swift
class GenerationPipeline<T: Decodable> {
    func generate(using builder: PromptBuilder, context: GameContext) async throws -> T {
        // 1. Build prompt
        let payload = builder.build(with: context)
        
        // 2. Check cache
        if let cached = await cache.get(payload.hash) {
            return cached
        }
        
        // 3. Call API with retry logic
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                let response = try await api.generate(payload)
                
                // 4. Parse response
                let parsed: T = try JSONDecoder().decode(T.self, from: response.data)
                
                // 5. Validate
                if let validatable = parsed as? Validatable {
                    let result = validatable.validate(context: context)
                    if !result.isValid {
                        throw ValidationError(result.errors)
                    }
                }
                
                // 6. Content filter
                if let filterable = parsed as? ContentFilterable {
                    let filterResult = contentFilter.check(filterable, playerAge: context.playerAge)
                    if filterResult == .reject {
                        throw ContentFilterError()
                    }
                }
                
                // 7. Cache and return
                await cache.set(payload.hash, value: parsed)
                return parsed
                
            } catch {
                lastError = error
                attempts += 1
                payload.adjustForRetry(attempt: attempts) // Lower temp, simplify context
            }
        }
        
        // 8. Fallback
        return try fallbackProvider.getFallback(for: builder, context: context)
    }
}
```

### 6.3 Context Compression Implementation

```swift
struct ContextCompressor {
    static func compress(_ context: FullGameContext, budget: Int) -> String {
        var result = ""
        var remainingBudget = budget
        
        // Priority 1: Identity (always include)
        let identity = compressIdentity(context.player)
        result += identity
        remainingBudget -= tokenEstimate(identity)
        
        // Priority 2: Current situation
        if remainingBudget > 50 {
            let situation = compressSituation(context)
            result += "\n" + situation
            remainingBudget -= tokenEstimate(situation)
        }
        
        // Priority 3: Relevant relationships (top 3)
        if remainingBudget > 100 {
            let relationships = compressRelationships(context.relationships.prefix(3))
            result += "\n" + relationships
            remainingBudget -= tokenEstimate(relationships)
        }
        
        // Priority 4: Recent events (most relevant)
        if remainingBudget > 50 {
            let events = compressRecentEvents(context.recentEvents.prefix(3))
            result += "\n" + events
        }
        
        return result
    }
    
    private static func compressIdentity(_ player: Player) -> String {
        return "P:\(player.name),\(player.age),\(player.occupation ?? "unemployed")"
    }
    
    private static func compressRelationships(_ relationships: [Relationship]) -> String {
        return "R:" + relationships.map { r in
            "\(r.npcName)(\(r.type.shortCode),\(r.quality)%)"
        }.joined(separator: ",")
    }
}
```

### 6.4 Caching Strategy

```swift
class PromptCache {
    // Short-term: Exact match cache for identical contexts
    private var exactCache: [String: CacheEntry] = [:]
    
    // Medium-term: Similar context cache with fuzzy matching
    private var similarCache: SimilarityIndex = SimilarityIndex()
    
    // Long-term: Template response cache for fallbacks
    private var templateCache: [String: [CachedResponse]] = [:]
    
    func get(_ key: String, similarity threshold: Double = 0.9) async -> CachedResponse? {
        // Try exact match first
        if let exact = exactCache[key], !exact.isExpired {
            return exact.response
        }
        
        // Try similar context
        if let similar = similarCache.findSimilar(key, threshold: threshold) {
            return similar.withContextAdjustment()
        }
        
        return nil
    }
}
```

---

## Appendix A: Quick Reference Card

### Prompt Selection Matrix

| Player Action | Prompt Type | Temperature | Max Tokens |
|--------------|-------------|-------------|------------|
| Time advances | Random Event | 0.85 | 400 |
| Makes choice | Decision Outcome | 0.5 | 500 |
| Talks to NPC | NPC Dialogue | 0.7 | 350 |
| Reaches milestone | Milestone Narration | 0.6 | 450 |
| Views consequences | Consequence Chain | 0.5 | 500 |
| Meets new NPC | Backstory Generation | 0.8 | 450 |

### Context Priority Quick Reference

```
ALWAYS INCLUDE: player age, current situation, active flags
USUALLY INCLUDE: relevant relationships, recent events
INCLUDE IF RELEVANT: historical context, world state
INCLUDE IF SPACE: detailed stats, secondary NPCs
```

### Content Safety Quick Check

```
Ages 0-12: No violence, romance (beyond friendship/crushes), substances, trauma
Ages 13-17: Mild conflict OK, age-appropriate romance, handle substances carefully
Ages 18+: Adult themes OK with tasteful handling, no explicit content ever
```

---

## Appendix B: Token Budget Examples

### Minimal Context Event (budget: 300 tokens)
```
System: [200 tokens base]
User: 
Player: Alex, 25, software developer
Status: employed, in relationship (Sam, 18mo)
Mood: stressed (bad review, relationship tension)
Generate: career event
[~100 tokens]
```

### Full Context Dialogue (budget: 500 tokens)
```
System: [200 tokens base + 100 tokens voice profile]
User:
Player context: [100 tokens compressed]
NPC Profile: [75 tokens]
Conversation context: [25 tokens]
[~500 tokens total]
```

---

*Document Version: 1.0*
*Last Updated: {{current_date}}*
*For: Life Encyclopedia iOS Application*
