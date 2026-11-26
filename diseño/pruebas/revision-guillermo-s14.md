# Revisión de Miguel — entrega de Guillermo, Semana 14

**Fecha:** 25/11/2026, America/Lima. **Responsable de revisión:** Miguel Alonso Solis Cunza.

## Dictamen

**Informe recibido y revisión técnica completada: evidencia documental consistente, aceptada
con observaciones para las revisiones de código declaradas por Guillermo.** Esto cierra el
pendiente de recepción/revisión del informe. No aprueba automáticamente la rama actual, el
despliegue, SonarCloud ni el Hito 5 completo.

Se conserva una copia idéntica del [informe original](informe-pruebas-unitarias-s14.md) y de
sus [evidencias](evidencias-s14/). Los originales de la raíz permanecen intactos. La
[validación automática](validacion-entrega-guillermo.json) incluye SHA-256 de los nueve
archivos para comprobar la copia y detectar modificaciones posteriores; esas huellas
acreditan integridad de esta entrega, no ejecución independiente ni autenticidad del run original.

## Comprobaciones realizadas

| Comprobación | Resultado |
|---|---|
| Backend: clases y casos individuales | 41 clases, 390 casos, todos con estado `aprobado`; sin identidades duplicadas |
| Frontend: archivos y aserciones | 43 archivos, 233 casos `passed`, sin duplicados; coinciden con los totales de Vitest |
| Backend: separación por tipo | 208 unitarias; 116 integración; 18 integración de capa; 19 componente HTTP simulado; 29 componente MVC standalone |
| Backend: cobertura de líneas | 1756 / 1930 = 90,98% |
| Backend: cobertura de ramas | 506 / 729 = 69,41% |
| Frontend: cobertura de líneas | 1250 / 1616 = 77,35% |
| Frontend: cobertura de ramas | 1005 / 1445 = 69,55% |
| Suma de contadores | Totales JaCoCo coinciden con paquetes; totales V8 coinciden con archivos |
| Matriz funcional | Están las 28 filas RF-01…RF-28; se explicitan criterios parciales pendientes |
| Capturas | Inspeccionadas: contadores de JaCoCo y V8 compatibles con los JSON; JaCoCo muestra instrucciones en su columna principal |
| Fecha frontend | `startTime` corresponde a 25/11/2026 00:02:50, America/Lima |
| Pruebas del validador de entrega | 8 aprobadas; más 5 del consolidador: 13 herramientas aprobadas en esta revisión |

No se cuentan 390 pruebas como unitarias estrictas. Las 116 integraciones ya están dentro
de esos 390 casos; no se suman de nuevo. Los tiempos de Maven/Vitest no son latencias del POS.

## Procedencia y diferencia con la copia local

| Componente | Revisión declarada por Guillermo | Revisión local revisada por Miguel |
|---|---|---|
| Backend, corrida local | `5555afbaa0a6d6e9b52917076b513598056cd7f9` | `375b46e` al recibir la entrega |
| Frontend, corrida local | `b09568bcde902f4637470123a0d2eee4c8170647` | `e102c7a` |
| Frontend, corrección posterior de formato según autor | `5ac85424709d3d0d7b00eb6a46c5db479fb6040a` | No disponible en el repositorio local |
| Backend, ajuste posterior JaCoCo según autor | `c22a8c8` | No se atribuye a los porcentajes de la corrida local anterior |

Los objetos de Git de los commits entregados no están disponibles en esta copia; no se pudo
traerlos porque GitHub sigue inaccesible desde el proceso local. Por ello no se verificó el
diff de las PR ni su estado actual. Los 390/233 casos son resultados de la entrega de Guillermo,
no una reejecución de las ramas combinadas.

En particular, aquí aún faltan los cuatro archivos frontend que aparecen en su evidencia:

- `src/pages/CashClosePage.test.tsx`.
- `src/pages/LoginPage.test.tsx`.
- `src/components/organisms/caja/ShiftOpenModal.test.tsx`.
- `src/components/organisms/clientes/AltaRapida.s14.test.tsx`.

La nueva `PosDependenciasIntegrationTest` de Miguel tampoco figura en la corrida de Guillermo.
Sus 10 casos esperados continúan pendientes de ejecución. Se registró el estado observable
en [estado-workspace-2026-11-25.json](estado-workspace-2026-11-25.json).

## Observaciones y acciones de cierre

| Hallazgo | Acción / decisión |
|---|---|
| PR backend #53 y frontend #47 declaradas en borrador | Integrar sus cambios con los de Miguel preservando autoría y volver a ejecutar sobre el SHA resultante; no copiar porcentajes de otra revisión |
| Corrección RF-22 del saldo teórico durante arqueo | Se acepta como hallazgo documentado; verificar la corrección y regresión en el código combinado antes de declararla desplegada |
| Se recibieron JSON y capturas, no los XML/LCOV originales completos | Consistencia recalculada desde JSON; conservar también los artefactos originales del próximo run combinado |
| JaCoCo 0.8.14 local y 0.8.13 en CI | Guillermo informa resolución en `c22a8c8`; no volver a introducir dos agentes de versiones diferentes al integrar |
| SonarCloud devuelve HTTP 403 según el informe | Pendiente de validar token, región/servidor y permisos y ejecutar nuevamente el escaneo/gate; no se certifica seguridad con un análisis fallido |
| Variación de cobertura entre corridas | Se usa únicamente la corrida final declarada; investigar si persiste después de un `clean` con versión única |
| RF parcialmente cubiertos y warnings | Se conservan en el informe original; presencia de una prueba no implica cierre completo de cada RF |

Las PR y el run de CI son **referencias aportadas por Guillermo**, no verificaciones remotas
realizadas en esta sesión: [backend #53](https://github.com/Taller-SW-Web/G4-Retail-backend/pull/53),
[frontend #47](https://github.com/Taller-SW-Web/G4-Retail-frontend/pull/47),
[informe #30](https://github.com/Taller-SW-Web/G4-Retail-specs/pull/30) y
[run del ajuste JaCoCo](https://github.com/Taller-SW-Web/G4-Retail-backend/actions/runs/45553340039/job/138999485122).

## Reproducir la revisión

Desde la raíz de specs:

```powershell
python -B -m unittest discover -s diseño/pruebas/scripts -p test_*.py -v
python -B diseño/pruebas/scripts/revisar_entrega.py --carpeta diseño/pruebas/evidencias-s14 --informe diseño/pruebas/informe-pruebas-unitarias-s14.md --salida diseño/pruebas/validacion-entrega-guillermo.json
```

El validador falla con casos duplicados, totales inconsistentes, estados no aprobados,
cobertura incompatible, suites vacías o matriz incompleta. No escribe resultados de tests
que no se hayan ejecutado ni convierte los JSON recibidos en supuestos XML de Surefire.

## Qué queda fuera de esta aceptación

Performance real del POS; PostgreSQL/Supabase de la versión combinada; G5/G6/G7 en nube;
API Management y flujo asíncrono de Mihael; Quality Gate de SonarCloud y despliegue productivo.
Estos puntos tienen seguimiento en el [cierre técnico de Miguel](cierre-tecnico-s14.md).
