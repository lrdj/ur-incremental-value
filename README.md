r0.3



r0.2 9 Sept
- add insight
- display tables
- stable


# Incremental UR Value Prototype

Prototype built with the GOV.UK Prototype Kit to illustrate how user research insights connect to OKRs and delivery, using a lightweight SQLite database. It ships with dummy data for Defra, DBT, and HMRC.

## Tech
- GOV.UK Prototype Kit 13.x
- Node.js 18+
- SQLite (via `better-sqlite3`)
- Nunjucks templates
- `date-fns` for light date utilities

## First‑time setup
1. Install dependencies:
   - `npm install`
2. Start the prototype:
   - `npm start`
3. Open the app:
   - `http://localhost:3000/okr/dashboard`

On first run the app creates `data/app.db` and runs the migrations + seed data automatically.

## Key routes
- `/okr/dashboard` – List of KRs with latest readings; links to KRs and Objectives
- `/okr/objective/:id` – Objective summary, its KRs (with latest), influencing insights, and contributing projects
- `/okr/kr/:id` – KR progress over time, linked insights with simple attribution score, and contributing projects
- `/projects` and `/projects/:id` – Projects list and detail (decisions, experiments, linked KRs)
- `/insights` and `/insights/:id` – Insight browser and detail (links to KRs, objectives, decisions, experiments)
- `/insights/new` – Minimal POST form to add a new insight and link it to a KR with a weight preset (0.1 / 0.3 / 0.6)

## Data model
SQLite schema captures:
- Organisations, Objectives, Key Results (KRs), KR progress points
- Insights, Projects, Decisions, Experiments
- Weighted links: `insight_objective`, `insight_kr` (with `contribution_weight`, `confidence`, `mechanism`), and `project_kr`

Migrations live in `data/migrations/` and run automatically if tables are missing:
- `001_init.sql` – full schema
- `002_seed.sql` – seed data for Defra, DBT, HMRC

## Attribution (simple demo)
- Per insight per KR: last KR delta × weight × confidence × time‑decay
- Implemented in `lib/attribution.js`. This is intentionally simple to communicate the idea.

## Development tips
- Auto‑reload during prototyping: `npm run dev`
- Change the port: `PORT=3001 npm start`
- Reset seeded data: stop the app, delete `data/app.db`, then `npm start`
- macOS build tools (if `better-sqlite3` fails to install): `xcode-select --install`

## File layout (high level)
```
/app
  /views
    okr/ (dashboard, objective, kr)
    insights/ (list, detail, new)
    projects/ (list, detail)
  routes.js
/data
  app.db           # created on first run
  /migrations      # SQL schema and seeds
/lib
  db.js            # sqlite bootstrap + migrations
  attribution.js   # simple scoring utility
```

## Licence
MIT (see `LICENCE.txt`).

