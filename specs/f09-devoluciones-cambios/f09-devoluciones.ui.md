# UI Spec — F9: Cambio directo de prenda (Semana 14)

**Acceso:** desde el POS para VENDEDOR o SUPERVISOR, con turno de caja abierto. Sin conexión (F10) la opción queda deshabilitada con su motivo.
**Referencias:** [Spec funcional](f09-devoluciones.md) y [Design System](../generales/design-system.md).

1. Buscar por número de boleta, por ejemplo `B001-00000045`.
2. Mostrar las prendas y las cantidades disponibles para cambio. Ante boleta inexistente, no elegible o fuera de los siete días calendario, mostrar el motivo y bloquear la selección.
3. Registrar motivo, etiquetas, signos de uso y estado del empaque. Para cambio de talla, bloquear el botón si las etiquetas no están intactas o la prenda presenta signos de uso. Indicar la derivación a Postventa en caso de falla de fábrica, sin continuar el cambio.
4. Elegir las prendas nuevas con el escáner o el catálogo (F2). Mostrar el crédito de la prenda devuelta, el total de las nuevas y la diferencia. Si la prenda nueva es el mismo modelo en otra talla o color, mostrar "Cambio sin costo" sin comparar precios. En otro caso, si el total nuevo es menor que el crédito, avisar que el cambio solo es por igual o mayor valor y bloquear la confirmación.
5. Con diferencia a pagar, cobrarla en el mismo modal de cobro de F5 (efectivo, tarjeta o mixto) y emitir la boleta de las prendas nuevas. Sin diferencia, confirmar sin cobro.
6. Imprimir el resultado: la constancia de cambio con su número `CAMB-…` (mismo valor) o la boleta con el crédito y la diferencia como medios de pago (mayor valor). Ambos referencian la boleta original.
