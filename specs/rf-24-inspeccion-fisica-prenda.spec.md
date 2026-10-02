# Spec — RF-24: Inspección Física y Registro de Estado de la Prenda (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-24: Inspección Física y Registro de Estado de la Prenda
### Funcionalidad Padre: F9: Gestión de Cambios y Devoluciones en Mostrador
### Prioridad: Must have (Condicionado a F9)

---

## ¿Por qué? (problema)
En prendas y calzado deportivo no se puede aceptar cualquier producto devuelto: artículos con signos evidentes de uso (zapatillas con suela desgastada o sucia, camisetas lavadas o manchadas de sudor, o sin etiquetas originales) no pueden retornar al inventario. Si no existe un checklist estandarizado y auditable de inspección física en mostrador, el vendedor puede recibir productos no aptos generando pérdidas económicas para la tienda.

## ¿Para qué? (objetivo)
Proveer al vendedor de un checklist interactivo de inspección física antes de aprobar el cambio o devolución en mostrador, verificando el cumplimiento de las condiciones de higiene y estado del producto (etiquetas colgantes intactas, sin olores ni suciedad, suela limpia en calzado, empaque original), registrando el motivo del cambio y el resultado de la evaluación.

## ¿Hasta dónde? (alcance)
* **Incluido:** Checklist digital con 4 criterios excluyentes:
  1. *Etiquetas y marquillas originales intactas*.
  2. *Sin signos de uso, lavado ni manchas*.
  3. *Empaque / caja original en buen estado*.
  4. *Pertenencia al catálogo deportivo de la marca*.
* Registro del motivo de cambio (*"Cambio de talla"*, *"Disconformidad de color/modelo"*, *"Falla de fábrica / Costura"*).
* Si es por falla de fábrica, permite marcar la prenda para derivación a garantía o merma.
* **Excluido:** Peritajes técnicos de laboratorio textil y emisión del vale monetario (cubierto en RF-25).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/retail/postventa/inspeccion-fisica`
* **Modelo:** `InspeccionPrendaRequest` (`pedidoId`, `skuDevuelto`, `motivo`, `etiquetasIntactas`, `sinSignosUso`, `empaqueOriginal`, `observaciones`), `InspeccionPrendaResponse` (`inspeccionId`, `aprobado`, `destinoSugerido`: `"REINGRESO_INVENTARIO" | "MERMA_GARANTIA"`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Microservicio Retail)
1. Expone `POST /api/v1/retail/postventa/inspeccion-fisica`:
   * Recibe el detalle de la inspección física.
   * Evalúa la regla de negocio RN-05:
     * Si `motivo == 'FALLA_FABRICA'`: La exigencia de etiquetas o empaque intacto puede ser flexibilizada según política de garantía.
     * Si `motivo != 'FALLA_FABRICA'` (ej. cambio de talla): Requiere obligatoriamente que `etiquetasIntactas == true` y `sinSignosUso == true`.
   * Determina si la prenda reingresará a la venta en tienda (`REINGRESO_INVENTARIO`) o si se apartará como merma/garantía (`MERMA_GARANTIA`).
2. Retorna `200 OK` con el resultado de aprobación técnica del cambio.

### Frontend
1. Al seleccionar la prenda a cambiar desde la pantalla de validación (RF-23):
   * Se abre el modal *"Inspección de Estado Físico de la Prenda"*.
2. El vendedor selecciona el motivo del cambio:
   * Dropdown: *"Cambio de Talla"*, *"Cambio de Modelo"*, *"Falla de Fábrica / Costura / Suela Despegada"*.
3. Formulario de Checklist interactivo con casillas de verificación (Switches / Checkboxes):
   * `[ ]` ¿Conserva las etiquetas colgantes originales de la marca deportiva?
   * `[ ]` ¿La prenda/calzado está completamente limpio y sin signos de uso deportivo?
   * `[ ]` ¿Cuenta con la caja o bolsa original en condiciones aptas?
4. Si el motivo es *"Cambio de Talla"* y alguna de las casillas críticas no está marcada:
   * El botón *"Aprobar Cambio"* se inhabilita y muestra alerta: *"No procede el cambio comercial si la prenda no cuenta con etiquetas o presenta signos de uso"*.
5. Si el motivo es *"Falla de Fábrica"*:
   * Permite adjuntar observación y habilita el botón con la leyenda *"Aprobar por Garantía de Calidad"*.
6. Botón *"Confirmar Inspección"*: Guarda la evaluación y pasa a la pantalla de resolución (RF-25).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Intentar aprobar cambio de talla con casilla "Etiquetas originales" desmarcada → Frontend bloquea la aprobación y muestra advertencia.
- [ ] Cambio de talla con todas las casillas marcadas → Aprueba la inspección física y sugiere `REINGRESO_INVENTARIO`.
- [ ] Cambio por falla de fábrica con observación detallada → Aprueba por garantía y sugiere `MERMA_GARANTIA`.
- [ ] Registro almacena el ID del vendedor que realizó la inspección física para fines de auditoría.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Haber validado previamente la existencia de la compra original (RF-23).
* Regla de Negocio RN-05: Políticas de calidad e higiene en devoluciones de prendas deportivas.

## ¿Qué NO hará? (fuera de alcance)
* No realiza pruebas químicas ni de laboratorio sobre las prendas en mostrador.
