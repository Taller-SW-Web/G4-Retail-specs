# Estado de cierre de Miguel — Semana 14

**Actualizado: 25/11/2026.** Este documento reúne lo realizado, el resultado comprobado
y los pasos que todavía requieren código/dependencias o acceso a servicios externos.

## Resultado actual

| Entregable | Estado comprobado |
|---|---|
| Recepción y revisión de Guillermo | **Completada.** Informe y ocho archivos copiados fielmente; resultados consistentes; dictamen con observaciones |
| Unitarias/componentes de la entrega | **Evidencia recibida y validada:** 390 backend y 233 frontend, de las revisiones declaradas por Guillermo |
| Integración | **Evidencia histórica incorporada.** 116 casos de integración y 18 de capa dentro del total backend; nueva suite de Miguel y PostgreSQL todavía sin resultado |
| CI/CD con seguridad | **Implementado; no certificado como aprobado.** Guillermo reporta Build/CodeQL/Dependency Review aprobados y SonarCloud con HTTP 403 |
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
8. Actualicé el informe de Miguel, el índice raíz y la documentación de performance.

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

### B. GitHub Actions y performance

Al ejecutar el pipeline de backend, la secuencia nueva es:

```text
Integración H2 + PostgreSQL
            ↓ si aprueba
Performance POS local (1, 5 y 10 usuarios)
            ↓ si aprueba y pasan los controles previos
Despliegue normal autorizado por el pipeline existente
```

El frontend conserva tests, build y auditoría npm. Sonar/CodeQL/Dependency Review siguen
en las plantillas compartidas. No se desactiva el Quality Gate ni se presenta un error
del analizador como cero hallazgos.

Descargar y conservar los artefactos:

- `backend-s14-*`: XML de suite completa, integración y PostgreSQL, separados.
- `frontend-s14-*`: JUnit y auditoría npm.
- `performance-s14-*`: `resultados.json`, `informe.md` y log del servidor.
- Reportes de Sonar, CodeQL/SARIF y Dependency Review del mismo commit.

La performance automática es una línea base de **H2 y mocks**, no de Supabase ni de módulos
externos. Para verificación local, desde backend con Java 21 y Node compatible:

```powershell
./scripts/performance/ejecutar-local.ps1
```

Para staging, seguir [README de performance](../../../G4-Retail-backend/scripts/performance/README.md)
con fixtures y token de prueba reales. Registrar entorno, SHA, configuración de adaptadores,
latencias, errores y RPS. No usar tiempos de las suites como mediciones del POS.

### C. SonarCloud HTTP 403

El informe registra un 403 al consultar metadatos JRE. Ese mensaje por sí solo no distingue
token inválido, región/host incorrectos, permisos o un problema del servicio/red. No hay acceso
al secreto ni al run remoto en esta sesión para determinar la causa exacta.

1. En cada repo, comprobar `SONAR_HOST_URL` y la región de la organización. Cloud EU usa
   `sonarcloud.io` y Cloud US `sonarqube.us`; no mezclar token, organización y servidor.
2. Comprobar `SONAR_TOKEN` en **Settings → Secrets and variables → Actions**, su vigencia y
   permisos de análisis para el proyecto. Actualizarlo allí si corresponde, sin pegarlo en
   Markdown, consola compartida o chat.
3. Contrastar la clave calculada por la plantilla: `Taller-SW-Web_G4-Retail-backend` o
   `Taller-SW-Web_G4-Retail-frontend`, y organización Cloud `taller-sw-web` salvo configuración distinta.
4. Reejecutar el scanner y comprobar que el Quality Gate corresponda al `analysisId` del
   mismo run. Si continúa el 403 con configuración válida, revisar el endpoint concreto,
   conectividad del runner y estado del servicio antes de atribuirlo a las credenciales.

Referencia oficial: [Web API y autenticación de SonarQube Cloud](https://docs.sonarsource.com/sonarqube-cloud/appendices/web-api).
No se rotaron secretos, se saltó autenticación ni se marcó Sonar como resuelto sin ejecución.

### D. Consolidación final

Usar `scripts/consolidar.py` para cada conjunto JUnit individual, con el SHA probado; nunca
mezclar el subconjunto de integración con la suite completa. Mantener separadas las cifras
de Guillermo de las de la versión combinada y de las herramientas de evidencia.

El cierre completo requiere: nueva ejecución combinada, la nueva suite y PostgreSQL,
performance real, Sonar en estado verificable y comprobación del despliegue requerido.

## Bloqueos comprobados en este workspace

- GitHub:443 sigue sin conexión desde los procesos de esta sesión.
- Falta Springdoc 2.8.9 en la caché Maven; no está instalado Vitest en el frontend.
- No están disponibles los objetos Git de los commits de Guillermo; tampoco sus cuatro
  archivos frontend nuevos. El informe no incluye el código fuente de esas modificaciones.
- No hay ejecución de performance del backend actual ni acceso a los secretos/configuración
  de SonarCloud. No se reemplaza esa falta de evidencia por resultados de otro binario.

Ver [estado observado](estado-workspace-2026-11-25.json) y
[dictamen de revisión](revision-guillermo-s14.md). La documentación está completada hasta
el alcance que permiten esos datos; el estado global sigue abierto por las verificaciones indicadas.
