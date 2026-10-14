# Contratos de API REST y Modelos de Datos — Módulo Retail (v0.2)

Este documento centraliza la especificación formal de todos los endpoints REST, esquemas de payload JSON, parámetros y códigos de respuesta HTTP requeridos por el **Módulo Retail (Canal para el Vendedor de Mostrador)**, abarcando tanto los servicios externos consumidos como los endpoints propios del backend de Retail.

---

## 1. Módulo Seguridad y Usuarios (Consumido por Retail)

### `POST /api/v1/auth/login`
Autentica al personal de tienda y genera el token de sesión JWT.

* **Request Body:**
```json
{
  "email": "vendedor1@deportesretail.com",
  "password": "PasswordSeguro123!"
}
```
* **Responses:**
  * `200 OK`:
    ```json
    {
      "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
      "usuario": {
        "id": "e3a89012-3456-4abc-8def-1234567890ab",
        "email": "vendedor1@deportesretail.com",
        "nombres": "Carlos",
        "apellidos": "Mendoza",
        "codigoVendedor": "VEND-1042",
        "rol": "VENDEDOR",
        "tiendaId": "TIENDA-MIRAFLORES",
        "activo": true
      }
    }
    ```
  * `400 Bad Request`: Formato de email inválido o campos vacíos (`application/problem+json`).
  * `401 Unauthorized`: Credenciales erróneas o usuario inactivo (`application/problem+json`).
  * `403 Forbidden`: El usuario no posee perfil operativo autorizado (`application/problem+json`).

> **Reglas de Validación Técnica:**
> * El emisor (`iss`) se valida dinámicamente consultando el endpoint de descubrimiento OpenID (`/api/v1/auth/.well-known/openid-configuration`).
> * La verificación de firma del token JWT se realiza de forma local utilizando la clave pública JWKS en caché.
> * Los permisos específicos dentro de la sucursal (`VENDEDOR`, `CAJERO`, `SUPERVISOR`) se resuelven contra la tabla local `RET_PERSONAL_TIENDA`.

---

### `POST /api/v1/clientes/buscar`
Busca un cliente persona natural registrado por su número exacto de DNI. Se consume enviando el token Bearer del usuario con rol `VENDEDOR` (no admite tokens de servicio). Cada consulta queda auditada individualmente y sujeta a límite de peticiones por vendedor.

> **Nota sobre RUC (Facturación a Empresas):** El RUC identifica personas jurídicas y corresponde al dominio tributario de Ventas. Las compras en mostrador con Factura capturan el RUC y la razón social directamente en la orden sin consultar al módulo de Seguridad.

* **Headers:**
  * `Authorization: Bearer <token_vendedor>`
  * `Content-Type: application/json`
* **Request Body:**
```json
{
  "documento": "72345678"
}
```
* **Responses:**
  * `200 OK`:
    ```json
    {
      "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "nombre": "Juan Pérez Torres",
      "documentoEnmascarado": "72****78"
    }
    ```
    *(El POS vincula el `id` y `nombre` con el DNI completo ingresado por el vendedor en pantalla para la orden).*
  * `400 Bad Request`: Documento no contiene 8 dígitos exactos (`application/problem+json`).
  * `401 Unauthorized`: Token de vendedor ausente, vencido o inválido (`application/problem+json`).
  * `403 Forbidden`: El usuario autenticado no posee rol `VENDEDOR` (`application/problem+json`).
  * `404 Not Found`: Cliente no registrado (`application/problem+json`).
  * `429 Too Many Requests`: Límite de solicitudes por vendedor alcanzado (`application/problem+json`).

---

### `POST /api/v1/clientes`
Alta rápida de un nuevo cliente captado en mostrador.

* **Request Body:**
```json
{
  "canalOrigen": "RETAIL",
  "tipoDocumento": "DNI",
  "numeroDocumento": "72345678",
  "nombres": "Juan",
  "apellidos": "Pérez Torres",
  "email": "juan.perez@email.com",
  "telefono": "987654321"
}
```
* **Responses:**
  * `201 Created`: Devuelve el recurso cliente creado con su identificador `id` para asociarlo de inmediato a la orden en curso. La cuenta queda en estado pendiente de activación para que el cliente configure su contraseña vía web de Marketplace.
    ```json
    {
      "id": "c89b1420-1b72-4d89-9821-3962d3aef651",
      "tipoDocumento": "DNI",
      "numeroDocumento": "72345678",
      "nombres": "Juan",
      "apellidos": "Pérez Torres",
      "email": "juan.perez@email.com",
      "telefono": "987654321",
      "estado": "PENDIENTE_ACTIVACION"
    }
    ```
  * `400 Bad Request`: Longitud o formato de documento inválido.
  * `409 Conflict`: Ya existe un cliente registrado con ese número de documento.

---

## 2. Módulo Productos y Ofertas (Consumido por Retail)

### `GET /api/v1/productos/catalogo`
Consulta de catálogo con filtros rápidos y búsqueda por SKU/texto.

* **Query Params:** `query` (texto/SKU), `categoria`, `disciplina`, `marca`, `talla`, `tiendaId`
* **Responses:**
  * `200 OK`:
    ```json
    {
      "total": 1,
      "items": [
        {
          "productoId": "PROD-CAM-01",
          "nombre": "Camiseta Deportiva Running Pro",
          "marca": "AeroSport",
          "categoria": "Textil",
          "disciplina": "Running",
          "precioBase": 129.90,
          "variantes": [
            {
              "sku": "CAM-RUN-M-AZUL",
              "codigoBarras": "7751234567890",
              "talla": "M",
              "color": "Azul",
              "stockTienda": 8,
              "stockAlmacenCentral": 45
            }
          ]
        }
      ]
    }
    ```

---

### `POST /api/v1/ofertas/evaluar-carrito`
Evalúa descuentos, promociones automáticas y cupones comerciales sobre una lista de ítems.

* **Request Body:**
```json
{
  "tiendaId": "TIENDA-MIRAFLORES",
  "cupon": "VERANO2026",
  "items": [
    {
      "sku": "CAM-RUN-M-AZUL",
      "cantidad": 2,
      "precioUnitario": 129.90
    }
  ]
}
```
* **Responses:**
  * `200 OK`:
    ```json
    {
      "subtotal": 259.80,
      "descuentoTotal": 25.98,
      "total": 233.82,
      "detalles": [
        {
          "sku": "CAM-RUN-M-AZUL",
          "descuento": 25.98,
          "promocionAplicada": "10% Cupón VERANO2026"
        }
      ]
    }
    ```

---

### `POST /api/v1/inventario/consumir`
Decrementa el stock tras concretar la venta presencial en mostrador.

* **Request Body:**
```json
{
  "tiendaId": "TIENDA-MIRAFLORES",
  "ordenReferencia": "PED-2026-00091",
  "items": [
    { "sku": "CAM-RUN-M-AZUL", "cantidad": 2 }
  ]
}
```
* **Responses:**
  * `200 OK`: `{"status": "CONFIRMADO", "transaccionId": "TRX-STOCK-8841"}`
  * `409 Conflict`: Stock insuficiente en tienda física.

---

### `GET /api/v1/productos/stock/critico?tiendaId={tiendaId}`
Consulta artículos con quiebre o stock crítico para la torre de control de mostrador.

* **Responses:**
  * `200 OK`:
    ```json
    {
      "tiendaId": "TIENDA-MIRAFLORES",
      "totalCriticos": 2,
      "items": [
        {
          "sku": "ZAP-RUN-41-NEG",
          "nombre": "Zapatilla Running Pegasus 40",
          "talla": "41",
          "color": "Negro",
          "stockLocal": 0,
          "stockAlmacenCentral": 28,
          "nivelAlerta": "AGOTADO"
        },
        {
          "sku": "CAM-PERU-M-BLA",
          "nombre": "Camiseta Selección 2026",
          "talla": "M",
          "color": "Blanco",
          "stockLocal": 1,
          "stockAlmacenCentral": 50,
          "nivelAlerta": "CRITICO"
        }
      ]
    }
    ```

---

### `GET /api/v1/promociones/vigentes?canal=RETAIL`
Consulta campañas comerciales del día para el tablón informativo de mostrador.

* **Responses:**
  * `200 OK`:
    ```json
    [
      {
        "id": "PROM-001",
        "titulo": "2x1 en Medias Deportivas",
        "beneficio": "2X1",
        "codigoCupon": null,
        "fechaFin": "2026-10-15T23:59:59Z"
      },
      {
        "id": "PROM-002",
        "titulo": "20% en Chimpunes Adidas",
        "beneficio": "DESCUENTO_20",
        "codigoCupon": "FUTBOL20",
        "fechaFin": "2026-09-30T23:59:59Z"
      }
    ]
    ```

---

### `POST /api/v1/inventario/incrementar-stock`
Reingresa stock al inventario de tienda tras un cambio de prenda en buen estado.

* **Request Body:**
```json
{
  "tiendaId": "TIENDA-MIRAFLORES",
  "sku": "CAM-RUN-M-AZUL",
  "cantidad": 1,
  "motivo": "CAMBIO_PRENDA_MOSTRADOR"
}
```
* **Responses:**
  * `200 OK`: `{"status": "STOCK_INCREMENTADO", "nuevoStock": 9}`

---

### `POST /api/v1/productos/inventario/ajuste-discrepancia`
Notifica el ajuste patrimonial de stock por acta de merma o prenda dañada en mostrador.

* **Request Body:**
```json
{
  "tiendaId": "TIENDA-MIRAFLORES",
  "actaNumero": "ACTA-MERMA-2026-0012",
  "items": [
    { "sku": "ZAP-RUN-41-NEG", "cantidad": 1, "tipoAjuste": "BAJA_POR_DETERIORO" }
  ]
}
```
* **Responses:**
  * `200 OK`: `{"status": "INVENTARIO_REGULARIZADO", "fechaAjuste": "2026-09-27T16:00:00Z"}`

---

## 3. Módulo Ventas y Postventa (Consumido por Retail)

### `POST /api/v1/pedidos`
Registra la orden de compra generada en mostrador. En canal `RETAIL`, dado que el cobro físico (efectivo o POS terminal) se realiza de forma presencial previa, el pedido nace directamente en estado `PAGADO`. Admite el header `Idempotency-Key` (UUID) para garantizar tolerancia a reintentos o sincronización diferida post-offline.

* **Headers:**
  * `Authorization: Bearer <token_vendedor>`
  * `Idempotency-Key: <UUID_operacion>`
  * `Content-Type: application/json`
* **Request Body:**
```json
{
  "canal": "RETAIL",
  "tiendaId": "TIENDA-MIRAFLORES",
  "vendedorId": "e3a89012-3456-4abc-8def-1234567890ab",
  "clienteId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "items": [
    { "sku": "CAM-RUN-M-AZUL", "cantidad": 2, "precioUnitario": 116.91 }
  ],
  "pago": {
    "medioPago": "TARJETA_POS",
    "monto": 233.82,
    "referenciaOperacion": "OP-983120"
  },
  "comprobanteReferencia": {
    "tipo": "BOLETA",
    "serieNumero": "B001-00045231",
    "numeroDocumento": "72345678",
    "razonSocial": "Juan Pérez Torres"
  }
}
```
* **Responses:**
  * `201 Created`:
    ```json
    {
      "pedidoId": "PED-2026-00091",
      "estado": "PAGADO",
      "total": 233.82,
      "fechaCreacion": "2026-09-27T10:15:30Z"
    }
    ```
  * `400 Bad Request`: Discrepancia en importes o estructura inválida.
  * `409 Conflict`: `Idempotency-Key` ya procesada anteriormente.

> **Nota de Arquitectura sobre Comprobantes:** La asignación de correlativo oficial (`B001` / `F001`), el cálculo de IGV y el renderizado del ticket térmico imprimible (80 mm) son procesados directamente por el microservicio Retail en caja, enviando a Ventas la referencia para trazabilidad.

---

### `GET /api/v1/pedidos/{id}`
Consulta el detalle y trazabilidad omnicanal de una orden de compra mediante su identificador único de formato `PED-YYYY-NNNNN`. También se utiliza en mostrador para validar compras previas en solicitudes de cambio (F9).

* **Responses:**
  * `200 OK`:
    ```json
    {
      "pedidoId": "PED-2026-00091",
      "canal": "RETAIL",
      "estado": "PAGADO",
      "fechaEmision": "2026-09-15T11:00:00Z",
      "total": 233.82,
      "items": [
        {
          "sku": "CAM-RUN-M-AZUL",
          "descripcion": "Camiseta Deportiva Running Pro Talla M",
          "precioPagado": 116.91,
          "cantidadComprada": 2
        }
      ],
      "historialEstados": [
        { "estado": "CREADO", "fecha": "2026-09-15T11:00:00Z" },
        { "estado": "PAGADO", "fecha": "2026-09-15T11:00:00Z" }
      ]
    }
    ```
    *(Enum cerrado de estados en Ventas: `CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`).*
  * `404 Not Found`: No existe la orden especificada (`PEDIDO_NO_ENCONTRADO`).

> **Nota sobre Pickup y Cambios en Mostrador:**
> * El sub-estado operativo `LISTO_PARA_RECOJO` de paquetes Click & Collect reside en el Módulo Despacho y Entrega (G2), el cual es consultado directamente por Retail en F7.
> * La inspección de prendas devueltas y la emisión de vales de compra térmicos se gestionan de forma autónoma en el backend de Retail mediante la tabla `RET_SOLICITUD_CAMBIO_MOSTRADOR`, requiriendo de Ventas únicamente la consulta histórica de la orden.

---

## 4. Módulo Despacho y Entrega (Consumido por Retail)

### `GET /api/v1/despachos/tienda/{tiendaId}/pendientes-pickup`
Lista los bultos arribados a la tienda para retiro presencial por el cliente (Click & Collect).

* **Responses:**
  * `200 OK`:
    ```json
    [
      {
        "bultoId": "BLT-8921",
        "pedidoId": "PED-2026-08910",
        "codigoTracking": "TRK-PICKUP-041",
        "clienteNombre": "María González",
        "clienteDni": "45678912",
        "anaquelUbicacion": "Anaquel B-04",
        "fechaArriboTienda": "2026-09-27T08:30:00Z"
      }
    ]
    ```

---

### `POST /api/v1/despachos/confirmar-entrega-tienda`
Registra la entrega física del paquete al cliente en el mostrador.

* **Request Body:**
```json
{
  "pedidoId": "PED-2026-08910",
  "dniRecoge": "45678912",
  "nombreRecoge": "María González",
  "esTitular": true,
  "encargadoEntregaId": "e3a89012-3456-4abc-8def-1234567890ab"
}
```
* **Responses:**
  * `200 OK`: `{"status": "ENTREGADO_EN_TIENDA", "fechaHora": "2026-09-27T16:30:00Z"}`
  * `400 Bad Request`: El paquete no figura en estado listo para recojo.

---

## 5. Endpoints Propios del Microservicio Retail (Grupo 4)

### `POST /api/v1/retail/caja/apertura`
Apertura de turno de caja con fondo fijo inicial.

* **Request Body:**
```json
{
  "terminalPos": "POS-01",
  "saldoInicialEfectivo": 200.00
}
```
* **Responses:**
  * `201 Created`: `{"sesionId": "ses-9912", "estado": "ABIERTA", "fechaHoraApertura": "2026-09-27T08:00:00Z"}`
  * `409 Conflict`: La terminal ya tiene una sesión abierta.

---

### `POST /api/v1/retail/caja/movimientos`
Registro de ingresos o egresos menores de efectivo (caja chica).

* **Request Body:**
```json
{
  "tipoMovimiento": "SALIDA_GASTO",
  "monto": 15.00,
  "motivo": "Compra de rollos de papel térmico para tickets",
  "autorizadoPor": "Supervisor Juan"
}
```
* **Responses:**
  * `201 Created`: `{"movimientoId": "mov-004", "nuevoSaldoEstimado": 185.00}`
  * `422 Unprocessable Entity`: Fondos en gaveta insuficientes para el egreso.

---

### `POST /api/v1/retail/caja/cierre`
Cierre formal de turno con arqueo ciego (declaración física de billetes y monedas).

* **Request Body:**
```json
{
  "montoDeclarado": 535.00,
  "observaciones": "Caja cuadrada sin novedad"
}
```
* **Responses:**
  * `200 OK`:
    ```json
    {
      "sesionId": "ses-9912",
      "saldoInicial": 200.00,
      "ventasEfectivoTotal": 350.00,
      "ingresosMenores": 0.00,
      "egresosMenores": 15.00,
      "saldoSistema": 535.00,
      "saldoDeclarado": 535.00,
      "diferencia": 0.00,
      "estado": "CERRADA",
      "reporteZUrl": "/reportes/corte-z-ses-9912.pdf"
    }
    ```

---

### `POST /api/v1/retail/carritos-espera`
Pausa una venta activa para liberar la cola mientras el cliente va a los probadores.

* **Request Body:**
```json
{
  "aliasTicket": "Probador 3 - Zapatillas Running",
  "items": [
    { "sku": "ZAP-RUN-41-NEG", "cantidad": 1, "precioUnitario": 299.90 }
  ]
}
```
* **Responses:**
  * `201 Created`: `{"carritoEsperaId": "park-012", "expiracion": "2026-09-27T18:00:00Z"}`

---

### `GET /api/v1/retail/carritos-espera`
Lista las ventas suspendidas activas de la tienda.

* **Responses:**
  * `200 OK`: Devuelve el arreglo de carritos en espera para su reanudación en 1 clic.

---

### `DELETE /api/v1/retail/carritos-espera/{id}`
Descarta o retira un carrito en espera tras ser reanudado en caja.

---

### `POST /api/v1/retail/contingencia/sincronizar`
Concilia en lote las ventas offline emitidas localmente en IndexedDB tras restablecerse la red.

* **Request Body:**
```json
{
  "terminalPos": "POS-01",
  "lote": [
    {
      "ventaLocalUuid": "c3b9e4a1-0001-49b2-...",
      "fechaHoraOffline": "2026-09-27T14:20:00Z",
      "items": [{ "sku": "CAM-RUN-M-AZUL", "cantidad": 1, "precio": 129.90 }],
      "totalNeto": 129.90,
      "efectivoRecibido": 150.00,
      "hashIntegridad": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    }
  ]
}
```
* **Responses:**
  * `200 OK`:
    ```json
    {
      "totalProcesados": 1,
      "exitosos": 1,
      "errores": 0,
      "ordenesMapeadas": [
        {
          "ventaLocalUuid": "c3b9e4a1-0001-49b2-...",
          "pedidoIdOficial": "PED-2026-00105",
          "comprobanteOficial": "B001-00045280"
        }
      ]
    }
    ```

---

### `POST /api/v1/retail/inventario/incidencias`
Reporta una prenda física dañada, manchada o extraviada en mostrador poniéndola en cuarentena.

* **Request Body:**
```json
{
  "varianteSkuId": "CAM-PERU-M-BLA",
  "codigoBarras": "7759876543210",
  "tipoFalla": "MANCHADO_PROBADOR",
  "detalleObservacion": "Mancha de maquillaje en el cuello",
  "fotoUrl": "https://storage.deportesretail.com/evidencias/inc-01.jpg"
}
```
* **Responses:**
  * `201 Created`: `{"incidenciaId": "INC-2026-0089", "estado": "EN_CUARENTENA", "stockBloqueado": 1}`

---

### `GET /api/v1/retail/inventario/cuarentena`
Lista las prendas actualmente retenidas en cuarentena de la tienda.

* **Responses:**
  * `200 OK`: Arreglo de artículos con incidencia que no pueden venderse en mostrador.

---

### `POST /api/v1/retail/inventario/actas-merma`
Consolida artículos en cuarentena y emite el acta oficial de salida o merma de mostrador.

* **Request Body:**
```json
{
  "incidenciasIds": ["INC-2026-0089"],
  "tipoDestino": "DEVOLUCION_ALMACEN_CENTRAL",
  "observaciones": "Lote enviado con transporte interno para cambio con proveedor"
}
```
* **Responses:**
  * `201 Created`:
    ```json
    {
      "actaNumero": "ACTA-MERMA-2026-0012",
      "totalPrendas": 1,
      "urlPdf": "/reportes/actas/ACTA-MERMA-2026-0012.pdf",
      "notificacionStockCentral": "EXITOSA"
    }
    ```
