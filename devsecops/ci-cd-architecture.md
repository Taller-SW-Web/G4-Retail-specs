# Arquitectura CI/CD Refactorizada — G4-Retail

## 1. Principios de diseño

1. **Dos workflows por repositorio de aplicación** (`workflow-pr.yml` para PRs y `workflow-main.yml` para `push` a `develop`/`main` y `workflow_dispatch`), eliminando wrappers redundantes (`workflow-evidence.yml`, `workflow-ci.yml`, `workflow-supply-chain.yml`, `workflow-performance.yml`, `workflow-dast.yml`, `workflow-e2e.yml`).
2. **Compilación única por ejecución**: `build_test` compila, ejecuta pruebas unitarias con cobertura (JaCoCo / Vitest LCOV) y empaqueta el artefacto (`retail-*.jar` o `dist/`) una sola vez. `sonar_analysis`, `performance` y `dast` descargan y reutilizan ese mismo artefacto del run.
3. **Validación progresiva `develop` → `main`**: `main` conserva todos los controles base de `develop` y añade `performance` + `dast` (backend) y `e2e` (frontend), sin `continue-on-error` ni aprobaciones falsas por jobs omitidos.
4. **Gate único estable (`pr-gate`)**: evalúa `needs` con `if: always()` y rechaza cualquier control obligatorio que termine en `failure`, `cancelled` o `skipped`.

## 2. Diagrama de arquitectura

```mermaid
flowchart TD
  PR["PR -> develop o main"] --> Q["quality (workflow-pr-analysis.yml)"]
  subgraph Q_JOBS["Jobs dentro de quality"]
    BT["build_test (policy + build + unit + coverage + JAR/dist)"]
    SC["supply_chain (Gitleaks + Dependency-Check / npm audit)"]
    BT --> SA["sonar_analysis (Maven / CLI)"]
    SA --> SG["sonar_gate (Quality Gate API)"]
    BT --> CQ["ghas_sast (CodeQL + SARIF gate)"]
    BT --> DR["ghas_sca (Dependency Review, solo PR)"]
    SG --> ST["status (Security Policy Result)"]
    CQ --> ST
    DR --> ST
    SC --> ST
  end

  Q --> INT["integration (Backend: H2 + PostgreSQL 16)"]
  Q --> PERF["performance (solo main, reutiliza JAR)"]
  Q --> DAST["dast (solo main, OWASP ZAP sobre JAR)"]
  Q --> E2E["e2e (Frontend solo main, Playwright POS exito + 409)"]

  INT --> GATE["pr-gate (if: always())"]
  PERF --> GATE
  DAST --> GATE
  E2E --> GATE
  Q --> GATE

  PUSH["push -> develop / main"] --> MQ["quality + integration + (main: perf/dast o e2e)"]
  MQ -->|"solo main"| REL["delivery (workflow-deploy.yml)"]
  REL --> VAL["validation (retail-operator + VERSION SemVer)"]
  VAL --> DEP["deployment (environment: production + Railway/Vercel + healthcheck)"]
  DEP --> PUB["release (collect_evidence.py + bundle.py + GitHub Release vX.Y.Z + ZIP)"]
```

## 3. Política progresiva `develop` vs `main`

| Control | PR `feat/*` → `develop` | PR `develop` → `main` | `push` `develop` | `push` `main` |
|---|---|---|---|---|
| Build + Unit + Coverage | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Sonar SAST + Quality Gate | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| CodeQL SAST (SARIF high/critical) | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Dependency Review (diff PR) | Obligatorio | Obligatorio | N/A (solo PR) | N/A (solo PR) |
| Gitleaks + SCA completo (Dep-Check / npm audit) | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Integración H2 + PostgreSQL 16 (Backend) | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Performance POS (reutilizando JAR) | Omitido (permitido) | Obligatorio | Omitido | Obligatorio |
| DAST OWASP ZAP API Scan (reutilizando JAR) | Omitido (permitido) | Obligatorio | Omitido | Obligatorio |
| E2E POS Playwright éxito + 409 (Frontend) | Omitido (permitido) | Obligatorio | Omitido | Obligatorio |
| `pr-gate` | Obligatorio | Obligatorio | N/A | N/A |
| Deploy `production` + Smoke + Release `vX.Y.Z` + ZIP | No ejecuta | No ejecuta | No ejecuta | Obligatorio |

