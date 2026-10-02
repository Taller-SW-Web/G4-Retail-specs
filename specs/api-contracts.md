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
        "id": "usr-001",
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
      "id": "cli-101",
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
      "id": "cli-102",
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
  "ordenReferencia": "ORD-RET-2026-0091",
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

### `POST /api/v1/ordenes/presenciales`
Registra la venta finalizada en mostrador, el cobro y emite comprobante oficial (con soporte de ticket de regalo).

* **Request Body:**
```json
{
  "canal": "RETAIL",
  "tiendaId": "TIENDA-MIRAFLORES",
  "vendedorId": "usr-001",
  "clienteId": "cli-101",
  "emitirTicketRegalo": true,
  "items": [
    { "sku": "CAM-RUN-M-AZUL", "cantidad": 2, "precioFinal": 116.91 }
  ],
  "pago": {
    "medioPago": "TARJETA_POS",
    "monto": 233.82,
    "referenciaOperacion": "OP-983120"
  },
  "comprobante": {
    "tipo": "BOLETA",
    "numeroDocumento": "72345678",
    "razonSocial": "Juan Pérez Torres"
  }
}
```
* **Responses:**
  * `201 Created`:
    ```json
    {
      "pedidoId": "ORD-RET-2026-0091",
      "estado": "PAGADO",
      "comprobante": {
        "serie": "B001",
        "correlativo": "00045231",
        "subtotal": 198.15,
        "igv": 35.67,
        "total": 233.82,
        "fechaEmision": "2026-09-27T10:15:30Z"
      },
      "ticketRegalo": {
        "codigoCanje": "GIFT-2026-09124",
        "fechaLimiteCambio": "2026-10-27T23:59:59Z",
        "mensaje": "Válido para cambio presencial por 30 días"
      }
    }
    ```
  * `400 Bad Request`: Discrepancia en importes o cliente sin DNI para boletas >= S/ 700.

---

### `GET /api/v1/ordenes/{id}`
Consulta detalle histórico y trazabilidad de cualquier pedido.

* **Responses:**
  * `200 OK`: Retorna el pedido con su historial de estados (`CREADO`, `EN_PREPARACION`, `LISTO_PARA_RECOJO`, `ENTREGADO`).
  * `404 Not Found`: No existe la orden especificada.

---

### `GET /api/v1/ventas/comprobantes/validar-cambio`
Valida si un comprobante de compra o ticket de regalo es apto para cambio de prenda en tienda física.

* **Query Params:** `comprobante` (ej. `B001-00045231`), `codigoTicketRegalo` o `dni`
* **Responses:**
  * `200 OK`:
    ```json
    {
      "pedidoId": "ORD-RET-2026-0091",
      "fechaEmision": "2026-09-15T11:00:00Z",
      "diasTranscurridos": 12,
      "plazoValido": true,
      "items": [
        {
          "sku": "CAM-RUN-M-AZUL",
          "descripcion": "Camiseta Deportiva Running Pro Talla M",
          "precioPagado": 116.91,
          "cantidadComprada": 2,
          "cantidadDisponibleCambio": 2
        }
      ]
    }
    ```
  * `422 Unprocessable Entity`: Comprobante con plazo expirado (> 30 días) o compra ya devuelta.

---

### `POST /api/v1/ventas/postventa/generar-nota-credito`
Emite formalmente una Nota de Crédito o Vale de Compra para canje presencial.

* **Request Body:**
```json
{
  "pedidoIdOrigen": "ORD-RET-2026-0091",
  "skuDevuelto": "CAM-RUN-M-AZUL",
  "monto": 116.91,
  "clienteId": "cli-101",
  "motivo": "CAMBIO_TALLA_MOSTRADOR"
}
```
* **Responses:**
  * `201 Created`:
    ```json
    {
      "codigoVale": "NC-RET-2026-00412",
      "monto": 116.91,
      "fechaVencimiento": "2026-12-26T23:59:59Z",
      "qrPayload": "NC-RET-2026-00412|116.91|cli-101"
    }
    ```

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
        "pedidoId": "ORD-WEB-2026-8910",
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
  "pedidoId": "ORD-WEB-2026-8910",
  "dniRecoge": "45678912",
  "nombreRecoge": "María González",
  "esTitular": true,
  "encargadoEntregaId": "usr-001"
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
          "pedidoIdOficial": "ORD-RET-2026-0105",
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
