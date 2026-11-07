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
  * Validación estricta de formatos (RF-09): DNI de 8 dígitos; RUC de 11 dígitos iniciando con 10 o 20; CE de 9 a 12 y pasaporte de 6 a 16 caracteres alfanuméricos; correo válido.
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
> Actualizado en la Semana 11 (Hito 4): reglas homologadas con Ventas (G5) y Seguridad (G7). Se agregan CE y pasaporte, y el RUC solo admite los prefijos `10` y `20`.

| Tipo | Regla | Expresión regular |
|---|---|---|
| `DNI` | Exactamente 8 dígitos numéricos | `^\d{8}$` |
| `RUC` | Exactamente 11 dígitos que empiezan con `10` o `20` | `^(10\|20)\d{9}$` |
| `CE` (carné de extranjería) | 9 a 12 caracteres alfanuméricos | `^[A-Za-z0-9]{9,12}$` |
| `PASAPORTE` | 6 a 16 caracteres alfanuméricos | `^[A-Za-z0-9]{6,16}$` |

* **Backend:**
  1. `ValidadorDocumento` aplica la regla del tipo en `GET` y `POST /api/v1/retail/clientes`, antes de consultar o modificar el padrón.
  2. Un formato inválido o un tipo no admitido responde `400 Bad Request` con `code: "DATO_INVALIDO"` (estándar homologado con G5) y el campo rechazado en `errores[]`.
  3. No se recorta ni se limpia el valor: espacios, guiones, puntos, letras con tilde o dígitos que no sean ASCII 0-9 se rechazan.
  4. CE y pasaporte se normalizan a mayúsculas; el padrón distingue el tipo (un pasaporte puede coincidir en dígitos con un DNI).
  5. Si viene `email`: valida su sintaxis con `^[^\s@.]+(\.[^\s@.]+)*@([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$`. La parte local no admite puntos consecutivos ni en los extremos. El dominio son etiquetas alfanuméricas (guion solo interno) separadas por un único punto, con TLD de al menos 2 letras. Rechaza `rosa@correo..com`, `rosa@.correo.com` o `rosa@correo.c` con `400 PARAMETRO_INVALIDO`.
* **Frontend:**
  1. Selector de tipo `DNI | RUC | CE | Pasaporte`. Las reglas viven en `src/lib/documento.ts`, espejo del backend.
  2. Máscara de caracteres: DNI y RUC solo admiten dígitos 0-9; CE y pasaporte, letras y dígitos (en mayúsculas).
  3. Límites de longitud: `maxlength` 8 (DNI), 11 (RUC), 12 (CE) y 16 (pasaporte).
  4. Validación visual en vivo (*Inline Validation*):
     * Muestra cuántos caracteres faltan mientras se escribe (aviso neutro).
     * Borde verde al completar un documento válido.
     * Borde rojo al salir del campo con el documento incompleto, y de inmediato si el RUC no empieza con 10 o 20.
  5. Validación de email en evento `blur`, con el mismo patrón del backend (`esCorreoValido`).
  6. Botones de búsqueda y guardado permanecen deshabilitados ante cualquier error de validación.
  7. Si el backend responde `400 DATO_INVALIDO`, se muestra el motivo de `errores[0]`.
* **Criterios de Aceptación (RF-09):**
  - [x] Intentar escribir letras en el campo de DNI o RUC no produce ningún caracter.
  - [x] DNI de 7 dígitos mantiene el botón inhabilitado con advertencia de longitud insuficiente.
  - [x] RUC que inicia con "30" (o "15", "17") muestra error inmediato de prefijo no autorizado.
  - [x] CE y pasaporte aceptan letras y respetan sus rangos de longitud.
  - [x] Correo electrónico sin formato válido (por ejemplo `rosa@correo..com`) bloquea el guardado en el modal y el backend lo rechaza con `400`.
  - [x] El backend rechaza cualquier formato inválido con `400 DATO_INVALIDO` (`ClienteValidationTest.java`).

---

## 6. Precondiciones y Dependencias
* Cumplimiento tributario en comprobantes de pago según normativa SUNAT (Regla RN-01).
