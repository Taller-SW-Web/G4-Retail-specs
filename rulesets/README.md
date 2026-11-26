# Rulesets por repositorio

Cada aplicación tiene dos JSON listos para importar desde su propia configuración:

- Backend: `G4-Retail-backend/.github/rulesets/protection-main.json` y `protection-develop.json`.
- Frontend: `G4-Retail-frontend/.github/rulesets/protection-main.json` y `protection-develop.json`.

En cada repo: **Settings → Rules → Rulesets → New ruleset → Import a ruleset**. Importa sus dos archivos por separado.

Los rulesets requieren PR, una aprobación, revisión de Code Owners, resolución de conversaciones, el check `Security Analysis / Security Policy Result`, historial sin force-push y protección contra eliminación de rama. CODEOWNERS dirige el código general a `@Taller-SW-Web/approve-retail-g4-dev` y `.github/**` y el propio CODEOWNERS a `@Taller-SW-Web/glb-devsecops-g4`.

Confirma que el check exista con ese nombre en cada repo antes de activar la regla. Los equipos necesitan acceso de escritura para recibir solicitudes de revisión.
