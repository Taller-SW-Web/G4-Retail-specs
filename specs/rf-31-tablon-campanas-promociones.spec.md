# Spec — RF-31: Tablón Informativo de Campañas y Promociones Vigentes (v0.1)

### Responsable: Mihael (Product Owner)
### Requerimiento Funcional: RF-31: Tablón Informativo de Campañas y Promociones Vigentes
### Funcionalidad Padre: F11: Torre de Control Operativa de Turno
### Prioridad: Could have (Opcional si F11 entra)

---

## ¿Por qué? (problema)
Las tiendas deportivas activan con frecuencia campañas comerciales dinámicas (ej. *"2x1 en camisetas de fútbol"*, *"Segundo par de zapatillas al 50%"* o *"Cupón de 20% pagando con Tarjeta X"*). Si el vendedor de mostrador no tiene una "chuleta" o tablón visual en su propia pantalla que le recuerde las promociones del día, pierde la oportunidad de asesorar activamente al cliente (up-selling/cross-selling) o aplica descuentos de manera incorrecta.

## ¿Para qué? (objetivo)
Proveer al vendedor de una barra o tablón informativo superior en el POS que resuma de forma sintética las campañas comerciales, combos activos y cupones vigentes aplicables en el canal Retail durante el día, con la posibilidad de copiar cupones o ver las condiciones de la promoción en un clic.

## ¿Hasta dónde? (alcance)
* **Incluido:** Tira informativa (*ticker/banner*) o carrusel horizontal discreto en la parte superior del POS; consulta al endpoint de promociones de *Productos y Ofertas*; despliegue de título de la campaña, vigencia y beneficio (ej. `2x1`, `-20%`); modal desplegable *"Ver Detalle de Campaña"* con lista de marcas/categorías participantes; y botón *"Aplicar Cupón al Carrito"* con un solo clic.
* **Excluido:** Creación o edición de reglas de precios (administrado por el gestor comercial en *Productos y Ofertas*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/promociones/vigentes?canal=RETAIL`
* **Modelo:** `CampanaPromocionalItem` (`id`, `titulo`, `tipoBeneficio`, `descripcionCorta`, `codigoCuponSugerido`, `fechaFinVigencia`, `categoriasParticipantes`: `[]`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Pasarela a Ofertas)
1. Expone `GET /api/v1/retail/control/campanas-vigentes`:
   * Consulta a *Productos y Ofertas* las promociones que tengan `canalAplicable == 'RETAIL'` y cuya fecha actual esté dentro de su vigencia.
   * Filtra las campañas más relevantes para la venta asistida.
2. Retorna la lista en formato JSON ligero con TTL de caché de 15 minutos.

### Frontend
1. Barra horizontal en la cabecera del POS (*"Promociones del Día en Mostrador"*):
   * Muestra chips de campañas con íconos llamativos:
     * Chip 1: `🏷️ 2x1 en Medias Deportivas (Fútbol / Running)`.
     * Chip 2: `⚡ 30% en Chimpunes Adidas con Cupón GOAL2026`.
     * Chip 3: `👕 Combo Camiseta + Short con 15% de Descuento`.
2. Interacción con el chip de campaña:
   * Al hacer clic en un chip de cupón: Copia automáticamente el código al portapapeles o lo inyecta directamente en el campo de cupón del Carrito POS (RF-11).
   * Al hacer clic en *"Ver Condiciones"*: Despliega un popover informativo con los requisitos: *"Monto mínimo de compra S/ 150. Válido solo para marcas seleccionadas"*.
3. Opción de colapsar la barra para maximizar el área de catálogo en pantallas de menor resolución.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] La barra superior muestra las campañas vigentes para el canal Retail devueltas por el backend.
- [ ] Clic en una campaña con cupón rellena automáticamente el campo de cupón del carrito POS sin obligar al vendedor a memorizarlo o tipear.
- [ ] Clic en "Ver Condiciones" despliega las restricciones de marca, categoría y vigencia.
- [ ] Campañas expiradas no aparecen en el tablón informativo de mostrador.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Conexión con el microservicio de *Productos y Ofertas*.
* Regla de Negocio RN-04: Transparencia y cumplimiento de las promociones comerciales.

## ¿Qué NO hará? (fuera de alcance)
* No autoriza descuentos discrecionales no contemplados en las campañas oficiales.
