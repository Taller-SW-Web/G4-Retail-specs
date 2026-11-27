# Auditoría V2 posterior al pull — 26/11/2026

Base observada: backend `51bc3fa`, frontend `87a2bc9`, specs `ae9f2e9`,
templates `2d44547`, actions `12fc65d`. Cinco repositorios independientes.
`devsecops-templates` es hermano de `github-actions`, no un subdirectorio suyo.
El diff de `mvnw.cmd` solo cambia finales de línea y se preserva fuera del trabajo.

| Archivo/elemento | Evento y jobs | Problema | Decisión |
|---|---|---|---|
| apps/workflow-pr.yml | PR develop/main; evidence, quality | No existe agregador estable | Conservar y agregar pr-gate |
| backend/workflow-evidence.yml | integración H2/PostgreSQL, performance, DAST | Ejecuta trabajos caros en todo PR | Conservar integración; carga/DAST para main/manual |
| backend/workflow-performance.yml | carga local | Recompila JAR ya disponible | Reutilizar artefacto del mismo run |
| backend/workflow-dast.yml | API Scan activo | Resumen puede ocultar fallos, token 10 min frente a scan 15 min | Endurecer, conservar SHA ZAP de main |
| frontend/workflow-evidence.yml | Vitest/build/npm audit | Sin navegador E2E | Conservar; documentar alcance |
| templates/workflow-pr-analysis.yml | validation/build_test/sonar_analysis/sonar_gate/ghas_sast/ghas_sca/status | Tests duplicados, seguridad advisory develop, CLI Java | Gate obligatorio; cobertura en build, scanner Maven |
| templates/workflow-ci.yml | verificación producción | No conserva CodeQL/SCA en push | Reutilizar controles comunes |
| templates/workflow-deploy.yml | autorización/calidad/deploy | Tag anterior al deploy; sin SemVer/ZIP; health no demuestra SHA | Migrar publicación y exigir procedencia |
| scripts/deploy | Railway y Vercel | Proveedores reconstruyen; identidad binaria no acreditada | Registrar límite, no afirmar binarios idénticos |
| github-actions | autorización retail-operator, política, reportes | Política informativa develop | Mantener autorización, endurecer decisión y tests |

Rutas workflow de apps están en `.github/workflows`; templates también. No hay
PDF de teoría disponible en el inventario; páginas de teoría 11 son referencias del
prompt, no verificación independiente. No hay staging configurado acreditado.
La red del proceso falló a GitHub:443 y Docker no tenía daemon disponible en la
comprobación previa. Revalidar antes de interpretar como limitación permanente.

## Arquitectura propuesta

Conservar nombres de workflows/checks existentes y añadir pr-gate. Todos los PR
requieren build, seguridad e integración; main añade carga/DAST del JAR exacto.
Mantener generador Node probado en lugar de añadir k6 redundante. Reutilizar
build/cobertura en Sonar. El push main debe conservar todos los controles base.
Releases independientes por componente: no hay coordinación multi-repo acreditada.
No publicar GO ni release estable con reportes ausentes o identidad de proveedor
desconocida. Las referencias compartidas @main necesitan publicación ordenada y
posterior fijación por SHA. Los settings remotos se validan fuera de esta auditoría.
