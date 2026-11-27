# Aceptación del prompt V2

PASS significa comprobación local indicada, no aprobación de la aplicación en producción.

| Criterio | Estado / evidencia |
|---|---|
| Auditoría estructura real | PASS, audit-current-state.md |
| Mapa de jobs originales y responsabilidad | PASS, auditoría e implementación |
| Base común develop/main | PASS implementación; ejecución CI pendiente |
| Main conserva base y añade controles | PASS implementación y DAG |
| pr-gate no aprueba omitidos | PASS, 8 escenarios sobre código del workflow |
| Scanner Java Maven / frontend LCOV | PASS configuración; análisis real pendiente |
| SCA y secretos auténticos | PENDIENTE ejecución de Gitleaks/Dependency-Check/npm audit |
| Unitarias/cobertura/integración conectadas | PASS configuración; suites actuales bloqueadas localmente |
| Trazabilidad de casos | PASS, informe GO/NO-GO y matriz histórica de Guillermo |
| AAA/casos límite/ramas | PENDIENTE revisión completa de suites combinadas; no reescritas |
| Distinguir DB y dobles | PASS documentación |
| Pirámide y selección por nivel | PASS documentación y condiciones por rama |
| E2E éxito/error | PASS implementación; PENDIENTE ejecución navegador |
| SAST/SCA/DAST diferenciados, destino propio | PASS configuración/documentación |
| Informe siete secciones GO/NO-GO | PASS, NO-GO fundamentado |
| Performance del SHA | PASS conexión JAR; PENDIENTE medición real |
| PR no despliega | PASS inspección de eventos |
| Autodeploy proveedores | PENDIENTE settings remotos |
| Producción tras controles | PASS composición; PENDIENTE corrida y configuración de environment |
| Release solo tras deploy y smoke | PENDIENTE conexión automática; publicador verifica run y manifiesto |
| SemVer y SHA/deploy | PASS validadores; PENDIENTE versión real y prueba proveedor |
| Artefacto realmente desplegado | PENDIENTE identidad binaria/proveedor |
| ZIP real por release | PENDIENTE; empaquetador probado y ejemplo explícitamente sintético |
| Procedencia de reportes | PASS validación SHA/run/attempt; PENDIENTE colector automático |
| Privacidad de ZIP | PENDIENTE revisión de evidencia real; whitelist y filtro implementados |
| Colisión de tags/versiones | PASS prueba negativa; no sobrescribe |
| Sintaxis/pruebas locales | PASS YAML/DAG/Bash/Node y tests; actionlint pendiente |
| Runbook settings externos | PASS, implementación-v2.md |
| No modificación remota inadvertida | PASS: sin deploy/release/settings remoto en sesión |
| Demostración completa al profesor | PENDIENTE runs y release reales; guion preparado |

## Commits locales de esta implementación

Rama en los cinco repositorios: `infra/refactor-hito5-v2`.

- github-actions: `1151290`.
- backend: `f995be2` (mvnw.cmd previo excluido).
- frontend: `4218978`.
- templates: `19c7f99` más limpieza posterior de caché Python.
- specs: contiene esta documentación y evidencia de herramientas.

No están publicados estos cambios. Dependencias compartidas deben publicarse antes de
los callers y validarse en CI. No confundir estos commits con los pushes históricos ya
confirmados por Miguel. No se puede declarar cumplido todo el super prompt todavía.
