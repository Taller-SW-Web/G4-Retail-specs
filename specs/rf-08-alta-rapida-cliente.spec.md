# Spec — RF-08: Alta Rápida de Cliente en Mostrador (v0.1)

### Responsable: Guillermo (QA / Calidad)
### Requerimiento Funcional: RF-08: Alta Rápida de Cliente en Mostrador
### Funcionalidad Padre: F3: Búsqueda y Registro Rápido de Clientes
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Cuando un cliente compra por primera vez de forma presencial en la tienda deportiva y no se encuentra en el sistema, obligarlo a llenar un formulario engorroso o cambiar de pantalla provoca abandono de la compra y pérdida de los artículos que el vendedor ya había cargado en el carrito de venta asistida.

## ¿Para qué? (objetivo)
Permitir al personal de mostrador dar de alta al nuevo cliente mediante una ventana modal ágil y simplificada con los datos mínimos obligatorios (Documento, Nombres/Razón Social, Apellidos, Teléfono, Correo), persistirlo en *Seguridad y Usuarios* y asociarlo de inmediato a la orden en curso sin perder el contenido del carrito ni recargar la página.

## ¿Hasta dónde? (alcance)
* **Incluido:** Apertura automática o manual de modal de "Nuevo Cliente" ante un documento no registrado, precarga del número de documento digitado en la búsqueda previa, formulario de captura de datos esenciales, envío a `POST /api/v1/clientes`, notificación de éxito y vinculación automática al carrito POS.
* **Excluido:** Búsqueda previa de cliente existente (cubierto en RF-07), validaciones de formato de DNI/RUC (cubierto en RF-09), y asignación de contraseñas de acceso al portal web (el cliente en tienda física no requiere contraseña inmediata).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/clientes` (Sección 1)
* **Modelo:** `ClienteNuevoRequest` (`tipoDocumento`, `numeroDocumento`, `nombres`, `apellidos`, `email`, `telefono`), `Cliente` (`id`, `nombres`, `apellidos`, `email`, `telefono`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Delegación de Alta)
1. Expone `POST /api/v1/retail/clientes/registro-rapido`:
   * Recibe el payload con los datos mínimos del cliente.
   * Valida que los campos obligatorios (`tipoDocumento`, `numeroDocumento`, `nombres`, `email`) no estén vacíos.
2. Invoca al microservicio de *Seguridad y Usuarios* (`POST /api/v1/clientes`).
3. Si la respuesta es `201 Created`:
   * Retorna el objeto del cliente recién creado con su `id` generado por el sistema.
4. Si la respuesta es `409 Conflict` (el documento ya existía por concurrencia):
   * Retorna advertencia clara para recuperar el cliente existente sin generar duplicados.

### Frontend
1. Si la búsqueda de cliente (RF-07) retorna `404 Not Found`, la interfaz despliega automáticamente el modal *"Registrar Nuevo Cliente"*:
   * El campo "Número de Documento" aparece precargado con el valor buscado.
   * El tipo de documento (DNI/RUC) se bloquea o preserva según la selección previa.
2. Campos del formulario modal:
   * Tipo y N° de Documento (de solo lectura o editable).
   * Nombres completos (o Razón Social si es RUC).
   * Apellidos (solo si es DNI).
   * Correo Electrónico (para envío de boleta digital).
   * Teléfono Celular (para avisos de recojo o entrega).
3. Botón de acción: *"Guardar y Asociar a Venta"*.
   * Permanece deshabilitado hasta completar todos los campos obligatorios.
4. Al hacer clic en guardar:
   * Muestra estado de guardado (spinner en botón).
   * Al recibir `201 Created`, cierra el modal automáticamente.
   * Muestra notificación flotante (*toast* verde): *"Cliente registrado y asociado exitosamente"*.
   * El resumen de la venta en curso muestra inmediatamente los datos del nuevo cliente sin alterar los ítems del carrito.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda fallida de DNI `78901234` abre el modal con el campo `78901234` ya escrito.
- [ ] Completar los campos requeridos y guardar → Retorna 201 Created y asocia al cliente al carrito en menos de 2 segundos.
- [ ] Durante todo el proceso de registro, los productos agregados al carrito POS se mantienen intactos.
- [ ] Si se cierra el modal con el botón "Cancelar" o tecla Escape, la orden no se pierde y permite continuar atendiendo.
- [ ] Ante intento de registro duplicado (409 Conflict), el modal muestra alerta: *"El documento ya se encuentra registrado"* y ofrece vincularlo.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe estar autenticado.
* El microservicio de *Seguridad y Usuarios* debe tener operativo el endpoint `POST /clientes`.
* Regla de negocio: No se solicitan contraseñas al cliente en el mostrador físico.

## ¿Qué NO hará? (fuera de alcance)
* No solicitará datos bancarios ni de tarjetas de crédito en el registro del cliente.
* No requerirá confirmación de correo electrónico (*email verification link*) para habilitar la compra presencial inmediata.
