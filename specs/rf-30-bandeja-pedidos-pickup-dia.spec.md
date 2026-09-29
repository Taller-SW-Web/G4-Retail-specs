# Spec — RF-30: Bandeja de Pedidos Pick-Up del Día en Tienda (v0.1)

### Responsable: Kevin (Frontend / UX)
### Requerimiento Funcional: RF-30: Bandeja de Pedidos Pick-Up del Día en Tienda
### Funcionalidad Padre: F11: Torre de Control Operativa de Turno
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Los clientes que compran por el Marketplace Web o por el Chatbot y eligen "Retiro en Tienda" (Click & Collect) llegan al mostrador esperando una entrega ágil en menos de un minuto. Si el vendedor no tiene una bandeja proactiva que le indique qué paquetes han llegado hoy desde el almacén y en qué anaquel del depósito están ubicados, debe perder minutos buscando a ciegas en el almacén o preguntando a sus compañeros mientras el cliente espera en la fila.

## ¿Para qué? (objetivo)
Implementar una bandeja visual dedicada de **Pedidos Pick-Up del Día**: listando en tiempo real las órdenes omnicanal en estado `LISTO_PARA_RECOJO` asignadas a esa tienda física, mostrando el nombre del cliente, código de tracking, ubicación en anaquel físico (ej. *Anaquel B-04*) y botón de acceso rápido para iniciar el proceso de verificación y entrega física (RF-18 / RF-19).

## ¿Hasta dónde? (alcance)
* **Incluido:** Vista tipo tablero/bandeja con pestañas: *"Pendientes de Hoy"*, *"Arribados Recientemente"*, *"Entregados en el Turno"*; buscador rápido por DNI o código de pedido dentro de la bandeja; indicador de anaquel físico de almacenamiento temporal; y llamada directa al modal de entrega física.
* **Excluido:** Seguimiento de rutas de camiones de despacho (materia del módulo de *Despacho y Entrega*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/despachos/tienda/{id}/pendientes-pickup` (Sección 4)
* **Modelo:** `BultoPickupItem` (`pedidoId`, `codigoTracking`, `clienteNombre`, `clienteDni`, `anaquelUbicacion`, `fechaArribo`, `tiempoEsperaHoras`, `estado`: `"LISTO_PARA_RECOJO"`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Agregación con Despacho)
1. Expone `GET /api/v1/retail/control/pickup-pendientes`:
   * Identifica la tienda asignada al vendedor.
   * Consulta a *Despacho y Entrega* los bultos en estado `LISTO_PARA_RECOJO` con destino a esa sucursal.
   * Filtra y ordena por fecha de arribo más reciente.
2. Retorna la lista formateada para el tablero del mostrador.

### Frontend
1. Pestaña de navegación superior en el POS: *"Retiro en Tienda / Pick-Up"* con badge de paquetes pendientes (ej. `5`).
2. Tablero de control de bultos:
   * Cada pedido se presenta como una tarjeta visual destacando:
     * Nombre completo del cliente y DNI.
     * Código de Orden (ej. `ORD-WEB-2026-8910`).
     * **Ubicación física en tienda:** Chip azul destacado: `📍 Anaquel A-12`.
     * Tiempo de espera: *"Arribó hoy hace 2 horas"*.
3. Acciones en la tarjeta:
   * Botón verde *"Entregar Paquete"*: Abre directamente el modal de verificación de identidad y entrega física (RF-18 / RF-19).
   * Barra de búsqueda rápida: Permite tipear el DNI del cliente que se acerca al mostrador para filtrar la tarjeta correspondiente en tiempo real sin recargar la página.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] La bandeja muestra los paquetes web asignados a esa tienda que están listos para recojo.
- [ ] La tarjeta muestra con claridad el anaquel físico de almacenamiento para que el vendedor ubique el producto rápidamente.
- [ ] Escribir el DNI del cliente en el filtro de la bandeja aísla instantáneamente su tarjeta de pedido.
- [ ] Pulsar "Entregar Paquete" transiciona directamente al flujo de entrega física formal.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Conexión con el microservicio de *Despacho y Entrega*.
* Regla de Negocio RN-03 y RN-05: Protocolo de entrega de mercancía presencial.

## ¿Qué NO hará? (fuera de alcance)
* No genera guías de remisión de transportistas externos.
