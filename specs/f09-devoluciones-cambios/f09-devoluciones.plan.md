# Plan de Implementación — F9: Solicitud de Cambio de Prenda y Emisión de Vales

> Documento de regularización y decisiones de arquitectura para devoluciones y vales.

---

## 1. Decisiones Técnicas Confirmadas
1. **Canje de Vales:** Los vales se registran en `RET_VALES_COMPRA` con fecha de caducidad (90 días) y se pueden usar como medio de pago `VALE` en el endpoint `POST /api/v1/ordenes` de F5.
2. **Reversión de Stock:** Si la prenda pasa la inspección física como apta, se incrementa automáticamente el stock en `RET_STOCK_TIENDA`.

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
