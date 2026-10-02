# Spec — RF-07: Búsqueda de Cliente por Documento de Identidad (v0.2)

### Responsable: Guillermo (QA / Calidad)
### Requerimiento Funcional: RF-07: Búsqueda de Cliente por Documento de Identidad
### Funcionalidad Padre: F3: Búsqueda y Registro Rápido de Clientes
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Al momento de atender en caja a un cliente recurrente en la tienda de deportes, volver a pedirle todos sus datos personales (nombres, apellidos, correo, teléfono) detiene la fluidez de la atención, incomoda al comprador y genera errores de digitación en los datos fiscales de emisión del comprobante.

## ¿Para qué? (objetivo)
Permitir al personal de mostrador buscar en un segundo a un cliente ingresando únicamente su número de documento de identidad (DNI de 8 dígitos para personas naturales), autocompletando de forma automática sus datos en la orden de venta activa si el cliente ya existe en el sistema.

## ¿Hasta dónde? (alcance)
* **Incluido:** Campo de búsqueda por documento en la cabecera del módulo POS, consumo del endpoint seguro de consulta de personas (`POST /api/v1/clientes/buscar`) con el token del vendedor autenticado, autocompletado y asociación del cliente encontrado a la orden en curso.
* **Excluido:** Formulario modal de registro cuando el cliente no existe (cubierto en RF-08), validación profunda de reglas de formato y longitud (cubierto en RF-09), y registro directo de RUC para facturas a empresas (gestionado en mostrador directamente hacia el módulo de Ventas).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/clientes/buscar` (Sección 1)
* **Modelo:** `ClienteResumen` (`id`, `tipoDocumento`, `numeroDocumento`, `nombre`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Pasarela a Seguridad y Usuarios)
1. Expone `POST /api/v1/retail/clientes/buscar`:
   * Recibe en el body `{ "tipoDocumento": "DNI", "numeroDocumento": "{nro}" }`.
   * Valida que `numeroDocumento` contenga exactamente 8 dígitos numéricos.
2. Si `tipoDocumento == "DNI"`:
   * Reenvía la petición a *Seguridad y Usuarios* (`POST /api/v1/clientes/buscar` con payload `{ "documento": "{nro}" }`).
   * Propaga obligatoriamente en la cabecera el token Bearer del usuario con rol `VENDEDOR` que opera la terminal.
3. Si el microservicio responde `200 OK`:
   * Recibe el identificador `id`, `nombre` y `documentoEnmascarado`.
   * Retorna el objeto `ClienteResumen` combinando los datos recibidos con el número de documento completo digitado en mostrador.
4. Si el microservicio responde `404 Not Found`:
   * Retorna `404 Not Found` con payload `{ "encontrado": false, "documento": "{nro}", "mensaje": "Cliente no registrado" }`.
5. Si ocurre error de red o timeout (máximo 3 segundos), responde con mensaje amigable sin congelar el backend.

### Frontend
1. Muestra una sección destacada en el POS: *"Identificación del Cliente"*.
2. Selector de tipo de comprobante/cliente:
   * **DNI (Persona Natural):** Campo de texto numérico de 8 dígitos con botón de lupa y soporte de la tecla `Enter`.
   * **RUC (Empresa):** Permite ingresar los 11 dígitos y razón social directamente para emisión de factura en Ventas sin consultar al servicio de usuarios.
3. Al presionar `Enter` o pulsar "Buscar" con DNI:
   * Muestra indicador de carga en el botón.
   * Invoca al endpoint `POST /api/v1/retail/clientes/buscar`.
4. Si la respuesta es `200 OK`:
   * Asocia inmediatamente al cliente con la venta actual.
   * Muestra una tarjeta verde de confirmación con: Nombre Completo y Documento.
   * Muestra botón *"Cambiar Cliente"* por si el vendedor se equivocó de documento.
5. Si la respuesta es `404 Not Found`:
   * Notifica que el cliente no se encuentra registrado y dispara el flujo de alta rápida (RF-08).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda con DNI registrado (ej. `72345678`) → Responde 200 OK en menos de 500 ms y autocompleta el nombre del cliente en la pantalla de venta.
- [ ] La petición hacia Seguridad viaja mediante método POST con el token Bearer del vendedor en los headers.
- [ ] Búsqueda con DNI no existente en base de datos → Responde 404 Not Found de forma controlada y abre opción de alta rápida.
- [ ] Intentar buscar con campo vacío o longitud distinta a 8 dígitos → Frontend bloquea la petición y solicita 8 dígitos exactos.
- [ ] Presionar la tecla Enter dentro del campo de documento ejecuta la búsqueda directamente sin usar el ratón.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe estar autenticado con sesión válida y rol `VENDEDOR`.
* El microservicio de *Seguridad y Usuarios* debe tener operativo el endpoint `POST /api/v1/clientes/buscar`.

## ¿Qué NO hará? (fuera de alcance)
* No consultará padrones externos gubernamentales de RENIEC ni SUNAT en esta versión.
* No consultará RUCs de empresas en el módulo de Seguridad (dominio de facturación de Ventas).
* No listará masivamente la base de datos completa de clientes.
