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

## 3. Web Research & Data

The `firecrawl` suite (`firecrawl-search`, `-scrape`, `-crawl`, `-map`,
`-monitor`, `-deep-research`, `-seo-audit`, `-qa`, `-website-design-clone`, etc.)
plus `deep-research`.

**Routing:** `librarian` (library/landscape research), `qa-tester`
(`firecrawl-qa` for live-site QA), `design-lead` (`firecrawl-website-design-clone`
for design-system extraction), `producer` (market/lead research flavors).
Prefer firecrawl skills over raw WebFetch/WebSearch when available.

## 4. Brand & Visual Assets

`brand`, `brandkit`, `banner-design`, `design`, `design-system`, `slides`,
`full-output-enforcement` (when exhaustive output is required).

**Consumers:** `creative-director`, `design-lead`, `changelog-writer` (slides for reports).

## 5. Required global skills (dependency manifest)

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
gsap-core
firecrawl
```

**RECOMMENDED** (flagged softly if absent):

```
gpt-taste · high-end-visual-design · redesign-existing-projects
convert-to-markdown
firecrawl-search · firecrawl-scrape · firecrawl-qa · firecrawl-website-design-clone
gsap-scrolltrigger · gsap-react · gsap-performance
design-system · brand · slides
```

The **source of truth for where each of these comes from** — creator and repo —
is §7 below. That table doubles as the install manifest: the missing-skill flow
(§6) reads its `install` column to actually fetch a skill.

## 6. Installing a missing skill (global vs portable)

When `/start` step 0f (or any agent) detects that a skill the studio depends on
is **not available in the session**, the harness does not just warn — it offers
to install it. The flow:

1. **Locate the source.** Look the skill up in §7. If it has no confirmed
   `install` source (`por verificar`), do NOT guess a repo — warn and stop,
   asking the user for the source instead. Installing from a wrong repo would
   credit the wrong creator and run unvetted code.
2. **Ask where to install** (`AskUserQuestion`), two real targets + skip:
   - **Global** — `~/.claude/skills/<name>/` (on this machine:
     `C:\Users\<user>\.claude\skills\<name>\`). **Default / recommended.** The
     skill is shared across every project and stays a single source of truth.
   - **Portable** — `<project>/.claude/skills/<name>/`, committed with the repo.
     Makes this repo self-contained (clone it and the skill travels with it),
     **but** a project-level copy **shadows** any future global install of the
     same name and **freezes** it at copy time (see §5). Choose it only when the
     project must carry the skill on its own (sharing the harness, pinning a
     version). If chosen, note the freeze in the session log.
   - **Skip** — leave it missing; keep the warning in the briefing.
3. **Install from the source.** Run the `install` command from §7 targeting the
   chosen skills dir. Most are one of three shapes:
   - `npx skills add <owner>/<repo> --skill <name>` (the `skills` CLI) — run it
     with the target dir as cwd (or its `--global` flag for the global dir).
   - A vendor installer, e.g. `npx impeccable install`, `npx firecrawl-cli@latest
     init` — follow the vendor's own instructions.
   - `git clone <repo>` into a temp dir, then copy the single `skills/<name>/`
     subfolder into the chosen target. Do NOT commit the whole upstream repo.
4. **Verify.** Confirm `<target>/<name>/SKILL.md` exists and its `name:`
   frontmatter matches. Report what was installed and where; if portable, remind
   that it now shadows the global.

The agent (orchestrator or `skill-curator`) performs the install; it never
installs silently — the target question is always asked first.

## 7. Credits & sources (attribution)

> These skills are other people's work. The studio depends on them, so it credits
> them and links their repos — no creator goes uncredited. This table is also the
> install manifest (§6). `skill-curator` keeps it in sync; a row marked
> `por verificar` means we have not confirmed the origin and must NOT auto-install
> or credit a guessed source.

| Skill(s) | Creator | Repo | Install | Confidence |
|----------|---------|------|---------|------------|
| `impeccable` | Paul Bakaus ([@pbakaus](https://github.com/pbakaus)) | https://github.com/pbakaus/impeccable | `npx impeccable install` (then `/impeccable init`) | confirmed |
| `ui-ux-pro-max` | [@nextlevelbuilder](https://github.com/nextlevelbuilder) | https://github.com/nextlevelbuilder/ui-ux-pro-max-skill | `git clone`, copy `.claude/skills/ui-ux-pro-max` | confirmed |
| `emil-design-eng` | Emil Kowalski ([@emilkowalski](https://github.com/emilkowalski)) — animations.dev | https://github.com/emilkowalski/skills | `npx skills add emilkowalski/skills --skill emil-design-eng` | confirmed |
| `design-taste-frontend` · `design-taste-frontend-v1` · `gpt-taste` (folder `gpt-tasteskill`) · `high-end-visual-design` · `redesign-existing-projects` | Leon ([@Leonxlnx](https://github.com/Leonxlnx)) — tasteskill.dev | https://github.com/Leonxlnx/taste-skill | `npx skills add Leonxlnx/taste-skill --skill <name>` | confirmed |
| `gsap-*` suite (`gsap-core`, `-timeline`, `-scrolltrigger`, `-plugins`, `-frameworks`, `-react`, `-utils`, `-performance`) | GreenSock — **official** | https://github.com/greensock/gsap-skills | `npx skills add greensock/gsap-skills` | confirmed |
| `firecrawl` + CLI suite (`firecrawl-search`, `-scrape`, `-crawl`, `-map`, `-interact`, `-parse`, `-monitor`, `-agent`) | Firecrawl (firecrawl.dev, formerly Mendable) — **official** | https://github.com/firecrawl/cli | `npx -y firecrawl-cli@latest init --all` | confirmed |
| `firecrawl-qa` · `firecrawl-website-design-clone` · other workflow flavors | Firecrawl — **official** | https://github.com/firecrawl/cli · https://github.com/firecrawl/skills | `npx firecrawl-cli@latest init` | likely (org confirmed; exact folder not enumerated) |
| `brand` | Anthropic — **official** (folder `brand-guidelines`) | https://github.com/anthropics/skills | clone/plugin from `anthropics/skills` | likely (renamed from `brand-guidelines`) |
| `slides` | Anthropic — **official** (closest folder `pptx`) | https://github.com/anthropics/skills | from `anthropics/skills` | likely |
| `design-system` | Anthropic (likely — no exact folder; candidates `theme-factory`, `frontend-design`) | https://github.com/anthropics/skills | — | por verificar |
| `convert-to-markdown` | — | — | — | por verificar (many markitdown-based community skills; none confirmed as the source) |

**Notes:**
- Four skills share **one** repo — `github.com/Leonxlnx/taste-skill`
  (`design-taste-frontend`, `gpt-taste`, `high-end-visual-design`,
  `redesign-existing-projects`). Credit Leon once, not four times.
- The `gsap-*` and `firecrawl` families are **genuinely official** — GreenSock and
  Firecrawl publish these skills themselves.
- Rows marked `por verificar` block auto-install (§6 step 1): ask the user for the
  source before installing or crediting.

## 8. Maintenance of this map

- New global skill installed → `skill-curator` adds it here (including a §7
  attribution row with creator + repo) and (if model-tier relevant) to
  `technical-preferences.md` § Skill Model Routing.
- `/start` step 0f enumerates available skills; if it finds skills missing from
  this map, it flags the drift to `skill-curator`; if a §7 row is `por verificar`,
  `skill-curator` should research and confirm the origin.
