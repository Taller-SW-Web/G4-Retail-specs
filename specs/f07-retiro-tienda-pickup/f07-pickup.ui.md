# UI Spec — F7: Verificación y Entrega Física en Tienda (Pickup)

**Pantalla:** Bandeja y Entrega de Pedidos Pickup  
**Ruta:** `/pickup`  
**Spec Funcional:** `f07-pickup.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Vendedor o encargado de entrega en tienda física atendiendo clientes que retiran paquetes.

## 2. Composición y Layout
- Buscador rápido por Código de Pickup o DNI con atajo para escanear código QR del cliente.
- Lista de paquetes pendientes en mostrador (`PickupCard`):
  - Código de retiro destacado (ej. `#PCK-8492`).
  - Nombre del cliente y prendas incluidas.
  - Gaveta o ubicación física en tienda (ej. *Gaveta B-04*).
  - Badge de estado (`LISTO_PARA_ENTREGA`).
- Modal de Entrega (`DeliveryModal`):
  - Formulario para confirmar DNI de la persona que retira (titular o tercero autorizado).
  - Botón principal *"Confirmar Entrega Física"* (variante `Confirm`).

## 3. Estados de Interfaz
- **Pendiente de Verificación:** Tarjeta resaltada con borde amarillo/información pendiente.
- **Entregado:** Transición con animación de check verde y desaparición de la bandeja activa.
