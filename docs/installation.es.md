<!-- Idioma: Español · English → installation.md -->

# Instalación y uso

El harness es el directorio `.claude/` más un contrato de proyecto. Instalarlo
significa dejar `.claude/` en un proyecto y generar el contrato `CLAUDE.md` a
partir de la plantilla.

## Prerrequisitos

- **[Claude Code](https://claude.com/claude-code)** (CLI, escritorio, web o una extensión de IDE).
- **Git** — el workflow de git del studio y varios hooks asumen un repo.
- **Bash** — los hooks son scripts POSIX. En Windows corren bajo **Git Bash**, que
  viene con Git para Windows. Los hooks degradan con elegancia cuando faltan
  `python`/`jq`.
- *(Opcional)* **Python 3** con **[`uv`](https://docs.astral.sh/uv/)** — solo si
  escribes scripts de Capa 3 en `execution/`. La regla del venv la refuerza
  `enforce-venv.sh`.

## Instalar en un proyecto nuevo o existente

1. **Copia el harness** a la raíz de tu proyecto:

   ```bash
   # desde el proyecto que quieres equipar
   cp -r /ruta/a/este-repo/.claude ./.claude
   ```

   O clona este repo y copia la carpeta, o parte tu proyecto *como* un clon de
   este repo.

2. **Genera el contrato.** Copia la plantilla a los tres archivos espejo para que
   las mismas instrucciones carguen en cualquier entorno de IA:

   ```bash
   cp .claude/templates/CLAUDE.template.md ./CLAUDE.md
   cp ./CLAUDE.md ./AGENTS.md
   cp ./CLAUDE.md ./GEMINI.md
   ```

   > Tip: la skill `/start` hace esto (y el resto del andamiaje) por ti de forma
   > idempotente — ver paso 4.

3. **Agrega un `.gitignore`.** Usa el `.gitignore` de este repo como base — ya
   excluye secretos, `settings.local.json`, estado de runtime y artefactos de build.

4. **Corre `/start`.** Abre Claude Code en el proyecto y ejecuta:

   ```
   /start
   ```

   Esto levanta todo el andamiaje (contrato, `directives/`, `backlog.md`,
   `roadmap.md`, session-state, `memory/`), chequea dependencias de skills, carga
   contexto y produce un briefing de estado. Es idempotente — seguro de correr en
   cada sesión, y el primer paso canónico de toda sesión.

## Primera sesión

- El **hook `SessionStart`** corre automáticamente e imprime rama, commits
  recientes, el resumen de cierre más nuevo (una vez que tengas uno) y el índice
  de memoria.
- Describe una feature y el orquestador puede **auto-invocar `/team-new-feature`**;
  di `directo` / `direct` para saltarte el pipeline en una edición trivial.
- Al final de una sesión, el **hook `Stop`** no te dejará terminar hasta que el
  estado esté persistido (`active.md` + el resumen de cierre de `session-log.md`).

## Personalización

- **Recorta el roster.** Los proyectos en solitario o pequeños no necesitan los 22
  agentes — borra los archivos de agente que no vayas a usar y poda las filas
  correspondientes en `.claude/docs/agent-roster.md` y `agent-coordination-map.md`.
- **Ajusta los permisos.** Edita las listas `allow` / `ask` / `deny` en
  `.claude/settings.json` según tu tolerancia al riesgo. (Editar este archivo es en
  sí una acción que requiere confirmación.)
- **Idioma.** El idioma de conversación por defecto es español neutro, reforzado
  por `enforce-language.sh` y la sección *Conversation language* del contrato. Para
  cambiarlo, edita tanto el hook como esa sección de `CLAUDE.md`.
- **Skills globales.** El studio referencia las skills instaladas globalmente por
  el usuario (suite de diseño, firecrawl, obsidian, GSAP, …) en
  `.claude/docs/global-skills-map.md`. Actualiza ese mapa para que calce con lo que
  realmente tienes instalado.

## Qué NO commitear

El `.gitignore` incluido ya se encarga de esto, pero como recordatorio — nunca
commitees: `.env*`, `credentials.json`, `token.json`, `*.pem`, `*.key`, `id_rsa*`,
`.claude/settings.local.json`, `production/session-logs/`, ni ningún archivo de
`memory/` con contexto sensible.
