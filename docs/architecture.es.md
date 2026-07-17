<!-- Idioma: Español · English → architecture.md -->

# Arquitectura

> Este documento explica *por qué* el harness tiene la forma que tiene. Para el
> catálogo exhaustivo de agentes, hooks, skills y ajustes, ve a
> [`reference.es.md`](reference.es.md).

El harness resuelve un desajuste central: **los LLM son probabilísticos, pero la
mayor parte del trabajo real es determinista y necesita ser consistente.** Un
único agente haciéndolo todo acumula error — 90% de acierto por paso da apenas
59% de éxito en cinco pasos. Todo el diseño empuja la complejidad *fuera* del
modelo y *hacia* una estructura determinista, para que al modelo le quede lo único
en lo que es bueno: criterio y enrutamiento.

Todo lo de abajo se apoya sobre esa idea.

---

## 1. El modelo de 3 capas

El cimiento. Cada tarea fluye por tres capas separadas:

| Capa | Nombre | Qué vive aquí | Naturaleza |
|------|--------|---------------|------------|
| **1** | **Directiva** (*qué hacer*) | SOPs en `directives/`, definiciones de agente en `.claude/agents/` | Instrucciones en lenguaje natural, como un brief para un empleado de nivel medio |
| **2** | **Orquestación** (*decidir*) | El modelo mismo + la red de delegación | Lee directivas, enruta a las herramientas en el orden correcto, maneja errores |
| **3** | **Ejecución** (*hacer el trabajo*) | Scripts de Python deterministas en `execution/` | Confiable, testeable, rápido — llamadas a APIs, procesamiento de datos, archivos |

El orquestador es el **pegamento entre la intención y la ejecución**. No scrapea
un sitio a mano — lee `directives/scrape_website.md`, decide entradas y salidas, y
corre `execution/scrape_single_site.py`.

### Auto-reparación (self-annealing)

Los errores se tratan como oportunidades de aprendizaje, no como callejones sin
salida. El bucle:

1. **Arregla** lo que se rompió.
2. **Arregla la herramienta** (el script / agente / hook), no el síntoma en el consumidor.
3. **Prueba** el arreglo contra el caso que falló.
4. **Actualiza la directiva** con lo aprendido (límites de API, tiempos, casos borde).
5. El sistema queda permanentemente más fuerte.

Esto aplica de forma recursiva: si un arreglo revela una falla estructural,
escala a `technical-director` y produce un ADR.

---

## 2. El Studio (un refinamiento, no un reemplazo)

Sobre el modelo de 3 capas corre el **Personal AI Dev Studio** — una organización
de 22 agentes especializados en 3 niveles que refleja un equipo de software real.
Calza limpiamente sobre las capas:

- **Capa 1 (Directiva)** ↔ definiciones de agente + SOPs
- **Capa 2 (Orquestación)** ↔ la red de delegación
- **Capa 3 (Ejecución)** ↔ agentes especialistas + scripts de Python

### Los tres niveles

```
        LIDERAZGO (Opus)           estrategia, aprobación, arbitraje
   technical-director · creative-director · producer
                    │
        LÍDERES DE ÁREA (Sonnet)   dueños de un dominio, delegan hacia abajo
   frontend · backend · mobile · devops · git · design ·
   skill-curator · doc-keeper
                    │
        ESPECIALISTAS (Sonnet/Haiku)  hacen el trabajo concreto
   react · web · node · python · db · mobile-impl ·
   qa-tester · librarian · skill-author · changelog-writer
```

Más un agente que queda **fuera** del árbol: `security-reviewer`, una compuerta de
solo lectura, invocable globalmente (Opus), que debe aprobar antes de commitear
cualquier cambio sensible.

### Por qué niveles, y por qué los modelos se calibran a ellos

A cada nivel se le asigna un modelo por **costo cognitivo**, no por prestigio:

- **Haiku** — chequeos de estado de solo lectura, formateo, búsquedas simples. Sin criterio.
- **Sonnet** — implementación, autoría de diseño, análisis de un solo sistema. El default.
- **Opus** — síntesis multi-documento, veredictos de compuerta de alto riesgo, revisión cruzada.

Regla práctica: *si quitar un agente no cambiaría la trayectoria del proyecto, es
nivel Haiku; si un mal criterio ahí quemaría semanas, es nivel Opus; todo lo demás
es Sonnet.* El frontmatter de los agentes siempre usa los **alias**
(`haiku`/`sonnet`/`opus`), nunca IDs fijos, para que los niveles sigan al modelo
más reciente automáticamente.

### La red de delegación

La delegación es **unidireccional y explícita** — hay una matriz documentada de
quién-delega-a-quién (ver [`reference.es.md`](reference.es.md)). Los líderes
delegan a especialistas; el liderazgo delega a líderes. Saltarse un nivel para una
decisión compleja es un anti-patrón. Dos aristas especiales rompen el árbol
estricto a propósito:

- **`qa-tester`** es propiedad de `devops-lead` pero es **invocable globalmente**
  por cualquier líder — es el especialista de verificación compartido.
- **`security-reviewer`** es una compuerta global que corre *antes* de `git-lead`
  en cualquier cambio que toque auth, PII, entrada externa, APIs de terceros o
  infra/secretos.

Los conflictos escalan al padre común más cercano; los veredictos de seguridad
ganan salvo que el usuario los anule explícitamente.

---

## 3. El archivo es la memoria

El invariante más importante: **la conversación es efímera; el sistema de archivos
es la memoria.** Cualquier estado que deba sobrevivir a una sesión — tarea actual,
decisiones tomadas, próximos pasos — se persiste a disco, nunca queda solo en el
contexto.

Esto se refuerza, no solo se sugiere:

| Archivo | Rol | Dueño |
|---------|-----|-------|
| `directives/session-log.md` | Bitácora cronológica; **la entrada más nueva arriba**, cada una abre con un bloque de cierre `<!-- cierre -->` | `doc-keeper` |
| `directives/project-overview.md` | Descripción siempre actual del proyecto (nunca >2 sesiones desactualizada) | `doc-keeper` |
| `production/session-state/active.md` | Estado en vuelo recuperable por máquina | `doc-keeper` |
| `directives/backlog.md` | Ideas diferidas / trabajo futuro (dos secciones: `Abiertas` / `Cerradas`, nunca se renumeran) | `producer` + `doc-keeper` |
| `directives/roadmap.md` | Plan por fases + alcances, creado cuando cierra la fase de idea | `producer` + `doc-keeper` |
| `memory/` (raíz del proyecto) | Hechos destilados y recuperables — un hecho por archivo, indexado por `memory/MEMORY.md` | `doc-keeper` |
| `**/ADR-*.md` | Registros de Decisión de Arquitectura (formato Nygard) | `technical-director` |

**El bloque de cierre es estructural, no cosmético.** El hook `SessionStart`
extrae con `sed` el primer bloque `<!-- cierre -->…<!-- /cierre -->` de
`session-log.md` y lo inyecta tal cual como la primera impresión de la sesión
siguiente. Como se fuerza "el más nuevo arriba", "el primer bloque del archivo" y
"el resumen de la sesión más nueva" son lo mismo. Los centinelas son ASCII para
que los hooks los puedan `grep`/`sed` sin importar el locale.

---

## 4. Hooks: pegamento determinista alrededor de un núcleo no determinista

Los hooks son scripts de shell que el harness ejecuta automáticamente en puntos
fijos del ciclo de vida. Son la forma en que el studio garantiza comportamientos
que el modelo podría olvidar. Los diez viven en `.claude/hooks/` y se conectan en
`.claude/settings.json`.

| Evento del ciclo de vida | Hook(s) | Qué garantiza |
|--------------------------|---------|----------------|
| `SessionStart` | `session-start.sh` | Inyecta rama, commits recientes, el resumen de cierre más nuevo y el índice de memoria en la sesión nueva |
| `UserPromptSubmit` | `route-intent.sh`, `enforce-language.sh` | Detecta intención de agregar/editar y de diseño y recuerda las autorizaciones vigentes; obliga a "responder siempre en español" |
| `PreToolUse` (Bash) | `validate-commit.sh`, `enforce-venv.sh` | Bloquea `rm -rf /`, escritura a `.env`, force-push a main; empuja mensajes de commit que referencien issues; bloquea `pip install` global |
| `PreCompact` / `PostCompact` | `pre-compact.sh`, `post-compact.sh` | Vuelca el estado completo antes de la compresión con pérdida, lo recarga después |
| `SubagentStart` / `SubagentStop` | `log-agent.sh`, `log-agent-stop.sh` | Escriben una traza de auditoría de cada invocación de subagente |
| `Stop` | `stop-state-reminder.sh` | Bloquea el fin de sesión si el estado no se persistió (refuerzo de "el archivo es la memoria") y dispara el Roadmap Checkpoint |

Los hooks son **privilegiados** (se auto-ejecutan), así que editar cualquier cosa
bajo `.claude/hooks/` o `settings*.json` requiere confirmación. Todo hook de
sistema de archivos hace `cd` a `${CLAUDE_PROJECT_DIR}` primero, porque un hook
puede heredar el cwd que el shell visitó por última vez (una lección aprendida de
un falso positivo real de deriva de cwd).

---

## 5. Mentalidad de orquestador (proceso por sobre modelo)

*La capacidad del modelo es fija; el proceso no.* El studio codifica una
disciplina de razonamiento para que cualquier sesión, en cualquier modelo,
converja a una calidad similar. Las ocho reglas, de un aliento:

1. **Evidencia antes que creencia** — nunca afirmar "listo/arreglado" sin observarlo.
2. **Auto-verificación adversarial** — un hallazgo debe sobrevivir un intento de refutarlo.
3. **Actúa en el punto de decisión** — sin re-litigar, sin narrar opciones, sin cerrar con promesas.
4. **Diagnostica la clase, arregla la raíz** — tras un arreglo, barre buscando hermanos de la misma clase de bug.
5. **Delegación calibrada** — abre en abanico por amplitud, nunca por una consulta de un dato; cada prompt autocontenido.
6. **Problema vs solicitud** — evaluación cuando el usuario describe, acción cuando el usuario pide.
7. **Gradiente de irreversibilidad** — reversible: hazlo; difícil de revertir: pide un sí fresco y explícito.
8. **Abre con el resultado** — la primera frase responde "qué pasó".

Algunas reglas las refuerza la estructura (hooks, reglas de permiso, la fase de
verificación de QA); el resto las carga el orquestador. Una regla violada es un
evento de auto-reparación: arreglas el artefacto que debió haberla hecho cumplir.

---

## 6. La seguridad es innegociable

Una sección dedicada del contrato pesa más que la productividad y que cualquier
directiva:

- **Los secretos no salen de casa** — nunca leer/imprimir/loguear `.env*`,
  `credentials.json`, `token.json`, `*.pem`, `*.key`, `id_rsa*`; referenciarlos
  solo por nombre de variable. Las reglas `deny` de permisos en `settings.json` lo respaldan.
- **Sin egreso no confiable** — no enviar datos del repo/usuario a un destino de
  red que el usuario no nombró en esta sesión; agregar/cambiar un remoto de git requiere confirmación.
- **Minimización de PII** — datos sintéticos en tests, nada de PII real en logs/memoria/commits.
- **Revisión de seguridad en el bucle** — la compuerta `security-reviewer` es
  obligatoria antes de commitear cualquier cosa que toque auth, PII, entrada
  externa, APIs de terceros o infra/secretos. Un PASS de `qa-tester` por sí solo no basta para eso.

---

## Política de idioma

La conversación con el usuario es en **español neutro**. Los **artefactos
portables quedan en inglés** para reutilizarse entre proyectos y entornos: el
harness (`.claude/**`), el código de `execution/**`, el contrato mismo
(`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`) y los registros técnicos portables (ADRs,
changelogs, SOPs de directivas). Solo los documentos de sesión/estado que el
usuario lee directamente — `session-log.md`, `project-overview.md`, `active.md`,
`backlog.md`, `roadmap.md` y `memory/` — se escriben en el idioma de conversación.

La documentación propia de este repositorio se entrega en **inglés y español**
(`*.md` / `*.es.md`) para que sea legible por cualquiera de las dos audiencias.
