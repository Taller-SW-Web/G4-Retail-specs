# Informe de implementación y evidencia — Miguel Alonso Solis Cunza

**Semana 14 / Hito 5 — revisión local del 24/11/2026, America/Lima.**

## 1. Estado real de la entrega

Se implementó la infraestructura de pruebas y evidencia descrita abajo. **El hito no se
declara aprobado todavía:** las suites Java/React y la medición del POS necesitan ejecutarse
en un entorno con las dependencias completas. No se inventaron capturas, cobertura, latencias,
resultados de Sonar ni ejecuciones de GitHub.

| Responsabilidad de Miguel | Implementación / revisión realizada | Evidencia disponible | Pendiente para cerrar |
|---|---|---|---|
| CI/CD y seguridad | Reutilización de Sonar/CodeQL/Dependency Review; corrección de disparadores; auditoría npm completa; Dependabot; gate de evidencia antes de despliegue normal | 41 pruebas de las acciones compartidas aprobadas; workflows inspeccionados y YAML válido | Ejecutar PR y comprobar configuración/licencias/gates en GitHub |
| Integración | Perfil Maven dedicado; nueva suite API + BD + HTTP; job H2 y PostgreSQL efímero | Código y matriz de escenarios; ejecución Java bloqueada por dependencia ausente | Ejecutar suites y descargar JUnit; repetir contra integraciones de Mihael |
| Performance | Generador HTTP, carga progresiva, umbrales, validación de JSON, JSON/Markdown automáticos, workflow y script Windows | 8 pruebas del generador aprobadas, con transporte simulado | Medir el backend y adjuntar resultados reales; no hay latencias del POS todavía |
| Revisión de Guillermo | Inventario estático y procedimiento de recepción/validación | Miguel confirmó que aún está pendiente de entrega | Recibirlo y contrastarlo con JUnit/JaCoCo/LCOV del mismo SHA |
| Evidencia de sustentación | Este informe, inventario, consolidador y guía de demo | 5 pruebas del consolidador aprobadas | Adjuntar artefactos de los runs y referencias de despliegue |

Los 41 + 8 + 5 casos corresponden a herramientas de CI/evidencia, **no** son el resultado
de las suites funcionales de Retail. Las pruebas del generador usan un doble de `fetch`;
sus tiempos no deben mostrarse como performance de la aplicación.

## 2. Qué ya existía y se conservó

- Callers de backend/frontend hacia `Taller-SW-Web/devsecops-templates`.
- SonarQube, CodeQL `security-extended`, Dependency Review, artefactos SARIF y reporte consolidado.
- Seguridad informativa hacia develop y obligatoria al promover develop a main en el template compartido.
- Validación de operadores, tags de producción, healthcheck y rollback de despliegue.
- Pruebas `VentaCobroCorteZIntegrationTest`, `VentaReintentosIntegrationTest`, repositorios,
  `PedidosVentasHttpTest`, `PickupVentasHttpTest`, `TokenServicioG7Test` y `SeguridadConfigTest`.
- Cobertura JaCoCo/LCOV generada por los scripts compartidos de análisis; no se agregó otro escaneo Sonar.

Los archivos locales muestran despliegue backend con **Railway** y frontend con **Vercel**.
La repartición menciona Render. No se cambió de proveedor ni se afirmó cuál está efectivamente
desplegado: validar la infraestructura real con Mihael/Maylle antes de la PPT.

## 3. Cambios exactos y motivo

### Backend

| Archivo | Cambio | Motivo |
|---|---|---|
| `.github/workflows/workflow-pr.yml` | Elimina `paths-ignore: .github/**`; llama workflow de evidencia | Los cambios del propio CI deben revisarse; generar resultados de integración |
| `.github/workflows/workflow-main.yml` | Mismo arreglo de disparadores; `delivery` depende de evidencia en despliegue normal | Evitar desplegar sin la nueva verificación; mantener autorización de rollback existente |
| `.github/workflows/workflow-evidence.yml` | Suite completa H2, subconjunto de integración y nueva suite sobre PostgreSQL 16 efímero; publica XML aun al fallar | Evidencia reproducible sin secretos de Supabase/G5/G7 |
| `.github/workflows/workflow-performance.yml` | Compila/verifica, levanta el jar local, espera health, ejecuta carga y publica artefactos | Medición automatizada con estado de fallo y diagnóstico explícitos |
| `.github/dependabot.yml` | Actualización semanal Maven y GitHub Actions hacia develop | Mantenimiento de dependencias sujeto a revisión |
| `pom.xml` | Perfil `integracion-s14`, informes separados y `failIfNoTests`; propiedad `retail.test.reports` | Selección inequívoca; no confundir ausencia de pruebas con aprobación |
| `src/test/java/pe/edu/unmsm/fisi/retail/integracion/PosDependenciasIntegrationTest.java` | 8 métodos de prueba, uno parametrizado en tres estados: 10 casos esperados | Recorrer API, servicios, perfil persistido y adaptadores HTTP, incluidos fallos |
| `scripts/performance/metricas.mjs` | Percentiles, tasa de error, RPS, excedencias y validación tributaria | Medir respuestas correctas y evitar falsos positivos |
| `scripts/performance/pos.mjs` | Ejecutor HTTP con preflight, calentamiento, tres etapas y reporte | Medir endpoints de contrato sin registrar ventas ni tocar stock |
| `scripts/performance/*.test.mjs` | 8 pruebas del generador | Verificar gates, credenciales locales, percentiles, exportación y errores |
| `scripts/performance/ejecutar-local.ps1` y `README.md` | Arranque/parada controlados y procedimiento Windows/staging | Reproducción de la demo |
| `.gitignore` | Ignora logs locales | Evitar commitear diagnósticos temporales |

`mvnw test` continúa ejecutando todas las pruebas; el perfil no elimina las integraciones
de la suite normal. El subconjunto vuelve a ejecutar algunos casos y **no debe sumarse**
a la suite completa como si fueran casos distintos.

### Frontend

| Archivo | Cambio | Motivo |
|---|---|---|
| `.github/workflows/workflow-pr.yml` y `workflow-main.yml` | Revisión de `.github/**` y evidencia reutilizable; gate previo a deploy normal | Misma política de evidencia que backend |
| `.github/workflows/workflow-evidence.yml` | Node 22.22.2, `npm ci`, Vitest/JUnit, build y `npm audit --audit-level=high --json` | Resultados descargables y revisión del lockfile completo |
| `.github/dependabot.yml` | npm y GitHub Actions semanales hacia develop | Propuestas de mantenimiento automatizadas |
| `package.json` | Agrega `test:run` y `test:ci` sin quitar `test` | Compatibilidad con la repartición y reporte JUnit |
| `.gitignore` | Ignora `reports/` y caché npm local | No versionar salidas temporales |

La auditoría npm incluye herramientas de desarrollo, ya que participan en el build.
El nuevo job falla ante vulnerabilidades high/critical **en ambas ramas**, o si la auditoría
no pudo ejecutarse. Esto es adicional al Dependency Review previo, que revisa diferencias
de dependencias del PR. No se ejecutó `npm audit fix` ni se cambiaron versiones/lockfile.

### Specs y carpeta raíz

- Este documento: detalle, límites, comandos y guion de sustentación.
- `inventario-s14.md`: clasificación estática de clases y lista de archivos frontend.
- `scripts/consolidar.py`: convierte JUnit de **un solo run** a JSON/Markdown, cuenta casos
  reales del XML y rechaza duplicados, reportes inexistentes, vacíos o todos omitidos.
- `scripts/test_consolidar.py`: 5 casos de verificación del consolidador, incluidos fallos del runner a nivel de suite.
- `evidencias-locales/`: resultados de herramientas y diagnóstico de dependencias.
- `MIGUEL-SOLIS-SEMANA14.md` en la raíz: índice y bitácora resumida.

No se modificaron endpoints, contratos, esquemas productivos ni funcionalidades asignadas
a los otros integrantes. Los cambios previos en `rulesets/README.md`, la eliminación de
dos rulesets de specs y los `.github/rulesets/` sin seguimiento se conservaron.

## 4. Matriz de integración

| RF / contrato | Prueba | Dependencias y alcance |
|---|---|---|
| F5/F8, cobro, Corte Z e idempotencia | `VentaCobroCorteZIntegrationTest`, `VentaReintentosIntegrationTest` (previas) | API + servicios + repositorios H2; G5 deshabilitado |
| F1, perfil activo / autorización | Nueva `PosDependenciasIntegrationTest` | Perfil consultado en H2 o PostgreSQL; 401 sin token y 403 sin perfil; G5 no se llama |
| RF-16/17, consulta de pedido | Nueva suite | MockMvc → servicio → perfil BD → `PedidosVentasHttp` → servidor HTTP local G5; `TokenServicioG7` real hacia doble HTTP G7 |
| Fallos externos | Nueva suite parametrizada | G5 403 → 503, 404 → 404, 503 → 503; no inventa pedidos |
| Contrato G7 | Nueva suite + `TokenServicioG7Test` previo | `client_credentials`, Bearer y G7 429; prueba previa cubre caché/renovación |
| RF-04/05/06, catálogo | Nueva suite + `ProductosMockTest` previo | Fixture de G6, barcode exacto, SKU/precio y 404 desconocido; **no G6 real** |
| RF-12, cálculo | Nueva suite | Petición solo SKU/cantidad; verifica desglose aritmético, no certifica consulta de precios G6 |
| Persistencia | Pruebas previas en `repository` | JPA/SQL; job adicional usa PostgreSQL solo para la nueva suite |
| Autenticación JWT | `SeguridadConfigTest` previo | JWKS local, firma y expiración; no infraestructura de G7 en nube |

La nueva clase contiene 7 `@Test` y un `@ParameterizedTest` con tres entradas: **10 casos
esperados**, aún no confirmados por Surefire. Mockito, H2 y servidores HTTP de prueba
deben explicarse como dependencias controladas, no como evidencia de servicios productivos.

## 5. Verificaciones realizadas y bloqueos

| Verificación | Resultado observado |
|---|---|
| `node --test tests/policy.test.cjs tests/security-report.test.cjs` en github-actions | 41 aprobadas, 0 fallos |
| `node --test scripts/performance/*.test.mjs` en backend | 8 aprobadas, 0 fallos |
| `python -B -m unittest discover -s diseño/pruebas/scripts -p test_*.py -v` en specs | 5 aprobadas, 0 fallos |
| Parseo YAML de workflows/Dependabot y XML de POM | Válidos sintácticamente; no equivale a ejecución de Actions |
| Parseo del script PowerShell | Sin errores de sintaxis |
| `git diff --check` de cambios de aplicación | Sin errores de whitespace |
| Maven con Java 21 y caché local | Bloqueado antes de compilar: falta `org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.9` |
| `npm ci --offline` con caché existente | Bloqueado: falta `fake-indexeddb:6.0.1` |
| `npm run test:run` | No ejecuta Vitest, instalación incompleta |
| `npm run build` | Falta `vite/client`, instalación incompleta |
| Conexión a repositorios Maven/npm | `WinError 10013`, sockets no permitidos por el entorno |
| Prueba de carga contra Retail | No ejecutada: no se pudo construir/levantar el backend |

La máquina tiene Node 22.17.0 y Java 24 por defecto; se seleccionó Java 21 instalado
para la comprobación de Maven. El lockfile exige como mínimo Node 22.22.2 para algunas
dependencias, por lo que el job nuevo declara esa versión. No se modificó la instalación del usuario.

## 6. Cómo producir la evidencia pendiente

Desde backend con Java 21 y acceso a Maven Central:

```powershell
./mvnw.cmd -B clean verify
./mvnw.cmd -B -Pintegracion-s14 test
./scripts/performance/ejecutar-local.ps1
```

PostgreSQL: ejecutar **Evidencias Backend S14** en GitHub. El servicio es descartable,
la base se llama `retail_s14` y se crea/elimina el esquema para las pruebas. **Nunca apuntar
el perfil local a Supabase.** La nueva prueba rechaza `S14_DB_URL` que no sea loopback
con esa base. Los XML de PostgreSQL quedan separados de H2.

Desde frontend con Node 22.22.2 o una versión compatible:

```powershell
npm ci
npm run test:ci
npm run build
npm audit --audit-level=high --json
```

Para consolidar, desde specs, reemplazar `SHA-DEL-RUN` por la revisión probada:

```powershell
python -B diseño/pruebas/scripts/consolidar.py --junit ../G4-Retail-backend/target/integration-reports --etiqueta backend-integracion-h2 --sha SHA-DEL-RUN --salida diseño/pruebas/evidencias-s14/integracion-h2
python -B diseño/pruebas/scripts/consolidar.py --junit ../G4-Retail-frontend/reports/vitest.xml --etiqueta frontend --sha SHA-DEL-RUN --salida diseño/pruebas/evidencias-s14/frontend
```

El consolidador retorna 2 si faltan reportes/son inválidos y 1 si la suite no aprueba.
No mezclar los XML de H2/PostgreSQL, ni integración con la suite completa.

En GitHub conservar: URL del run, SHA, fecha, resultado del **Security Policy Result**,
artefactos JUnit/SARIF/Sonar y auditoría npm. Los nuevos nombres de checks deben seleccionarse
en protección de ramas tras el primer run: **Integración H2 y PostgreSQL** en backend y
**Pruebas, build y auditoría de dependencias** en frontend. Mantener el gate de seguridad
existente. No se alteraron reglas remotas ni secretos desde esta sesión.

Antes del deploy normal ambos callers esperan que la nueva evidencia pase. Rollback mantiene
su flujo de autorización previo y reconstrucción de la versión seleccionada, sin usar como
evidencia histórica los tests de otro commit.

## 7. Performance y lectura del resultado

Ver [guía del generador](../../../G4-Retail-backend/scripts/performance/README.md).
Carga cerrada de 1/5/10 usuarios, 20 s por etapa, 5 s de calentamiento excluido. Se registran
peticiones, errores, p50/p95/p99, máximo, RPS y excedencias. Catálogo/escaneo: gate p95 <
800 ms derivado de RF-04; se reportan excedencias porque la spec es más estricta que un
percentil. Carrito: objetivo propuesto p95 < 500 ms. Mínimo 20 muestras por endpoint/etapa.

**Resultado del POS al cierre de esta sesión: NO MEDIDO.** Los archivos que produzcan los
tests del generador en `target/pruebas-generador` son fixtures de verificación de la herramienta
y no deben incorporarse al informe de performance del hito.

Una medición local posterior solo acredita comportamiento con H2/mocks. Para nube, repetir
en staging con token y fixtures reales, registrar configuración de adaptadores y revisar trazas.
No se hicieron pruebas de carga a Render, Railway ni a los módulos de otros equipos.

## 8. Recepción del informe de Guillermo

Miguel confirmó durante esta sesión que Guillermo todavía no entrega el informe. No se encontró
`diseño/pruebas/informe-pruebas-unitarias-s14.md`. No se creó un documento
en su nombre ni se dio por revisado un informe inexistente.

Al recibirlo: confirmar SHA/fecha; comparar cantidades con JUnit; separar unitarias,
slices e integración; revisar JaCoCo/LCOV del mismo run; contrastar RF-01…RF-28 con la matriz;
verificar fallos, omitidos y RF sin cubrir; registrar observaciones y aceptación de Miguel.
El inventario adjunto ayuda a comparar archivos, pero no sustituye cobertura ni trazabilidad.

## 9. Hallazgos previos que deben quedar visibles

1. `SeguridadConfig` acepta HS256 con una clave pública de desarrollo sin restringirlo a
   perfil local/mock. Revisar antes de certificar seguridad de producción; un pipeline configurado
   no demuestra que la aplicación sea segura. Este trabajo no modifica el decodificador.
2. `CarritoService` usa `precioUnitario` recibido y un precio por defecto; §5.4 del contrato
   dice obtener precio del backend/G6. Promociones siguen codificadas. La prueba de RF-12
   valida aritmética, no declara cerrado el contrato de precios/promociones de Mihael.
3. G6 sigue como `ProductosMock` y clientes G7 siguen pendientes según la implementación revisada.
   La evidencia real de esas integraciones depende del merge de Mihael y su configuración.
4. No confundir Railway del pipeline con Render mencionado en la repartición.
5. Dependabot es mantenimiento, no un resultado de escaneo. Un archivo YAML tampoco acredita
   licencias GHAS, permisos, protección de ramas ni un Quality Gate aprobado.

## 10. Guion breve para sustentar

1. Mostrar PR de Miguel hacia develop y SHA probado.
2. Abrir Security Policy Result y hallazgos reales de Sonar/CodeQL/dependencias.
3. Mostrar JUnit de integración y explicar qué BD/módulos son reales o controlados.
4. Ejecutar/mostrar carga y explicar p95, errores, RPS y límites del entorno medido.
5. Mostrar el informe de Guillermo ya validado, o declarar pendiente si aún no existe.
6. Cerrar con las correcciones pendientes respaldadas por evidencia, sin presentar mocks como nube.

## Referencias de configuración

- [GitHub: filtros por rutas en workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).
- [Maven Surefire: selección y parámetros de test](https://maven.apache.org/surefire/maven-surefire-plugin/test-mojo.html).

Las decisiones de alcance provienen de `reparticionSemana14.md` y de los contratos locales;
las referencias anteriores se consultaron para comprobar sintaxis y comportamiento de herramientas.
