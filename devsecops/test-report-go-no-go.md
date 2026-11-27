# Informe de pruebas y decisión V2

## 1. Resumen y alcance
NO-GO para certificar producción/release. Se verifican herramientas y composición local;
no existe corrida remota completa de estos cambios. Criterios Hito 5: seguridad CI/CD,
integración y performance. E2E/DAST enriquecen la entrega, no inventan nuevos criterios.

## 2. Entorno
Windows, Java 21 instalado, Node 22.17 local, Python 3.13. CI propone Ubuntu/Java21/Node22.22.2.
Bases Git posteriores al pull en `audit-current-state.md`; cambios actuales se identificarán
por sus commits. APIs E2E simuladas; carga/DAST H2/mocks, PostgreSQL efímero en integración.

## 3. Casos y trazabilidad
46 pruebas de acciones, 12 herramientas backend, 9 release y 8 escenarios del gate pasan.
No sumar estos casos a 390 backend/233 frontend de Guillermo (otros SHA).

| Caso | RF / criterio | Nivel/técnica | Esperado | Observado/estado |
|---|---|---|---|---|
| CP-F5-exito | RF-04/14/15: SKU → cobro → comprobante | UI navegador / API stub, partición válida | Una venta, comprobante y total 59.9 | NOT_RUN; `frontend/e2e/venta.cjs` |
| CP-F5-rechazo | RF-14: 409 STOCK_INSUFICIENTE | UI / tabla éxito-rechazo | Mensaje, sin boleta ni duplicado | NOT_RUN; mismo script |
| CP-GATE-01 | Prompt V2 §13: obligatorio omitido | Herramienta, negativo | NO-GO para skipped/failure/cancelled | PASS, código real del gate |
| CP-REL-01 | Prompt V2 §18: identidad | Herramienta, particiones | Rechazar otro SHA/run/attempt | PASS, test_bundle.py |
| CP-REL-02 | Prompt V2 §7: inmutabilidad | Herramienta, negativo | Tag existente no se mueve | PASS, test_publish.py |

Los expected de F5 se apoyan en `specs/f05-orden-cobro` y api-contracts (409 stock).
No se cambiaron reglas de negocio ni las suites de Guillermo. Se reutiliza su matriz RF
en `diseño/pruebas/informe-pruebas-unitarias-s14.md`; no duplicar porcentajes como actuales.

## 4. Defectos
Corregidos localmente: build ausente admitido por agregador, política advisory develop,
resumen DAST que ocultaba error, recompilación innecesaria performance, tag antes de smoke.
Pendientes de comprobar: efectos remotos, compatibilidad Sonar PR/plan, resultados NVD,
identidad de despliegue y ejecución E2E. No se inventaron issues ni vulnerabilidades.

## 5. Métricas
Sin nuevas métricas de cobertura de aplicación ni p95 de Retail. Las pruebas del generador
usan HTTP simulado. No declarar OWASP sin hallazgos porque el scanner no se ejecutó.

## 6. Riesgos y pirámide
Alta prioridad: autorización, integridad de venta/cobro y duplicidad → unitarias/integración
existentes y los dos E2E propuestos. Riesgo medio: búsqueda/catálogo → suites actuales y carga.
Muchas unitarias, menos integración, dos escenarios UI; SAST/SCA/secrets complementarios.
Teoría 11 páginas 26–28, 33–40 y 45 según síntesis del prompt; PDF no disponible.
Cobertura de ramas importa, pero 80% y p95<500ms son ejemplos, no umbrales impuestos nuevos.
Navegador/API stub no acredita integración de sistemas; PostgreSQL efímero no es Supabase.

## 7. Decisión
**NO-GO** mientras falten CI real, revisión de resultados, procedencia del proveedor y release
con evidencia verificada. Este juicio técnico no equivale a aprobación humana ni a despliegue.
Mihael mantiene responsabilidad sobre API Management/asíncrono y módulos reales pendientes.
