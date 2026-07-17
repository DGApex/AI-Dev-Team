# Global Skills Map — Personal AI Dev Studio

> The user's globally installed skills are **first-class citizens of the studio**.
> They are part of the user's workflow; agents and the orchestrator must know
> they exist and route to them. This map is the registry. `skill-curator` owns
> keeping it in sync with what is actually installed (`/start` lists them).
>
> **How subagents use skills:** subagents generally do NOT have the Skill tool.
> The orchestrator (main loop) invokes the skill and **injects the distilled
> guidance into the Task/workflow prompt**. If a specialist receives UI work
> without design guidance in its prompt, it must flag that as a protocol gap.

## 1. Design & Frontend — THE MANDATORY SUITE

**Rule: any task that touches UI, UX, visual design, or frontend look-and-feel
MUST engage the core suite before/while implementing. This is not optional.**
Skipping it is a protocol violation equivalent to skipping qa-tester.

| Skill | Role | When |
|-------|------|------|
| `impeccable` | UX/UI quality bar: hierarchy, a11y, motion, anti-patterns | ALWAYS on UI design/redesign/review |
| `ui-ux-pro-max` | Styles, palettes, font pairings, UX guidelines per stack | ALWAYS on UI build/plan |
| `emil-design-eng` | Polish philosophy: component feel, animation decisions, invisible details | ALWAYS on UI implementation |
| `design-taste-frontend` | Anti-slop direction for landings/portfolios/redesigns | ALWAYS on landing/marketing/portfolio work |

**Derivatives / reinforcement (pick per task):**
- `design-taste-frontend-v1` — only for exact backward compatibility
- `gpt-taste` — editorial layouts + strict GSAP scroll motion
- `high-end-visual-design` — premium agency defaults (fonts, shadows, spacing)
- `minimalist-ui` / `industrial-brutalist-ui` — specific aesthetic systems
- `redesign-existing-projects` — audits + upgrades of existing UIs
- `image-to-code`, `imagegen-frontend-web`, `imagegen-frontend-mobile` — when designing from/needing visual references
- `stitch-design-taste`, `ui-styling`, `design-taste` derivatives — as applicable

**Consumers:** `creative-director`, `design-lead`, `frontend-lead`,
`web-implementer`, `react-specialist`, `mobile-implementer` (via orchestrator injection).

## 2. Animation

`gsap-core`, `gsap-timeline`, `gsap-scrolltrigger`, `gsap-plugins`,
`gsap-frameworks`, `gsap-react`, `gsap-utils`, `gsap-performance` —
owned by `web-implementer` (already encoded in its agent definition).

## 3. Knowledge & Vault (Obsidian)

| Skill | Role | When |
|-------|------|------|
| `obsidian-vault` | Read/write the user's AI Brain vault | Documenting learnings, **and lightweight reads**: when the studio needs prior context/knowledge ("what do we know about X"), read the vault instead of asking the user |
| `obsidian-export` | Portable HTML export with graph | Sharing/exporting notes |
| `repo-scan` | Repo analysis → .md summary / blueprint | Understanding external repos; chains into obsidian-vault |
| `github-snapshot` | Top AI repos snapshot cross-referenced with vault | Discovery sessions |
| `convert-to-markdown` | Files/URLs → Markdown | Ingesting documents |

**Consumers:** `doc-keeper`, `librarian`, `producer`. Vault reads are allowed
without ceremony; vault WRITES follow the obsidian-vault skill's own structure rules.

## 4. Web Research & Data

The `firecrawl` suite (`firecrawl-search`, `-scrape`, `-crawl`, `-map`,
`-monitor`, `-deep-research`, `-seo-audit`, `-qa`, `-website-design-clone`, etc.)
plus `deep-research`.

**Routing:** `librarian` (library/landscape research), `qa-tester`
(`firecrawl-qa` for live-site QA), `design-lead` (`firecrawl-website-design-clone`
for design-system extraction), `producer` (market/lead research flavors).
Prefer firecrawl skills over raw WebFetch/WebSearch when available.

## 5. Brand & Visual Assets

`brand`, `brandkit`, `banner-design`, `design`, `design-system`, `slides`,
`full-output-enforcement` (when exhaustive output is required).

**Consumers:** `creative-director`, `design-lead`, `changelog-writer` (slides for reports).

## 6. Required global skills (dependency manifest)

The studio DECLARES these globally-installed skills as dependencies — the
`package.json` pattern applied to skills. They are not copied into the project
(project-level copies would shadow the global ones and freeze them at copy
time); instead `/start` verifies them at session start and reports what's missing.

**REQUIRED** (missing one = warning in every session briefing):

```
impeccable
ui-ux-pro-max
emil-design-eng
design-taste-frontend
obsidian-vault
gsap-core
firecrawl
```

**RECOMMENDED** (flagged softly if absent):

```
gpt-taste · high-end-visual-design · redesign-existing-projects
obsidian-export · repo-scan · convert-to-markdown
firecrawl-search · firecrawl-scrape · firecrawl-qa · firecrawl-website-design-clone
gsap-scrolltrigger · gsap-react · gsap-performance
design-system · brand · slides
```

## 7. Maintenance of this map

- New global skill installed → `skill-curator` adds it here and (if model-tier
  relevant) to `technical-preferences.md` § Skill Model Routing.
- `/start` step 2 enumerates available skills; if it finds skills missing from
  this map, it flags the drift to `skill-curator`.
