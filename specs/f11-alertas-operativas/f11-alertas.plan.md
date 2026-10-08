# Plan de Implementación — F11: Alertas Operativas y Notificaciones en Tienda

> Documento de regularización y decisiones de arquitectura para el sistema de alertas.

---

## 1. Decisiones Técnicas Confirmadas
1. **Polling Liviano:** Para el entorno web de tienda, el cliente realiza un polling periódico cada 60 segundos hacia `GET /api/v1/alertas` para mantener el badge actualizado sin sobrecargar el servidor.

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
