# Plan de Implementación — F4: Gestión del Carrito de Compras en Mostrador

> Documento de regularización y decisiones de arquitectura para el carrito POS.

---

## 1. Decisiones Técnicas Confirmadas
1. **Doble Validación Financiera:** El frontend calcula el total en tiempo real para feedback instantáneo al cajero, pero el backend recalcula y valida obligatoriamente cada céntimo al registrar la orden para prevenir manipulaciones.
2. **Carritos en Espera en Memoria Local:** Los carritos pausados (*held carts*) se persisten en `localStorage` con un identificador temporal para que el cajero pueda alternar entre clientes sin requerir llamadas al servidor.
3. **Cálculo de IGV:** Se calcula aplicando `total / 1.18` para la base imponible y restando del total para obtener el impuesto exacto, garantizando concordancia tributaria.

## 2. Componentes e Integraciones
- **Frontend:** `cartStore` (Zustand/Redux), `CartPanel`, `TotalsPanel`, `HeldCarts`.
- **Backend:** `CalculoFinancieroService`.

## 3. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
