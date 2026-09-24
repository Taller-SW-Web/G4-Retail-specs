# Spec — RF-07: Búsqueda de Cliente por Documento de Identidad (v0.1)

### Responsable: Guillermo (QA / Calidad)
### Requerimiento Funcional: RF-07: Búsqueda de Cliente por Documento de Identidad
### Funcionalidad Padre: F3: Búsqueda y Registro Rápido de Clientes
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Al momento de atender en caja a un cliente recurrente en la tienda de deportes, volver a pedirle todos sus datos personales (nombres, apellidos, correo, teléfono) detiene la fluidez de la atención, incomoda al comprador y genera errores de digitación en los datos fiscales de emisión del comprobante.

## ¿Para qué? (objetivo)
Permitir al personal de mostrador buscar en un segundo a un cliente ingresando únicamente su número de documento de identidad (DNI de 8 dígitos o RUC de 11 dígitos), autocompletando de forma automática sus datos en la orden de venta activa si el cliente ya existe en el sistema.

## ¿Hasta dónde? (alcance)
* **Incluido:** Campo de búsqueda por documento en la cabecera del módulo POS, consumo del endpoint de consulta de clientes de *Seguridad y Usuarios* (`GET /api/v1/clientes?documento={nro}`), autocompletado y asociación del cliente encontrado a la orden en curso.
* **Excluido:** Formulario modal de registro cuando el cliente no existe (cubierto en RF-08), validación profunda de reglas de formato y longitud (cubierto en RF-09), y edición de los datos históricos del cliente.

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/clientes?documento={nro}` (Sección 1)
* **Modelo:** `ClienteResumen` (`id`, `tipoDocumento`, `numeroDocumento`, `nombres`, `apellidos`, `email`, `telefono`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Pasarela a Seguridad y Usuarios)
1. Expone `GET /api/v1/retail/clientes/buscar`:
   * Recibe el parámetro `documento` por query string.
   * Valida que no venga vacío.
2. Reenvía la petición a *Seguridad y Usuarios* (`GET /api/v1/clientes?documento={documento}`).
3. Si el microservicio responde `200 OK`:
   * Retorna el objeto `ClienteResumen` con el perfil del comprador.
4. Si el microservicio responde `404 Not Found`:
   * Retorna `404 Not Found` con payload `{ "encontrado": false, "documento": "{documento}", "mensaje": "Cliente no registrado" }`.
5. Si ocurre error de red o timeout (máximo 3 segundos), responde con mensaje amigable sin congelar el backend.

### Frontend
1. Muestra una sección destacada en el POS: *"Identificación del Cliente"*.
2. Selector de tipo: DNI o RUC, acompañado de un campo de texto numérico con botón de lupa y soporte de la tecla `Enter`.
3. Al presionar `Enter` o pulsar "Buscar":
   * Muestra indicador de carga en el botón.
   * Invoca al endpoint de búsqueda.
4. Si la respuesta es `200 OK`:
   * Asocia inmediatamente al cliente con la venta actual.
   * Muestra una tarjeta verde de confirmación con: Nombre Completo, Tipo y N° de Documento, y Correo electrónico.
   * Muestra botón *"Cambiar Cliente"* por si el vendedor se equivocó de documento.
5. Si la respuesta es `404 Not Found`:
   * Notifica que el cliente no se encuentra registrado y dispara el flujo de alta rápida (RF-08).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda con DNI registrado (ej. `72345678`) → Responde 200 OK en menos de 500 ms y autocompleta nombres y correo en la pantalla de venta.
- [ ] Búsqueda con RUC registrado (ej. `20123456789`) → Responde 200 OK y muestra la razón social de la empresa.
- [ ] Búsqueda con documento no existente en base de datos → Responde 404 Not Found de forma controlada.
- [ ] Intentar buscar con campo vacío → El frontend no realiza la petición y solicita digitar el documento.
- [ ] Presionar la tecla Enter dentro del campo de documento ejecuta la búsqueda directamente sin usar el ratón.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe estar autenticado con sesión válida.
* El microservicio de *Seguridad y Usuarios* debe tener operativo el endpoint de consulta por documento.

## ¿Qué NO hará? (fuera de alcance)
* No consultará padrones externos gubernamentales de RENIEC ni SUNAT en esta versión.
* No listará masivamente la base de datos completa de clientes.
