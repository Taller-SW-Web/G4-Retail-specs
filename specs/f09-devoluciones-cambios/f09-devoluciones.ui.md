# UI Spec — F9: Cambios y vales de compra (Semana 11)

**Acceso:** desde el POS para VENDEDOR o SUPERVISOR.
**Referencias:** [Spec funcional](f09-devoluciones.md) y [Design System](../generales/design-system.md).

1. Buscar por número de boleta, por ejemplo `B001-00000045`.
2. Mostrar las prendas y las cantidades disponibles para cambio. Ante boleta inexistente, no elegible o fuera de los siete días calendario, mostrar el motivo y bloquear la selección.
3. Registrar motivo, etiquetas, signos de uso y estado del empaque. Para cambio de talla, bloquear el botón si las etiquetas no están intactas o la prenda presenta signos de uso. Indicar la derivación a Postventa en caso de falla de fábrica.
4. Mostrar el vale emitido con su código, importe, código de barras, fecha de vencimiento y opción de impresión térmica.
