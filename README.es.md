<!-- Idioma: Español · English → README.md -->

# Personal AI Dev Studio — Harness

**Un harness portable y con opiniones que convierte a un único asistente de código
con IA en un studio de software disciplinado de 22 agentes.** Deja el directorio
`.claude/` en cualquier proyecto y obtienes una organización de agentes por
niveles, hooks deterministas del ciclo de vida, una política de permisos con la
seguridad primero y un modelo de estado "el archivo es la memoria" — todo diseñado
para que las sesiones converjan a resultados de calidad frontera sin importar el
modelo por debajo.

> 🇪🇸 Español · 🇬🇧 [Read it in English](README.md)

[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-yellow.svg)](LICENSE)
![Hecho para Claude Code](https://img.shields.io/badge/hecho%20para-Claude%20Code-8A2BE2)
![Docs: EN + ES](https://img.shields.io/badge/docs-EN%20%2B%20ES-blue)

---

## Por qué existe

Los LLM son probabilísticos, pero la mayor parte del trabajo real es determinista
y debe ser consistente. Un solo agente haciéndolo todo acumula error — 90% de
acierto por paso da apenas **59% de éxito en cinco pasos**. Este harness corrige el
desajuste empujando la complejidad *fuera* del modelo y *hacia* una estructura
determinista: SOPs, scripts, una red de delegación y hooks. Al modelo le queda lo
único en lo que es bueno — criterio y enrutamiento.

## Qué obtienes

- 🧱 **Arquitectura de 3 capas** — Directiva (*qué hacer*) → Orquestación
  (*decidir*) → Ejecución (*scripts deterministas*), con un bucle de
  auto-reparación que hace al sistema más fuerte cada vez que algo se rompe.
- 🏢 **Un studio de 22 agentes** en tres niveles (Liderazgo · Líderes ·
  Especialistas) más una compuerta de solo lectura `security-reviewer`, cableados
  por una red de delegación explícita.
- 🪝 **10 hooks del ciclo de vida** que garantizan comportamientos que el modelo
  podría olvidar: inyección de contexto al iniciar sesión, enrutamiento de
  intención, refuerzo de idioma, validación de commit/venv, volcado/restauración de
  estado en la compactación, una traza de auditoría de subagentes y un guardia de
  cierre que se niega a terminar una sesión con estado sin guardar.
- 🧠 **"El archivo es la memoria"** — cada decisión recuperable se persiste a
  disco; la primera impresión de la sesión siguiente se inyecta tal cual desde el
  resumen de cierre más nuevo.
- 🔐 **La seguridad primero por defecto** — las reglas de permiso amurallan
  secretos y operaciones peligrosas; una compuerta de seguridad obligatoria corre
  antes de cualquier commit sensible.
- 🧩 **7 skills de equipo + un workflow determinista de plan/build** con QA adversarial.
  `/start` y `/close` enmarcan cada sesión: uno lee el último resumen de cierre,
  el otro escribe el siguiente.
- 🌍 **Docs bilingües** — todo lo de cara al usuario está en inglés y español.

## Inicio rápido

```bash
# 1. Obtén el harness
git clone https://github.com/DGApex/ai-dev-studio-harness.git
cp -r ai-dev-studio-harness/.claude /ruta/a/tu-proyecto/.claude

# 2. Abre Claude Code y levanta el studio
#    (idempotente — seguro de correr al inicio de cada sesión;
#     genera el contrato CLAUDE.md/AGENTS.md/GEMINI.md por ti)
/start
```

Pasos completos, prerrequisitos y personalización: **[docs/installation.es.md](docs/installation.es.md)**.

## El studio de un vistazo

```
        LIDERAZGO (Opus)           estrategia · aprobación · arbitraje
   technical-director · creative-director · producer
                    │
        LÍDERES DE ÁREA (Sonnet)   dueños de un dominio · delegan hacia abajo
   frontend · backend · mobile · devops · git · design ·
   skill-curator · doc-keeper
                    │
        ESPECIALISTAS (Sonnet/Haiku)  trabajo concreto
   react · web · node · python · db · mobile-impl ·
   qa-tester · librarian · skill-author · changelog-writer

   security-reviewer ── compuerta de solo lectura, fuera del árbol,
                        corre antes de cualquier commit sensible
```

Los modelos se asignan por **costo cognitivo** usando alias
(`haiku`/`sonnet`/`opus`) que siempre siguen al modelo más reciente de cada nivel.

## Estructura del repositorio

```
ai-dev-studio-harness/
├── .claude/                 el harness en sí
│   ├── agents/              22 definiciones de agente
│   ├── docs/                8 documentos del studio (roster, red, reglas, principios…)
│   ├── hooks/               10 scripts de shell del ciclo de vida + lib/payload.sh
│   ├── skills/              7 skills del proyecto (team-* + humanizer)
│   ├── templates/           CLAUDE.template.md — el contrato portable
│   ├── workflows/           team-new-feature.js — workflow de plan/build
│   ├── settings.json        permisos + cableado de hooks (se commitea)
│   └── settings.local.json  overrides locales de la máquina (git-ignored)
├── docs/                    arquitectura · referencia · instalación (EN + ES)
├── README.md / README.es.md
├── CONTRIBUTING.md          bilingüe
├── CHANGELOG.md
├── LICENSE                  MIT
└── .gitignore
```

## Documentación

| Tema | English | Español |
|------|---------|---------|
| Arquitectura (el *porqué*) | [architecture.md](docs/architecture.md) | [architecture.es.md](docs/architecture.es.md) |
| Referencia (el catálogo completo) | [reference.md](docs/reference.md) | [reference.es.md](docs/reference.es.md) |
| Instalación y uso | [installation.md](docs/installation.md) | [installation.es.md](docs/installation.es.md) |

## Requisitos

- [Claude Code](https://claude.com/claude-code) (CLI, escritorio, web o extensión de IDE)
- Git, y Bash (Git Bash en Windows) para los hooks
- *(Opcional)* Python 3 + [`uv`](https://docs.astral.sh/uv/) para los scripts de Capa 3

## Nota sobre el idioma

El harness conversa en **español neutro** por defecto, mientras que todos los
artefactos portables (`.claude/**`, código, el contrato, ADRs) quedan en **inglés**
para su reutilización. Ambos son configurables — ver
[installation.es.md](docs/installation.es.md#personalización).

## Licencia

[MIT](LICENSE) © 2026 Alexander Frings.
