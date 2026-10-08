# Plan de Implementación — F10: Modo Contingencia y Sincronización Offline

> Documento de regularización y decisiones de arquitectura para resiliencia offline.

---

## 1. Decisiones Técnicas Confirmadas
1. **Catálogo Cacheado:** Al iniciar la jornada, la terminal descarga un snapshot liviano de precios y códigos de barras de la tienda física en IndexedDB.
2. **Identificador Idempotente:** Cada venta generada offline lleva un UUID v4 generado en el cliente para garantizar idempotencia en caso de reintentos de red repetidos.

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
