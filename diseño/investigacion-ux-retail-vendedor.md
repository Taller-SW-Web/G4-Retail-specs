# Investigación UX: el vendedor de mostrador

**Funcionalidad:** F2 — Consulta de catálogo y disponibilidad (RF-04, RF-05, RF-06)
**Autor:** Kevin Mendoza — Frontend & UX Lead
**Hito:** 3 (Semana 8)

---

## 1. Por qué esta investigación

El Canal Retail no es una tienda en línea con otra piel. Son dos actividades distintas y, si se
diseñan igual, la de mostrador sale perdiendo:

| | E-commerce | Mostrador físico |
|---|---|---|
| Quién opera | el cliente, solo | el vendedor, frente al cliente |
| Qué busca | descubrir y comparar | **confirmar** lo que ya tiene en la mano |
| Tiempo disponible | ilimitado | el que tolera la cola detrás |
| Dispositivo | mouse y scroll | teclado y lector láser |
| Costo de un error | un carrito abandonado | una prenda entregada en la talla equivocada |

La consecuencia de diseño es directa: en e-commerce la interfaz invita a explorar; en mostrador
tiene que **cerrar la decisión en el menor número de acciones posible**, y ser imposible de
equivocar cuando el vendedor no está mirando la pantalla.

## 2. Método

Observación estructurada del flujo de atención presencial, apoyada en la evaluación heurística del
equipo ([`evaluacion_heuristica.md`](./evaluacion_heuristica.md)), simulando los dos escenarios que
dominan el mostrador:

1. **Escenario de etiqueta** — el cliente trae la prenda; el vendedor la escanea y cobra.
2. **Escenario de pregunta** — el cliente describe lo que quiere ("unas zapatillas de running, talla
   40") y el vendedor tiene que encontrarlo y verificar que hay esa talla.

En ambos se midió lo mismo: cuántas acciones separan el inicio de la atención del artículo correcto
en el carrito, y en qué punto el vendedor deja de mirar la pantalla.

## 3. Hallazgos

### H-01 · La mano que opera no es la que señala
El vendedor sostiene la prenda con una mano y el lector con la otra. El mouse exige soltar algo. Es
el hallazgo que ordena todo lo demás: **cada interacción que obliga a apuntar cuesta un movimiento
físico**, no un clic.

### H-02 · Escanear es teclear muy rápido
El lector láser es, para el navegador, un teclado que escribe un código y envía `Enter`. No hace
falta ninguna integración especial: basta que la caja de búsqueda tenga el foco. Lo que sí hace
falta es que el foco **vuelva solo** después de cada lectura, porque en mostrador se escanean varias
prendas seguidas.

### H-03 · El código de barras identifica la prenda, no el modelo
Una etiqueta no dice "Zapatillas Velocity X": dice esa talla, ese color. Si al escanear se abre la
ficha del modelo pidiendo elegir talla, se le está preguntando al vendedor algo que la etiqueta ya
respondió.

### H-04 · Esconder lo agotado hace perder la venta
Al ocultar las tallas sin stock, el vendedor concluye que el modelo no existe y deja ir al cliente.
Mostrarlas visibles pero bloqueadas comunica la verdad: el modelo está, esa talla no.

### H-05 · El precio se dice en voz alta antes de cobrarlo
El vendedor repite el precio al cliente mientras opera. Si el precio solo aparece en el carrito, lo
dice de memoria, y ahí es donde aparecen los reclamos en caja.

## 4. Decisiones de diseño

| Hallazgo | Decisión | Dónde se ve |
|---|---|---|
| H-01, H-02 | Campo de lectura con foco automático que se devuelve solo tras cada escaneo; las flechas recorren las tallas sin usar el mouse | `organisms/catalogo/ScannerSimulator.tsx`, `ProductDetailModal.tsx` |
| H-02 | La búsqueda acepta nombre, categoría, SKU **y código de barras**: para el buscador, escanear y teclear son lo mismo | `lib/catalog.ts` |
| H-03 | Escanear abre la ficha con la variante **ya seleccionada**; el vendedor solo confirma | `lib/scanner.ts`, `PosPage.tsx` |
| H-04 | Las tallas agotadas se muestran tachadas y deshabilitadas, nunca ocultas | `ProductDetailModal.tsx` |
| H-04 | No se puede agregar al carrito sin elegir una variante con existencias | `ProductDetailModal.tsx` |
| H-05 | Precio, SKU, código y semáforo de stock visibles en la ficha, antes del botón | `ProductDetailModal.tsx`, `molecules/StockBadge.tsx` |
| H-01 | Botones de talla y color de 44×44 px como mínimo (RNF-05) | `ProductDetailModal.tsx` |

## 5. Relación con las heurísticas de Nielsen

- **H1. Visibilidad del estado:** el semáforo de stock dice qué hay *en esta tienda*, no en la
  cadena, que es la única cifra que permite entregar la prenda hoy.
- **H2. Correspondencia con el mundo real:** la ficha se organiza como la caja del producto —
  modelo, color, talla— y no como un formulario.
- **H5. Prevención de errores:** la variante agotada se bloquea en el origen. El error no llega al
  cobro porque nunca entra al carrito.
- **H7. Flexibilidad y eficiencia:** el lector y el teclado son el camino rápido; el mouse sigue
  funcionando para quien recién entra al puesto.
- **H8. Diseño estético y minimalista:** la grilla muestra foto, nombre, precio y stock. Todo lo
  demás vive en la ficha, a un toque.

## 6. Pendientes

- **Stock real por tienda.** Productos (G6) no publica cantidades a los canales (X-P0-03): informa
  un estado, no un número. El semáforo con unidades exactas depende de que Inventario exponga el
  saldo por tienda; hoy el número sale del catálogo semilla.
- **La variante aún no viaja al carrito.** La ficha obliga a elegir talla y color y bloquea lo
  agotado, pero el carrito (F4) guarda el artículo, no el SKU. Coordinado con Mihael para el
  siguiente hito: es el cambio que permite vender dos tallas del mismo modelo en un ticket.
- **Medición en tienda.** Todo lo anterior sale de observación simulada. Falta cronometrar la
  atención real en una tienda con cola.
