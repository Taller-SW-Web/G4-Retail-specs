# Rulesets de protección retail

Se prepararon dos rulesets de organización para importar desde GitHub:

- `organization-main.json`: protege `main` en `G4-Retail-backend` y `G4-Retail-frontend`.
- `organization-develop.json`: protege `develop` en esos mismos repositorios.

Ambos exigen PR, una aprobación, aprobación de Code Owner, resolución de conversaciones y el check `Security Analysis / Security Policy Result`. También bloquean force-push y eliminación de ramas protegidas. Se permiten los métodos merge, squash y rebase.

Los archivos `CODEOWNERS` de cada aplicación asignan el código general a `@Taller-SW-Web/approve-retail-g4-dev` y `.github/**` junto al propio `CODEOWNERS` a `@Taller-SW-Web/glb-devsecops-g4`. Los equipos deben ser públicos/visibles y tener permiso de escritura en ambos repositorios para poder recibir solicitudes de revisión.

## Importación

En GitHub: organización `Taller-SW-Web` → **Settings** → **Repository** → **Rulesets** → **New ruleset** → **Import a ruleset**. Importar cada JSON por separado y revisar que ambos repositorios aparezcan como targets antes de crear.

Después de activar los dos rulesets de organización, retirar o desactivar la regla de repositorio `Protection develop and main` en cada aplicación para evitar duplicar controles. Las reglas de repositorio y organización se acumulan.

## Check requerido

El JSON usa el contexto `Security Analysis / Security Policy Result`, observado en las ejecuciones de los PR. Antes de activar los rulesets, confirmar que ese nombre aparece exactamente en **Settings → Rulesets → Required status checks** para ambos repositorios. El workflow reporta el mismo resultado para PR hacia `develop` y `main`.

La importación debe hacerse con una cuenta que sea owner de la organización. La API de GitHub requiere permiso `Administration: write` de organización para crear rulesets org.
