# Contrato de API — Módulo Retail (G4) · v0.5.7

| Campo | Valor |
|---|---|
| Versión | **0.5.1 — integraciones reales, API Management y mecanismo asíncrono**, con el cierre de las coordinaciones con G5, G6 y G7 del 26/11 (reemplaza a v0.4) |
| Estado | Aprobado por el PO (Mihael) para el Hito 5; las filas 🟡 siguen pendientes de los módulos dueños |
| Responsable | Arquitectura de Software (Maylle) · v0.5: PO e integración (Mihael) |
| Fecha | 26/11/2026 (v0.5) · 11/10/2026 (v0.4) |
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
| **Ventas y Postventa (G5)** | Pedido central, pago del pedido, garantía y devoluciones con Inventario. **No** emite comprobantes fiscales (R6) | Crear pedidos `canal: RETAIL` con pago, consultar el pedido, sincronizar ventas offline | Crear pedidos centrales paralelos |
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


### 2.8. API Management (v0.5)

Retail aplica la capa de API Management en dos sentidos:

- **Lo que expone:** políticas aplicadas dentro de `ms-retail`, como filtros de entrada antes de los controladores.
- **Lo que consume:** a Ventas lo consume a través del API Gateway de G5.

| Política | Dónde | Regla |
|---|---|---|
| **Enrutamiento y versionado** | `ms-retail` | Toda la API propia vive bajo `/api/v1/retail/*`. Una versión incompatible se publica como `/api/v2/retail/*` y convive con la anterior. Cada respuesta lleva `X-Api-Version: v1` |
| **Autenticación** | `ms-retail` | JWT de Seguridad (G7) validado localmente con su JWKS (§2.4). Solo `GET /health`, `/v3/api-docs` y `/swagger-ui` quedan públicos |
| **Límite de peticiones** | `ms-retail` | Ventana por minuto **por vendedor** (el `sub` del JWT) o **por IP** si la petición no trae token. Valor por defecto: `120` peticiones por minuto (`RETAIL_LIMITE_PETICIONES_POR_MINUTO`). Al excederlo responde `429 DEMASIADAS_SOLICITUDES` en el formato de §2.5, con `Retry-After` (segundos). Toda respuesta lleva `X-RateLimit-Limit` y `X-RateLimit-Remaining`. `GET /health` no cuenta |
| **Trazabilidad** | `ms-retail` → G5, G6 y G7 | Se acepta `X-Correlation-Id` **solo si es un UUID** (el gateway de G6 responde `400 VALIDACION` a cualquier otro valor, verificado el 26/11); si no llega o no es UUID, se genera uno. Se devuelve en la respuesta, se escribe en cada línea de log (MDC `correlationId`) y se propaga en cada llamada saliente a otro módulo |
| **Catálogo de la API** | `ms-retail` | OpenAPI publicado en `/v3/api-docs` y Swagger UI en `/swagger-ui.html` |
| **Consumo de Ventas** | API Gateway de G5 | `RETAIL_VENTAS_URL=https://g5-api-gateway.onrender.com`. Las rutas y el token de servicio de §4.3 no cambian. Límite del gateway (confirmado por G5 el 26/11): **300 por minuto por cliente** con el token de `modulo-retail`, sumando todas las cajas; 60 por minuto por IP sin token. Al pasarlo responde `429` con `Retry-After` |
| **Consumo de Productos** | Azure API Management de G6 | `RETAIL_PRODUCTOS_URL=https://apim-g6-productos-chile.azure-api.net/api/v1` y `RETAIL_INVENTARIO_URL` igual (G6, 27/11). El gateway directo anterior responde `403 RBAC: access denied` a todo consumidor. APIM limita las llamadas por cliente: al pasarse responde `429 Rate limit is exceeded` |

Un `429` que venga de otro módulo, por ejemplo el límite de búsquedas de G7, se responde también como `429 DEMASIADAS_SOLICITUDES` y conserva su `Retry-After`.

### 2.9. Mecanismo asíncrono entre microservicios: outbox (v0.5)

Las notificaciones que no deben bloquear al vendedor viajan de forma asíncrona con el patrón **transactional outbox**.

1. **Registro:** el servicio de negocio guarda su cambio y, **en la misma transacción**, un evento en `RET_OUTBOX_EVENTO` con estado `PENDIENTE`. Si el cambio no se confirma, el evento tampoco existe.
2. **Envío:** un job programado de `ms-retail` toma los eventos `PENDIENTE` cuyo `proximoIntento` ya pasó, cada `30 s` (`RETAIL_OUTBOX_INTERVALO_MS`) y en lotes de `20`. Los envía al módulo destino con el token de servicio de `modulo-retail` y `Idempotency-Key: <agregadoId>`.
3. **Resultado:**
   - Una respuesta `2xx` pasa el evento a `ENVIADO`, guarda la `referenciaExterna` que devuelve el destino y publica dentro de `ms-retail` el evento `EventoOutboxEnviado`, que el dueño del agregado usa para actualizar su estado.
   - Un error transitorio (sin respuesta, timeout, `408`, `429` o `5xx`) suma un intento y reprograma el envío con espera creciente: `30 s × 2^(intentos−1)`, con un tope de `1 h`.
   - Al llegar a `10` intentos (`RETAIL_OUTBOX_MAX_INTENTOS`), o ante un rechazo definitivo (`400`, `401`, `403`, `404`, `409` o `422`), el evento pasa a `FALLIDO` con el `ultimoError`. Queda visible para su revisión y no se reintenta solo.
4. **Idempotencia:** el destino recibe la misma `Idempotency-Key` en cada reintento, así que un reenvío después de un timeout no duplica el registro.

| Campo de `RET_OUTBOX_EVENTO` | Tipo | Uso |
|---|---|---|
| `id` | UUID | Identificador del evento |
| `tipo_evento` | texto | `INCIDENCIA_INVENTARIO_REPORTADA` (F12). Se pueden sumar más tipos |
| `agregado_id` | texto | Id del recurso de Retail (`incidenciaId`); es también la `Idempotency-Key` |
| `destino` | texto | `PRODUCTOS_G6` |
| `payload` | texto JSON | Cuerpo exacto que se envía |
| `estado` | texto | `PENDIENTE` · `ENVIADO` · `FALLIDO` |
| `intentos`, `proximo_intento`, `ultimo_error` | int, timestamptz, texto | Control de reintentos |
| `referencia_externa` | texto | Id que devuelve el destino (`incidenciaInventoryId`) |
| `creado_en`, `enviado_en` | timestamptz | Auditoría |

**Primer flujo asíncrono real:** el reporte de incidencias de F12 a Inventory (G6), descrito en §5.12. Mientras G6 confirma la ruta, el destino es el mock del perfil `mock` (§6). Pasar al real es solo configuración (`RETAIL_INVENTARIO_URL`).

---

## 3. Mapa general

| F | Funcionalidad | API propia | Integración externa |
|---|---|---|---|
| F1 | Sesión y perfil | §5.1 | Seguridad: login (desde la SPA), JWKS |
| F2 | Catálogo y lector | §5.2 | Productos: catálogo, código de barras, disponibilidad |
| F3 | Clientes | §5.3 | Seguridad: `/usuarios/*` |
| F4 | Carrito y totales | §5.4 | Productos: evaluación de promociones |
| F5 | Venta y cobro | §5.5 | Ventas: pedido `canal: RETAIL` con el pago incluido. El comprobante lo emite Retail (R6) |
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
| Búsqueda de cliente por documento | `POST /api/v1/usuarios/busqueda-documento` (G4-P1-01, A7) | `ms-retail` con el **token del vendedor** | ✅ OpenAPI de G7 |
| Alta rápida de cliente (registro asistido) | `POST /api/v1/usuarios/clientes` (G4-P1-01, A6) | `ms-retail` con el **token del vendedor** | ✅ OpenAPI de G7 |

Notas:
- **Credenciales de servicio:** `ms-retail` envía `grant_type=client_credentials`, `client_id=modulo-retail` y `client_secret` como formulario a `POST /api/v1/auth/token`. El OpenAPI de G7 documenta `scope` opcional, con los valores separados por espacios. La respuesta `200` contiene `accessToken`, `tokenType`, `expiresIn` (segundos) y `scopes` concedidos. El secreto se configura solo en el servidor y el token de servicio viaja como Bearer en la llamada al módulo destino.
- La búsqueda de clientes se hace con el token del vendedor, queda auditada y tiene límite de consultas (`429`); la respuesta enmascara el documento.
- **RUC:** identifica a personas jurídicas y no se consulta en Seguridad. El RUC y la razón social se capturan en la venta (§5.5).

**Payloads de `/usuarios/*` (copiados del OpenAPI de G7, v0.5):**

| Operación | Request | Respuesta | Errores |
|---|---|---|---|
| `POST /usuarios/busqueda-documento` | `{ "tipoDocumento": "DNI", "numeroDocumento": "45781234" }`; `tipoDocumento` ∈ `DNI` · `CE` · `PASAPORTE` (sin `RUC`) | `200 { "id": "<uuid>", "nombreCompleto": "María Quispe Rojas", "documentoEnmascarado": "*****234", "estado": "ACTIVO" }`; `estado` ∈ `ACTIVO` · `PENDIENTE_VERIFICACION` | `404` inexistente · `403` sin `cliente.buscar` o con token de servicio · `429 DEMASIADAS_SOLICITUDES` con `Retry-After` (60 búsquedas por hora y vendedor) |
| `POST /usuarios/clientes` | `{ "correo", "nombres", "apellidos", "celular"?, "tipoDocumento"?, "numeroDocumento"? }`; `celular` con patrón `^\+51[0-9]{9}$` | `201 { "id": "<uuid>", "estado": "PENDIENTE_VERIFICACION" }` | `409 CORREO_NO_DISPONIBLE` · `409 DOCUMENTO_NO_DISPONIBLE` (buscarlo por documento) · `403` sin `cliente.registrar` |

- Ambas exigen un **token de usuario** con el permiso del rol `VENDEDOR` de G7 (`cliente.buscar` y `cliente.registrar`). `ms-retail` reenvía el `Authorization` del vendedor; **no** usa el token de servicio (G7 responde `403`).
- `ms-retail` traduce el `429` de G7 a su propio `429 DEMASIADAS_SOLICITUDES` y conserva el `Retry-After` (§2.8).
- **G7 (26/11):** el rol `VENDEDOR` ya tiene `cliente.buscar` y `cliente.registrar` en su catálogo. 🟡 Falta que G7 confirme que las dos rutas están disponibles en Render para probarlas con el token del vendedor.

### 4.2. Productos y Ofertas (G6)

**URL base (v0.5.7):** `https://apim-g6-productos-chile.azure-api.net/api/v1`, a través del Azure API Management de G6 (desde el 27/11; antes `https://api-gateway.calmgrass-aec0b33c.chilecentral.azurecontainerapps.io/api/v1`, que ya no acepta tráfico externo). No pide clave de suscripción. Cada llamada lleva `Authorization: Bearer <JWT de servicio de G7>` con identidad `modulo-retail`, audiencia `api-productos` y el scope de la operación.

| Operación | Ruta oficial (Anexo C del reporte) | Estado |
|---|---|---|
| Catálogo comercial | `GET /api/v1/productos?canal=RETAIL` (paginación desde `1`, sin precios) · variantes desde el detalle `GET /api/v1/productos/{id}?canal=RETAIL` (campo `variants`). **No** se usa `GET /productos/{id}/variantes`: solo acepta tokens de usuario y responde `403 SCOPE_INSUFICIENTE` al token de servicio · nombres de marca y categoría con `GET /api/v1/marcas` y `GET /api/v1/categorias` | ✅ OpenAPI de G6 · ✅ probado contra G6 real el 26/11 |
| Formato de atributos | `valor` puede ser de cualquier tipo. Talla y color llegan como `{ "nombre": "S", "valor_id": "…" }`: Retail muestra `nombre` | ✅ Probado contra G6 real el 26/11 |
| Precio vigente de un SKU | `GET /api/v1/precios/skus/{sku}` (scope `precios:leer`) | ✅ OpenAPI de G6 |
| Disponibilidad comercial (sin cantidades) | `GET /api/v1/inventario/disponibilidad/comercial?skus=…&canal=RETAIL` (hasta 100 SKU, scope `inventario:disponibilidad:leer`) | ✅ OpenAPI de G6. `INDETERMINADO` **no** equivale a `AGOTADO` (G6, 26/11) |
| Resolver código de barras (no asumir código = SKU) | `POST /api/v1/productos/codigos-barras/resolver` (devuelve solo el `sku`) | ✅ OpenAPI de G6 |
| Evaluar promociones y cupón | `POST /api/v1/promociones/evaluar` (scope `promociones:evaluar`) · `POST /api/v1/cupones/validar` (scope `cupones:validar`) | ✅ OpenAPI de G6 |
| Reportar incidencias (asíncrono, desde el outbox, §2.9) | `POST /api/v1/inventario/incidencias` (scope `inventario:incidencias:reportar`) | ✅ OpenAPI de G6 (`x-allowed-client-ids: modulo-retail`); mapeo de `type` aprobado por G6 · 🟡 `location_id` de cada tienda (G6 lo confirma con la lista de códigos de tienda de Retail) |
| Resolver incidencias (RF-34) | `POST /api/v1/inventario/incidencias/{incidenciaId}/resolver` (scope `inventario:incidencias:resolver`) | ✅ OpenAPI de G6 |
| Promociones vigentes del canal (F11) | `GET /api/v1/promociones?canal=RETAIL&vigentes=true` (scope `promociones:leer`) | ✅ OpenAPI de G6 |
| Stock crítico por tienda (F11, X-P0-03) | Se deriva de `STOCK_BAJO` y `AGOTADO` de la disponibilidad comercial. `GET /inventario/alertas` sigue siendo administrativo (JWT de usuario) y G6 no lo abre en M2M | ✅ Decisión con G6 (26/11): se usan los estados comerciales. El umbral de `STOCK_BAJO` lo define G6 y no necesariamente es ≤ 2 unidades |

Permisos de `modulo-retail` en `api-productos` (JWT de servicio, `client_credentials`), aprobados por G6 el 26/11: `catalogo:leer`, `precios:leer`, `inventario:disponibilidad:leer`, `promociones:leer`, `promociones:evaluar`, `cupones:validar`, `inventario:incidencias:reportar` e `inventario:incidencias:resolver` (estos dos, exclusivos de `modulo-retail`). `combos:leer` y `recomendaciones:leer` quedan disponibles si Retail llega a usarlos. G6 delegó el trámite en Retail. **G7 los asignó a `modulo-retail` el 26/11.** 🟡 Falta verificar un token nuevo con audiencia `api-productos` y esos scopes.

| ⛔ Prohibido para Retail | Motivo |
|---|---|
| `/inventario/consumir`, `/inventario/reservas` y su confirmación o liberación | El stock lo orquesta Ventas (G4-P0-01). G6 lo ratificó el 26/11: Retail → Ventas → reserva en G6 → confirmación (asíncrona) → consumo |
| `/inventario/reintegros` | Lo pide Postventa tras aceptar la devolución (G4-P0-03). G6 no lo amplía a `modulo-retail` (26/11), tampoco para el cambio directo de F9 |
| `/inventario/conciliaciones-offline` | Lo pide Ventas al registrar la venta offline (G4-P0-02) |
| `/inventario/disponibilidad` en su vista detallada (con saldos por almacén) | No es contrato de canales |
| Cualquier "ajuste de discrepancia" o "incrementar stock" | Inventory es la única fuente de saldos (G4-P0-05) |

### 4.3. Ventas y Postventa (G5)

**URL base (v0.5):** `ms-retail` consume Ventas **a través del API Gateway de G5** (`https://g5-api-gateway.onrender.com`), configurable con `RETAIL_VENTAS_URL`. Las rutas no cambian. Límite: 300 peticiones por minuto para `modulo-retail` (§2.8).

| Operación | Ruta | Estado |
|---|---|---|
| Crear pedido presencial con `Idempotency-Key` | `POST /api/v1/pedidos` | ✅ Acordado (14-Oct) |
| Registrar el pago aprobado del pedido | Incluido en `POST /api/v1/pedidos` (`canal: RETAIL`, nace `PAGADO`) | ✅ Acordado (14-Oct) |
| Consultar pedido y su historial | `GET /api/v1/pedidos/{id}` | ✅ Acordado (14-Oct) |
| Registrar venta offline | `POST /api/v1/pedidos` (uno a uno con `Idempotency-Key: <ventaLocalUuid>`) | ✅ Acordado (14-Oct) |
| Buscar pedidos por DNI, RUC o código (RF-16-DOC) | `GET /api/v1/pedidos?buscar={DNI, RUC o PED-…}` (scope `ventas:pedidos:buscar-documento`). Solo devuelve pedidos `RETAIL` y de recojo en tienda. Cada resultado trae `pedidoId`, `canal`, `estado`, `total`, `moneda`, `fechaCreacion` y `nombreCliente` | ✅ Acordado con G5 (26/11) · 🟡 G7 asigna el scope cuando G5 publique la ruta |
| Pedido de un cambio de prenda (F9) | `POST /api/v1/pedidos` con `metodoPago: CREDITO_CAMBIO` (§5.9) | ✅ Acordado con G5 (26/11) · 🟡 G5 lo publica tras su revisión |

**Stock de los pedidos `RETAIL` (26/11, reemplaza el acuerdo R9):** Ventas reserva y confirma el consumo en Productos para todos los pedidos `RETAIL`, incluidos los offline. El pedido sigue naciendo `PAGADO`. Si Productos no recibe la reserva, Ventas responde `503` y Retail reintenta con la **misma** `Idempotency-Key` (como en §5.5 y §5.10).

**Evidencia externa de Pickup (Semana 11):** se reportó un `200 OK` al consultar directamente `GET /api/v1/pedidos/pickup?tiendaId={tiendaId}` en G5 con un token de servicio emitido por G7. La prueba cubrió la emisión del token y la lectura de la bandeja. La entrega, el flujo desde Retail y el cierre formal de la decisión #9 se verifican por separado.

* **Detalles del Acuerdo de Integración (G4 ↔ G5 — Octubre 2026):**
  1. **Nacimiento de la orden:** En canal `RETAIL`, al realizarse el cobro físico previo en mostrador, el pedido se registra directamente en estado `PAGADO` (no `CREADO`).
  2. **Comprobante de mostrador:** Retail gestiona el correlativo (`B001`/`F001`), el cálculo del IGV (18%) y la generación del ticket térmico de 80 mm. El vínculo comprobante–pedido se guarda en Retail. La boleta, la factura y las notas de crédito o vales son **solo de Retail**; Ventas no emite ni guarda comprobantes (acuerdo R6 de G5). El número de comprobante puede viajar en `pago.comprobanteReferencia` solo como dato de consulta (R11).
  3. **Identificadores estándar:** `vendedorId` y `clienteId` se manejan como `UUID` v4 canónicos (`sub` del JWT de Seguridad G7). `tiendaId` es el código de sucursal en texto (`TIENDA-MIRAFLORES`, D-05). Identificador oficial de pedido: `PED-YYYY-NNNNN`.
  4. **Idempotencia obligatoria:** Envío permanente del header `Idempotency-Key: <UUID>` en cada creación de pedido.
  5. **Estados oficiales de pedido:** Enum cerrado de Ventas: `CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`.
  6. **Autonomía en cambios:** Retail valida la boleta de mostrador en su registro local de ventas confirmadas y resuelve el cambio directo según §5.9 (R6). G5 conserva la orden central y atiende la revisión de garantía. En un cambio de mayor valor, Retail crea un pedido nuevo con las prendas nuevas.

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
- **Rendimiento (v0.5.6):** con G6 real cada detalle de producto tarda ~1,4 s y el POS pide el catálogo completo al entrar (`size=100`). Retail no hace esperar al vendedor:
  - pide las variantes de la página y los tramos de disponibilidad **en paralelo** (máximo `RETAIL_PRODUCTOS_PARALELISMO`, 4 por defecto desde v0.5.7, llamadas simultáneas a G6);
  - pide los **precios en lote** con `GET /precios?skus=a,b&canal=RETAIL` (hasta 100 SKU por llamada), no uno por SKU (v0.5.7): uno por SKU eran ~200 llamadas por catálogo y el APIM de G6 las corta con `429`;
  - guarda las variantes 6 horas en caché (`RETAIL_PRODUCTOS_CACHE_VARIANTES_SEGUNDOS`), porque casi no cambian;
  - **precalienta** el catálogo con esa misma paginación al arrancar y cada 4 minutos;
  - sirve la lista, las variantes y la disponibilidad **desde caché aunque hayan vencido** (hasta 30 minutos) mientras las refresca en segundo plano. La `disponibilidad` del catálogo puede tener unos minutos de antigüedad; la venta la confirma Ventas (G5) al reservar el stock.
  - Objetivo: respuesta en milisegundos con caché caliente; en frío, el catálogo completo en ~10 s.

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
- **Cuarentena (F12, RF-33):** si algún SKU tiene una incidencia activa (`PENDIENTE_REPORTE` o `EN_CUARENTENA`) en la tienda del perfil, responde `422 SKU_EN_CUARENTENA` con el detalle *"PRODUCTO BLOQUEADO POR CUARENTENA"* y los SKU bloqueados. Es el respaldo del bloqueo que la SPA ya aplica con `enCuarentena` (§5.2).
- **Errores:** `400` (carrito vacío o `cantidad ≤ 0`); `404 SKU_NO_ENCONTRADO`; `422 SKU_EN_CUARENTENA`.
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

**Restricción A10 confirmada por G5 al PO:** `GET /api/v1/pedidos?buscar={DNI_o_RUC}` busca pedidos de cualquier canal y estado, pero solo admite `ADMIN_VENTAS`. El cliente de servicio `modulo-retail` no tiene acceso a ese listado. No asignar `ADMIN_VENTAS` a Retail.

**Acuerdo con G5 (26/11, RF-16-DOC):** G5 habilita `GET /api/v1/pedidos?buscar={documento}` con el scope `ventas:pedidos:buscar-documento`, limitado a pedidos `RETAIL` y de recojo en tienda (§4.3). Es la sección 1.4c del [contrato de Ventas de G5](https://github.com/Taller-SW-Web/G5-Ventas-Postventas/blob/main/specs/api/api-ventas.md). Retail le pasa el `documentoCliente` en `buscar`, pide páginas de 50 (`pagina`, `tamano`, el máximo de G5) hasta `totalPaginas` (tope de 10 páginas) y toma de cada elemento de `contenido` `pedidoId`, `canal`, `fechaCreacion`, `estado` (→ `estadoComercial`) y `total`. El detalle sigue saliendo de `GET /api/v1/pedidos/{id}`.

- **Activación por configuración:** `RETAIL_PEDIDOS_BUSQUEDA_DOCUMENTO=g5`. Mientras G7 no asigne el scope, el valor por defecto `registro` sigue buscando solo en las ventas de este mostrador (comportamiento del Hito 4).
- Con `g5`: si G5 responde `401` o `403`, se responde `503 VENTAS_CREDENCIAL_RECHAZADA`; una caída o un `5xx`, `503 VENTAS_NO_DISPONIBLE`; sin resultados, `404 PEDIDO_NO_ENCONTRADO`.

#### `GET /api/v1/retail/pedidos`
Ejemplo del hito actual: `GET /api/v1/retail/pedidos?codigoPedido=PED-2026-00981&page=0&size=20`
- **Roles:** VENDEDOR, SUPERVISOR. Exige al menos un filtro (`400 PARAMETRO_OBLIGATORIO` si no llega ninguno).
- **Parámetros:**

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `codigoPedido` | query | `string` | Condicional | — | Identificador opaco de Ventas. Ej. `PED-2026-00981` |
| `documentoCliente` | query | `string` | Condicional | — | RF-16-DOC (v0.5.2). DNI de 8 dígitos o RUC de 11 (`^(\d{8}\|\d{11})$`) |
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

**Integración consumida (Ventas G5, por su API Gateway `https://g5-api-gateway.onrender.com`; antes `g5-servicio-ventas.onrender.com`):**

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

### 5.9. F9 — Cambio directo de prenda en mostrador (Semana 14)

> **Semana 14 (decisión del PO, 25/11/2026):** el vale comercial de la Semana 11 se reemplaza por el cambio directo. `RET_VALE_COMPRA` queda en desuso y el POS deja de emitir vales. Retail es dueño del cambio de mostrador (acuerdo R6 con G5).

#### `GET /api/v1/retail/cambios/validar/{boletaNumero}`

- **Roles:** VENDEDOR, SUPERVISOR. Tienda resuelta desde el perfil (§2.4).
- **Parámetro:** `boletaNumero`, ruta, texto obligatorio y sin valor por defecto. Formato `^B001-[0-9]{8}$`. Ejemplo: `B001-00000045`.
- Retail recupera la venta de mostrador confirmada desde `RET_VENTA` y sus líneas. El `pedidoId` identifica la orden central de origen. La consulta de F9 se resuelve en Retail.
- El cambio comercial se admite hasta el séptimo día calendario inclusive desde la fecha de compra en la zona horaria de la tienda.
- **200 OK:** devuelve `boletaNumero`, `pedidoId`, `fechaEmision`, `diasTranscurridos`, `plazoDias` (7), `plazoValido` e `items` con `sku`, `descripcion`, `precioPagado`, `cantidadComprada` y `cantidadDisponibleCambio`. La consulta de una boleta vencida devuelve `plazoValido: false` para mostrar el motivo en el POS.
- **Errores:** `400 PARAMETRO_INVALIDO`, `404 COMPROBANTE_NO_ENCONTRADO`, `422 PEDIDO_NO_APTO`.

#### `POST /api/v1/retail/cambios` 🔁 · PROPUESTO

- **Roles:** VENDEDOR, SUPERVISOR. Vendedor y tienda resueltos desde el perfil (§2.4). **Precondición:** turno de caja `ABIERTA` en la terminal. No disponible en modo offline (F10).
- **Body:**

```json
{
  "boletaNumero": "B001-00000045",
  "terminalPos": "POS-01",
  "turnoId": "5b0e3f0a-6c1d-4d3e-9a2b-1f0c7e8d9a10",
  "motivo": "CAMBIO_TALLA",
  "devuelto": {
    "sku": "CAM-RUN-M-AZUL",
    "cantidad": 1,
    "inspeccion": { "etiquetasIntactas": true, "sinSignosUso": true, "empaqueOriginal": true }
  },
  "nuevos": [ { "sku": "CAM-RUN-L-AZUL", "cantidad": 1 } ],
  "pagoDiferencia": null,
  "comprobante": null,
  "clienteId": null
}
```

- Los motivos comerciales son `CAMBIO_TALLA` y `CAMBIO_MODELO`. Para cambio de talla se exigen etiquetas intactas y prenda sin signos de uso. El estado del empaque se registra. `clienteId` es opcional. Los casos de falla de fábrica pasan a revisión de garantía en Postventa.
- Revalida el plazo y la cantidad disponible. **Crédito** = importe efectivamente pagado por las unidades devueltas según `RET_VENTA`. Si el descuento no puede atribuirse a las unidades (X-P0-13), responde `MONTO_NO_DETERMINABLE`.
- **Total nuevo:** Retail lo recalcula con el precio vigente, como `POST /carritos/calcular` y sin cupón. Las prendas nuevas no pueden estar en cuarentena (F12).
- **Mismo modelo:** si las prendas nuevas son el mismo producto que la devuelta (mismo `productoId` del catálogo, otra talla o color) y en la misma cantidad, el cambio es `MISMO_VALOR` sin comparar precios, aunque el precio vigente haya subido o bajado desde la compra.
- **Según el valor** (en cualquier otro caso):
  - `MISMO_VALOR` (total nuevo = crédito): `pagoDiferencia` y `comprobante` van en `null`. Se registra el cambio sin cobro y sin boleta, pero **sí** se crea el pedido en Ventas, pagado por completo con `CREDITO_CAMBIO` (acuerdo con G5 del 26/11), para que la prenda nueva reserve y consuma stock.
  - `MAYOR_VALOR` (total nuevo > crédito): `pagoDiferencia` es obligatorio, con la forma y las reglas de `pago` de §5.5 aplicadas a la diferencia. `comprobante` sigue las reglas de §5.5. Retail emite la boleta por el total nuevo, con el crédito y la diferencia como medios de pago, y crea el pedido en Ventas con la **misma** `Idempotency-Key`. El pago del pedido sigue la propuesta de G5 (abajo).
  - Total nuevo < crédito: se rechaza con `CAMBIO_MENOR_VALOR`. No se emiten vales ni se devuelve dinero en mostrador.
- Registra el cambio en `RET_SOLICITUD_CAMBIO_MOSTRADOR` en una sola transacción. Solo la diferencia cobrada entra al cobro del turno (F8).
- **Pedido en Ventas (acuerdo con G5 del 26/11):** en los dos tipos de cambio, el pedido viaja con estos campos dentro de `pago`:

  | Campo | Valor |
  |---|---|
  | `metodoPago` | `CREDITO_CAMBIO` (`retail.ventas.metodo-pago-credito`) |
  | `montoCreditoCambio` | `montoCredito` del cambio |
  | `pedidoOrigenId` | `pedidoId` de la boleta de origen. G5 exige que esté `ENTREGADO` |
  | `itemsDevueltos` | `[{ "sku", "cantidad" }]` con la prenda devuelta (`devuelto` del body). G5 lo usa para saber qué reintegrar |
  | `montoEfectivo` o `montoTarjeta` | La diferencia, según `pagoDiferencia.medioPago`. Con tarjeta, también `referenciaOperacion`. En `MISMO_VALOR` no van |
  | Regla | `montoCreditoCambio + montoEfectivo + montoTarjeta = total` |

  Errores nuevos de G5 (`422`): `PEDIDO_ORIGEN_NO_ENCONTRADO`, `PEDIDO_ORIGEN_NO_ENTREGADO` e `ITEM_DEVUELTO_INVALIDO` se responden como `422 PEDIDO_NO_APTO`, con el motivo en `detail`. 🟡 G5 lo publica tras su revisión; mientras tanto, se prueba contra el mock de Ventas. El contrato de G5 (1.1) confirma que todo pedido `RETAIL` queda `PAGADO` y `ENTREGADO` en la misma operación, así que una boleta de mostrador siempre es un origen válido.
- **Inventario (cerrado con G5 y G6 el 26/11):** Retail no llama a Inventory. La prenda nueva se reserva y consume por el pedido de Ventas, y la devuelta la reintegra Postventa sola al recibir el pedido con `CREDITO_CAMBIO`, `pedidoOrigenId` e `itemsDevueltos`. `InventarioPort` se reemplaza por el envío del pedido a Ventas. `estadoInventario` pasa a `CONFIRMADO` cuando Ventas acepta el pedido. Si Ventas responde `503`, el cambio no se revierte: queda `PENDIENTE` y el job de Retail reintenta el pedido cada 5 minutos con la misma `Idempotency-Key`.
- **201 Created:**

```json
{
  "cambioId": "9f2c…",
  "numeroConstancia": "CAMB-2026-000123",
  "tipoCambio": "MAYOR_VALOR",
  "boletaOrigen": "B001-00000045",
  "montoCredito": 116.91,
  "totalNuevo": 139.90,
  "diferencia": 22.99,
  "pago": { "medioPago": "EFECTIVO", "montoRecibido": 30.00, "vuelto": 7.01 },
  "comprobante": { "tipo": "BOLETA", "serie": "B001", "correlativo": "00045310", "total": 139.90, "fechaEmision": "…", "qr": "…" },
  "pedidoId": "PED-2026-01012",
  "estadoInventario": "PENDIENTE",
  "fechaCambio": "2026-11-26T15:30:00Z"
}
```

  En `MISMO_VALOR`: `diferencia` es `0`, `pago` y `comprobante` van en `null` y `pedidoId` trae el pedido creado en Ventas (`null` mientras `estadoInventario` sea `PENDIENTE`). El POS imprime la constancia de cambio con `numeroConstancia`, `boletaOrigen`, las prendas y `fechaCambio`. `numeroConstancia` es un correlativo `CAMB-YYYY-XXXXXX` por año y tienda, y se asigna en los dos tipos de cambio. `estadoInventario`: `CONFIRMADO` · `PENDIENTE`.
- Aplica la semántica de `Idempotency-Key` de §2.3. Reintentar la misma operación devuelve el cambio original y no consume unidades adicionales.
- **Errores:** `400 PARAMETRO_INVALIDO`, `400 MONTO_INSUFICIENTE`, `400 REFERENCIA_VOUCHER_INVALIDA`, `404 COMPROBANTE_NO_ENCONTRADO`, `409 TURNO_NO_ABIERTO`, `409 IDEMPOTENCY_CONFLICT`, `422 INSPECCION_NO_APTA`, `422 PLAZO_VENCIDO`, `422 PEDIDO_NO_APTO`, `422 CANTIDAD_NO_DISPONIBLE`, `422 MONTO_NO_DETERMINABLE`, `422 GARANTIA_REQUIERE_POSTVENTA`, `422 CAMBIO_MENOR_VALOR`, `422 SKU_EN_CUARENTENA`, `503 VENTAS_NO_DISPONIBLE` (solo en `MAYOR_VALOR`; como en §5.5, se conserva la clave para reintentar).

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

Todos los endpoints exigen el rol `VENDEDOR` o `SUPERVISOR`. Toman la tienda del perfil (§2.4) y responden `200`.

| Método y ruta | Contenido | Fuente | Estado |
|---|---|---|---|
| `GET /api/v1/retail/control/resumen` | Contadores para el badge; la SPA consulta cada 60 s | Los otros tres | APROBADO |
| `GET /api/v1/retail/control/pickup-pendientes` | Pedidos pickup `LISTO_PARA_RECOJO` de la tienda (RF-30) | Bandeja pickup de Ventas G5 (§5.7) | APROBADO |
| `GET /api/v1/retail/control/stock-critico` | Variantes agotadas o críticas en la tienda (RF-29) | Disponibilidad comercial de G6 (`AGOTADO` → `AGOTADO`, `STOCK_BAJO` → `CRITICO`) | APROBADO · sin cantidades (X-P0-03, ratificado por G6 el 26/11) |
| `GET /api/v1/retail/control/campanas-vigentes` | Promociones vigentes del canal `RETAIL` (RF-31), en caché 15 min | `GET /promociones?canal=RETAIL` de G6, detrás de `CampanasPort` | APROBADO |

#### `GET /api/v1/retail/control/resumen`
```json
{ "pickupPendientes": 3, "stockCritico": 2, "campanasVigentes": 4, "fuentesNoDisponibles": [], "actualizadoEn": "2026-11-26T15:00:00Z" }
```
Si una fuente no responde, su contador viaja como `null` y su nombre aparece en `fuentesNoDisponibles` (`VENTAS_G5` o `PRODUCTOS_G6`). El resumen nunca responde `503` por una sola fuente caída.

#### `GET /api/v1/retail/control/pickup-pendientes`

| Parámetro | Ubicación | Tipo | Obligatorio | Por defecto | Restricciones |
|---|---|---|:---:|---|---|
| `dni` | query | `string` | No | — | `^\d{8}$`. Deja solo los pedidos de ese titular |

- **200 OK:** arreglo con el mismo elemento de `GET /pickup/pendientes` (§5.7): `pedidoId`, `clienteNombre`, `clienteDni`, `anaquelUbicacion`, `fechaArriboTienda`, `estado` y `articulos[]`. Solo trae `LISTO_PARA_RECOJO` y ordena por `fechaArriboTienda` de la más reciente a la más antigua.
- **Errores:** `400 PARAMETRO_INVALIDO` si el `dni` no tiene 8 dígitos; `503 VENTAS_NO_DISPONIBLE`.

#### `GET /api/v1/retail/control/stock-critico`
```json
[
  { "sku": "ZAP-RUN-42", "productoId": "PROD-101", "nombreProducto": "Zapatilla Running Pro", "talla": "42", "color": "Negro",
    "nivel": "AGOTADO", "stockTienda": 0, "disponibleEnCentral": true, "stockCentral": 45 }
]
```
- `nivel`: `AGOTADO` (0 en tienda) o `CRITICO` (estado `STOCK_BAJO` de G6; su umbral lo define G6 y puede no coincidir con las 2 unidades de RF-29). `INDETERMINADO` no se cuenta como crítico. Primero van los `AGOTADO` y luego los `CRITICO`; dentro de cada nivel, por `nombreProducto`.
- `stockTienda` y `stockCentral` pueden venir `null` si Productos no expone cantidades (X-P0-03). En ese caso el `nivel` sale del estado comercial y la SPA muestra solo el semáforo.
- **Errores:** `503 PRODUCTOS_NO_DISPONIBLE`.

#### `GET /api/v1/retail/control/campanas-vigentes`
```json
[
  { "campanaId": "CMP-2026-011", "titulo": "30% en chimpunes", "descripcion": "Con cupón en mostrador", "tipoDescuento": "PORCENTAJE", "valor": 30.00,
    "codigoCupon": "GOAL2026", "montoMinimo": 150.00, "condiciones": "No acumulable con otras promociones",
    "vigenteDesde": "2026-11-20T05:00:00Z", "vigenteHasta": "2026-11-30T04:59:59Z" }
]
```
- Solo trae las campañas del canal `RETAIL` cuya vigencia incluye el momento de la consulta; una campaña vencida no aparece.
- `tipoDescuento` es `PORCENTAJE`, `MONTO_FIJO` o `NXM`. `tipoDescuento`, `valor`, `codigoCupon` y `montoMinimo` pueden ser `null`: el `PromocionResumen` de G6 solo trae nombre, estado, vigencia y canales.
- La SPA inyecta `codigoCupon` en `POST /carritos/calcular` (RF-11).
- **Errores:** `503 PRODUCTOS_NO_DISPONIBLE`.

### 5.12. F12 — Incidencias de inventario

Estados locales: `EN_CUARENTENA` · `DERIVADO_ALMACEN` · `BAJA_DEFINITIVA` · `PENDIENTE_REPORTE` (Inventory todavía no la aceptó; se reintenta desde el outbox). La **cuarentena activa**, la que bloquea la venta en el POS (RF-33), son `PENDIENTE_REPORTE` y `EN_CUARENTENA`.

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
- **201 Created:** `{ "incidenciaId": "…", "estado": "PENDIENTE_REPORTE", "sku": "CAM-PERU-M-BLA" }`. La prenda queda bloqueada en el POS desde ese momento.
- Retail guarda una **proyección local** para la interfaz y la reporta a Inventory, que bloquea la unidad. El saldo central manda (G4-P0-05).

#### Notificación asíncrona a Inventory (RF-34, tarea B6; mecanismo de §2.9)

Al registrar la incidencia, el servicio de F12 deja en la misma transacción un evento `INCIDENCIA_INVENTARIO_REPORTADA` en el outbox. El job lo envía a Inventory con el cuerpo `CrearIncidenciaInventarioRequest` del OpenAPI de G6:

```http
POST /api/v1/inventario/incidencias
Authorization: Bearer <token de servicio de modulo-retail, audiencia api-productos>
Idempotency-Key: <incidenciaId>
X-Correlation-Id: <uuid>
```
```json
{
  "operation_id": "5b0e3f0a-6c1d-4d3e-9a2b-1f0c7e8d9a10",
  "external_incident_id": "5b0e3f0a-6c1d-4d3e-9a2b-1f0c7e8d9a10",
  "sku": "CAM-PERU-M-BLA",
  "quantity": 1,
  "location_id": "aea2f0d8-e8c6-b09c-8e7a-b4a3630bc485",
  "type": "DANIO",
  "occurred_at": "2026-11-26T15:30:00Z",
  "actor_ref": "bbbbbbbb-0000-0000-0000-000000000001"
}
```

| Campo de G6 | Sale de |
|---|---|
| `operation_id`, `external_incident_id` | `incidenciaId` de Retail |
| `quantity` | `1`: en el mostrador se reporta prenda por prenda |
| `location_id` | UUID de ubicación de G6 que corresponde a la tienda del perfil, según `RETAIL_INVENTARIO_UBICACIONES` (`store_code=uuid`). `TIENDA-MIRAFLORES` → `aea2f0d8-e8c6-b09c-8e7a-b4a3630bc485` (confirmado por G6 el 26/11; en G6 es `TDA-MIRAFLORES`). El adaptador lo reemplaza al enviar |
| `type` | `MANCHADO_PROBADOR`, `COSTURA_ROTA` y `DEFECTO_FABRICA` → `DANIO`; `EXTRAVIO_NO_UBICADO` → `NO_UBICADA` (aprobado por G6 el 26/11). Retail conserva internamente su `tipoFalla` detallado |
| `actor_ref` | `usuarioId` del vendedor |

- **Respuesta de Inventory:** `201 IncidenciaInventarioResponse` con `incidencia_id` y `estado: ABIERTA`. Al recibirla, la incidencia de Retail pasa de `PENDIENTE_REPORTE` a `EN_CUARENTENA` y guarda `incidencia_id` como su `incidenciaInventoryId`.
- `409 IDEMPOTENCY_CONFLICT`, `409 STOCK_INSUFICIENTE` y los `422` (`SKU_NO_ENCONTRADO`, `UBICACION_NO_ENCONTRADA`…) son rechazos definitivos: el evento queda `FALLIDO` para revisión (§2.9).
- La resolución (rehabilitar, merma, faltante o traslado al almacén central) la registra Inventory con `POST /inventario/incidencias/{incidenciaId}/resolver`.

#### `GET /api/v1/retail/inventario/cuarentena`
- **200 OK:** lista de `incidenciaId`, `sku`, `nombreProducto`, `tipoFalla`, `fechaReporte` y `estado` de la tienda del perfil.
- La misma cuarentena activa marca `enCuarentena` en el catálogo y el lector (§5.2) y bloquea el SKU en `POST /carritos/calcular` (§5.4) y en el cambio (§5.9) con `422 SKU_EN_CUARENTENA`.

#### `POST /api/v1/retail/inventario/actas-merma`
- **Roles:** SUPERVISOR.
- **Body:** `{ "incidenciasIds": ["…"], "tipoDestino": "DEVOLUCION_CENTRAL", "observaciones": "Lote enviado con transporte interno" }`, con `tipoDestino`: `DEVOLUCION_CENTRAL` · `BAJA_DEFINITIVA` · `AJUSTE_PERDIDA`.
- **201 Created:**
```json
{
  "actaNumero": "ACTA-MERMA-2026-0012",
  "fechaEmision": "2026-11-28T18:00:00Z",
  "tiendaId": "TIENDA-MIRAFLORES",
  "tipoDestino": "DEVOLUCION_CENTRAL",
  "observaciones": "Lote enviado con transporte interno",
  "supervisor": { "id": "…", "nombre": "…" },
  "totalPrendas": 1,
  "incidencias": [
    { "incidenciaId": "…", "sku": "CAM-PERU-M-BLA", "tipoFalla": "MANCHADO_PROBADOR", "detalleObservacion": "Mancha de maquillaje en el cuello", "estado": "DERIVADO_ALMACEN" }
  ]
}
```
- El acta se imprime desde el POS con estos datos; Retail no genera PDF. El correlativo es por año y único en el módulo. Cada incidencia guarda su `actaNumero`, y la notificación a Inventory sale por el outbox de incidencias (no la hace este endpoint).
- El acta **documenta la salida, pero no cierra el caso**: Inventory resuelve cada incidencia y registra la recepción en el almacén central.
- **Estado de cada incidencia según `tipoDestino`** (decisión del PO, 26/11):

  | `tipoDestino` | Estado de la incidencia |
  |---|---|
  | `DEVOLUCION_CENTRAL` | `DERIVADO_ALMACEN` |
  | `BAJA_DEFINITIVA` | `BAJA_DEFINITIVA` |
  | `AJUSTE_PERDIDA` | `BAJA_DEFINITIVA`: la prenda extraviada no vuelve a la venta ni viaja al almacén; Inventory registra el faltante al resolver la incidencia |

- **Solo entran incidencias en `EN_CUARENTENA`**, es decir, las que Inventory ya aceptó (decisión del PO, 26/11). Una incidencia en `PENDIENTE_REPORTE` todavía no existe en Inventory: el acta no la despacha y responde `409 INCIDENCIA_NO_EN_CUARENTENA` hasta que el outbox la confirme. Lo mismo para una incidencia ya liquidada o de otra tienda.
- **Errores:** `400 LISTA_VACIA`; `409 INCIDENCIA_NO_EN_CUARENTENA` (alguna incidencia no está en `EN_CUARENTENA`; el acta no se emite y nada cambia).

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
| Productos · campañas vigentes (F11, v0.5) | `CampanasPort` devuelve campañas de varios canales y vigencias; el servicio filtra `RETAIL` vigentes | Cupones `VERANO2026` y `DESCUENTO10` (los mismos de RF-11), una campaña vencida y una de otro canal |
| Inventory · incidencias (F12, outbox, v0.5) | Acepta `POST /inventario/incidencias` y devuelve un `incidencia_id` `INC-INV-…`, el mismo para la misma `Idempotency-Key` | — |
| Ventas · pedido y cobro | Devuelve `pedidoId` `PED-…` y un comprobante `B001-…` correlativo | — |
| Inventario · movimientos del cambio (`InventarioPort`, Semana 14) | Firma: `reintegrar(cambioId, tiendaId, sku, cantidad)` y `consumir(cambioId, tiendaId, items)`, con claves de idempotencia `<cambioId>:REINTEGRO` y `<cambioId>:CONSUMO`. Acepta ambos movimientos y permite simular un fallo para probar el estado `PENDIENTE`. El adaptador real se conecta cuando G6 autorice a `modulo-retail` (§7.1) | — |
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
| OpenAPI de Seguridad: continuación del MFA (`/usuarios/*` ✅ cargado en v0.5) | Login con MFA de §4.1 | Pedir la ruta a G7 |
| ~~Dueño del Pickup (decisión #9)~~ ✅ Resuelta en S11: Ventas (§5.7) | §5.11 | Retail + Ventas |
| Señal de "apto para pagar" (X-P0-02) | Paso 4 del flujo de §5.5 | Ventas + Productos + canales |
| ~~Validar N unidades sin exponer saldos (X-P0-03)~~ ✅ G6 (26/11): solo estados comerciales; `/inventario/alertas` no se abre en M2M | `stockTienda` y stock crítico | Productos |
| Prorrateo de descuentos (X-P0-13) | `montoCredito` de §5.9 | Postventa + Productos + Retail |
| ~~Descuento de stock de las ventas Retail~~ ✅ G5 ya lo programó: reserva y confirmación en G6 para todo pedido `RETAIL`, también offline (reemplaza R9). 🟡 Lo publica tras su revisión y se prueba en conjunto | §5.5, §5.9, §5.10 | Ventas |
| ~~Stock del cambio directo~~ ✅ Va por el pedido de Ventas con `CREDITO_CAMBIO`; Postventa reintegra sola (§5.9) | §5.9 | Ventas/Postventa |
| ~~`metodoPago` del cambio~~ ✅ `CREDITO_CAMBIO` + `montoCreditoCambio` + `pedidoOrigenId` + `itemsDevueltos` (§5.9). Ya está en el contrato de G5 v1.12.0. 🟡 Falta que publiquen el código | §5.9 | Ventas |
| ~~`location_id` y scopes de `api-productos`~~ ✅ `location_id` de Miraflores dado por G6; scopes asignados por G7 (26/11). 🟡 Verificar el token nuevo | Outbox de F12 (§2.9) y §4.2 | Retail (Mihael) |
| Búsqueda de pedidos por documento (RF-16-DOC). Ruta y campos acordados con G5 (§4.3) | §5.6 | Seguridad asigna `ventas:pedidos:buscar-documento` cuando G5 publique |
| Rutas `/usuarios/*` de G7 disponibles en Render | F3 real (§4.1) | Seguridad |
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
| `/retail/pedidos/*` | F6 | — | APROBADO (v0.5.2). La búsqueda por documento en G5 se activa al asignar el scope | Mihael (backend) · Kevin (SPA) |
| `/retail/pickup/*` | F7 | — | PROPUESTO (integrado con G5 en S11) | Maylle |
| `GET /retail/cambios/validar/{boletaNumero}` | F9 | — | APROBADO para Semana 11 (PO) | Cristhian |
| `POST /retail/cambios` (cambio directo) | F9 | — | PROPUESTO para Semana 14 (PO). `MAYOR_VALOR` depende de G5 y el inventario real de G6 (§7.1); se programa con mocks | Cristhian |
| `POST /retail/contingencia/sincronizar` | F10 | — | PROPUESTO | Según la matriz de RF |
| `/retail/control/*` | F11 | — | APROBADO (v0.5). Fuentes de G6 confirmadas (v0.5.1) y scopes asignados por G7 (v0.5.2); se pasa a real quitando el perfil `mock` | Mihael (backend) · Kevin (SPA) |
| `/retail/inventario/*` | F12 | — | APROBADO (v0.5) | Angie (RF-32, RF-33) · Cristhian (RF-34) · Mihael (outbox hacia G6) |

---

## 9. Trazabilidad con el Reporte de Consistencia Intermodular

| Hallazgo | Cómo lo resuelve este contrato |
|---|---|
| G4-P0-01 | Se elimina `/inventario/consumir`; la venta crea el pedido en Ventas (§5.5) y Ventas orquesta el stock |
| G4-P0-02 | La sincronización offline envía cada `ventaLocalUuid` a Ventas, con resultado por venta y `REQUIERE_REVISION` (§5.10) |
| G4-P0-03 | Retail registra la inspección y resuelve el cambio directo en mostrador (§5.9). El reintegro de la prenda devuelta lo hace Postventa; G6 no lo abre a Retail (§7.1). Se elimina `/inventario/incrementar-stock` |
| G4-P0-04 | Las integraciones referencian solo rutas oficiales y no redefinen payloads (§4) |
| G4-P0-05 | Las incidencias se reportan a Inventory; la cuarentena local es una proyección (§5.12). Se elimina `/ajuste-discrepancia` |
| G4-P1-01 | Clientes vía `/usuarios/busqueda-documento` y `/usuarios/clientes` (§4.1, §5.3) |
| G4-P1-02 | Login con challenge MFA directo contra Seguridad (§4.1) |
| G4-P1-03 | `plazoDias` de 7 días para el cambio comercial de mostrador (§5.9), confirmado por el PO en la Semana 14 |
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

## 11. Cambios respecto de v0.4

**v0.5.7 (27/11, G6 detrás de APIM):**

- **Productos e Inventory (§2.8, §4.2):** URL base `https://apim-g6-productos-chile.azure-api.net/api/v1`. El gateway directo de G6 responde `403 RBAC` desde el 27/11.
- **F2 (§5.2):** precios en lote con `GET /precios`, variantes 6 h en caché y paralelismo 4, para no superar el límite por cliente del APIM (`429`).

**v0.5.6 (27/11, rendimiento del catálogo con G6 real):**

- **F2 (§5.2):** variantes y disponibilidad en paralelo, catálogo precalentado y caché que se refresca en segundo plano. Medido en producción antes del cambio: 72 a 85 s para el catálogo completo.

**v0.5.5 (26/11, bloqueo del carrito por cuarentena):**

- **F4 (§5.4) y F12 (§5.12):** `POST /carritos/calcular` responde `422 SKU_EN_CUARENTENA` si algún SKU tiene una incidencia activa en la tienda del perfil (RF-33). Usa el mismo código que el cambio de §5.9.

**v0.5.4 (26/11, acta de merma):**

- **F12 (§5.12):** estado de cada incidencia según `tipoDestino` (`AJUSTE_PERDIDA` → `BAJA_DEFINITIVA`) y el acta solo admite incidencias en `EN_CUARENTENA`.

**v0.5.3 (26/11, prueba de punta a punta contra G6 real):**

- **Productos (§4.2):** las variantes salen del detalle comercial `GET /productos/{id}?canal=RETAIL`; marca y categoría se muestran por nombre (`/marcas`, `/categorias`) y el filtro del catálogo acepta el nombre; talla y color se leen de `valor.nombre`.
- **F4 (§5.4):** se cumple que el precio del carrito sale de Productos y no del cliente (antes se usaba el enviado o 100.00).
- Verificado en local contra G6 real: catálogo (52 productos), código de barras, carrito con precio y cupón, F11 completo con G5 y G6.

**v0.5.2 (26/11, cierre con G5, G6 y G7):**

- **API Management (§2.8):** `X-Correlation-Id` solo se reutiliza si es UUID.
- **Ventas (§4.3, §5.6):** ruta, formato (`contenido`, paginado) y campos de la búsqueda por documento, según la 1.4c del contrato de G5; stock de `RETAIL` reservado y confirmado por Ventas, con reintento ante `503` con la misma `Idempotency-Key`.
- **F9 (§5.9):** el cambio de igual valor también crea pedido en Ventas; se agrega `itemsDevueltos`; `pedidoOrigenId` debe estar `ENTREGADO` (los pedidos `RETAIL` ya lo están); errores nuevos de G5; Retail ya no llama a Inventory.
- **F12 (§5.12):** `location_id` de Miraflores y mapeo por `RETAIL_INVENTARIO_UBICACIONES`.
- **Seguridad (§4.1, §4.2):** permisos del `VENDEDOR` y scopes de `api-productos` asignados por G7.

**v0.5.1 (26/11, respuestas de G5 y G6):**

- **Ventas (§2.8, §4.3):** límite del gateway de G5 de 300 por minuto por cliente con token (60 por IP sin token).
- **Productos (§2.8, §4.2):** URL base del gateway de G6 en Azure; scopes aprobados, con `precios:leer`; trámite de scopes con G7 a cargo de Retail; `INDETERMINADO` no es `AGOTADO`; stock crítico solo con estados comerciales.
- **F6 (§5.6):** acuerdo con G5 para RF-16-DOC con un scope propio de `modulo-retail`.
- **F9 (§5.9):** pago del crédito con `CREDITO_CAMBIO`, `montoCreditoCambio` y `pedidoOrigenId`. El stock del cambio pasa por Ventas y Postventa, no por Inventory directo.
- **F12 (§5.12):** mapeo de `type` aprobado; `location_id` pendiente de la lista de tiendas.
- **Pendientes (§7.1):** el descuento de stock de `RETAIL` queda en Ventas (se reemplaza R9).

**v0.5:**

- **API Management (§2.8):** versionado, límite de peticiones por vendedor con `429` y `Retry-After`, `X-Correlation-Id` propagado, catálogo OpenAPI y consumo de Ventas por el API Gateway de G5 (§4.3).
- **Mecanismo asíncrono (§2.9):** outbox transaccional `RET_OUTBOX_EVENTO` con job de reenvío, espera creciente, idempotencia y estado `FALLIDO`. El primer flujo es el reporte de incidencias de F12 a Inventory (§5.12).
- **Seguridad (§4.1):** payloads reales de `/usuarios/busqueda-documento` y `/usuarios/clientes`, tomados del OpenAPI de G7. Se llaman con el token del vendedor.
- **Productos (§4.2):** rutas reales del OpenAPI de G6 (catálogo, variantes, precio por SKU, código de barras y disponibilidad). La ruta de incidencias queda propuesta.
- **F11 (§5.11):** respuestas de `resumen`, `pickup-pendientes`, `stock-critico` y `campanas-vigentes`. El tablero pasa a APROBADO.
- **F12 (§5.12):** la incidencia nace `PENDIENTE_REPORTE` y pasa a `EN_CUARENTENA` cuando Inventory la acepta. Se agrega el cuerpo propuesto de la notificación.
- **Pendientes (§7.1):** nuevas filas consultadas a G5 y G6 el 26/11.

## 12. Cambios respecto de v0.3

- **Perfil único de mostrador (D-08):** se elimina `CAJERO`; el `VENDEDOR` asume la venta, el cobro, la caja y la contingencia offline. Los perfiles quedan en `VENDEDOR` y `SUPERVISOR` (§2.4) y se actualizan los roles de cada endpoint, el ejemplo de `GET /perfil` y los usuarios semilla de los mocks (§6).
- **Tipado de parámetros (D-09):** nueva §2.6 con los tipos de parámetro y los errores `400 PARAMETRO_INVALIDO` y `400 PARAMETRO_OBLIGATORIO`. La paginación pasa a §2.7 con `page` y `size` como `integer`, sus valores por defecto y el límite `size ≤ 100`.
- **Tablas de parámetros** en `catalogo`, `catalogo/codigo-barras/{codigo}`, `clientes`, `carritos-espera`, `ventas/{ventaId}/comprobante`, `pedidos`, `pedidos/{pedidoId}`, `pickup/{pedidoId}/entrega`, `caja/turnos/actual`, `caja/turnos/{turnoId}/*` y `cambios/validacion`.
- **`GET /pedidos`** pasa a ser paginado (§2.7).

## 13. Cambios respecto de v0.2

- **Eliminados:** `/inventario/consumir`, `/inventario/incrementar-stock`, `/productos/inventario/ajuste-discrepancia` y los dos endpoints de Despacho.
- **Reemplazados por rutas oficiales:** `/clientes/buscar` y `/clientes` (ahora `/usuarios/*`), `/productos/catalogo` (`/productos`), `/ofertas/evaluar-carrito` (`/promociones/evaluar`) y `/ordenes/presenciales` (`POST /pedidos` de Ventas, detrás de `/retail/ventas`).
- **Unificados bajo `/api/v1/retail`:** caja (ahora con el `turnoId` en la ruta), carritos en espera, contingencia e inventario.
- **Agregados:** convenciones, identificadores canónicos, roles por endpoint, `Idempotency-Key`, formato de error, mocks de la Semana 8, tablero de endpoints y las APIs propias de F1, F2, F3, F4, F5, F6, F7, F9 y F11.
- **Arqueo ciego:** la respuesta de movimientos de caja ya no devuelve el saldo estimado.
