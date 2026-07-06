# VU AI Desk Backend

`askVuAi` is a callable Firebase Cloud Function used by the Flutter AI Desk.
It keeps the OpenAI API key on the server, reads safe campus context from
Firestore, asks the model for a structured response, and logs each request in
`ai_queries`.

## Setup

```bash
cd functions
pnpm install
cd ..
firebase functions:secrets:set OPENAI_API_KEY --project vu-community-app
firebase deploy --only functions --project vu-community-app
```

The function runs on Node.js 22 and defaults to `gpt-5.4-mini`. Keep model/API keys in Firebase
Functions secrets or environment configuration, never in Flutter source.

## Context Used

The function reads public or approved campus collections only:

- `announcements`
- `past_papers`
- `vu_resources`
- `events`
- `departments`
- `guild_posts`
- `discussions`
- `posts`
- `ai_faqs`

It does not use private chats or general user records as AI knowledge.
