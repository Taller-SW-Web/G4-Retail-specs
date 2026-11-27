# Runbook de Operación, Configuración Externa y Rollback — G4-Retail

## 1. Orden de publicación de cambios

1. Publicar primero `Taller-SW-Web/github-actions` (rama `main`).
2. Publicar `Taller-SW-Web/devsecops-templates` (rama `main`).
3. Publicar `G4-Retail-backend` y `G4-Retail-frontend` (PR hacia `develop` y luego `develop` → `main`).
4. Fijar las referencias `@main` a SHA de commit cuando los workflows queden estables en remoto.

## 2. Configuración remota pendiente en GitHub (manual)

- **Branch Protection / Rulesets (`develop` y `main`):**
  - Añadir `pr-gate` como *required status check* junto a `Security Analysis / Security Policy Result` (mantener ambos durante la transición).
  - Exigir PR con revisión de `CODEOWNERS` y prohibir force-push/eliminación.
- **GitHub Environment `production`:**
  - Configurar *Deployment branches* restringido a `main`.
  - Configurar *Required reviewers* si el plan del repositorio lo permite.
- **Variables y Secrets (solo NOMBRES, nunca valores):**
  - Repository Variables (`vars`): `SONAR_HOST_URL`, `PRODUCTION_HEALTHCHECK_URL`.
  - Repository / Environment Secrets (`secrets`): `SONAR_TOKEN`, `GH_TOKEN_G4`, `RAILWAY_TOKEN`, `RAILWAY_SERVICE`, `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.

## 3. Configuración externa de proveedores

- **SonarCloud:** en *Project → Administration → Analysis Method*, desactivar **Automatic Analysis** para evitar conflictos 403/de método con el análisis ejecutado desde GitHub Actions.
- **Railway / Vercel:** desactivar el *auto-deploy* automático por integración Git en producción si se desea que únicamente GitHub Actions despliegue tras superar `quality` + `integration` + `performance`/`dast`/`e2e`.

## 4. Procedimiento de Rollback

1. Ir a **Actions → Production Deploy (`workflow-main.yml`) → Run workflow**.
2. Seleccionar en *Use workflow from* el **Tag** de producción previo (`vX.Y.Z` o `production-...`).
3. Marcar `rollback: true` y ejecutar (requiere pertenecer al equipo `retail-operator`).
4. `deployment-validator` verificará la membresía del actor y del autor original del tag, desplegará el commit asociado y ejecutará `verify-production-health.sh`.

