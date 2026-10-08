# Plan de Implementación — F3: Búsqueda y Registro Rápido de Clientes

> Documento de regularización y decisiones de arquitectura para la gestión express de clientes en mostrador.

---

## 1. Decisiones Técnicas Confirmadas
1. **Validación de RUC:** Para clientes con RUC (empresas que solicitan factura), se valida que inicie con 10 o 20 y tenga 11 dígitos numéricos exactos.
2. **Cliente Varios por Defecto:** Si el cliente no desea brindar sus datos y el monto es menor al umbral tributario que exige SUNAT para identificación obligatoria, la venta procede asociada a un ID genérico `CLIENTE-GENERICO` (*Clientes Varios*).
3. **Persistencia Local y Sincronización:** El cliente nuevo se guarda en `RET_CLIENTES` local de Retail para que no dependa de conectividad inmediata con el marketplace central durante la atención en caja.

## 2. Componentes e Integraciones
- **Backend:** `ClienteController`, `ClienteService`, `ClienteRepository`.
- **Frontend:** `CustomerSection` en `PosPage`, `QuickCustomerModal`.

## 3. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
