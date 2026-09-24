# Contratos de API REST y Modelos de Datos — Módulo Retail (v0.1)

Este documento centraliza los contratos de endpoints REST, esquemas de payload JSON y códigos de respuesta HTTP referenciados por las especificaciones SDD del Módulo Retail.

---

## 1. Módulo Seguridad y Usuarios (Consumido por Retail)

### `POST /api/v1/auth/login`
Autentica a un empleado de tienda y genera el token de sesión.

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
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "usuario": {
        "id": "usr-001",
        "email": "vendedor1@deportesretail.com",
        "nombres": "Carlos",
        "apellidos": "Mendoza",
        "rol": "vendedor",
        "tiendaId": "TIENDA-MIRAFLORES"
      }
    }
    ```
  * `400 Bad Request`: Datos de solicitud incompletos o mal formateados.
  * `401 Unauthorized`: Credenciales inválidas o cuenta bloqueada.
  * `403 Forbidden`: Usuario no tiene rol de vendedor o cajero.

### `GET /api/v1/clientes?documento={nroDocumento}`
Busca un cliente por DNI o RUC.

* **Responses:**
  * `200 OK`:
    ```json
    {
      "id": "cli-101",
      "tipoDocumento": "DNI",
      "numeroDocumento": "72345678",
      "nombres": "Juan",
      "apellidos": "Pérez Torres",
      "email": "juan.perez@email.com",
      "telefono": "987654321"
    }
    ```
  * `404 Not Found`: No existe cliente con ese documento.

### `POST /api/v1/clientes`
Registro rápido de cliente desde mostrador.

* **Request Body:**
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
* **Responses:**
  * `201 Created`: Devuelve el recurso cliente creado con su `id`.
  * `400 Bad Request`: Formato de DNI/RUC inválido o campos obligatorios vacíos.
  * `409 Conflict`: Ya existe un cliente con ese número de documento.

---

## 2. Módulo Productos y Ofertas (Consumido por Retail)

### `GET /api/v1/productos/catalogo`
Consulta de catálogo con filtros rápidos para mostrador.

* **Query Params:** `query` (texto), `categoria`, `disciplina`, `marca`, `talla`, `tiendaId`
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

### `POST /api/v1/ofertas/evaluar-carrito`
Evalúa descuentos y promociones sobre una lista de ítems.

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

### `POST /api/v1/inventario/consumir`
Decrementa stock tras concretar la venta presencial.

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
  * `409 Conflict`: Stock insuficiente en la tienda para alguno de los ítems.

---

## 3. Módulo Ventas y Postventa (Consumido por Retail)

### `POST /api/v1/ordenes/presenciales`
Registra la orden finalizada, el cobro y genera el comprobante.

* **Request Body:**
```json
{
  "canal": "RETAIL",
  "tiendaId": "TIENDA-MIRAFLORES",
  "vendedorId": "usr-001",
  "clienteId": "cli-101",
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
        "fechaEmision": "2026-09-19T10:15:30Z"
      }
    }
    ```
  * `400 Bad Request`: Inconsistencia en importes o datos fiscales faltantes.

### `GET /api/v1/ordenes/{id}`
Consulta detalle y estado de una orden.

* **Responses:**
  * `200 OK`: Devuelve el objeto completo de la orden con sus estados históricos y modalidad de entrega (`TIENDA` o `DOMICILIO`).
  * `404 Not Found`: No existe orden con dicho identificador.

---

## 4. Módulo Despacho y Entrega (Consumido por Retail)

### `GET /api/v1/despachos/tienda/{tiendaId}/pendientes-pickup`
Lista pedidos pendientes de recojo en mostrador.

### `POST /api/v1/despachos/confirmar-entrega-tienda`
Registra la entrega física del paquete al cliente en el mostrador.

* **Request Body:**
```json
{
  "pedidoId": "ORD-RET-2026-0091",
  "dniRecoge": "72345678",
  "nombreRecoge": "Juan Pérez Torres",
  "encargadoEntregaId": "usr-001"
}
```
* **Responses:**
  * `200 OK`: `{"status": "ENTREGADO_EN_TIENDA", "fechaHora": "2026-09-19T11:00:00Z"}`
  * `400 Bad Request`: El pedido no se encuentra en estado `LISTO_PARA_RECOJO`.
