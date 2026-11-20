# Prueba real G4 -> G5 con token modulo-retail

Gateway: `https://g5-api-gateway.onrender.com` · tienda: `TIENDA-MIRAFLORES` · ejecutado: 2026-11-20 05:23 UTC

| Caso | Qué se probó | Hora (UTC) | HTTP | Pedido | Estado | Error | Esperado |
|---|---|---|---|---|---|---|---|
| 1a | EFECTIVO | 2026-11-20 05:23:09Z | 201 | PED-2026-00076 | ENTREGADO |  | 201 ENTREGADO |
| 1b | TARJETA_POS | 2026-11-20 05:23:19Z | 201 | PED-2026-00077 | ENTREGADO |  | 201 ENTREGADO |
| 1c | MIXTO 50 efectivo + 79.90 tarjeta | 2026-11-20 05:23:21Z | 201 | PED-2026-00078 | ENTREGADO |  | 201 ENTREGADO |
| 1d | Offline, fechaVenta 2026-11-20T03:23:09Z | 2026-11-20 05:23:22Z | 201 | PED-2026-00079 | ENTREGADO |  | 201, fechaVenta en historial |
| 1e | Misma clave y cuerpo que 1a | 2026-11-20 05:23:24Z | 200 | PED-2026-00076 | ENTREGADO |  | 200 mismo pedido |
| 1f | Misma clave que 1a, cantidad 2 | 2026-11-20 05:23:24Z | 409 | — | — | IDEMPOTENCY_KEY_REUSED | 409 IDEMPOTENCY_KEY_REUSED |
| Pickup | `GET /pedidos/pickup?tiendaId=TIENDA-MIRAFLORES` | 2026-11-20 05:23:25Z | 200 | — | — | | 200 |

## Respuestas completas

### 1a (Idempotency-Key `cec648dc-8a57-4bd6-9fe8-43ce252b85cc`) → 201

```json
{"pedidoId":"PED-2026-00076","estado":"ENTREGADO","total":129.9,"moneda":"PEN","canal":"RETAIL","fechaCreacion":"2026-11-20T05:23:16.439699775Z"}
```

### 1b (Idempotency-Key `2b842c47-99dd-49d9-9b19-bb15e307b173`) → 201

```json
{"pedidoId":"PED-2026-00077","estado":"ENTREGADO","total":129.9,"moneda":"PEN","canal":"RETAIL","fechaCreacion":"2026-11-20T05:23:19.238400561Z"}
```

### 1c (Idempotency-Key `1dad08c8-fdf5-4f64-bfbe-e7c061895fdb`) → 201

```json
{"pedidoId":"PED-2026-00078","estado":"ENTREGADO","total":129.9,"moneda":"PEN","canal":"RETAIL","fechaCreacion":"2026-11-20T05:23:20.901429022Z"}
```

### 1d (Idempotency-Key `4408e900-6466-4980-8bed-d58fdc7ab292`) → 201

```json
{"pedidoId":"PED-2026-00079","estado":"ENTREGADO","total":129.9,"moneda":"PEN","canal":"RETAIL","fechaCreacion":"2026-11-20T05:23:22.104532494Z"}
```

### 1e (Idempotency-Key `cec648dc-8a57-4bd6-9fe8-43ce252b85cc`) → 200

```json
{"pedidoId":"PED-2026-00076","estado":"ENTREGADO","total":129.90,"moneda":"PEN","canal":"RETAIL","fechaCreacion":"2026-11-20T05:23:16.4397Z"}
```

### 1f (Idempotency-Key `cec648dc-8a57-4bd6-9fe8-43ce252b85cc`) → 409

```json
{"codigo":"IDEMPOTENCY_KEY_REUSED","mensaje":"La Idempotency-Key ya se usó con un pedido distinto","timestamp":"2026-11-20T05:23:23Z","detalles":[]}
```

### Pickup → 200

```json
[{"pedidoId":"PED-2026-00053","clienteNombre":"María González López","clienteDni":"45678912","anaquelUbicacion":"Anaquel B-04","fechaArriboTienda":"2026-11-07T03:00:39.746714Z","estado":"LISTO_PARA_RECOJO","articulos":[{"sku":"ZAP-RUN-41-BLANC","nombre":"Zapatilla Running Pegasus 40 - Talla 41","talla":"-","color":"-","cantidad":1}]},{"pedidoId":"PED-2026-00055","clienteNombre":"Juan Pérez Torres","clienteDni":"72345678","anaquelUbicacion":"Estante A - Casillero 14","fechaArriboTienda":"2026-11-07T00:19:44.224217Z","estado":"LISTO_PARA_RECOJO","articulos":[{"sku":"CAM-PERU-M-BLANC","nombre":"Camiseta Selección 2026 - Talla M","talla":"-","color":"-","cantidad":1},{"sku":"BAL-FUT-5-BLANC","nombre":"Balón de Fútbol Match N.° 5","talla":"-","color":"-","cantidad":1}]},{"pedidoId":"PED-2026-PICKUP01","clienteNombre":"Carlos Mendoza","clienteDni":"72345678","anaquelUbicacion":"Estante A-12","fechaArriboTienda":"2026-11-06T02:39:03.194954Z","estado":"LISTO_PARA_RECOJO","articulos":[{"sku":"SKU-ZAP-RUN-42","nombre":"Zapatillas Running Pro Talla 42","talla":"-","color":"-","cantidad":1}]}]
```
