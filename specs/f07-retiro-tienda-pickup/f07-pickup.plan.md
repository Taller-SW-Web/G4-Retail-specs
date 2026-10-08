# Plan de Implementación — F7: Verificación y Entrega Física en Tienda (Pickup)

> Documento de regularización y decisiones de arquitectura para entrega presencial.

---

## 1. Decisiones Técnicas Confirmadas
1. **Validación de Código:** El cliente recibe un PIN alfanumérico de 6 caracteres o QR en su correo de compra. El cajero ingresa el PIN para desbloquear el botón de entrega.
2. **Sincronización:** Al entregarse, se emite evento al microservicio de Despacho y Entrega mediante mock controlado.

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
