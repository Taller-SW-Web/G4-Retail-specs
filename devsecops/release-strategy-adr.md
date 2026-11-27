# ADR: Estrategia de Releases SemVer y Multi-Repositorio

- **Estado:** Aceptado (implementado en `devsecops-templates` + `G4-Retail-backend` + `G4-Retail-frontend`).
- **Contexto:** `G4-Retail-backend` (Maven/Java 21/Railway) y `G4-Retail-frontend` (React/Vite/Vercel) viven en repositorios Git independientes. No existe un repositorio orquestador con tokens cross-repo para despliegues atómicos coordinados.

## Decisión

Se adopta **Opción B — Releases independientes por componente con SemVer explícito (`VERSION`)**:

1. **Fuente de verdad de versión:** archivo `VERSION` en la raíz de cada repositorio (`0.1.0` inicial) o `version_override` validado en `workflow_dispatch`. `resolve_version.py` normaliza a `vMAJOR.MINOR.PATCH` y rechaza cualquier etiqueta ya existente en Git (idempotencia por rechazo seguro; nunca mueve tags).
2. **Orden de publicación:** `release` en `workflow-deploy.yml` solo se ejecuta en `refs/heads/main`, sin rollback, y únicamente cuando `validation`, `quality`, las pruebas de integración/performance/dast/e2e y `deployment` + `verify-production-health.sh` han terminado en `success`.
3. **Assets publicados en cada GitHub Release `vX.Y.Z`:**
   - `release-evidence-vX.Y.Z.zip` (generado por `collect_evidence.py` + `bundle.py` con reportes reales del run y `SHA256SUMS` interno).
   - `release-manifest.json` y `SHA256SUMS`.
   - Artefacto compilado del commit (`retail-*.jar` en backend, `frontend-dist-vX.Y.Z.tar.gz` en frontend).
4. **Límite de identidad binaria documentado:** Railway (`railway up`) y Vercel (`vercel build --prod`) realizan su propio build/empaquetado remoto. Por ello `deploy-meta.json` registra `identity: "provider-source"` junto con el `deployment.id` y `sha` del commit desplegado, sin afirmar igualdad binaria entre el JAR/tarball de CI y el contenedor remoto.

## Consecuencias

- Cada repositorio mantiene autonomía total de CI/CD y rollback (`workflow_dispatch` con `rollback: true` sobre tag existente).
- Para trazabilidad global del producto G4, `G4-Retail-specs` puede registrar la pareja `(backend.version + sha, frontend.version + sha)` una vez ambos despliegues estén acreditados.

