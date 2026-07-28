<!-- Idioma: Español · English → reference.md -->

# Referencia

Catálogo exhaustivo de todo lo que trae el harness. Para el *porqué*, lee
[`architecture.es.md`](architecture.es.md).

Todo vive bajo `.claude/`:

```
.claude/
├── agents/         22 definiciones de agente (persona + herramientas + modelo)
├── docs/           8 documentos del studio (roster, red, reglas, principios, ...)
├── hooks/          10 scripts de shell del ciclo de vida
├── skills/         6 skills del proyecto (pipelines team-* + humanizer)
├── templates/      CLAUDE.template.md (el contrato portable)
├── workflows/      team-new-feature.js (workflow determinista de plan/build)
├── worktrees/      dir de aislamiento en runtime para agentes en paralelo (git-ignored)
├── settings.json         permisos + cableado de hooks (se commitea)
└── settings.local.json   overrides locales de la máquina (git-ignored, nunca se commitea)
```

---

## Agentes (22)

Cada agente es un archivo Markdown en `.claude/agents/` con frontmatter YAML
(`name`, `description`, `tools`, `model`) seguido de una línea de persona, una
sección **Collaboration Protocol** (Pregunta → Opciones → Decisión → Borrador →
Aprobación) y **Key Responsibilities**.

### Nivel 1 — Liderazgo (Opus)

| Agente | Dominio | Cuándo usarlo |
|--------|---------|---------------|
| `technical-director` | Arquitectura, aprobación técnica, arbitraje de la red | Decisiones técnicas cruzadas, aprobación de ADR, cambios de stack |
| `creative-director` | Visión UX/UI, marca, voz, estrategia de diseño | Dirección de diseño, consistencia de marca, arbitraje de trade-offs de UX |
| `producer` | Planificación, alcance, priorización, supervisión de docs | Arranque de sprint, arbitraje de alcance, síntesis de estado |

### Nivel 2 — Líderes de área (Sonnet)

| Agente | Dominio | Cuándo usarlo |
|--------|---------|---------------|
| `frontend-lead` | Arquitectura frontend web | Elección de framework, estructura de componentes |
| `backend-lead` | API, servidor, auth, lógica de negocio | Diseño de API, estrategia de auth |
| `mobile-lead` | iOS / Android / multiplataforma | RN vs Flutter vs Expo, arquitectura móvil |
| `devops-lead` | Infra, CI/CD, deploys, secretos | Setup de pipeline, estrategia de deploy |
| `git-lead` | Estrategia de control de versiones | Commits, ramas, PRs, tags, timing de release |
| `design-lead` | Sistema de diseño, componentes, assets | Autoría del DS, librería de componentes |
| `skill-curator` | Dueño de `Skills/` | Brechas de skills, propuestas de regen, flujos multi-skill |
| `doc-keeper` | Dueño de `directives/` + docs vivos | Mantención de docs, seguimiento de ADRs, disciplina del session-log |

### Compuerta transversal (Opus)

| Agente | Dominio | Cuándo usarlo |
|--------|---------|---------------|
| `security-reviewer` | Compuerta de seguridad y protección de datos (solo lectura) | Antes de que `git-lead` commitee cualquier cambio que toque auth, PII, entrada externa, APIs de terceros o infra/secretos. Veredicto: PASS / CONCERNS / BLOCK |

### Nivel 3 — Especialistas (Sonnet / Haiku)

| Agente | Dominio | Modelo |
|--------|---------|--------|
| `react-specialist` | React + ecosistema (hooks, estado, SSR) | Sonnet |
| `web-implementer` | Web vanilla (HTML/CSS/JS, animaciones GSAP) | Sonnet |
| `node-specialist` | Node / Express / Fastify | Sonnet |
| `python-specialist` | Scripts de Python deterministas (Capa 3) | Sonnet |
| `db-specialist` | Esquemas, queries, migraciones | Sonnet |
| `mobile-implementer` | Implementación RN / Expo / Flutter | Sonnet |
| `qa-tester` | Tests + verificación (invocable globalmente) | Sonnet |
| `librarian` | Investigación y ranking de librerías | Haiku |
| `skill-author` | Escribe/edita skills | Sonnet |
| `changelog-writer` | Changelogs, reportes de estado, notas de release | Haiku |

---

## Hooks (10)

Scripts de shell cableados en `.claude/settings.json`, ejecutados en puntos fijos
del ciclo de vida.

| Hook | Evento | Propósito |
|------|--------|-----------|
| `session-start.sh` | SessionStart | Inyecta rama, commits recientes, el resumen de cierre más nuevo + índice de memoria en la sesión |
| `route-intent.sh` | UserPromptSubmit | Detecta intención de agregar/editar y de diseño **solo en el prompt del usuario**; recuerda al orquestador las autorizaciones vigentes de pipeline y suite de diseño |
| `enforce-language.sh` | UserPromptSubmit | Inyecta el recordatorio de "dirígete siempre al usuario en español neutro" |
| `validate-commit.sh` | PreToolUse (Bash) | Bloquea duro `rm -rf /`, escritura a `.env`, force-push a main y **cualquier comando que revele el contenido de un archivo de secretos** (`cat`/`head`/`base64`/`cp`/`curl`, `python -c`, redirecciones `< .env`…); pregunta (soft) ante mensajes de commit sin referencia a issue/ADR |
| `enforce-venv.sh` | PreToolUse (Bash) | Bloquea instalaciones pip global/de sistema; enseña la ruta de venv correcta para que el agente se auto-corrija |
| `pre-compact.sh` | PreCompact | Vuelca el estado completo de la sesión + git status + archivos modificados recientemente antes de comprimir |
| `post-compact.sh` | PostCompact | Recarga el estado de la sesión tras la compresión |
| `log-agent.sh` | SubagentStart | Abre una entrada de auditoría por subagente |
| `log-agent-stop.sh` | SubagentStop | Cierra la entrada de auditoría |
| `stop-state-reminder.sh` | Stop | Bloquea el fin de sesión si hay archivos más nuevos que `active.md` o falta el resumen de cierre; dispara el Roadmap Checkpoint |
| `lib/payload.sh` | *(librería, no es un hook)* | Helper compartido `payload_field`: extrae un campo del JSON del evento que llega por stdin. Lo cargan los hooks que lo necesitan |

**Notas de portabilidad:** cada hook hace `cd` a `${CLAUDE_PROJECT_DIR}` primero y
degrada con elegancia — el JSON se parsea vía `python`→`python3`→`py -3`→`grep`,
de modo que funcionan en Git Bash de Windows donde `python` puede no estar en el
PATH. Esa extracción ahora vive una sola vez en `.claude/hooks/lib/payload.sh`;
quien la usa **protege el `source`** (`[ -f "$LIB" ] && . "$LIB"`) y lleva un
fallback inline, para que un harness copiado a medias nunca bloquee todas las
llamadas a herramientas. Los hooks que inspeccionan el prompt matchean **solo** el
campo `prompt`, nunca el payload crudo: su `cwd` y su `transcript_path` llevan el
nombre de la carpeta del proyecto y dispararían en cada prompt de un proyecto que
viva en una carpeta llamada `landing` o `frontend`. Los hooks salen en silencio en
un proyecto que aún no tiene archivos de estado (p. ej. este mismo repo del harness).

---

## Skills (7)

Skills del proyecto en `.claude/skills/`. Se invocan con `/nombre` o desde el orquestador.

| Skill | Qué hace |
|-------|----------|
| `team-session-start` (`/start`) | Bootstrap idempotente de todo el andamiaje del proyecto + carga de contexto; `producer` + `doc-keeper` sintetizan un briefing de estado. El primer paso canónico de toda sesión |
| `team-session-close` (`/close`) | El espejo de `/start`: reconstruye la sesión desde evidencia (git diff/log + mtimes + `active.md`, nunca desde la memoria), escribe la entrada de session-log con su bloque `<!-- cierre -->`, reescribe `active.md` al final, sincroniza project-overview / backlog / roadmap / memory, ofrece checkpoint de git y hace una purga de `.tmp` + pasada de secretos/PII. Flags `--quick`, `--no-git` |
| `team-new-feature` | Pipeline de feature de punta a punta: junta contexto → workflow de plan determinista (producer → technical-director → líder) tras una compuerta de aprobación → workflow de build (especialistas → QA adversarial) → checkpoint de git → log de docs. Obliga la suite de diseño en trabajo de UI |
| `team-git-checkpoint` | `git-lead` analiza el working tree, propone rama + plan de commits; tras aprobación commitea, opcionalmente pushea / abre un PR. Compuertas condicionales de devops + seguridad, flujo de release/tag, logging de doc-keeper |
| `team-library-recommendation` | `librarian` investiga una lista corta de 2–4 opciones con trade-offs; el líder de dominio elige; `doc-keeper` escribe un ADR Nygard y actualiza la lista de permitidos |
| `team-skill-regeneration` | Regenera/arregla una skill: `skill-curator` analiza la brecha → `skill-author` edita → `qa-tester` valida en dry-run → `doc-keeper` registra. Soporta `--dry-run` |
| `humanizer` | Elimina las marcas de escritura de IA en un texto (33 patrones): bucle borrador → auditoría "¿sigue sonando a IA?" → reescritura final, prohibiendo rayas em/en; matching de voz opcional |

---

## Workflow

`.claude/workflows/team-new-feature.js` — un workflow JS determinista de dos modos
(se corre con la herramienta Workflow) que respalda la skill `team-new-feature`.

- **Modo plan** — secuencial `producer` (encuadre) → `technical-director`
  (aprobación / ADR) → líder de dominio (diseña las tareas para especialistas),
  cada uno devolviendo un esquema JSON validado.
- **Modo build** — los especialistas escritores corren en paralelo (aislamiento
  con git-worktree solo cuando hay más de un escritor que muta), luego las tareas
  de solo lectura, luego verificación de `qa-tester` criterio por criterio con una
  segunda opinión adversarial ante cada falla. Devuelve
  `{ files_modified, implementations, blocked, used_worktrees, qa: { verdict, criteria } }`.

---

## Documentos del studio (8)

Material de referencia en `.claude/docs/`, cargado bajo demanda.

| Documento | Contenido |
|-----------|-----------|
| `agent-roster.md` | Los 22 agentes por nivel + referencia de asignación de modelos |
| `agent-coordination-map.md` | La red de delegación, rutas de escalamiento y 8 patrones de workflow |
| `coordination-rules.md` | Las 6 reglas de coordinación, subagentes-vs-teams, protocolos paralelo + auto-reparación |
| `agent-architecture-design-principles.md` | Los 8 insights de diseño, catálogo de anti-patrones (A1–A9), heurística de enrutamiento de modelos |
| `orchestrator-mindset.md` | Las 8 reglas de razonamiento + el mapa de enforcement |
| `technical-preferences.md` | Defaults de stack, nomenclatura, presupuestos de performance, testing, patrones prohibidos, librerías permitidas, enrutamiento de ADR + skills |
| `global-skills-map.md` | Registra las skills instaladas globalmente por el usuario como herramientas del studio + enrutamiento |
| `backlog-triage-standard.md` | Los buckets de triage por milestone (P0/P1/P2, gate, diferido, cerrado) y el flujo de revisión |

---

## Ajustes y permisos

`.claude/settings.json` (se commitea) declara el cableado de hooks y una política
de permisos:

- **`allow`** — comandos git/ls de solo lectura y seguros corren sin preguntar.
- **`ask`** — ediciones a `.claude/hooks/**` y `settings*.json` siempre confirman
  (archivos privilegiados que se auto-ejecutan).
- **`deny`** — un muro duro alrededor de secretos y operaciones peligrosas:
  leer/escribir `.env*`, `credentials.json`, `token.json`, `*.pem`, `*.key`,
  `id_rsa*`, `settings.local.json`; `rm -rf`, force-push, `git reset --hard`,
  `git clean -f`, `sudo`, `chmod 777`; egreso de red con cuerpo/upload
  (`curl --data`, `scp`, `nc`); y agregar/cambiar un remoto de git.

`.claude/settings.local.json` guarda overrides locales de la máquina. Está
**git-ignored y nunca debe commitearse** (además está en la lista `deny` de lectura).

---

## El contrato (`CLAUDE.template.md`)

`.claude/templates/CLAUDE.template.md` es el contrato portable que se convierte en
`CLAUDE.md` (reflejado a `AGENTS.md` / `GEMINI.md`) cuando el harness se instala en
un proyecto. Es la única fuente de verdad que el orquestador carga en cada sesión,
y cubre: el modelo de 3 capas, principios de operación, el studio, las reglas de
documentación viva, la mentalidad de orquestador, la política de idioma y la
sección completa de Protección de Datos y Seguridad.
