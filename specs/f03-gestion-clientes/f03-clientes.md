# Spec — F3: Búsqueda y Registro Rápido de Clientes (v1.0)

### Responsable: Guillermo (QA / Calidad) & Kevin (Frontend Lead)
### Requerimientos Funcionales Incluidos: RF-07, RF-08, RF-09
### Prioridad: Must have (Crítico para Hito 3)

---

## 1. ¿Por qué? (Problema de Negocio)
Para emitir comprobantes de pago válidos en mostrador (boletas con DNI o facturas con RUC) y asociar la compra al comprador:
1. Pedirle todos los datos personales a un cliente recurrente detiene la fluidez de atención en caja.
2. Si el cliente no existe y se le obliga a llenar formularios engorrosos o cambiar de pantalla, se pierde la venta y se borran los ítems ya escaneados en el carrito.
3. Si se permite ingresar documentos con longitudes o formatos inválidos, el sistema falla durante la facturación electrónica ante SUNAT.

---

## 2. ¿Para qué? (Objetivo)
Permitir al personal de mostrador buscar a un cliente en 1 segundo ingresando su número de documento (DNI de 8 dígitos o RUC de 11 dígitos), autocompletar sus datos en la orden activa si existe, o desplegar un modal de alta rápida (*Quick Customer Registration*) con validaciones fiscales estrictas para registrarlo y vincularlo al carrito sin perder los productos escaneados.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Búsqueda por documento (`GET /api/v1/clientes?documento={doc}`).
  * Modal de alta rápida de cliente (`POST /api/v1/clientes`) con captura de datos esenciales.
  * Validación estricta de formatos (DNI: 8 dígitos numéricos; RUC: 11 dígitos iniciando con 10, 15, 17 o 20; correo válido).
  * Máscara numérica en inputs para bloquear letras y caracteres especiales.
  * Vinculación inmediata del cliente a la venta en curso sin recargar la página.
* **Excluido:**
  * Consulta en vivo a pads de RENIEC / SUNAT vía web services de terceros.
  * Asignación de contraseñas de portal web para el cliente.

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `GET /api/v1/clientes`, `POST /api/v1/clientes`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_CLIENTES`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-07"></a>RF-07: Búsqueda de Cliente por Documento de Identidad
* **Backend:**
  1. Expone `GET /api/v1/clientes?documento={nro}`:
     * Valida que el documento sea numérico.
     * Consulta `RET_CLIENTES` (o delega a Seguridad G7 con Bearer token del vendedor).
     * Si existe: retorna `200 OK` con `{ id, tipoDocumento, documento, nombres, apellidos, razonSocial, email, telefono }`.
     * Si no existe: retorna `404 Not Found` con código `CLIENTE_NO_ENCONTRADO`.
* **Frontend:**
  1. Sección *"Identificación del Cliente"* en la cabecera del panel de venta del POS.
  2. Input numérico con selector DNI/RUC y soporte de tecla `Enter`.
  3. Al presionar `Enter` o clic en buscar, realiza la consulta mostrando spinner.
  4. Si existe: asocia al cliente con la venta actual y muestra tarjeta verde de cliente verificado con botón para cambiar cliente.
  5. Si no existe: notifica que no se encuentra registrado y abre automáticamente el modal de alta rápida.
* **Criterios de Aceptación (RF-07):**
  - [ ] Búsqueda con DNI registrado responde 200 OK en < 500 ms y autocompleta los datos en la pantalla de venta.
  - [ ] Búsqueda con DNI no existente responde 404 Not Found y abre la opción de alta rápida.
  - [ ] Presionar la tecla `Enter` dentro del campo de documento ejecuta la búsqueda directamente.
  - [ ] Permite cambiar o desvincular al cliente con un clic si se ingresó un documento equivocado.

---

### <a id="rf-08"></a>RF-08: Alta Rápida de Cliente en Mostrador
* **Backend:**
  1. Expone `POST /api/v1/clientes` recibiendo: `{ tipoDocumento, documento, nombres, apellidos, razonSocial, email, telefono }`.
  2. Valida obligatoriedad de nombres/apellidos (o razón social si es RUC) y datos no vacíos.
  3. Si el documento ya existe: retorna `409 Conflict` (`DOCUMENTO_DUPLICADO`).
  4. Si es válido: persiste y retorna `201 Created` con el ID generado para asociarlo inmediatamente a la orden.
* **Frontend:**
  1. Modal `QuickCustomerModal` desplegado con el número de documento precargado de la búsqueda fallida previa.
  2. Formulario simplificado con campos: Nombres, Apellidos (o Razón Social), Correo Electrónico y Teléfono.
  3. Botón *"Guardar y Asociar a Venta"* con spinner durante la petición.
  4. Al responder 201 Created, cierra el modal, muestra notificación verde (*toast*) y asocia al cliente al carrito activo sin alterar ningún ítem escaneado.
  5. Cerrar el modal o presionar `Escape` no borra el contenido del carrito.
* **Criterios de Aceptación (RF-08):**
  - [ ] Búsqueda fallida de DNI precarga el modal con dicho documento ya escrito.
  - [ ] Guardar datos válidos responde 201 Created y asocia al cliente en menos de 2 segundos.
  - [ ] Durante todo el proceso de registro, los artículos agregados al carrito se mantienen intactos.
  - [ ] Cancelar el modal no pierde la orden y permite continuar atendiendo.

---

### <a id="rf-09"></a>RF-09: Validación Estricta de Formatos de Identificación
* **Backend:**
  1. Si `tipoDocumento == "DNI"`: exige exactamente 8 caracteres numéricos (`^\d{8}$`), rechazando con `400 Bad Request` si no cumple.
  2. Si `tipoDocumento == "RUC"`: exige exactamente 11 dígitos numéricos (`^\d{11}$`) y que inicie con `10`, `15`, `17` o `20`.
  3. Si viene `email`: valida sintaxis estándar con arroba y dominio válido.
* **Frontend:**
  1. Máscara de caracteres en inputs: bloquea el tipeo de letras y caracteres especiales (solo dígitos 0-9).
  2. Límites de longitud: `maxlength="8"` para DNI y `maxlength="11"` para RUC.
  3. Validación visual en vivo (*Inline Validation*):
     * Muestra cuántos dígitos faltan mientras se escribe.
     * Borde verde al completar los dígitos exactos.
     * Borde rojo si el RUC no inicia con 10, 15, 17 o 20.
  4. Validación de email en evento `blur`.
  5. Botones de búsqueda y guardado permanecen deshabilitados ante cualquier error de validación.
* **Criterios de Aceptación (RF-09):**
  - [ ] Intentar escribir letras en el campo de documento no produce ningún caracter.
  - [ ] DNI de 7 dígitos mantiene el botón inhabilitado con advertencia de longitud insuficiente.
  - [ ] RUC que inicia con "30" muestra error inmediato de prefijo no autorizado.
  - [ ] Correo electrónico sin formato válido bloquea el guardado en modal.

---

## 6. Precondiciones y Dependencias
* Cumplimiento tributario en comprobantes de pago según normativa SUNAT (Regla RN-01).
