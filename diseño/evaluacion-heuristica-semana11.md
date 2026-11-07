# Evaluación Heurística de Usabilidad — Semana 11 (Hito 4)

**Módulo:** Retail (G4) — Canal para el Vendedor de Mostrador
**Interfaces evaluadas:** F9 (Cambios y Vales), F6 (Consulta Histórica de Pedidos) y F7 (Pickup)
**Responsable QA:** Guillermo Ramos
**Fecha de corte:** 6 de noviembre de 2026

---

## 1. Marco metodológico

**Método:** inspección heurística experta con las 10 heurísticas de Nielsen (1994). Se recorrió cada flujo como lo haría el vendedor de mostrador y se revisó el código de las pantallas para confirmar cada hallazgo. Cada hallazgo indica el componente y la condición que lo produce, para que el responsable pueda reproducirlo.

**Versiones evaluadas:**

| Funcionalidad | Responsable | Versión inspeccionada | Pantallas |
|---|---|---|---|
| F9 — Cambios y Vales | Cristhian | `G4-Retail-frontend`, rama `feat/f9-cambios-ui` (commit `13e83ba`) | `ExchangePage.tsx`, `ExchangeModal.tsx`, `VoucherThermalTicket.tsx` |
| F7 — Pickup | Maylle | `G4-Retail-frontend`, rama `develop` | `PickupPage.tsx`, `PickupCard.tsx`, `DeliveryModal.tsx` |
| F6 — Historial | Kevin | Sin pantalla implementada a la fecha de corte | Revisión de diseño sobre `f06-trazabilidad.ui.md` y la guía de la Semana 11 |

> **Alcance de F6:** a la fecha de corte no había `OrdersHistoryPage.tsx` ni `OrderHistoryModal.tsx` en `develop` ni en las ramas remotas. Se evaluó el **diseño especificado**, para corregir los problemas antes de programarlos. Conviene repetir la evaluación sobre la pantalla terminada.

**Escala de severidad (Nielsen, 0 a 4):**

| Nivel | Significado | Acción |
|:---:|---|---|
| 0 | No es un problema de usabilidad | Ninguna |
| 1 | Cosmético | Corregir si sobra tiempo |
| 2 | Menor: el vendedor se recupera solo, con pérdida de tiempo | Prioridad baja |
| 3 | Mayor: provoca errores o bloquea casos reales | Prioridad alta, antes de la sustentación |
| 4 | Catástrofe: impide completar la tarea o genera un daño difícil de revertir | Corregir obligatoriamente |

**Heurísticas (abreviatura usada en las tablas):**
H1 Visibilidad del estado del sistema · H2 Relación con el mundo real · H3 Control y libertad del usuario · H4 Consistencia y estándares · H5 Prevención de errores · H6 Reconocer antes que recordar · H7 Flexibilidad y eficiencia de uso · H8 Diseño estético y minimalista · H9 Ayuda para reconocer, diagnosticar y recuperarse de errores · H10 Ayuda y documentación.

---

## 2. F9 — Cambios y Vales de Compra (`/cambios`)

**Tarea evaluada:** el cliente vuelve con la boleta `B001-00000045` para cambiar una polera por talla. El vendedor valida la boleta, inspecciona la prenda y emite el vale térmico.

### Fortalezas observadas
- **H1:** el badge «Válido para cambio (día X de 7)» muestra el plazo sin hacer cálculos. Si venció, se explica el motivo y los botones quedan deshabilitados.
- **H5:** «Aprobar cambio» se bloquea mientras falte una condición crítica, y el aviso lista exactamente qué falta.
- **H5:** la clave de idempotencia por intento evita emitir dos vales si la red falla y se reintenta.
- **H2:** el vale imita un ticket térmico de 80 mm, con QR escaneable por el mismo lector de productos.

### Hallazgos

| # | Heurística | Hallazgo | Sev. | Recomendación |
|---|---|---|:---:|---|
| 9.1 | H3, H5 | «Aprobar cambio y emitir vale de S/ X» emite un documento con valor monetario en un solo clic, sin paso de confirmación. Después de emitido no hay forma de anularlo desde la interfaz. | 3 | Agregar una confirmación con resumen (prenda, unidades, monto, motivo) o PIN de supervisor sobre cierto monto. Exponer la anulación (`ANULADO` ya existe en `RET_VALE_COMPRA`). |
| 9.2 | H2, H4 | La etiqueta dice «Boleta **o factura** de la compra», pero `esBoletaValida` solo acepta `B001-########`. Una factura `F001-…` recibe «El comprobante debe tener el formato B001-00000045», sin explicar que las facturas no se cambian aquí. | 3 | Aceptar `F001` o cambiar la etiqueta a «Boleta» y, ante una factura, mostrar un mensaje específico con el procedimiento alternativo. |
| 9.3 | H5, H7 | El correlativo exige 8 dígitos con ceros a la izquierda: `B001-45` se rechaza. Al tipear a mano (sin lector), el vendedor tiene que contar ceros. | 2 | Autocompletar ceros al validar (`B001-45` → `B001-00000045`) o separar serie y correlativo en dos campos. |
| 9.4 | H5 | El motivo viene preseleccionado en «Cambio de talla». Si el vendedor no lo cambia, una falla de fábrica se registra como cambio ordinario y se le exige un checklist que no aplica. | 2 | No preseleccionar un motivo: el vendedor tiene que elegirlo para habilitar el checklist. |
| 9.5 | H6, H10 | El checklist muestra tres condiciones iguales, pero solo dos bloquean («Empaque o caja original» no es obligatoria, según `evaluarInspeccion`). El vendedor no sabe cuál es opcional hasta que se equivoca. | 2 | Marcar «(obligatorio)» / «(opcional)» en cada ítem o separarlos en dos grupos. |
| 9.6 | H4 (accesibilidad) | Los botones de motivo son `<label>` con el radio `sr-only`: al navegar con Tab no se ve el foco, porque no hay estilo `focus-within`/`focus-visible`. | 2 | Agregar `focus-within:ring-2` a la etiqueta del motivo. |
| 9.7 | H7 | Después de emitir el vale no hay atajo para volver al POS y aplicarlo a la nueva compra (el caso típico de un cambio de talla). | 2 | Botón «Usar vale en nueva venta» que vuelva a `/pos` con el código del vale cargado. |
| 9.8 | H1 | Las unidades se recortan en silencio al máximo disponible (al escribir 5 con 2 disponibles, el campo muestra 2 sin avisar). | 1 | Mostrar «Máximo 2 unidades disponibles» al recortar. |
| 9.9 | H7 | El acceso a `/cambios` desde el POS es un enlace en la barra superior, sin atajo de teclado (F6 sí lo tendrá). | 1 | Definir un atajo consistente con el resto del POS. |

**Severidad promedio F9: 2.0** (9 hallazgos: 2 mayores, 5 menores, 2 cosméticos)

---

## 3. F7 — Pickup / Click & Collect (`/pickup`)

**Tarea evaluada:** una clienta llega a recoger el pedido `PED-2026-08910`. El vendedor lo busca por DNI, procesa el retiro, verifica la identidad y entrega la constancia.

### Fortalezas observadas
- **H1:** el contador «N pendientes» en la cabecera, el estado «Cargando pedidos…» y el botón «Reintentar» ante un error de red.
- **H5:** si el DNI tecleado no coincide con el del titular, se avisa y se sugiere «Tercero Autorizado». Con un tercero, la carta poder es obligatoria.
- **H6:** el modal repite el pedido, el anaquel y las prendas, así que no hay que recordar la tarjeta.
- **H3:** el modal no se cierra mientras se registra la entrega, para no dejar estados a medias.

### Hallazgos

| # | Heurística | Hallazgo | Sev. | Recomendación |
|---|---|---|:---:|---|
| 7.1 | H5, H2 | `DeliveryModal` solo acepta DNI de 8 dígitos (`esDniValido`). Un cliente extranjero con CE o pasaporte (documentos que RF-09 incorpora en la Semana 11) no puede retirar su pedido. | 3 | Cuando se integre el PR de F3 (`feat/f3-cliente-ui-regex`), reutilizar su selector y sus reglas (`src/lib/documento.ts`: DNI/CE/Pasaporte) en «Documento de quien recoge». |
| 7.2 | H3 | Si se cierra la constancia sin imprimirla, el pedido sale de la bandeja y no hay forma de reimprimirla. | 2 | Guardar la última constancia o permitir consultarla por número de pedido (puede integrarse con F6). |
| 7.3 | H1, H9 | El aviso «El pedido se encuentra en camino o asignado a otra sede…» no dice en qué estado está realmente el pedido. El vendedor no puede darle al cliente una respuesta concreta. | 2 | Mostrar el estado y la sede reales del pedido encontrado (por ejemplo «EN_CAMINO · llega a esta tienda el 08/11»). |
| 7.4 | H3 | Pulsar Escape o hacer clic fuera del modal lo cierra y borra el DNI, el nombre y los checks que ya se capturaron. | 1 | Pedir confirmación antes de cerrar si hay datos capturados. |
| 7.5 | H4 | Al no coincidir el DNI, el mensaje usa `text-red-700` en lugar del token `text-error`, y el campo no recibe borde rojo ni `aria-invalid`, a diferencia de F3. | 1 | Usar los tokens del design system y marcar el campo con `aria-invalid`. |
| 7.6 | H2 | La tarjeta muestra siempre «· 1 bulto» aunque el pedido tenga varias prendas o paquetes. | 1 | Mostrar el número real de bultos o quitar el dato si G5 no lo informa. |
| 7.7 | H7 | El filtro de fecha usa el selector nativo y no tiene atajo «Hoy» ni botón para limpiarlo. | 1 | Agregar los chips «Hoy» y «Todas». |

**Severidad promedio F7: 1.6** (7 hallazgos: 1 mayor, 2 menores, 4 cosméticos)

---

## 4. F6 — Consulta Histórica de Pedidos (`/pedidos`) — revisión de diseño

**Tarea evaluada:** después de emitir `B001-00000045` / `PED-2026-00412`, el vendedor pulsa «Ver en Historial», confirma el estado `PAGADO` y desde ahí solicita el cambio (el recorrido completo de la demo, sección 4 de la guía).

| # | Heurística | Hallazgo | Sev. | Recomendación |
|---|---|---|:---:|---|
| 6.1 | H5, H7 | El atajo previsto es la tecla **F6**, que en Chrome y Edge mueve el foco a la barra de direcciones. Si no se intercepta, el vendedor sale del POS en plena demo. | 3 | Capturar `keydown` de `F6` con `preventDefault()` y probarlo en el navegador del mostrador. Como alternativa, usar `Alt+H`. |
| 6.2 | H4 | La UI spec define colores solo para `ENTREGADO`, `LISTO_PICKUP` y `ANULADO`, pero la guía exige mostrar `PAGADO` y `EN_PREPARACION`. Sin una tabla completa, cada pantalla elegirá colores distintos. | 2 | Completar el mapeo estado → color/ícono en `f06-trazabilidad.ui.md` y usar el mismo `Badge` en F6, F7 y F9. |
| 6.3 | H7, H2 | La búsqueda solo contempla DNI de 8 dígitos o `PED-YYYY-NNNNN`. Los clientes con CE o pasaporte, o con RUC (factura), no se pueden buscar. | 2 | Reutilizar el selector de documento de F3 (PR `feat/f3-cliente-ui-regex`, pendiente de integración) y detectar el tipo de código automáticamente (un `PED-` va por pedido, 8 dígitos por DNI, etc.). |
| 6.4 | H6 | «Ver en Historial» desde el comprobante debe llevar el `pedidoId` y abrir el detalle directamente. Si solo abre la pantalla vacía, el vendedor tiene que volver a tipear `PED-2026-00412`. | 2 | Navegar a `/pedidos?pedidoId=PED-2026-00412` y abrir el detalle al cargar. |
| 6.5 | H7 | El paso «Solicitar Cambio» desde el detalle no está especificado. Sin él, se rompe el recorrido de la demo y hay que copiar la boleta a mano. | 2 | Botón «Solicitar cambio» en el detalle que navegue a `/cambios?boleta=B001-…` (F9 ya lee ese parámetro). |
| 6.6 | H1 | La spec define bien los estados vacío, sin resultados y cargando (skeletons), pero no el error de red o de G5 caído. | 1 | Agregar el estado de error con «Reintentar», igual que la bandeja de F7. |

**Severidad promedio F6 (diseño): 2.0** (6 hallazgos: 1 mayor, 4 menores, 1 cosmético)

---

## 5. Consolidado y priorización

| Funcionalidad | Hallazgos | Sev. 3 | Sev. 2 | Sev. 1 | Promedio |
|---|:---:|:---:|:---:|:---:|:---:|
| F9 — Cambios y Vales | 9 | 2 | 5 | 2 | 2.0 |
| F7 — Pickup | 7 | 1 | 2 | 4 | 1.6 |
| F6 — Historial (diseño) | 6 | 1 | 4 | 1 | 2.0 |
| **Total** | **22** | **4** | **11** | **7** | **1.9** |

No hubo hallazgos de severidad 4: ninguna de las tres interfaces impide completar su tarea principal.

### Correcciones recomendadas antes de la sustentación (severidad 3)

1. **6.1 — Interceptar la tecla F6** (Kevin): sin `preventDefault()`, el atajo saca al vendedor de la aplicación durante la demo.
2. **9.1 — Confirmar la emisión del vale** (Cristhian): es una acción con valor monetario que hoy es irreversible desde la interfaz.
3. **9.2 — Boleta vs. factura en F9** (Cristhian): alinear la etiqueta con lo que la validación acepta.
4. **7.1 — Documentos de extranjeros en el retiro** (Maylle): aceptar CE y pasaporte, reutilizando `src/lib/documento.ts` de F3 cuando su PR se integre a `develop`.

### Mejoras transversales

- **Una sola regla de documentos.** F3 concentra las reglas de RF-09 en `ValidadorDocumento.java` (backend, rama `feat/f3-cliente-validaciones-regex`) y en `src/lib/documento.ts` (frontend, rama `feat/f3-cliente-ui-regex`). A la fecha de corte ninguno de los dos está integrado a `develop`, donde el frontend aún valida solo DNI y RUC. Una vez integrados, F6, F7 y F9 deberían reutilizarlos en vez de repetir `/^\d{8}$/` en cada pantalla (hallazgos 7.1 y 6.3).
- **Un solo mapeo de estados a colores** para los badges de pedido (hallazgo 6.2).
- **Navegación encadenada para la demo:** comprobante → «Ver en Historial» (`?pedidoId=`) → «Solicitar Cambio» (`?boleta=`). Así el recorrido completo de la sección 4 de la guía toma menos de 60 segundos sin tipear de nuevo (hallazgos 6.4, 6.5 y 9.7).

---

## 6. Referencias

- Nielsen, J. (1994). *10 Usability Heuristics for User Interface Design*. Nielsen Norman Group.
- Nielsen, J. (1994). *Severity Ratings for Usability Problems*. Nielsen Norman Group.
- `specs/f06-trazabilidad-pedidos/f06-trazabilidad.ui.md`, `specs/f07-retiro-tienda-pickup/`, `specs/f09-devoluciones-cambios/`.
- Guía de Trabajo y Repartición Técnica — Semana 11 (Hito 4).
