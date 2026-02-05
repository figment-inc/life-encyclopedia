# Life Encyclopedia - Prompt Engineering Quick Reference

## Prompt Selection Matrix

| Trigger | Prompt Type | Temp | Max Tokens |
|---------|-------------|------|------------|
| Time advances | `random_event` | 0.85 | 400 |
| Player chooses | `decision_outcome` | 0.50 | 500 |
| Talk to NPC | `npc_dialogue` | 0.70 | 350 |
| Hit milestone | `milestone_narration` | 0.60 | 450 |
| View ripple effects | `consequence_chain` | 0.50 | 500 |
| Meet new character | `backstory_generation` | 0.80 | 450 |

---

## Context Priority (What to Include)

### Always Include
- Player age
- Current occupation/status
- Active flags (employed, married, etc.)

### Usually Include
- Top 3 relationships + quality scores
- Last 3 significant events
- Current mood/emotional state

### Include If Relevant
- Specific stats for the prompt type
- Historical context for recurring NPCs
- Era/setting constraints

### Include If Token Budget Allows
- Secondary NPCs
- Detailed stat breakdown
- Extended event history

---

## Compressed Context Format

```
Player: Alex Chen, 25, software developer
Status: stressed (recent: bad review, relationship tension)
Key relationships: Sam (partner, 75%), Jordan (friend, 90%)
Recent: bad_review, argument_with_sam, promotion_passed
Flags: employed, in_relationship, no_children
```

**Token estimate:** ~50-80 tokens

---

## Age-Appropriate Content Guide

| Age Range | Include | Avoid |
|-----------|---------|-------|
| 0-5 | Family, health, milestones | Everything complex |
| 6-12 | School, friends, hobbies | Violence, romance, substances |
| 13-17 | Teen drama, crushes, identity | Adult romance, explicit content |
| 18-25 | Career, relationships, growth | Explicit content |
| 26+ | Full adult themes | Explicit sexual content, gratuitous violence |

---

## JSON Output Structure Cheat Sheet

### Random Event
```json
{
  "event": {
    "id": "evt_xxx",
    "title": "Short Title",
    "description": "2-3 sentences, second person",
    "category": "career|health|relationship|...",
    "tone": "positive|negative|neutral|bittersweet",
    "severity": "minor|moderate|major|life_changing",
    "immediate_effects": { "stat_changes": {}, "relationship_changes": [] },
    "decision_prompt": { "required": true/false, "options": [] }
  }
}
```

### NPC Dialogue
```json
{
  "dialogue": {
    "spoken_text": "What the NPC says",
    "tone": "warm|friendly|neutral|distant|...",
    "subtext": "What they're really thinking",
    "body_language": "Brief physical description",
    "conversation_options": [
      { "type": "supportive|challenging|...", "text": "Response option" }
    ]
  }
}
```

### Decision Outcome
```json
{
  "outcome": {
    "result_type": "success|partial_success|failure|...",
    "narrative": "2-4 sentences describing what happens",
    "immediate_effects": {},
    "delayed_effects": [{ "timeframe": "", "description": "", "probability": "" }],
    "npc_reactions": [{ "npc": "", "reaction": "" }]
  }
}
```

---

## Tone Settings Reference

| Setting | 0.0-0.3 | 0.4-0.6 | 0.7-1.0 |
|---------|---------|---------|---------|
| Humor | Serious | Occasional | Frequent |
| Drama | Understated | Balanced | Heightened |
| Realism | Idealized | Grounded | Harsh |

**Add to system prompt:**
```
NARRATIVE TONE:
- Humor: {level} ({description})
- Drama: {level} ({description})
- Realism: {level} ({description})
```

---

## Relationship Quality Effects on Dialogue

| Quality | Dialogue Character |
|---------|-------------------|
| 80-100 | Warm, trusting, terms of endearment |
| 60-79 | Friendly, comfortable, casual |
| 40-59 | Polite but distant, underlying tension |
| 20-39 | Strained, guarded, brief |
| 0-19 | Hostile, cold, may refuse to engage |

---

## Fallback Strategy

1. **Retry**: Lower temp by 0.2, simplify context
2. **Template**: Use pre-written fallback with variable slots
3. **Cache**: Use similar cached response with adjustments
4. **Generic**: Safe placeholder content, queue for async retry

**Example fallback event:**
```json
{
  "title": "A Quiet Moment",
  "description": "Life continues at its usual pace. Sometimes the most peaceful days are the ones where nothing much happens.",
  "category": "random",
  "tone": "neutral",
  "severity": "minor"
}
```

---

## System Prompt Structure

```
[BASE PROMPT FOR TYPE]
- Role definition
- Core rules
- Output format instructions

[CONTENT SAFETY]
- Age-appropriate filters
- Forbidden content list

[TONE SETTINGS] (if configured)
- Humor/drama/realism levels

[ERA CONTEXT] (if not modern)
- Available technology
- Period slang
- Social norms

[VOICE PROFILE] (for NPC dialogue)
- Speech patterns
- Characteristic phrases
```

---

## Common Placeholders

| Placeholder | Description |
|-------------|-------------|
| `{{player_context}}` | Compressed player state |
| `{{life_phase}}` | childhood/teen/young_adult/adult/senior |
| `{{recent_event_types}}` | Categories of recent events |
| `{{category_hint}}` | Preferred event category or "any" |
| `{{npc_profile}}` | NPC personality and history |
| `{{relationship_quality}}` | 0-100 score |
| `{{situation_context}}` | Current scene description |
| `{{decision_text}}` | What player chose |
| `{{involved_npcs}}` | NPCs affected by event |

---

## Validation Checklist

- [ ] JSON parses correctly
- [ ] Required fields present
- [ ] Category/tone/type are valid enums
- [ ] Description length: 50-500 chars
- [ ] Stat changes within bounds (±30 max)
- [ ] Content passes age filter
- [ ] No anachronisms for era
- [ ] NPC voice matches profile

---

## Token Budget Quick Math

| Context Element | ~Tokens |
|-----------------|---------|
| Identity line | 15-20 |
| Status line | 10-15 |
| Each relationship | 10-15 |
| Each recent event | 10-15 |
| Flags line | 10-20 |
| **Typical total** | **60-100** |

**Budget allocation:**
- System prompt: 200-300 tokens (cached)
- User prompt: 100-200 tokens
- Output: 300-500 tokens
