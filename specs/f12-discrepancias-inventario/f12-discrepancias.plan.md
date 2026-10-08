# Plan de Implementación — F12: Gestión de Discrepancias y Prendas no Ubicadas

> Documento de regularización y decisiones de arquitectura para discrepancias de inventario.

---

## 1. Decisiones Técnicas Confirmadas
1. **Separación de Estados de Stock:** El stock físico de `RET_STOCK_TIENDA` se divide en `cantidad_disponible` y `cantidad_cuarentena`. Al emitir el acta, las unidades se transfieren a cuarentena impidiendo su adición a cualquier carrito.

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
