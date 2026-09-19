# Spec — Búsqueda y Registro Rápido de Clientes (v0.1)

### Responsable: Guillermo (QA / Calidad)
### Requerimientos Funcionales asociados: RF-07, RF-08, RF-09

---

## ¿Por qué? (problema)
En la atención física en tienda, solicitar datos extensos a un comprador detiene la fila en mostrador y provoca abandono de la compra. Si un cliente nuevo no está registrado o no se pueden validar sus datos de forma ágil, no es posible emitir su comprobante de pago electrónico ni acumular su historial.

## ¿Para qué? (objetivo)
Permitir al personal de mostrador buscar en un segundo a un cliente existente por su DNI o RUC, y si no existe, registrarlo con los datos mínimos obligatorios mediante un formulario modal rápido sin abandonar la orden en curso.

## ¿Hasta dónde? (alcance)
* **Incluido:** Búsqueda por documento (DNI de 8 dígitos o RUC de 11 dígitos), autocompletado de datos del cliente en la orden, modal de alta rápida con validación estricta de formato y persistencia en el microservicio de *Seguridad y Usuarios*.
* **Excluido:** Edición del perfil completo del cliente, consulta masiva de clientes, validación contra servicios gubernamentales externos (RENIEC / SUNAT) y gestión de contraseñas de clientes (son gestionadas por el canal Marketplace/Seguridad).

## Referencias
* **Contrato:** [specs/api-contracts.md](file:///c:/Users/Mihae/Programacion/Activos/modulo-retail/specs/api-contracts.md) — `GET /api/v1/clientes?documento={nro}` y `POST /api/v1/clientes`
* **Modelo:** `Cliente` (`id`, `tipoDocumento`, `numeroDocumento`, `nombres`, `apellidos`, `email`, `telefono`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Intermediación con Seguridad y Usuarios)
1. Expone `GET /api/v1/retail/clientes/buscar` para consultar el cliente por documento en *Seguridad y Usuarios*.
2. Si existe, responde `200 OK` con el perfil del cliente.
3. Si no existe, responde `404 Not Found`.
4. Expone `POST /api/v1/retail/clientes/registro-rapido` que reenvía los datos hacia *Seguridad y Usuarios*:
   * Valida que si `tipoDocumento == "DNI"`, `numeroDocumento` contenga exactamente 8 dígitos numéricos.
   * Valida que si `tipoDocumento == "RUC"`, `numeroDocumento` contenga exactamente 11 dígitos numéricos comenzando con 10 o 20.
   * Valida que `nombres`, `apellidos`, `email` y `telefono` no vengan en blanco.
5. Si *Seguridad y Usuarios* responde `201 Created`, retorna el cliente creado con su `id` asignado.
6. Si el documento ya existía al intentar crearlo, responde `409 Conflict`.

### Frontend
1. Campo de entrada de documento en la cabecera del carrito POS con botón de búsqueda y soporte de tecla Enter.
2. Si la búsqueda arroja `200 OK`: Asocia automáticamente al cliente al pedido, mostrando su nombre completo y correo en la tarjeta de resumen.
3. Si la búsqueda arroja `404 Not Found`: Abre automáticamente un modal de *"Nuevo Cliente"* con el número de documento ya precargado.
4. Formulario modal de alta rápida:
   * Tipo documento (selector DNI / RUC).
   * Número de documento (campo numérico con máscara de longitud según tipo).
   * Nombres y Apellidos (o Razón Social).
   * Correo electrónico y Teléfono celular.
5. El botón *"Guardar y Asociar"* permanece deshabilitado hasta que todos los campos requeridos cumplan las reglas de validación.
6. Al guardar exitosamente, cierra el modal, muestra una notificación toast de éxito y asocia al cliente directamente al carrito en curso sin recargar la página.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda con DNI existente → 200 OK y autocompleta nombres y correo en el POS.
- [ ] Búsqueda con DNI inexistente → 404 Not Found y abre modal de registro rápido con el DNI precargado.
- [ ] Registro rápido con datos completos y válidos → 201 Created y el cliente queda asociado al carrito.
- [ ] Registro rápido con DNI de 7 o 9 dígitos → El frontend bloquea el envío y muestra advertencia *"El DNI debe tener 8 dígitos"*.
- [ ] Registro rápido con correo sin formato válido (`@` y dominio) → Validación de frontend impide el envío.
- [ ] Intento de registro con documento duplicado → 409 Conflict y muestra alerta clara: *"El documento ya se encuentra registrado"*.
- [ ] El flujo completo de alta y asociación se realiza en menos de 3 pasos sin perder los productos agregados al carrito.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Depende de que el microservicio de *Seguridad y Usuarios* tenga implementados los endpoints `GET /clientes` y `POST /clientes`.
* Regla de negocio: El número de documento debe ser único en todo el marketplace.
* Supuesto: No se requiere clave ni contraseña para el cliente en este registro rápido presencial de tienda.

## ¿Qué NO hará? (fuera de alcance)
* No valida el DNI contra web services oficiales de RENIEC/SUNAT en esta versión académica.
* No permite cambiar la dirección de domicilio del cliente desde este modal.
* No lista clientes registrados ni permite dar de baja a usuarios.
