# Overview — Módulo Retail (Canal para el Vendedor en Mostrador)

## 1. Propósito
El **Módulo Retail (Grupo 4)** forma parte del ecosistema de **Marketplace Multicanal de Artículos Deportivos** de la FISI - UNMSM. Su propósito principal es dotar al personal de tienda (vendedores y cajeros) de una aplicación web POS (*Point of Sale*) optimizada para atención en mostrador de alta velocidad, permitiendo la búsqueda ágil de productos, gestión de carritos en terminal, cobro y emisión de comprobantes, despacho de pedidos *pickup* y control estricto de turnos de caja con arqueo ciego.

---

## 2. Alcance del Proyecto

### 2.1 Alcance del Hito 3 (Semana 8 — Examen Parcial: Happy Path Operativo)
- **F1: Inicio de Sesión y Perfil:** Autenticación de cajero/vendedor y recuperación de terminal/tienda asignada.
- **F2: Catálogo y Lector de Código de Barras:** Consulta de productos deportivos con soporte prioritario para escáner físico de código de barras.
- **F3: Búsqueda y Alta Rápida de Clientes:** Búsqueda por DNI/RUC y registro express sin abandonar la venta.
- **F4: Carrito de Mostrador:** Agregado dinámico, cálculo automático de subtotal e IGV (18%), aplicación de descuentos.
- **F5: Registro de Orden y Emisión de Boleta:** Cobro multimoneda/efectivo con cálculo de vuelto y emisión de comprobante de pago.
- **F8 (Base): Control de Caja:** Apertura de turno con fondo fijo inicial.

### 2.2 Alcance Completo del Ciclo (Semanas 9 a 16)
- **F6:** Consulta y trazabilidad histórica de pedidos multicanal.
- **F7:** Verificación y entrega física de pedidos con retiro en tienda (*Store Pickup*).
- **F8 (Avanzado):** Cierre de turno y corte ciego (*Corte Z*) con actas de descuadre.
- **F9:** Gestión de cambios de prenda y emisión de vales / notas de crédito.
- **F10:** Modo de contingencia offline con almacenamiento local en IndexedDB y sincronización diferida.
- **F11:** Tablón de alertas operativas (stock crítico y pedidos pickup del día).
- **F12:** Reporte de discrepancias de inventario y cuarentena de prendas dañadas.

---

## 3. Actores y Roles

| Actor / Rol | Responsabilidad en Mostrador |
|---|---|
| **Vendedor de Mostrador** | Atiende al cliente en piso de venta, escanea productos, asesora sobre variantes (tallas/colores), aplica promociones y crea la orden de compra. |
| **Cajero de Terminal** | Responsable de la gaveta de dinero, apertura de turno con fondo fijo, procesamiento de cobros (efectivo/tarjeta/vales), emisión de boleta/factura y arqueo de caja. |
| **Supervisor de Tienda** | Autoriza anulaciones, aperturas/cierres excepcionales, emisión de notas de crédito y resuelve actas de discrepancia de stock. |
| **Cliente Presencial** | Comprador en tienda que suministra su documento de identidad (DNI/RUC), realiza el pago y recibe los artículos. |

---

## 4. Arquitectura y Stack Tecnológico

| Capa | Stack y Herramientas | Responsabilidad |
|---|---|---|
| **Frontend (`G4-Retail-frontend`)** | React 18+ + TypeScript + Vite. Tailwind CSS + Atomic Design. Gestión de estado con Redux Toolkit / Zustand y `useState`. Testing con Vitest. | SPA optimizada para terminal POS, responsive (desktop mostrador / tablet), atajos de teclado y soporte de escáner HID. |
| **Backend (`G4-Retail-backend`)** | Java 17/21 + Spring Boot 3.x. Spring Data JPA + Hibernate + Bean Validation. Build: Maven Wrapper (`mvnw`). | API REST segura, orquestación de reglas de negocio, cálculo de impuestos, cierres de caja transaccionales ACID y capa de integración. |
| **Base de Datos** | PostgreSQL alojado en la nube en **Supabase**. Esquema gestionado con DDL relacional (`schema.sql`) y datos semilla (`seed.sql`). | Persistencia de turnos, cajas, órdenes locales, comprobantes, vales de crédito y logs de auditoría. |
| **Comunicación Intermodular** | API REST sobre HTTPS/TLS. Contrato oficial centralizado en `specs/generales/api-contracts.md`. | Comunicación con microservicios externos (*Ventas G5*, *Seguridad G7*, *Catálogo G6*) usando mocks controlados para desarrollo local y Semana 8. |

---

## 5. Integraciones y Límites de Dominio

Siguiendo la matriz cruzada de microservicios establecida en los lineamientos del curso (PRA):

1. **Seguridad y Usuarios (G7):** Es el dueño de la entidad usuario. Retail delega la autenticación (`POST /api/v1/auth/login`) y solo mapea localmente el perfil operativo en tienda (`RET_PERSONAL_TIENDA`).
2. **Ventas y Postventa (G5):** Es el dueño del ciclo de vida del pedido multicanal. Retail emite pedidos de mostrador (`POST /api/v1/pedidos`) y consulta estados. Ventas es el orquestador hacia el stock global.
3. **Productos y Ofertas (G6):** Es el dueño del catálogo de productos y stock maestro. Retail consulta productos por código de barras (`GET /api/v1/productos/barcode/{codigo}`) y stock en tienda física.
4. **Regla de Aislamiento:** Durante la fase de desarrollo y para el Hito 3, Retail interactúa con su base de datos local y aísla las dependencias externas mediante controladores de Mocks bien definidos.

---

## 6. Restricciones y Decisiones de Ingeniería

- **Metodología Spec-Driven Development (SDD):** Las especificaciones en `/specs` son la única fuente de verdad; no se programa código sin una spec asociada.
- **Entrada prioritaria por Código de Barras:** La UI del POS prioriza la captura continua por lector de código de barras para no interrumpir el flujo del cajero.
- **Transaccionalidad en Caja y Ventas:** Toda operación de apertura, cobro y cierre se ejecuta en bloques transaccionales `@Transactional` para evitar descuadres o comprobantes huérfanos.
- **Idioma del Proyecto:** Documentación, comentarios, contratos y mensajes de error en español.
- **Formato homogéneo de respuesta de error:** Todo error del backend debe seguir la estructura:
  ```json
  {
    "error": {
      "codigo": "STOCK_INSUFICIENTE",
      "mensaje": "No hay existencias suficientes para el producto especificado",
      "detalles": ["SKU: ZAP-RUN-42 (Disponible: 1, Solicitado: 2)"]
    }
  }
  ```

---

## 7. Glosario de Términos de Retail

- **POS (Point of Sale / Terminal de Punto de Venta):** Estación física de mostrador compuesta por pantalla, teclado, escáner de código de barras y gaveta de dinero.
- **Arqueo Ciego (Corte Z):** Proceso de cierre de turno en el que el cajero cuenta físicamente el dinero en caja e ingresa el monto sin que el sistema le muestre el total esperado del sistema, garantizando honestidad.
- **Fondo Fijo (Base de Caja):** Dinero inicial en efectivo asignado al cajero al inicio de su turno para dar vuelto a los primeros clientes.
- **SKU (Stock Keeping Unit):** Identificador alfanumérico único por variante de producto (modelo, color y talla).
- **Código de Barras (EAN-13 / Code128):** Código numérico leído ópticamente por el escáner para agregar artículos al carrito en milisegundos.
- **Store Pickup (Retiro en Tienda):** Modalidad de compra donde el cliente compró por Marketplace o Chatbot y retira físicamente el pedido en mostrador de Retail.
- **Nota de Crédito / Vale de Compra:** Comprobante tributario o cupón interno generado cuando un cliente realiza una devolución y recibe saldo a favor para futuras compras.
