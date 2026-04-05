# Onboarding Questionnaire And Consent Copy

## Purpose

This document translates the Birmingham beta launch pack into concrete user-facing onboarding content.

It includes:

- a beta-ready onboarding questionnaire
- question-order guidance
- a draft privacy and beta consent flow

This copy is product draft copy, not final legal copy.

## Questionnaire Design Rules

- Hard max: 20 questions
- Target range: 10-12 direct prompts plus bridge/permission steps
- The questionnaire should understand the human deeply enough to form a good first knot without making signup feel like a survey prison
- Questions that should be inferred later should not be asked directly in beta

## Mandatory Direct Question Set

### 1. What do you want more of in your life right now?

**Prompt:**  
`What do you want more of right now?`

**Helper text:**  
`Examples: better routines, more time outside, more friends, more fun, more creativity, more peace, more movement, more good food, more events.`

### 2. What do you want less of right now?

**Prompt:**  
`What do you want less of right now?`

**Helper text:**  
`Examples: boredom, isolation, wasted time, stress, bad nights out, expensive plans, feeling stuck.`

### 3. What do you care about most?

**Prompt:**  
`What matters most to you these days?`

**Helper text:**  
`Pick or describe your values in your own words.`

### 4. What kinds of things are you interested in?

**Prompt:**  
`What are you naturally drawn to?`

**Helper text:**  
`Think in terms of interests, scenes, hobbies, environments, communities, and experiences.`

### 5. What do you do for fun, or what do you want to do more for fun?

**Prompt:**  
`What do you do for fun, or wish you did more often?`

**Helper text:**  
`This can be specific or broad.`

### 6. What are some places you already like?

**Prompt:**  
`Name a few places, kinds of places, or vibes you already enjoy.`

**Helper text:**  
`They can be restaurants, cafes, parks, venues, neighborhoods, events, clubs, communities, or anything else.`

### 7. What are you aiming toward?

**Prompt:**  
`What are you working toward right now?`

**Helper text:**  
`Personal, social, creative, health, career, spiritual, or anything else.`

### 8. How do you usually like to get around?

**Prompt:**  
`How do you usually get around?`

**Helper text:**  
`Examples: walking, driving, biking, rideshare, transit, mixed.`

### 9. What kind of spending feels comfortable to you?

**Prompt:**  
`What kind of spending feels right for a normal plan?`

**Helper text:**  
`This is about spending preference, not exact finances.`

### 10. Are you more introverted, more extroverted, or somewhere in the middle?

**Prompt:**  
`Which feels most like you?`

**Choices:**  
- `More introverted`
- `Somewhere in the middle`
- `More extroverted`

### 11. Short bio

**Prompt:**  
`Tell AVRAI anything you want it to know about you.`

**Helper text:**  
`Where you spend time, what you care about, what you like doing, who you like being around, what you want life to feel like. Share only what you want to share.`

This should be the last questionnaire step before DNA sequencing and knot creation.

## Topics To Infer Rather Than Ask

- exact routine
- exact time-of-day patterns
- who they usually go with
- exact comfort with strangers
- precise homebase if location inference is available
- detailed energy patterns

## Off-Limits Questions For Beta

Do not ask direct questions about:

- exact routine
- illegal behavior
- comfort with strangers
- sexuality
- exact address
- exactly who they live with

If the user volunteers some of this in the bio, that is allowed.

## Suggested Question Order

1. more of
2. less of
3. values
4. interests
5. fun
6. favorite places / place types / vibes
7. goals
8. transportation
9. spending preference
10. introvert / middle / extrovert
11. short bio

## DNA / Knot Loading Copy

### Loading title

`Building your knot`

### Loading body

`Your knot is AVRAI’s first mathematical picture of who you are right now. It will keep changing as you live, explore, connect, and grow in the real world.`

### Follow-up body

`AVRAI uses this living knot to find spots, lists, events, clubs, and communities that fit your actual life, not just your taps.`

## Walkthrough Copy

### Walkthrough framing

`AVRAI works best when you live your life, not when you stay on your phone.`

### Walkthrough points

- `Daily Drop`: `Each day, AVRAI gives you a small set of strong doors to explore.`
- `Explore`: `Browse Birmingham through spots, lists, events, clubs, and communities.`
- `AI2AI`: `Nearby AVRAI agents can learn from each other without needing the internet.`
- `Your agent`: `Your personal agent keeps learning from your real behavior and helps you find what fits.`
- `Privacy`: `Your private human identity stays protected. Admin sees agent-level learning, not your direct personal identity by default.`

## Beta Consent Flow

This should be shown as a dedicated consent surface, not hidden behind generic legal-only copy.

### Consent title

`Birmingham beta consent`

### Intro

`This beta is an active learning system. Before you continue, you need to understand what AVRAI does, what stays private, and how the beta is supervised.`

### Section 1: What AVRAI is doing in beta

`AVRAI is learning from your real-world behavior, your app behavior, your saved choices, your optional connected data, and agent-to-agent exchange through the AI2AI network. The goal is to help you find better spots, lists, events, clubs, and communities in real life.`

### Section 2: What stays private

`Your direct human identity is not shown to admin by default. Names, phone numbers, addresses, social handles, and linked account identity are protected and are not supposed to appear in normal admin views.`

### Section 3: What admin can see

`Because this is a supervised beta, the secure admin app can see agent-level learning, kernel state, tuples, recommendation behavior, locality flow, AI2AI activity, and safety/governance information. This is how the system is kept safe and improved during beta.`

### Section 4: Air gap

`Anything that moves between devices or into oversight surfaces is supposed to move through AVRAI’s privacy filters and air-gap boundaries. You will be able to tune some privacy strength settings later, but beta supervision remains part of the system.`

### Section 5: Break-glass cases

`If AVRAI detects dangerous, malicious, illegal, trust-breaking, or hacking behavior, a human admin may use break-glass review to investigate and protect the system and the people in it. AI cannot break glass by itself.`

### Section 6: Offline-first meaning

`Offline-first does not only mean single-device mode. AVRAI can still learn and exchange through on-device intelligence and AI2AI local transport even without internet service. Internet is a secondary aid, not the only path.`

### Section 7: Your controls

`You will be able to adjust permissions, bridges, notification settings, matching settings, and privacy strength settings later. Some supervision and sharing behavior remain necessary for this beta to function and improve safely.`

### Section 8: Work-in-progress truth

`This beta is not promising perfection. Recommendations, place vibes, locality understanding, and social fit will improve over time. Your honest feedback and real-world behavior help the system get better.`

### Consent checkbox copy

`I understand that this is a supervised Birmingham beta, that AVRAI learns from my behavior and agent activity, and that admin can see agent-level learning without my direct personal identity by default.`

### Continue button

`I understand and want to continue`

## Permissions Explainer Copy

### Permissions title

`Help AVRAI work the way it was built to`

### Permissions intro

`These permissions help your personal agent learn from real life and help the AI2AI network work without depending on the internet. You can review them now and adjust them later.`

### Location

`Location helps AVRAI understand what part of Birmingham you are actually living in and what doors are around you.`

### Background location

`Background location helps AVRAI learn routines, context shifts, dwell, and real-world follow-through without needing constant phone interaction.`

### Bluetooth

`Bluetooth is a core AI2AI transport for nearby exchange. Without it, the nearby network is weaker.`

### Calendar

`Calendar helps AVRAI understand what you commit to, save, and follow through on.`

### Health/activity

`Health and activity signals help AVRAI understand movement, energy, and real-world behavior more accurately.`

### Notifications

`Notifications help AVRAI deliver daily drops, strong nudges, compatibility prompts, updates, and important safety or support responses.`

## First Daily Drop Intro Copy

### Header

`Your first doors`

### Body

`Here are your first 5 doors: one spot, one list, one event, one club, and one community that AVRAI thinks might fit who you are right now. Save what feels right. The real learning starts when you live your life.`
