# Contributing · Cómo contribuir

> English first, español abajo.

---

## English

Thanks for your interest in improving the harness. It is a small, opinionated
system — contributions that keep it coherent are more valuable than ones that add
surface area.

### Ground rules

1. **The harness stays English.** Everything under `.claude/**` — agent
   definitions, hooks, docs, skills — and the contract itself are portable
   artifacts and must remain in English. User-facing repo docs are bilingual
   (`*.md` + `*.es.md`); if you change one, update the other.
2. **Respect the tiers.** New agents declare a `model` alias (`haiku`/`sonnet`/
   `opus`) by cognitive cost, never a pinned model ID. New agents must appear in
   `agent-roster.md` and, if they delegate or receive delegation, in
   `agent-coordination-map.md`.
3. **Hooks are privileged.** Any change under `.claude/hooks/` or `settings*.json`
   is security-sensitive. Keep hooks defensive: `cd "${CLAUDE_PROJECT_DIR}"`
   first, degrade gracefully when `python`/`jq` are missing, and never print
   secrets.
4. **Never weaken security.** Do not loosen the `deny` permission rules or the
   Data Protection section without a clear, documented reason.
5. **Self-anneal.** If you fix a bug, fix the *class*: sweep for siblings and
   patch the artifact that should have prevented it, not just the symptom.

### Workflow

- Branch with a Conventional Commits prefix (`feat/`, `fix/`, `docs/`, `chore/`).
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- Test hooks by feeding them a sample JSON payload on stdin before committing.
- Open a PR describing *what* changed and *why*; link any relevant doc.

---

## Español

Gracias por tu interés en mejorar el harness. Es un sistema pequeño y con
opiniones — las contribuciones que lo mantienen coherente valen más que las que
agregan superficie.

### Reglas base

1. **El harness queda en inglés.** Todo lo que está bajo `.claude/**` —
   definiciones de agente, hooks, docs, skills — y el contrato mismo son
   artefactos portables y deben permanecer en inglés. Los docs del repo de cara al
   usuario son bilingües (`*.md` + `*.es.md`); si cambias uno, actualiza el otro.
2. **Respeta los niveles.** Los agentes nuevos declaran un alias `model`
   (`haiku`/`sonnet`/`opus`) por costo cognitivo, nunca un ID de modelo fijo. Los
   agentes nuevos deben aparecer en `agent-roster.md` y, si delegan o reciben
   delegación, en `agent-coordination-map.md`.
3. **Los hooks son privilegiados.** Cualquier cambio bajo `.claude/hooks/` o
   `settings*.json` es sensible en seguridad. Mantén los hooks defensivos: `cd
   "${CLAUDE_PROJECT_DIR}"` primero, degrada con elegancia cuando falten
   `python`/`jq`, y nunca imprimas secretos.
4. **Nunca debilites la seguridad.** No aflojes las reglas de permiso `deny` ni la
   sección de Protección de Datos sin una razón clara y documentada.
5. **Auto-repara.** Si arreglas un bug, arregla la *clase*: barre buscando
   hermanos y parcha el artefacto que debió prevenirlo, no solo el síntoma.

### Flujo

- Ramas con prefijo de Conventional Commits (`feat/`, `fix/`, `docs/`, `chore/`).
- Los mensajes de commit siguen [Conventional Commits](https://www.conventionalcommits.org/).
- Prueba los hooks pasándoles un payload JSON de ejemplo por stdin antes de commitear.
- Abre un PR que describa *qué* cambió y *por qué*; enlaza el doc relevante.
