# Estado de cierre de Miguel — Semana 14

**Actualizado: 26/11/2026.** Este documento reúne lo realizado, el resultado comprobado
y los pasos que todavía requieren código/dependencias o acceso a servicios externos.

## Resultado actual

| Entregable | Estado comprobado |
|---|---|
| Recepción y revisión de Guillermo | **Completada.** Informe y ocho archivos copiados fielmente; resultados consistentes; dictamen con observaciones |
| Unitarias/componentes de la entrega | **Evidencia recibida y validada:** 390 backend y 233 frontend, de las revisiones declaradas por Guillermo |
| Integración | **Evidencia histórica incorporada.** 116 casos de integración y 18 de capa dentro del total backend; nueva suite de Miguel y PostgreSQL todavía sin resultado |
| CI/CD con seguridad | **Implementado; no certificado como aprobado.** Sonar/CodeQL/Dependency Review previos se conservan; el último error Sonar fue coexistencia de CI Analysis y Automatic Analysis |
| DAST OWASP ZAP | **Implementado; no ejecutado.** API Scan activo, autenticado con JWT efímero y aislado en H2/mocks |
| Performance | **Implementado y conectado al CI automáticamente. Sin medición real todavía.** Las pruebas del generador no miden Retail |
| Código combinado | **Pendiente de sincronización y ejecución.** Los commits de Guillermo no están disponibles en esta copia |
| Nube y módulos reales | **No verificados.** No hay evidencia nueva de Supabase, G6/G7 reales ni despliegue |

No falta recibir el informe. Los pendientes actuales son distintos y están identificados
para evitar repetir una solicitud ya atendida.

## Qué se terminó en esta continuación

1. Recalculé los 390/233 casos desde los registros individuales, sin confiar solo en el resumen.
2. Verifiqué sumas por tipo y cobertura, tolerando la truncación decimal de Istanbul y los
   contadores omitidos por JaCoCo cuando un paquete no tiene elementos de ese tipo.
3. Revisé las capturas y la matriz RF-01…RF-28; conservé los límites funcionales descritos.
4. Incorporé el informe y sus ocho evidencias sin alterar los originales; registré sus SHA-256.
5. Añadí el validador reproducible y sus ocho pruebas. Las trece pruebas de los scripts de
   revisión/consolidación aprobaron en esta sesión.
6. Registré las diferencias entre el código local y los SHA que Guillermo probó.
7. Conecté `workflow-performance.yml` como workflow reutilizable, llamado después de integración
   en `workflow-evidence.yml`. Ahora las PR y los despliegues normales producirán performance
   cuando puedan ejecutar correctamente el backend; ya no requiere editar la carpeta de carga.
8. Implementé `workflow-dast.yml`, política de bloqueo, resumen Markdown y guía de alcance para ZAP.
9. Verifiqué 11 pruebas Node de herramientas: 8 de performance y 3 del resumen DAST; no son un run ZAP.
10. Actualicé el informe de Miguel, el índice raíz y la documentación de performance/DAST.

## Cierre operativo, en orden

### A. Código que debe probarse

Revisar e integrar [backend #53](https://github.com/Taller-SW-Web/G4-Retail-backend/pull/53)
y [frontend #47](https://github.com/Taller-SW-Web/G4-Retail-frontend/pull/47), junto con los
cambios de Miguel. Son referencias declaradas en la entrega; su estado remoto actual no
se pudo consultar aquí. Preservar las pruebas y corrección de RF-22 de Guillermo, el perfil
`integracion-s14`, los reportes de Miguel y los scripts `test:run`/`test:ci`.

El informe cita el ajuste backend `c22a8c8` que alinea JaCoCo a 0.8.13 con la plantilla.
Su resultado CI está descrito en el informe, pero los porcentajes locales corresponden a
0.8.14. Registrar el SHA combinado y generar nueva evidencia, sin mezclar agentes ni runs.

### B. GitHub Actions, DAST y performance

Al ejecutar el pipeline de backend, la secuencia nueva es:

```text
Integración H2 + PostgreSQL
      ┌─────┴─────┐
      ↓           ↓
Performance     DAST API Scan activo
H2/mocks        H2/mocks con OpenAPI
      └─────┬─────┘
            ↓ si ambos aprueban
Despliegue normal autorizado por el pipeline existente
```

El frontend conserva tests, build y auditoría npm. Sonar/CodeQL/Dependency Review siguen
en las plantillas compartidas. No se desactiva el Quality Gate ni se presenta un error
del analizador como cero hallazgos.

Descargar y conservar los artefactos:

- `backend-s14-*`: XML de suite completa, integración y PostgreSQL, separados.
- `frontend-s14-*`: JUnit y auditoría npm.
- `performance-s14-*`: `resultados.json`, `informe.md` y log del servidor.
- `dast-zap-s14-*`: resumen, reportes ZAP, preflights y log del servidor; su ausencia indica ejecución incompleta.
- Reportes de Sonar, CodeQL/SARIF y Dependency Review del mismo commit.

La performance automática es una línea base de **H2 y mocks**, no de Supabase ni de módulos
externos. Para verificación local, desde backend con Java 21 y Node compatible:

```powershell
./scripts/performance/ejecutar-local.ps1
```

Para staging, seguir [README de performance](../../../G4-Retail-backend/scripts/performance/README.md)
con fixtures y token de prueba reales. Registrar entorno, SHA, configuración de adaptadores,
latencias, errores y RPS. No usar tiempos de las suites como mediciones del POS.

DAST importa `/v3/api-docs`, verifica una ruta autenticada con JWT de desarrollo efímero y ejecuta
ZAP activo solo contra `127.0.0.1`. La política bloquea inyecciones, XSS, Path Traversal, RFI, CRLF,
manipulación de parámetros y XXE; los demás WARN se guardan para revisión sin bloquear por sí solos.
No se usa `continue-on-error`, `|| true` ni el modo seguro/pasivo. Ver la
[guía DAST](../../../G4-Retail-backend/scripts/dast/README.md) antes de cualquier variante para staging.

### C. SonarCloud: Automatic Analysis en conflicto

El último log ya superó el 403 anterior, cargó el proyecto configurado y terminó porque se ejecutó
un análisis CI mientras **Automatic Analysis** estaba activo. No hay confirmación de que el ajuste
se haya cambiado ni un Quality Gate aprobado.

1. Abrir el proyecto backend en SonarCloud: **Administration → Analysis Method**.
2. Desactivar **Automatic Analysis** y conservar el análisis de GitHub Actions ya configurado.
3. Reejecutar el job fallido en GitHub Actions y comprobar el Quality Gate del mismo `analysisId`.
4. Revisar el mismo ajuste para frontend solo si también tiene Automatic Analysis activado.

No se borran tokens, se cambia de plan ni se marca Sonar como resuelto sin una ejecución real.

### D. Consolidación final

Usar `scripts/consolidar.py` para cada conjunto JUnit individual, con el SHA probado; nunca
mezclar el subconjunto de integración con la suite completa. Mantener separadas las cifras
de Guillermo de las de la versión combinada y de las herramientas de evidencia.

El cierre completo requiere: nueva ejecución combinada, la nueva suite y PostgreSQL, DAST y
performance reales, Sonar en estado verificable y comprobación del despliegue requerido.

## Bloqueos comprobados en este workspace

- La falta de conexión GitHub:443 corresponde a una sesión anterior; Miguel sí confirmó la publicación desde su terminal. El acceso de esta sesión no se asume.
- Falta Springdoc 2.8.9 en la caché Maven; no está instalado Vitest en el frontend.
- No están disponibles los objetos Git de los commits de Guillermo; tampoco sus cuatro
  archivos frontend nuevos. El informe no incluye el código fuente de esas modificaciones.
- No hay ejecución de performance o DAST del backend actual ni acceso a la configuración de
  SonarCloud. No se reemplaza esa falta de evidencia por resultados de otro binario.

Ver [estado observado](estado-workspace-2026-11-25.json) y
[dictamen de revisión](revision-guillermo-s14.md). La documentación está completada hasta
el alcance que permiten esos datos; el estado global sigue abierto por las verificaciones indicadas.
