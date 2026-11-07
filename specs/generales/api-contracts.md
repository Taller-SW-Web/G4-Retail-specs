# Contrato de API — Módulo Retail (G4) · v0.4

| Campo | Valor |
|---|---|
| Versión | **0.4 — borrador corregido** (reemplaza a v0.3) |
| Estado | Pendiente de aprobación por PO (Mihael) y Tech Lead (Miguel) |
| Responsable | Arquitectura de Software (Maylle) |
| Fecha | 11/10/2026 |
| Base | Specs F1–F12 (fuente de verdad) · Reporte de Consistencia Intermodular (corte 05/10/2026) · Contrato de Despacho G2 · Convenciones de Seguridad G7 · Observaciones de la revisión del pull request de v0.3 |

> **Regla de implementación (Guía Semana 7):** ningún endpoint se programa en backend ni se consume en frontend hasta que figure como **APROBADO** en el [tablero de endpoints](#8-tablero-de-endpoints). Arquitectura notifica a Miguel y Cristhian cada aprobación.

---

## 1. Propósito y alcance

Este documento define **dos superficies de comunicación**:

1. **API propia del backend de Retail** (`ms-retail`), consumida exclusivamente por la SPA del POS. Retail es dueño de su firma.
2. **Integraciones consumidas** por `ms-retail` desde otros módulos. Retail **no** es dueño de esas firmas: las copia de la fuente oficial de cada módulo (G4-P0-04) y no las redefine.

```text
SPA (navegador del POS) ──► ms-retail  /api/v1/retail/*  ──► Seguridad (G7) · Productos (G6) · Ventas y Postventa (G5)
        └──────────────► Seguridad (G7): solo login (con MFA)
```

### 1.1. Límites de responsabilidad

| Módulo | Es dueño de | Retail le pide | Retail nunca hace |
|---|---|---|---|
| **Retail (G4)** | Turnos de caja, movimientos y arqueo, cobros por turno, comprobantes de mostrador y registro local de ventas confirmadas, carritos en espera, inspección y vales comerciales de mostrador, proyección de incidencias, log offline, perfil local del personal | — | — |
| **Seguridad (G7)** | Usuarios, clientes, credenciales, JWT, roles globales | Login, claves públicas (JWKS), búsqueda y alta de clientes | Emitir tokens propios ni guardar contraseñas |
| **Productos y Ofertas (G6)** | Catálogo, precios, promociones, stock (Inventory) | Lecturas comerciales e incidencias de inventario | Consumir, reintegrar o ajustar stock (G4-P0-01, 03, 05) |
| **Ventas y Postventa (G5)** | Pedido central, pago del pedido, garantía y devoluciones con Inventario | Crear pedidos `IN_STORE` con pago, consultar el pedido, sincronizar ventas offline | Crear pedidos centrales paralelos |
| **Despacho (G2)** | Envíos a domicilio | — | Retail no se integra con Despacho (ver §4.4) |

---

## 2. Convenciones comunes

### 2.1. URL y formato

- Prefijo de la API propia: **`/api/v1/retail`**.
- Formato `application/json; charset=UTF-8`; campos en `camelCase`; enumeraciones en `UPPER_SNAKE_CASE`.
- Fechas y horas en ISO 8601 **UTC**; la SPA las muestra en hora de Perú (UTC-5).
- Importes: número con 2 decimales en **PEN**.
- Identificadores: **cadenas opacas**. Ningún cliente infiere información de ellas.

### 2.2. Identificadores canónicos (X-P0-04 y sección 11 del reporte)

| Concepto | Dueño | Campo | Tipo | Ejemplo |
|---|---|---|---|---|
| Tienda | Acuerdo intermodular | `tiendaId` | texto (`store_code`) | `TIENDA-MIRAFLORES` |
| Terminal POS | Retail | `terminalPos` | texto | `POS-01` |
| Usuario (personal) | Seguridad | `usuarioId` (= `sub` del JWT) | UUID en texto | `2f31c1b1-7568-41b8-bf91-342db68431df` |
| Cliente | Seguridad | `clienteId` | texto opaco | `8d4e0c3a-91b2-4f1e-a0c7-5e2b7f6d9a10` |
| Pedido | Ventas | `pedidoId` | texto opaco | `PED-2026-00981` |
| Producto | Productos | `productoId` | texto opaco | `PROD-101` |
| SKU (variante) | Productos | `sku` | texto opaco | `CAM-RUN-M-AZUL` |
| Recursos propios | Retail | `turnoId`, `carritoEsperaId`, `incidenciaId`, … | UUID en texto | `5b0e3f0a-…` |

> Retail **no cambia el tipo** de un identificador ajeno: en base de datos se guardan como `text`, nunca como `UUID` propio (ver §10).

### 2.3. Encabezados

| Encabezado | Uso |
|---|---|
| `Authorization: Bearer <jwt>` | Obligatorio en todos los endpoints salvo `GET /health` |
| `Idempotency-Key: <uuid>` | **Obligatorio** en los comandos marcados con 🔁. Repetir la misma clave con el mismo cuerpo devuelve el resultado original; con un cuerpo distinto responde `409 IDEMPOTENCY_CONFLICT` |
| `X-Correlation-Id: <uuid>` | Opcional; si no llega, el backend lo genera y lo propaga a los demás módulos |
| `Content-Type: application/json` | Cuerpos JSON |

### 2.4. Autenticación y autorización

- El JWT lo emite **Seguridad (RS256)**. `ms-retail` lo valida **localmente** con las claves de `GET /api/v1/auth/.well-known/jwks.json` (en caché) y el emisor publicado en `GET /api/v1/auth/.well-known/openid-configuration`.
- Se exige `tipo=acceso`. El perfil operativo **no viene en el token**: se resuelve con el `sub` en la tabla local de personal de tienda (`RET_PERSONAL_TIENDA`).
- El `tiendaId` y el `usuarioId` se toman **del perfil**, nunca del cuerpo de la petición.

| Perfil local | Puede |
|---|---|
| `VENDEDOR` | Catálogo, clientes, carrito, carritos en espera, venta y cobro, turnos de caja, contingencia offline, pedidos, pickup, cambios, incidencias |
| `SUPERVISOR` | Todo lo anterior + autorizar egresos de caja, actas de merma y excepciones |

> Retail maneja un **único perfil operativo de mostrador: `VENDEDOR`**. La misma persona atiende, vende, cobra y opera la caja; **no existe un perfil `CAJERO`** (D-08).

### 2.5. Errores

Se adopta **`application/problem+json` (RFC 7807)**, el mismo formato de Seguridad (G7) y Despacho (G2). Los clientes deciden por `status` y `code`, nunca por el texto de `detail`.

```json
{
  "type": "https://retail.g4/problemas/stock-insuficiente",
  "title": "Stock insuficiente",
  "status": 409,
  "code": "STOCK_INSUFICIENTE",
  "detail": "No hay existencias suficientes para completar la venta",
  "instance": "/api/v1/retail/ventas",
  "errores": [
    { "campo": "items[0].cantidad", "motivo": "SKU ZAP-RUN-42 (solicitado: 2)" }
  ],
  "correlationId": "35ac19fa-4b25-4a98-bbdd-882234ec1a2c",
  "timestamp": "2026-10-11T15:30:00Z"
}
```

| HTTP | Significado |
|---|---|
| `400` | Formato o validación básica inválida |
| `401` | Token ausente, vencido o con firma inválida (incluye `WWW-Authenticate: Bearer`) |
| `403` | Token válido, pero sin perfil en la tienda o sin el rol requerido |
| `404` | Recurso inexistente |
| `409` | Estado incompatible, duplicado o conflicto de idempotencia |
| `422` | Petición válida pero rechazada por una regla de negocio |
| `429` | Límite de consultas excedido |
| `503` | Un módulo externo no responde (la SPA puede pasar a contingencia, F10) |

### 2.6. Parámetros de consulta y de ruta

Cada parámetro de query o de ruta se documenta con su **ubicación**, **tipo**, **obligatoriedad**, **valor por defecto** y **restricciones**. Tipos usados:

| Tipo | Significado | Ejemplo válido | Ejemplo inválido |
|---|---|---|---|
| `string` | Texto UTF-8 | `POS-01` | — |
| `integer` | Entero de 32 bits en base 10, sin decimales | `20` | `20.5`, `abc` |
| `enum` | Uno de los valores listados, en `UPPER_SNAKE_CASE` | `DNI` | `dni` |
| `uuid` | UUID en texto (36 caracteres) | `5b0e3f0a-6c1d-4d3e-9a2b-1f0c7e8d9a10` | `123` |

Reglas:

- Los documentos (DNI, RUC) se tipan como `string`, nunca como `integer`, para no perder ceros a la izquierda.
- Un parámetro con tipo, formato o rango inválido responde `400 PARAMETRO_INVALIDO`, indicando en `errores[]` el `campo` y el `motivo`.
- Un parámetro obligatorio ausente responde `400 PARAMETRO_OBLIGATORIO`.
- Un parámetro opcional enviado vacío (`?marca=`) se trata como ausente.

### 2.7. Paginación

Las listas paginadas reciben:

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `page` | query | `integer` | No | `0` | ≥ 0 (la primera página es la `0`) |
| `size` | query | `integer` | No | `20` | Entre `1` y `100` |

Y responden `{ "items": [...], "page": 0, "size": 20, "total": 57 }`, donde `page`, `size` y `total` son `integer` e `items` es un arreglo (vacío si no hay resultados).

---

## 3. Mapa general

| F | Funcionalidad | API propia | Integración externa |
|---|---|---|---|
| F1 | Sesión y perfil | §5.1 | Seguridad: login (desde la SPA), JWKS |
| F2 | Catálogo y lector | §5.2 | Productos: catálogo, código de barras, disponibilidad |
| F3 | Clientes | §5.3 | Seguridad: `/usuarios/*` |
| F4 | Carrito y totales | §5.4 | Productos: evaluación de promociones |
| F5 | Venta y cobro | §5.5 | Ventas: pedido `IN_STORE`, cobro, comprobante |
| F6 | Pedidos | §5.6 | Ventas |
| F7 | Pickup | §5.7 | Ventas: bandeja pickup y entrega (decisión #9 resuelta) |
| F8 | Caja | §5.8 | — (datos propios) |
| F9 | Cambios de mostrador | §5.9 | Registro local de ventas confirmadas (F5) |
| F10 | Contingencia offline | §5.10 | Ventas (conciliación) |
| F11 | Alertas | §5.11 | Ventas y Productos |
| F12 | Incidencias | §5.12 | Productos: Inventory incidencias |

---

## 4. Integraciones consumidas (`ms-retail` → otros módulos)

**Reglas:**

1. La firma oficial es la del módulo dueño. Este capítulo solo **referencia** sus rutas; los payloads se copian de su OpenAPI y se versionan aquí.
2. Las llamadas de servidor a servidor usan un **token de servicio** de `modulo-retail`, obtenido con `POST /api/v1/auth/token` (`grant_type=client_credentials`). El `client_secret` vive solo en el servidor.
3. Los adaptadores aplican timeout de 3 s, reintentos con espera creciente y `Idempotency-Key` en los comandos.
4. **Semana 8:** todas estas integraciones se **simulan con mocks** que respetan exactamente la misma firma (ver §6).

**Estado de homologación:** ✅ confirmada en fuente oficial · 🟡 ruta conocida, payload pendiente del OpenAPI del dueño · ⛔ prohibida.

### 4.1. Seguridad y Usuarios (G7)

| Operación | Ruta oficial | Quién llama | Estado |
|---|---|---|---|
| Descubrimiento OpenID | `GET /api/v1/auth/.well-known/openid-configuration` | `ms-retail` | ✅ |
| Claves públicas | `GET /api/v1/auth/.well-known/jwks.json` | `ms-retail` | ✅ |
| Token de servicio | `POST /api/v1/auth/token` (`application/x-www-form-urlencoded`) | `ms-retail` | ✅ |
| Login del personal **con MFA** | `POST /api/v1/auth/login` → si responde `mfaRequerido`, continuar con `challengeToken` (G4-P1-02) | **SPA** | 🟡 ruta de continuación MFA pendiente |
| Introspección (autorización de supervisor) | `POST /api/v1/auth/introspeccion` (scope `tokens:introspeccion`) | `ms-retail` | 🟡 grant pendiente |
| Búsqueda de cliente por DNI | `/usuarios/busqueda-documento` (G4-P1-01) | `ms-retail` | 🟡 payload pendiente |
| Alta rápida de cliente | `/usuarios/clientes` (G4-P1-01) | `ms-retail` | 🟡 payload pendiente |

Notas:
- **Credenciales de servicio:** `ms-retail` envía `grant_type=client_credentials`, `client_id=modulo-retail` y `client_secret` como formulario a `POST /api/v1/auth/token`. El OpenAPI de G7 documenta `scope` opcional, con los valores separados por espacios. La respuesta `200` contiene `accessToken`, `tokenType`, `expiresIn` (segundos) y `scopes` concedidos. El secreto se configura solo en el servidor y el token de servicio viaja como Bearer en la llamada al módulo destino.
- La búsqueda de clientes se hace con el token del vendedor, queda auditada y tiene límite de consultas (`429`); la respuesta enmascara el documento.
- **RUC:** identifica a personas jurídicas y no se consulta en Seguridad. El RUC y la razón social se capturan en la venta (§5.5).

### 4.2. Productos y Ofertas (G6)

| Operación | Ruta oficial (Anexo C del reporte) | Estado |
|---|---|---|
| Catálogo comercial | `GET /api/v1/productos` · `GET /api/v1/productos/{id}` | 🟡 |
| Disponibilidad comercial (sin cantidades) | `GET /api/v1/inventario/disponibilidad/comercial` | 🟡 |
| Resolver código de barras (no asumir código = SKU) | `POST /api/v1/productos/codigos-barras/resolver` | 🟡 |
| Evaluar promociones y cupón | `POST /api/v1/promociones/evaluar` | 🟡 consumidor según protocolo final |
| Reportar y resolver incidencias | `POST /api/v1/inventario/incidencias` y su operación de resolución | 🟡 ruta de resolución pendiente |
| Promociones vigentes del canal (F11) | No figura en el Anexo C | 🟡 confirmar con G6 |

Permisos de `modulo-retail` en `api-productos`: **lecturas comerciales e incidencias (reportar y resolver)**. Nombres exactos de los scopes: pendientes del registro en Seguridad.

| ⛔ Prohibido para Retail | Motivo |
|---|---|
| `/inventario/consumir`, `/inventario/reservas` y su confirmación o liberación | El stock lo orquesta Ventas (G4-P0-01) |
| `/inventario/reintegros` | Lo pide Postventa tras aceptar la devolución (G4-P0-03) |
| `/inventario/conciliaciones-offline` | Lo pide Ventas al registrar la venta offline (G4-P0-02) |
| `/inventario/disponibilidad` (detallada) | No es contrato de canales |
| Cualquier "ajuste de discrepancia" o "incrementar stock" | Inventory es la única fuente de saldos (G4-P0-05) |

### 4.3. Ventas y Postventa (G5)

| Operación | Ruta | Estado |
|---|---|---|
| Crear pedido presencial con `Idempotency-Key` | `POST /api/v1/pedidos` | ✅ Acordado (14-Oct) |
| Registrar el pago aprobado del pedido | Incluido en `POST /api/v1/pedidos` (`canal: RETAIL`, nace `PAGADO`) | ✅ Acordado (14-Oct) |
| Consultar pedido y su historial | `GET /api/v1/pedidos/{id}` | ✅ Acordado (14-Oct) |
| Registrar venta offline | `POST /api/v1/pedidos` (uno a uno con `Idempotency-Key: <ventaLocalUuid>`) | ✅ Acordado (14-Oct) |

**Evidencia externa de Pickup (Semana 11):** se reportó un `200 OK` al consultar directamente `GET /api/v1/pedidos/pickup?tiendaId={tiendaId}` en G5 con un token de servicio emitido por G7. La prueba cubrió la emisión del token y la lectura de la bandeja. La entrega, el flujo desde Retail y el cierre formal de la decisión #9 se verifican por separado.

* **Detalles del Acuerdo de Integración (G4 ↔ G5 — Octubre 2026):**
  1. **Nacimiento de la orden:** En canal `RETAIL`, al realizarse el cobro físico previo en mostrador, el pedido se registra directamente en estado `PAGADO` (no `CREADO`).
  2. **Comprobante de mostrador:** Retail gestiona el correlativo (`B001`/`F001`), el cálculo del IGV (18%) y la generación del ticket térmico de 80 mm. El vínculo comprobante–pedido se guarda en Retail. El DTO de creación publicado por G5 todavía carece de `comprobanteReferencia`.
  3. **Identificadores estándar:** `vendedorId`, `clienteId` y `tiendaId` se manejan como `UUID` v4 canónicos (claims del JWT de Seguridad G7). Identificador oficial de pedido: `PED-YYYY-NNNNN`.
  4. **Idempotencia obligatoria:** Envío permanente del header `Idempotency-Key: <UUID>` en cada creación de pedido.
  5. **Estados oficiales de pedido:** Enum cerrado de Ventas: `CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`.
  6. **Autonomía en cambios:** En Semana 11, Retail valida la boleta de mostrador en su registro local de ventas confirmadas y emite el vale comercial según §5.9. G5 conserva la orden central y atiende la revisión de garantía.

### 4.4. Despacho y Entrega (G2)

**Sin integración.** El contrato de G2 solo atiende a Marketplace, Chatbot y Ventas y cubre entregas a domicilio. Se eliminan los endpoints `pendientes-pickup` y `confirmar-entrega-tienda` de v0.2. El retiro en tienda queda entre Retail y Ventas (decisión #9, resuelta en la Semana 11: el dueño es Ventas; ver §5.7).

---

## 5. API propia del backend de Retail (SPA → `ms-retail`)

Prefijo: `/api/v1/retail`. 🔁 = requiere `Idempotency-Key`. 🟢 = prioridad Semana 8 (happy path).

### 5.1. F1 — Sesión y perfil

#### `GET /api/v1/retail/perfil` 🟢
Devuelve el perfil operativo del usuario autenticado. La SPA lo llama justo después del login.

- **Roles:** cualquier usuario autenticado.
- **200 OK:**
```json
{
  "usuarioId": "2f31c1b1-7568-41b8-bf91-342db68431df",
  "codigoVendedor": "VEND-1042",
  "perfilTienda": "VENDEDOR",
  "tiendaId": "TIENDA-MIRAFLORES",
  "activo": true
}
```
- **Errores:** `401`; `403 FORBIDDEN_USUARIO_SIN_TIENDA` (sin registro activo en la tienda).

#### `GET /api/v1/retail/health`
Heartbeat de la contingencia (F10). **Sin autenticación.**
- **200 OK:** `{ "estado": "UP", "timestamp": "2026-10-11T15:30:00Z" }`

### 5.2. F2 — Catálogo y lector de código de barras

#### `GET /api/v1/retail/catalogo` 🟢
- **Roles:** VENDEDOR, SUPERVISOR.
- **Parámetros** (la tienda sale del perfil):

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `q` | query | `string` | No | — | Texto libre de búsqueda |
| `categoria` | query | `string` | No | — | Ej. `Textil` |
| `disciplina` | query | `string` | No | — | Ej. `Running` |
| `marca` | query | `string` | No | — | Ej. `AeroSport` |
| `page` | query | `integer` | No | `0` | Ver §2.7 |
| `size` | query | `integer` | No | `20` | Ver §2.7 |

- **200 OK** (paginado):
```json
{
  "items": [
    {
      "productoId": "PROD-101",
      "nombre": "Camiseta Deportiva Running Pro",
      "marca": "AeroSport",
      "categoria": "Textil",
      "disciplina": "Running",
      "precio": 129.90,
      "imagenUrl": "https://…/prod-101.jpg",
      "variantes": [
        {
          "sku": "CAM-RUN-M-AZUL",
          "talla": "M",
          "color": "Azul",
          "disponibilidad": "DISPONIBLE",
          "stockTienda": 8,
          "enCuarentena": false
        }
      ]
    }
  ],
  "page": 0, "size": 20, "total": 1
}
```
- `disponibilidad`: `DISPONIBLE` · `ULTIMAS_UNIDADES` · `SOLO_ALMACEN_CENTRAL` · `AGOTADO_TOTAL` (RF-06).
- ⚠️ `stockTienda` es **opcional y puede venir `null`**: Productos no expone cantidades a los canales (X-P0-03). En la Semana 8 lo entrega el mock. La SPA no debe depender de él fuera del mock.
- **Integración:** `GET /productos` + disponibilidad comercial (Productos).

#### `GET /api/v1/retail/catalogo/codigo-barras/{codigo}` 🟢
Lectura prioritaria por escáner (EAN-13 / Code128).
- **Roles:** VENDEDOR, SUPERVISOR.
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `codigo` | ruta | `string` | Sí | — | Solo dígitos, de 8 a 14 (`^\d{8,14}$`). Ej. `7751234567890` |

- **200 OK:**
```json
{
  "codigoBarras": "7751234567890",
  "productoId": "PROD-101",
  "nombre": "Camiseta Deportiva Running Pro",
  "precio": 129.90,
  "variante": { "sku": "CAM-RUN-M-AZUL", "talla": "M", "color": "Azul",
                "disponibilidad": "DISPONIBLE", "stockTienda": 8, "enCuarentena": false }
}
```
- **Errores:** `404 CODIGO_BARRAS_NO_ENCONTRADO`.
- Si `enCuarentena = true`, la SPA bloquea la adición al carrito (RF-33).
- **Integración:** `POST /productos/codigos-barras/resolver` (Productos).

### 5.3. F3 — Clientes

#### `GET /api/v1/retail/clientes` 🟢
Ejemplo: `GET /api/v1/retail/clientes?tipoDocumento=DNI&numeroDocumento=72345678`
- **Roles:** VENDEDOR, SUPERVISOR.
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `tipoDocumento` | query | `enum` | Sí | — | `DNI`, `CE` o `PASAPORTE` |
| `numeroDocumento` | query | `string` | Sí | — | Según el tipo (RF-09): DNI `^\d{8}$`; CE 9 a 12 y pasaporte 6 a 16 caracteres alfanuméricos |

- **Validación (RF-09, Semana 11):** DNI `^\d{8}$`, CE `^[A-Za-z0-9]{9,12}$`, pasaporte `^[A-Za-z0-9]{6,16}$`.
- **RUC excluido de la búsqueda:** `tipoDocumento=RUC` responde `400 DATO_INVALIDO` con el campo `tipoDocumento`, aunque ese RUC se haya registrado con el `POST`. El RUC identifica a una persona jurídica: no se busca en el padrón, se captura con la razón social para la factura.
- **200 OK:**
```json
{
  "clienteId": "8d4e0c3a-91b2-4f1e-a0c7-5e2b7f6d9a10",
  "tipoDocumento": "DNI",
  "nombreCompleto": "Juan Pérez Torres",
  "documentoEnmascarado": "72****78"
}
```
- **Errores:** `400 DATO_INVALIDO` (formato inválido, tipo no admitido o `RUC`; código homologado con G5, el campo va en `errores[]`); `404 CLIENTE_NO_ENCONTRADO` (la SPA abre el alta rápida); `429 LIMITE_CONSULTAS`.
- **Integración:** `/usuarios/busqueda-documento` (Seguridad).

#### `POST /api/v1/retail/clientes` 🟢
- **Roles:** VENDEDOR, SUPERVISOR.
- **Body:**
```json
{
  "tipoDocumento": "DNI",
  "numeroDocumento": "72345678",
  "nombres": "Juan",
  "apellidos": "Pérez Torres",
  "email": "juan.perez@email.com",
  "telefono": "987654321"
}
```
- `tipoDocumento` admite `DNI`, `RUC`, `CE` o `PASAPORTE`, con las reglas de RF-09 (RUC `^(10|20)\d{9}$`). A diferencia del `GET`, el alta sí admite RUC.
- `email` y `telefono` son opcionales; si llega `email`, se valida su formato según RF-09 (dominio con etiquetas separadas por un único punto y TLD de al menos 2 letras; `rosa@correo..com` responde `400 PARAMETRO_INVALIDO`). El backend agrega `canalOrigen = RETAIL`.
- **201 Created:** `{ "clienteId": "…", "nombreCompleto": "Juan Pérez Torres", "estado": "PENDIENTE_ACTIVACION" }`
- **Errores:** `400 DATO_INVALIDO`; `409 DOCUMENTO_DUPLICADO`.
- **Integración:** `/usuarios/clientes` (Seguridad).

### 5.4. F4 — Carrito, totales y carritos en espera

#### `POST /api/v1/retail/carritos/calcular` 🟢
Vista previa de totales y promociones. **No crea nada.** El total oficial lo congela Ventas al crear el pedido (X-P0-05).
- **Roles:** VENDEDOR, SUPERVISOR.
- **Body:** solo SKU y cantidad; el precio lo obtiene el backend, **nunca se confía en el precio enviado por el cliente**.
```json
{ "items": [ { "sku": "CAM-RUN-M-AZUL", "cantidad": 2 } ], "cupon": "VERANO2026" }
```
- **200 OK:**
```json
{
  "lineas": [
    { "sku": "CAM-RUN-M-AZUL", "cantidad": 2, "precioUnitario": 129.90,
      "descuento": 25.98, "precioFinal": 233.82, "promocionAplicada": "10% Cupón VERANO2026" }
  ],
  "subtotalBruto": 259.80,
  "descuentoTotal": 25.98,
  "totalPagar": 233.82,
  "baseImponible": 198.15,
  "montoIgv": 35.67,
  "moneda": "PEN",
  "evaluacionId": "EVAL-7c1f…",
  "advertencias": []
}
```
- **Fórmula (RF-12):** `totalPagar = subtotalBruto − descuentoTotal`; `baseImponible = round(totalPagar / 1.18, 2)`; `montoIgv = totalPagar − baseImponible`.
- Un cupón inválido **no bloquea**: se informa en `advertencias` (`CUPON_INVALIDO`) y no se aplica.
- **Errores:** `400` (carrito vacío o `cantidad ≤ 0`); `404 SKU_NO_ENCONTRADO`.
- **Integración:** `POST /promociones/evaluar` (Productos).

#### Carritos en espera (RF-10)
> En la Semana 8 la SPA los guarda en `localStorage` (spec F4). Estos endpoints sincronizan la bandeja en el servidor y **no reservan stock**.

| Método y ruta | Uso | Respuesta |
|---|---|---|
| `POST /api/v1/retail/carritos-espera` | Pausar la venta | `201` `{ "carritoEsperaId", "fechaExpiracion" }` |
| `GET /api/v1/retail/carritos-espera?estado=SUSPENDIDO` | Bandeja de la tienda | `200` lista |
| `POST /api/v1/retail/carritos-espera/{id}/reanudar` | Cargarlo en el POS (estado `REANUDADO`) | `200` carrito completo |
| `DELETE /api/v1/retail/carritos-espera/{id}` | Descartar | `204`; `404` si no existe |

Body de `POST`:
```json
{
  "aliasTicket": "Probador 3 - Zapatillas Running",
  "clienteId": null,
  "items": [
    { "sku": "ZAP-RUN-41-NEG", "productoId": "PROD-220", "nombreProducto": "Zapatilla Running Pegasus 40",
      "tallaColor": "41 / Negro", "cantidad": 1, "precioUnitario": 299.90 }
  ]
}
```
Estados: `SUSPENDIDO` · `REANUDADO` · `EXPIRADO`.

Parámetros:

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `estado` | query (`GET`) | `enum` | No | `SUSPENDIDO` | `SUSPENDIDO` · `REANUDADO` · `EXPIRADO` |
| `id` | ruta (`reanudar`, `DELETE`) | `uuid` | Sí | — | `carritoEsperaId` devuelto al pausar |

### 5.5. F5 — Venta y cobro

#### `POST /api/v1/retail/ventas` 🟢 🔁
Cierra la venta en mostrador: registra el pedido y el pago en Ventas y devuelve el comprobante de mostrador emitido por Retail. La SPA imprime los datos de esa respuesta.

- **Roles:** VENDEDOR, SUPERVISOR. **Precondición:** turno de caja `ABIERTA` en la terminal.
- **Body:**
```json
{
  "terminalPos": "POS-01",
  "turnoId": "5b0e3f0a-6c1d-4d3e-9a2b-1f0c7e8d9a10",
  "clienteId": "8d4e0c3a-91b2-4f1e-a0c7-5e2b7f6d9a10",
  "items": [ { "sku": "CAM-RUN-M-AZUL", "cantidad": 2 } ],
  "cupon": "VERANO2026",
  "evaluacionId": "EVAL-7c1f…",
  "pago": {
    "medioPago": "EFECTIVO",
    "montoRecibidoEfectivo": 250.00,
    "montoTarjeta": null,
    "referenciaOperacion": null
  },
  "comprobante": { "tipo": "BOLETA", "numeroDocumento": "72345678", "razonSocial": null },
  "emitirTicketRegalo": false
}
```
- **Reglas (RF-13, RF-15):**
  - `EFECTIVO`: `montoRecibidoEfectivo ≥ totalPagar`; `vuelto = montoRecibidoEfectivo − totalPagar`.
  - `TARJETA_POS`: `referenciaOperacion` obligatoria, de al menos 4 caracteres; `vuelto = 0`.
  - `MIXTO`: `montoRecibidoEfectivo + montoTarjeta ≥ totalPagar` y referencia obligatoria.
  - `BOLETA` con total ≥ S/ 700.00: exige DNI y nombre del cliente (sin cliente anónimo).
  - `FACTURA`: exige RUC de 11 dígitos que empiece con 10 o 20 (`^(10|20)\d{9}$`, RF-09), más la razón social.
  - Sin `clienteId` y total < S/ 700.00: boleta a "Clientes varios".
- **Flujo en el backend:**
  1. Valida el turno y recalcula los totales.
  2. Crea el pedido `IN_STORE` en Ventas, con la **misma** `Idempotency-Key`.
  3. El DTO de G5 usa `canal: RETAIL` y responde con el pedido confirmado. El flujo de reserva de G5 omite este canal en la implementación publicada. La coordinación del descuento de stock queda pendiente y fuera de este cambio de F5/F9.
  4. El pedido presencial se registra con el pago incluido (§4.3).
  5. Retail asigna el correlativo durable de ocho dígitos por serie y emite el comprobante de mostrador.
  6. Antes de devolver una venta confirmada, Retail guarda el vínculo entre turno, boleta y pedido central, junto con sus líneas, cantidades e importes pagados, en `RET_VENTA` y su detalle. El registro sirve al arqueo (F8) y a la consulta por boleta (F9).

  Retail **no toca inventario** (G4-P0-01).
- **201 Created:**
```json
{
  "ventaId": "c1a4e8b2-…",
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "PAGADO",
  "pago": { "medioPago": "EFECTIVO", "montoRecibido": 250.00, "vuelto": 16.18 },
  "items": [ { "sku": "CAM-RUN-M-AZUL", "cantidad": 2, "precioFinal": 116.91 } ],
  "comprobante": {
    "tipo": "BOLETA", "serie": "B001", "correlativo": "00045231",
    "subtotal": 198.15, "igv": 35.67, "total": 233.82,
    "fechaEmision": "2026-10-11T15:30:00Z", "qr": "…"
  },
  "ticketRegalo": null
}
```
  Con `emitirTicketRegalo = true`: `"ticketRegalo": { "codigoCanje": "GIFT-2026-09124", "fechaLimiteCambio": "…" }`.
- **Errores:**
  - `400 MONTO_INSUFICIENTE` (indica el faltante) · `400 REFERENCIA_VOUCHER_INVALIDA`.
  - `409 TURNO_NO_ABIERTO` · `409 STOCK_INSUFICIENTE` (reserva rechazada por Ventas/Inventory) · `409 IDEMPOTENCY_CONFLICT`.
  - `422 DNI_OBLIGATORIO` · `422 RUC_INVALIDO`.
  - `503 VENTAS_NO_DISPONIBLE` (si no hay confirmación, se conserva la clave y el cuerpo para reintentar; el POS no emite comprobante).
  - `409 MONTO_TARJETA_DISTINTO` cuando el importe cobrado por el POS físico difiere del total recalculado.
- **Pendiente intermodular (X-P0-02):** si Ventas formaliza el estado "apto para pagar", el paso 4 esperará esa señal antes de registrar el cobro. La firma de este endpoint no cambia.

#### `GET /api/v1/retail/ventas/{ventaId}/comprobante`
Reimpresión del ticket. **Roles:** VENDEDOR, SUPERVISOR. **200** con la misma estructura `comprobante`; **404** `VENTA_NO_ENCONTRADA`.
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `ventaId` | ruta | `uuid` | Sí | — | `ventaId` devuelto por `POST /ventas` |

### 5.6. F6 — Consulta de pedidos

**Corte de alcance del PO (06/11/2026):** Hito 4 / Semana 11 incluye consulta por código y trazabilidad. La búsqueda histórica por DNI/RUC se difiere al siguiente hito como **RF-16-DOC**, con seguimiento en [la spec de F6](../f06-trazabilidad-pedidos/f06-trazabilidad.md#31-pendiente-para-la-planificación-del-siguiente-hito--rf-16-doc) y sus tareas B4/F4. Las firmas siguientes conservan el objetivo completo; `documentoCliente` no está habilitado para la integración de este hito.

**Restricción A10 confirmada por G5 al PO:** `GET /api/v1/pedidos?buscar={DNI_o_RUC}` busca pedidos de cualquier canal y estado, pero solo admite `ADMIN_VENTAS`. El cliente de servicio `modulo-retail` no tiene acceso a ese listado. Para retomarlo, acordar primero con G5 datos visibles, límites y autorización; coordinar con G7 únicamente si el acuerdo exige un permiso nuevo. No asignar `ADMIN_VENTAS` a Retail.

#### `GET /api/v1/retail/pedidos`
Ejemplo del hito actual: `GET /api/v1/retail/pedidos?codigoPedido=PED-2026-00981&page=0&size=20`
- **Roles:** VENDEDOR, SUPERVISOR. Exige al menos un filtro (`400 PARAMETRO_OBLIGATORIO` si no llega ninguno).
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `codigoPedido` | query | `string` | Condicional | — | Identificador opaco de Ventas. Ej. `PED-2026-00981` |
| `documentoCliente` | query | `string` | Condicional | — | **Siguiente hito (RF-16-DOC), pendiente de acuerdo A10.** DNI de 8 dígitos o RUC de 11 (`^(\d{8}\|\d{11})$`) |
| `page` | query | `integer` | No | `0` | Ver §2.7 |
| `size` | query | `integer` | No | `20` | Ver §2.7 |

- **200 OK** (paginado, §2.7): `items` ordenados del más reciente al más antiguo, cada uno con `pedidoId`, `canal`, `fechaCreacion`, `estadoComercial`, `total`.
- **Errores:** `404 PEDIDO_NO_ENCONTRADO`.

#### `GET /api/v1/retail/pedidos/{pedidoId}`
- **Roles:** VENDEDOR, SUPERVISOR.
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `pedidoId` | ruta | `string` | Sí | — | Identificador opaco de Ventas. Ej. `PED-2026-00981` |

- **200 OK:** cabecera, líneas (`sku`, nombre, talla, color, cantidad, precio) e `historialEstados` en orden cronológico ascendente.
- Los estados se separan por dimensión (X-P0-08): `estadoComercial`, `estadoPago`, `modalidad` (`DELIVERY` · `PICKUP` · `IN_STORE`) y `estadoFulfillment`. Los valores exactos son los que publique Ventas.
- **Integración por código:** `GET /api/v1/pedidos/{pedidoId}` de G5 con `ventas:pedidos:consultar`; G5 confirmó el acceso al detalle y su historial. El filtro local por DNI de la bandeja Pickup (§5.7) solo cubre recojos pendientes de la tienda y no sustituye RF-16-DOC. Esta definición de contrato no acredita por sí sola una integración desplegada de F6.

### 5.7. F7 — Retiro en tienda (pickup) · 🟢 integrado con Ventas (G5) en la Semana 11

**Decisión #9 resuelta:** el dueño del pedido pickup y de su estado es **Ventas (G5)**. Retail lee la bandeja de su tienda y le informa la entrega; Ventas hace la transición a `ENTREGADO`. Retail solo verifica en mostrador a quien recoge.

| Método y ruta | Uso |
|---|---|
| `GET /api/v1/retail/pickup/pendientes` | Pedidos listos para recoger en la tienda del perfil |
| `POST /api/v1/retail/pickup/{pedidoId}/entrega` 🔁 | Confirmar la entrega física |

- **Roles:** VENDEDOR, SUPERVISOR.
- **Tienda:** sale del perfil local del vendedor (`RET_PERSONAL_TIENDA`, buscado por el `sub` del JWT), nunca del token ni del cliente. Si el perfil aún guarda la tienda como UUID (D-05), se traduce a su código (`TIENDA-...`) con la tabla `retail.tienda.codigos-por-uuid` (variable `RETAIL_TIENDAS_POR_UUID`). Un UUID sin código **no se adivina**: responde `409 TIENDA_SIN_CODIGO_SUCURSAL`.
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `pedidoId` | ruta (`entrega`) | `string` | Sí | — | Identificador opaco de Ventas. Ej. `PED-2026-00981` |

Body de la entrega:
```json
{ "dniRecoge": "45678912", "nombreRecoge": "María González", "esTerceroAutorizado": false, "codigoRetiro": null, "cartaPoderVerificada": null }
```

| Campo | Tipo | Obligatorio | Regla |
|---|---|:---:|---|
| `dniRecoge` | `string` | Sí | 8 dígitos, digitados por el vendedor desde el documento físico. Si recoge el titular, debe ser el DNI del pedido |
| `nombreRecoge` | `string` | Sí | Máximo 120 caracteres |
| `esTerceroAutorizado` | `boolean` | Sí | `true` si no recoge el titular |
| `cartaPoderVerificada` | `boolean` | Solo si es tercero | El vendedor revisó la carta poder del titular |
| `codigoRetiro` | `string` | No | 6 caracteres `[A-Z0-9]`. Opcional: Ventas no lo valida |

- **200 OK:** `{ "constanciaId": "CONST-PED-2026-00981", "fechaHoraEntrega": "…", "estado": "ENTREGADO" }` (la constancia la emite Ventas).
- **Errores:**
  - `400 PARAMETRO_INVALIDO`: DNI que no tiene 8 dígitos o código de retiro mal formado.
  - `404 PEDIDO_NO_ENCONTRADO`: el pedido no figura en la bandeja de la tienda (no existe, ya se entregó o es de otra tienda).
  - `409 PEDIDO_NO_LISTO_PARA_RECOJO`: el paquete todavía no llega a la tienda.
  - `409 TIENDA_SIN_CODIGO_SUCURSAL` (también en `pendientes`): la tienda del perfil es un UUID sin código de sucursal configurado.
  - `422 DNI_NO_COINCIDE_CON_TITULAR`: recoge el titular pero el DNI no es el del pedido.
  - `422 DNI_TITULAR_NO_REGISTRADO`: recoge el titular pero el pedido llegó sin DNI (`clienteDni: null`); no hay identidad que verificar, así que solo puede recoger un tercero con carta poder.
  - `422 CARTA_PODER_REQUERIDA`: recoge un tercero sin carta poder verificada.
  - `503 VENTAS_NO_DISPONIBLE` · `503 VENTAS_CREDENCIAL_RECHAZADA` · `503 SEGURIDAD_NO_DISPONIBLE`: Ventas o Seguridad no responden; se puede reintentar.
- Se retiran `422 PEDIDO_DE_OTRA_TIENDA` (Ventas filtra por tienda; se responde 404) y `422 CODIGO_RETIRO_INVALIDO` (Ventas no emite códigos de retiro).
- La entrega se informa **solo a Ventas**; Despacho no participa (§4.4).

**Integración consumida (Ventas G5, `https://g5-servicio-ventas.onrender.com`):**

| Retail | Ventas (G5) | Scope del token de servicio |
|---|---|---|
| `GET /retail/pickup/pendientes` | `GET /api/v1/pedidos/pickup?tiendaId={tienda}` | `ventas:pedidos:consultar` |
| `POST /retail/pickup/{id}/entrega` | `POST /api/v1/pedidos/{pedidoId}/entrega-pickup` | `ventas:pedidos:estado` |

- Ambas llamadas llevan `Authorization: Bearer <token de servicio>`. El token lo emite Seguridad (G7) con `client_credentials` (`client_id=modulo-retail`, `audience=api-ventas`) y Retail lo reutiliza hasta un minuto antes de vencer.
- El secreto del cliente solo se configura por la variable de entorno `G7_CLIENT_SECRET`. Sin ella, `ms-retail` usa pedidos de ejemplo en memoria (`retail.integracion.ventas.pickup.modo=auto`).
- A Ventas se le envían solo `dniRecoge`, `nombreRecoge`, `esTerceroAutorizado` y `codigoRetiro`; la carta poder se verifica en Retail.

### 5.8. F8 — Turnos de caja y arqueo ciego

Estados del turno: `ABIERTA` · `CERRADA` · `OBSERVADA` (cerrada con diferencia).

La caja la opera el `VENDEDOR` (no hay perfil `CAJERO`, D-08). En `…/movimientos` y `…/cierre`, el parámetro de ruta `turnoId` es `uuid`, obligatorio, y corresponde al `turnoId` devuelto en la apertura.

#### `POST /api/v1/retail/caja/turnos` 🟢
Apertura con fondo fijo (RF-20).
- **Roles:** VENDEDOR, SUPERVISOR.
- **Body:** `{ "terminalPos": "POS-01", "saldoInicialEfectivo": 200.00 }`, con `saldoInicialEfectivo ≥ 0`.
- **201 Created:** `{ "turnoId": "…", "terminalPos": "POS-01", "estado": "ABIERTA", "fechaHoraApertura": "…", "saldoInicialEfectivo": 200.00 }`.
- **Errores:** `400`; `409 TURNO_YA_ABIERTO` (la terminal ya tiene un turno abierto).

#### `GET /api/v1/retail/caja/turnos/actual` 🟢
Ejemplo: `GET /api/v1/retail/caja/turnos/actual?terminalPos=POS-01`

Recupera el turno abierto tras recargar la página (`cajaStore`). **No muestra ventas ni saldo esperado** (arqueo ciego).
- **Roles:** VENDEDOR, SUPERVISOR.
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `terminalPos` | query | `string` | Sí | — | Código de la terminal. Ej. `POS-01` |

- **200 OK:** `{ "turnoId", "terminalPos", "estado", "fechaHoraApertura", "saldoInicialEfectivo" }`.
- **Errores:** `400 PARAMETRO_OBLIGATORIO` (falta `terminalPos`); `404 SIN_TURNO_ABIERTO`.

#### `POST /api/v1/retail/caja/turnos/{turnoId}/movimientos` 🔁
Ingresos y egresos menores (RF-21).
- **Roles:** VENDEDOR, SUPERVISOR. Un egreso registrado por un VENDEDOR exige la autorización de un SUPERVISOR.
- **Body:**
```json
{
  "tipoMovimiento": "SALIDA_GASTO",
  "monto": 15.00,
  "motivo": "Compra de rollos de papel térmico",
  "autorizacion": { "supervisorToken": "<jwt del supervisor>" }
}
```
- `tipoMovimiento`: `INGRESO_SENCILLO` · `SALIDA_GASTO`. `monto > 0` y `motivo` de al menos 5 caracteres.
- El token del supervisor se valida con la introspección de Seguridad.
- **201 Created:** `{ "movimientoId": "…", "fechaHora": "…" }`. **No devuelve el saldo estimado**, para no romper el arqueo ciego.
- **Errores:** `403 AUTORIZACION_SUPERVISOR_REQUERIDA`; `409 TURNO_NO_ABIERTO`; `422 FONDOS_INSUFICIENTES`.

#### `POST /api/v1/retail/caja/turnos/{turnoId}/cierre`
Cierre con arqueo ciego (RF-22).
- **Roles:** VENDEDOR, SUPERVISOR.
- **Body:** `{ "montoDeclarado": 535.00, "observaciones": "Caja cuadrada sin novedad" }`.
- **Cálculo en el servidor:** `saldoSistema = saldoInicial + ventasEfectivo + ingresos − egresos`; `diferencia = montoDeclarado − saldoSistema`. `ventasEfectivo` sale de los **cobros por turno** que guarda F5.
- **200 OK:**
```json
{
  "turnoId": "…", "saldoInicial": 200.00, "ventasEfectivo": 350.00,
  "ingresos": 0.00, "egresos": 15.00, "saldoSistema": 535.00,
  "saldoDeclarado": 535.00, "diferencia": 0.00, "estado": "CERRADA",
  "fechaHoraCierre": "…", "reporteZUrl": "/api/v1/retail/caja/turnos/…/reporte-z"
}
```
  Si `diferencia ≠ 0`, el estado es `OBSERVADA` y las observaciones son obligatorias.
- **Errores:** `409 TURNO_NO_ABIERTO`; `422 OBSERVACION_OBLIGATORIA`.

### 5.9. F9 — Cambios de prenda en mostrador (Semana 11)

#### `GET /api/v1/retail/cambios/validar/{boletaNumero}`

- **Roles:** VENDEDOR, SUPERVISOR. Tienda resuelta desde el perfil (§2.4).
- **Parámetro:** `boletaNumero`, ruta, texto obligatorio y sin valor por defecto. Formato `^B001-[0-9]{8}$`. Ejemplo: `B001-00000045`.
- Retail recupera la venta de mostrador confirmada desde `RET_VENTA` y sus líneas. El `pedidoId` identifica la orden central de origen. La consulta de F9 se resuelve en Retail.
- El cambio comercial se admite hasta el séptimo día calendario inclusive desde la fecha de compra en la zona horaria de la tienda.
- **200 OK:** devuelve `boletaNumero`, `pedidoId`, `fechaEmision`, `diasTranscurridos`, `plazoDias` (7), `plazoValido` e `items` con `sku`, `descripcion`, `precioPagado`, `cantidadComprada` y `cantidadDisponibleCambio`. La consulta de una boleta vencida devuelve `plazoValido: false` para mostrar el motivo en el POS.
- **Errores:** `400 PARAMETRO_INVALIDO`, `404 COMPROBANTE_NO_ENCONTRADO`, `422 PEDIDO_NO_APTO`.

#### `POST /api/v1/retail/cambios` 🔁

- **Roles:** VENDEDOR, SUPERVISOR. Vendedor y tienda resueltos desde el perfil (§2.4).
- **Body:**

```json
{
  "boletaNumero": "B001-00000045",
  "sku": "CAM-RUN-M-AZUL",
  "cantidad": 1,
  "motivo": "CAMBIO_TALLA",
  "inspeccion": { "etiquetasIntactas": true, "sinSignosUso": true, "empaqueOriginal": true },
  "clienteId": null
}
```

- Los motivos comerciales son `CAMBIO_TALLA` y `CAMBIO_MODELO`. Para cambio de talla se exigen etiquetas intactas y prenda sin signos de uso. El estado del empaque se registra. `clienteId` es opcional para la atención en mostrador. La modalidad del hito es vale comercial. Los casos de falla de fábrica pasan a revisión de garantía en Postventa.
- Revalida el plazo y la cantidad disponible. Registra la inspección en `RET_SOLICITUD_CAMBIO_MOSTRADOR` y emite el vale comercial en `RET_VALE_COMPRA` en una misma transacción. Retail no ajusta stock (G4-P0-03).
- El vale tiene código único `VALE-AAAA-NNNNN`, código de barras y vigencia de 30 días desde su emisión. El monto es el efectivamente pagado por las unidades cambiadas. Los casos cuyo descuento no pueda atribuirse a las unidades quedan pendientes de X-P0-13.
- **201 Created:** devuelve `solicitudId`, `estadoAprobacion` (`APROBADO_EN_TIENDA`), `destinoSugerido`, `observaciones`, `montoAcreditado` y `vale` con `codigoVale`, `monto`, `boletaOrigen`, `fechaEmision`, `fechaVencimiento`, `estado` y `codigoBarras`.
- Aplica la semántica de `Idempotency-Key` de §2.3. Reintentar la misma operación devuelve el vale original y no consume unidades adicionales.
- **Errores:** `400 PARAMETRO_INVALIDO`, `404 COMPROBANTE_NO_ENCONTRADO`, `422 INSPECCION_NO_APTA`, `422 PLAZO_VENCIDO`, `422 PEDIDO_NO_APTO`, `422 CANTIDAD_NO_DISPONIBLE`, `422 MONTO_NO_DETERMINABLE`, `422 GARANTIA_REQUIERE_POSTVENTA`, `409 IDEMPOTENCY_CONFLICT`.

### 5.10. F10 — Contingencia offline

#### `POST /api/v1/retail/contingencia/sincronizar` 🔁 (cada venta es idempotente por `ventaLocalUuid`)
- **Roles:** VENDEDOR, SUPERVISOR. Lote máximo: 50 ventas.
- **Body:**
```json
{
  "terminalPos": "POS-01",
  "turnoId": "5b0e3f0a-…",
  "lote": [
    {
      "ventaLocalUuid": "c3b9e4a1-0001-49b2-8f3c-2d1e0a9b7c65",
      "correlativoContingencia": "CONT-TIENDA01-00012",
      "fechaHoraOffline": "2026-10-11T14:20:00Z",
      "items": [ { "sku": "CAM-RUN-M-AZUL", "cantidad": 1, "precioUnitario": 129.90 } ],
      "totalNeto": 129.90,
      "efectivoRecibido": 150.00,
      "vuelto": 20.10,
      "clienteId": null,
      "hashIntegridad": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    }
  ]
}
```
- **200 OK** (resultado por venta; nunca falla el lote entero por una sola venta):
```json
{
  "totalProcesados": 1,
  "resultados": [
    { "ventaLocalUuid": "c3b9e4a1-…", "estado": "RESINCRONIZADO",
      "pedidoId": "PED-2026-01005", "comprobante": "B001-00045280", "motivo": null }
  ]
}
```
- `estado` por venta: `RESINCRONIZADO` · `DUPLICADO` (ya se había procesado; devuelve el resultado original) · `REQUIERE_REVISION` (conciliación parcial; queda visible para el supervisor) · `RECHAZADO` (hash inválido).
- **Flujo:** Retail registra el log y envía cada venta a Ventas de forma idempotente; Ventas concilia el inventario. **Retail no descuenta stock** (G4-P0-02).

Detalles de implementación F10 S11: el hash canónico, la reserva de comprobante B010 y los casos de revisión se especifican en [F10 §7](../f10-contingencia-offline/f10-contingencia-offline.md#7-criterios-de-integración-de-semana-11). Se conserva la firma del lote. `DUPLICADO` devuelve el pedido y comprobante originales incluso tras reiniciar Retail. Un UUID con cuerpo diferente devuelve `RECHAZADO` con motivo `IDEMPOTENCY_CONFLICT`; sin respuesta verificable de G5 devuelve `REQUIERE_REVISION`, nunca un pedido ficticio. La tienda procede del perfil; se verifica terminal y turno. Los errores de cada venta no abortan las restantes.

### 5.11. F11 — Torre de control (alertas)

| Método y ruta | Contenido | Estado |
|---|---|---|
| `GET /api/v1/retail/control/resumen` | Contadores para el badge (la SPA consulta cada 60 s) | Propuesto |
| `GET /api/v1/retail/control/pickup-pendientes` | Pedidos pickup del día (RF-30) | 🟡 depende de la decisión #9 |
| `GET /api/v1/retail/control/stock-critico` | Variantes agotadas o críticas en tienda (RF-29) | 🟡 depende de X-P0-03 (cantidades) |
| `GET /api/v1/retail/control/campanas-vigentes` | Promociones vigentes del canal `RETAIL` (RF-31), en caché 15 min | 🟡 confirmar ruta con G6 |

### 5.12. F12 — Incidencias de inventario

Estados locales: `EN_CUARENTENA` · `DERIVADO_ALMACEN` · `BAJA_DEFINITIVA` · `PENDIENTE_REPORTE` (Inventory todavía no la aceptó; se reintenta desde el outbox).

#### `POST /api/v1/retail/inventario/incidencias` 🔁
- **Roles:** VENDEDOR, SUPERVISOR, con turno activo.
- **Body:**
```json
{
  "sku": "CAM-PERU-M-BLA",
  "codigoBarras": "7759876543210",
  "tipoFalla": "MANCHADO_PROBADOR",
  "detalleObservacion": "Mancha de maquillaje en el cuello",
  "evidenciaFotoUrl": "https://storage…/inc-01.jpg"
}
```
- `tipoFalla`: `MANCHADO_PROBADOR` · `COSTURA_ROTA` · `EXTRAVIO_NO_UBICADO` · `DEFECTO_FABRICA`. `detalleObservacion` de al menos 5 caracteres.
- **201 Created:** `{ "incidenciaId": "…", "incidenciaInventoryId": "…", "estado": "EN_CUARENTENA", "sku": "CAM-PERU-M-BLA" }`.
- Retail guarda una **proyección local** para la interfaz y la reporta a Inventory, que bloquea la unidad. El saldo central manda (G4-P0-05).

#### `GET /api/v1/retail/inventario/cuarentena`
- **200 OK:** lista de `incidenciaId`, `sku`, `nombreProducto`, `tipoFalla`, `fechaReporte` y `estado` de la tienda del perfil.

#### `POST /api/v1/retail/inventario/actas-merma`
- **Roles:** SUPERVISOR.
- **Body:** `{ "incidenciasIds": ["…"], "tipoDestino": "DEVOLUCION_CENTRAL", "observaciones": "Lote enviado con transporte interno" }`, con `tipoDestino`: `DEVOLUCION_CENTRAL` · `BAJA_DEFINITIVA` · `AJUSTE_PERDIDA`.
- **201 Created:** `{ "actaNumero": "ACTA-MERMA-2026-0012", "totalPrendas": 1, "urlPdf": "…", "incidencias": [ { "incidenciaId": "…", "estado": "DERIVADO_ALMACEN" } ] }`.
- El acta **documenta la salida, pero no cierra el caso**: Inventory resuelve cada incidencia y registra la recepción en el almacén central.
- **Errores:** `400 LISTA_VACIA`; `409 INCIDENCIA_NO_EN_CUARENTENA`.

---

## 6. Mocks de la Semana 8

Para el Hito 3 la entrega se aísla con mocks controlados (Guía Semana 7). Reglas:

1. Cada mock **implementa la misma firma** de la §4. Pasar al módulo real debe ser **solo configuración**: URL base y perfil de Spring `mock`.
2. Los mocks viven en `ms-retail`, detrás de la misma interfaz que el adaptador real.
3. Los datos semilla de los mocks van **separados** de las tablas propias de Retail (prefijo `MOCK_` o archivos de datos). No son datos de Retail (database-per-service).

| Integración | Comportamiento del mock en la Semana 8 | Datos semilla (Angie) |
|---|---|---|
| Seguridad · login | Emula `POST /api/v1/auth/login` con los usuarios semilla y firma con una clave de prueba; la SPA apunta a él por variable de entorno | 2 usuarios (1 vendedor y 1 supervisor) + su perfil en `RET_PERSONAL_TIENDA` |
| Seguridad · clientes | Búsqueda por DNI y alta | 3 a 5 clientes de prueba |
| Productos · catálogo y código de barras | Catálogo, resolución de código de barras, disponibilidad y `stockTienda` | 15 a 20 productos con variantes y código de barras único por SKU |
| Productos · promociones | Evalúa un cupón de prueba (`VERANO2026`) | 1 o 2 promociones |
| Ventas · pedido y cobro | Devuelve `pedidoId` `PED-…` y un comprobante `B001-…` correlativo | — |
| Tienda y terminales | — | `TIENDA-MIRAFLORES`, `POS-01`, `POS-02` |

---

## 7. Decisiones de este contrato (a validar con el PO)

| ID | Decisión | Motivo | Impacto |
|---|---|---|---|
| D-01 | Errores en `application/problem+json` | Mismo formato que Seguridad y Despacho | Actualizar `AGENTS.md` §3.4 y `overview.md` §6 |
| D-02 | El login va de la SPA a Seguridad; en la Semana 8, a su mock | El JWT y el MFA son de Seguridad (G4-P1-02) | Spec F1: el backend ya no expone `/auth/login` y deja de emitir tokens HMAC |
| D-03 | Prefijo único `/api/v1/retail/*` | Evita chocar con las rutas de Productos y Ventas | Specs F2–F8 y la guía (`/productos`, `/ordenes`) |
| D-04 | La venta es una fachada propia que crea el pedido en Ventas | Ventas es dueño del pedido central y orquesta el stock con Productos (G4-P0-01). Retail emite el comprobante de mostrador | F5 mantiene el registro local y el correlativo, sin replicar pedidos centrales ni stock |
| D-05 | `tiendaId` = `store_code` en texto | X-P0-04 | `schema.sql`: `tienda_id` pasa a `text` |
| D-06 | Carritos en espera en `localStorage` en la Semana 8 y en el servidor después | La spec permite ambos | Ninguno para la Semana 8 |
| D-07 | Los estados del turno son `ABIERTA`, `CERRADA` y `OBSERVADA` | Coincide con `schema.sql` | Specs F5 y F8 usan `ABIERTO`; deben corregirse |
| D-08 | Un solo perfil de mostrador: `VENDEDOR`; se elimina `CAJERO` | Observación de la revisión del PR de v0.3: no separar cajero y vendedor | Specs F1 y F8, `schema.sql` y `modelo-datos.md` (`perfil_tienda`), `specs/generales/api-contracts.md` |
| D-09 | Todo parámetro de query y de ruta declara ubicación, tipo, obligatoriedad, valor por defecto y restricciones (§2.6) | Observación de la revisión del PR de v0.3: no se sabía si `size` era entero o texto | Validación en los controladores (`400 PARAMETRO_INVALIDO` / `PARAMETRO_OBLIGATORIO`) y tipado del cliente HTTP en la SPA |

### 7.1. Pendientes intermodulares (no se inventan; se marcan 🟡)

| Tema | Bloquea | Responsable |
|---|---|---|
| Firmas de Ventas `api-ventas.md` 1.4 y Postventa | Payloads de §4.3 | Pedir el contrato a G5 |
| OpenAPI de Seguridad (MFA y `/usuarios/*`) | Payloads de §4.1 | Pedir el contrato a G7 |
| ~~Dueño del Pickup (decisión #9)~~ ✅ Resuelta en S11: Ventas (§5.7) | §5.11 | Retail + Ventas |
| Señal de "apto para pagar" (X-P0-02) | Paso 4 del flujo de §5.5 | Ventas + Productos + canales |
| Validar N unidades sin exponer saldos (X-P0-03) | `stockTienda` y stock crítico | Productos |
| Prorrateo de descuentos (X-P0-13) | `montoAcreditado` de §5.9 | Postventa + Productos + Retail |
| Política intermodular de cambios y garantía (G4-P1-03) | Semana 11 fija 7 días para el cambio comercial de mostrador; la garantía se deriva a Postventa | Retail + Postventa |

---

## 8. Tablero de endpoints

Estados: **PROPUESTO** (redactado, falta aprobación) · **APROBADO** (se puede programar) · **BLOQUEADO** (depende de un pendiente externo).

| Endpoint | F | Semana 8 | Estado | Implementa (Guía S7) |
|---|---|:---:|---|---|
| `GET /retail/perfil` | F1 | 🟢 | PROPUESTO | Cristhian |
| `GET /retail/health` | F10 | 🟢 | PROPUESTO | Cristhian |
| `GET /retail/catalogo` | F2 | 🟢 | PROPUESTO | Cristhian |
| `GET /retail/catalogo/codigo-barras/{codigo}` | F2 | 🟢 | PROPUESTO | Cristhian |
| `GET` / `POST /retail/clientes` | F3 | 🟢 | PROPUESTO | Según la matriz de RF |
| `POST /retail/carritos/calcular` | F4 | 🟢 | PROPUESTO | Según la matriz de RF |
| `POST /retail/ventas` | F5 | 🟢 | APROBADO para Semana 11 (PO) | Retail |
| `GET /retail/ventas/{id}/comprobante` | F5 | 🟢 | PROPUESTO | Miguel |
| `POST /retail/caja/turnos` · `GET …/actual` | F8 | 🟢 | PROPUESTO | Según la matriz de RF |
| `POST …/turnos/{id}/movimientos` · `…/cierre` | F8 | — | PROPUESTO | Según la matriz de RF |
| `/retail/carritos-espera/*` | F4 | — | PROPUESTO | Según la matriz de RF |
| `/retail/pedidos/*` | F6 | — | BLOQUEADO (G5) | Según la matriz de RF |
| `/retail/pickup/*` | F7 | — | PROPUESTO (integrado con G5 en S11) | Maylle |
| `GET /retail/cambios/validar/{boletaNumero}` · `POST /retail/cambios` | F9 | — | APROBADO para Semana 11 (PO). La disponibilidad depende del despliegue y sus migraciones | Cristhian |
| `POST /retail/contingencia/sincronizar` | F10 | — | PROPUESTO | Según la matriz de RF |
| `/retail/control/*` | F11 | — | BLOQUEADO (#9, X-P0-03) | Según la matriz de RF |
| `/retail/inventario/*` | F12 | — | PROPUESTO | Según la matriz de RF |

---

## 9. Trazabilidad con el Reporte de Consistencia Intermodular

| Hallazgo | Cómo lo resuelve este contrato |
|---|---|
| G4-P0-01 | Se elimina `/inventario/consumir`; la venta crea el pedido en Ventas (§5.5) y Ventas orquesta el stock |
| G4-P0-02 | La sincronización offline envía cada `ventaLocalUuid` a Ventas, con resultado por venta y `REQUIERE_REVISION` (§5.10) |
| G4-P0-03 | Retail registra la inspección y emite el vale comercial en mostrador (§5.9). El reintegro corresponde al flujo de Postventa e Inventory. Se elimina `/inventario/incrementar-stock` |
| G4-P0-04 | Las integraciones referencian solo rutas oficiales y no redefinen payloads (§4) |
| G4-P0-05 | Las incidencias se reportan a Inventory; la cuarentena local es una proyección (§5.12). Se elimina `/ajuste-discrepancia` |
| G4-P1-01 | Clientes vía `/usuarios/busqueda-documento` y `/usuarios/clientes` (§4.1, §5.3) |
| G4-P1-02 | Login con challenge MFA directo contra Seguridad (§4.1) |
| G4-P1-03 | `plazoDias` de 7 días para el cambio comercial de mostrador en Semana 11 (§5.9) |
| X-P0-04 | `tiendaId` = `store_code` en texto (§2.2) |
| X-P0-08 | La venta de mostrador es un pedido con modalidad `IN_STORE`; los estados se separan por dimensión (§5.5, §5.6) |
| G5-P0-01 | `Idempotency-Key` obligatorio en la venta y en los comandos críticos (§2.3) |

---

## 10. Artefactos que deben actualizarse para quedar consistentes

| Artefacto | Cambio |
|---|---|
| `diseño/schema.sql` y `modelo-datos.md` | `tienda_id`, `variante_sku_id`, `producto_id` y `pedido_id_origen` pasan a `text`; nueva tabla de cobros por turno; enums `INGRESO_SENCILLO`, `BAJA_DEFINITIVA`, `PENDIENTE_REPORTE` y `REQUIERE_REVISION`; `perfil_tienda` solo admite `VENDEDOR` y `SUPERVISOR` (D-08) |
| Spec y plan F1 | Login contra Seguridad (sin HMAC ni `/auth/login` propio); perfiles `VENDEDOR` y `SUPERVISOR` (sin `CAJERO` ni `SUPERVISOR_TIENDA`, D-08) |
| Spec F8 | La caja la abre, opera y cierra el `VENDEDOR` (sin `CAJERO`, D-08) |
| Specs F2 a F12 | Rutas de esta versión; quitar `RET_STOCK_TIENDA`, `RET_ORDENES`, `RET_PAGOS`, `RET_COMPROBANTES`, `RET_CLIENTES`, `RET_VARIANTES_PRODUCTO` y el nombre anterior `RET_VALES_COMPRA`; F9 usa `RET_VALE_COMPRA` |
| `AGENTS.md` y `overview.md` | Formato de error `problem+json` (D-01) |
| `specs/api-contracts.md` | Era un duplicado de v0.2; ahora solo apunta a este archivo |

---

## 11. Cambios respecto de v0.3

- **Perfil único de mostrador (D-08):** se elimina `CAJERO`; el `VENDEDOR` asume la venta, el cobro, la caja y la contingencia offline. Los perfiles quedan en `VENDEDOR` y `SUPERVISOR` (§2.4) y se actualizan los roles de cada endpoint, el ejemplo de `GET /perfil` y los usuarios semilla de los mocks (§6).
- **Tipado de parámetros (D-09):** nueva §2.6 con los tipos de parámetro y los errores `400 PARAMETRO_INVALIDO` y `400 PARAMETRO_OBLIGATORIO`. La paginación pasa a §2.7 con `page` y `size` como `integer`, sus valores por defecto y el límite `size ≤ 100`.
- **Tablas de parámetros** en `catalogo`, `catalogo/codigo-barras/{codigo}`, `clientes`, `carritos-espera`, `ventas/{ventaId}/comprobante`, `pedidos`, `pedidos/{pedidoId}`, `pickup/{pedidoId}/entrega`, `caja/turnos/actual`, `caja/turnos/{turnoId}/*` y `cambios/validacion`.
- **`GET /pedidos`** pasa a ser paginado (§2.7).

## 12. Cambios respecto de v0.2

- **Eliminados:** `/inventario/consumir`, `/inventario/incrementar-stock`, `/productos/inventario/ajuste-discrepancia` y los dos endpoints de Despacho.
- **Reemplazados por rutas oficiales:** `/clientes/buscar` y `/clientes` (ahora `/usuarios/*`), `/productos/catalogo` (`/productos`), `/ofertas/evaluar-carrito` (`/promociones/evaluar`) y `/ordenes/presenciales` (`POST /pedidos` de Ventas, detrás de `/retail/ventas`).
- **Unificados bajo `/api/v1/retail`:** caja (ahora con el `turnoId` en la ruta), carritos en espera, contingencia e inventario.
- **Agregados:** convenciones, identificadores canónicos, roles por endpoint, `Idempotency-Key`, formato de error, mocks de la Semana 8, tablero de endpoints y las APIs propias de F1, F2, F3, F4, F5, F6, F7, F9 y F11.
- **Arqueo ciego:** la respuesta de movimientos de caja ya no devuelve el saldo estimado.
