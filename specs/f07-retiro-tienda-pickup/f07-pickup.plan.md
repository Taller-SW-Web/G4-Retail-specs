# Plan de Implementación — F7: Verificación y Entrega Física en Tienda (Pickup)

> Documento de regularización y decisiones de arquitectura para entrega presencial.

---

## 1. Decisiones Técnicas Confirmadas
1. **Validación de identidad (S11):** Ventas (G5) no emite código de retiro, así que el PIN pasa a ser opcional. El vendedor verifica el DNI del titular o, si recoge un tercero, la carta poder.
2. **Sincronización (S11):** La entrega se informa a Ventas (G5) con `POST /api/v1/pedidos/{pedidoId}/entrega-pickup`; Despacho (G2) no participa (contrato §4.4).

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.

## 3. Puesta en servicio en Railway

1. Comprueba que el servicio despliega una revisión de `G4-Retail-backend` que incluya la corrección del PR #24 y que tenga activo el perfil `supabase`. Si usa una variable explícita `RETAIL_PICKUP_MODO`, su valor debe ser `g5`.
2. Carga `G7_CLIENT_SECRET` en las variables del servicio del backend. Usa el secreto emitido por G7 para `modulo-retail`, con acceso a `api-ventas` y permisos `ventas:pedidos:consultar` y `ventas:pedidos:estado`. Aplica los cambios con un nuevo despliegue.
3. Ingresa con un vendedor de la sucursal del pedido de prueba. Si su perfil guarda la tienda como UUID, comprueba que esté asociado al código de G5 en `RETAIL_TIENDAS_POR_UUID`. Consulta la bandeja y verifica que aparezca el pedido de prueba listo para recoger.
4. Confirma la entrega de ese pedido de prueba. Verifica que Retail devuelve `200` con `constanciaId`, que el pedido sale de la bandeja y que G5 lo registra como `ENTREGADO`.
