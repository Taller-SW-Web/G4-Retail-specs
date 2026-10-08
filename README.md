# Sistema de Punto de Venta Retail (POS Mostrador) — Grupo 4

Proyecto académico de la Facultad de Ingeniería de Sistemas e Informática (**UNMSM**), perteneciente al curso de **Taller de Construcción de Software Web (Ciclo 2026-II)**. Forma parte del ecosistema de **Marketplace Multicanal de Artículos Deportivos** y representa el canal web para el vendedor y cajero en mostrador.

El desarrollo se rige estrictamente bajo la metodología **Spec-Driven Development (SDD)** asistido por agentes de Inteligencia Artificial (Antigravity, Claude Code, Copilot). En este proyecto **el código no es lo primero que se escribe: nace de especificaciones formalizadas y versionadas en `/specs`**, las cuales constituyen la única fuente de verdad.

---

## 1. Propósito Funcional

Permite operar la atención comercial en mostrador de tiendas físicas deportivas: identificación rápida de clientes por DNI/RUC, lectura de artículos mediante escáner de código de barras (EAN-13 / Code128), gestión de carrito de compras en terminal, cobro en efectivo con cálculo de vuelto o tarjeta, emisión de comprobantes electrónicos (boletas/facturas), entrega física de pedidos de retiro en tienda (*Store Pickup*) y control de caja con arqueo ciego (*Corte Z*).

---

## 2. Alcance del Proyecto

* **Hito 3 (Semana 8 — Examen Parcial / Happy Path Operativo):**
  * F1: Inicio de sesión del personal de tienda y resolución de roles (Cajero/Vendedor).
  * F2: Consulta de catálogo con lector prioritario de código de barras.
  * F3: Búsqueda y alta rápida de clientes por DNI/RUC.
  * F4: Carrito de compras POS con cálculo de IGV (18%) y soporte de ventas en espera.
  * F5: Registro de venta, cobro multimétodo y emisión de boleta electrónica.
  * F8: Apertura de turno de caja con fondo fijo inicial.
* **Alcance Completo del Ciclo (Semanas 9 a 16):**
  * F6: Consulta histórica y trazabilidad de pedidos multicanal.
  * F7: Bandeja y entrega presencial de pedidos *Store Pickup*.
  * F8: Cierre de turno de caja con arqueo ciego (*Corte Z*).
  * F9: Gestión de devoluciones, inspección de prendas y emisión de vales de compra.
  * F10: Modo de contingencia offline con almacenamiento en IndexedDB y sincronización diferida.
  * F11: Tablón de alertas operativas (stock crítico y avisos del día).
  * F12: Reporte de discrepancias de inventario y prendas en cuarentena.

---

## 3. Arquitectura y Stack Tecnológico

| Capa | Stack Tecnológico |
|---|---|
| **Frontend (`G4-Retail-frontend`)** | React 18+ + TypeScript + Vite. Tailwind CSS bajo arquitectura Atomic Design. Estado global con Redux Toolkit / Zustand y estado local con `useState`. Testing unitario con Vitest. |
| **Backend (`G4-Retail-backend`)** | Java 17/21 + Spring Boot 3.x con Spring Data JPA + Hibernate. Validaciones con Bean Validation. Build tool: Maven Wrapper (`./mvnw`). |
| **Base de Datos** | PostgreSQL alojado en la nube en **Supabase**. Esquema DDL en `diseño/schema.sql` y datos semilla en `seed.sql`. |
| **Comunicación Intermodular** | API REST vía HTTPS/TLS. Contrato oficial centralizado en [`specs/generales/api-contracts.md`](specs/generales/api-contracts.md). En desarrollo local se emplean Mocks controlados para aislar dependencias externas (Ventas G5, Seguridad G7, Catálogo G6). |

Detalle arquitectónico completo: [`specs/generales/overview.md`](specs/generales/overview.md) y [`diseño/modelo-datos.md`](diseño/modelo-datos.md).

---

## 4. Estructura del Repositorio

```text
G4-Retail-specs/
├── AGENTS.md                         Reglas obligatorias de SDD, arquitectura y convenciones para IA y devs
├── G4-Retail.code-workspace          Workspace multi-raíz de VS Code (Specs + Front + Back)
├── FUNCIONALIDADES-RF.md             Matriz maestra de trazabilidad (12 Funcionalidades y 34 RFs MoSCoW)
├── README.md                         Visión general y tabla índice de specs navegable
├── diseño/                           Modelo Entidad-Relación, diccionario de datos y schema DDL SQL
├── assets/                           Diagramas de arquitectura C4, guía semanal y lineamientos de curso
└── specs/                            FUENTE DE VERDAD: Especificaciones formales del sistema
    ├── generales/                    Overview, design system, contratos de API
    │   ├── overview.md
    │   ├── design-system.md
    │   └── api-contracts.md
    ├── f01-autenticacion-personal/   F1: Login y RBAC (RF-01, RF-02, RF-03)
    ├── f02-catalogo-productos/       F2: Catálogo y Lector de Barras (RF-04, RF-05, RF-06)
    ├── f03-gestion-clientes/         F3: Búsqueda y Alta de Clientes (RF-07, RF-08, RF-09)
    ├── f04-carrito-mostrador/        F4: Carrito POS y Totales (RF-10, RF-11, RF-12)
    ├── f05-orden-cobro/              F5: Venta y Emisión de Boleta (RF-13, RF-14, RF-15)
    ├── f06-trazabilidad-pedidos/     F6: Histórico y Trazabilidad (RF-16, RF-17)
    ├── f07-retiro-tienda-pickup/     F7: Despacho Pickup en Tienda (RF-18, RF-19)
    ├── f08-caja-turnos/              F8: Turnos de Caja y Corte Z (RF-20, RF-21, RF-22)
    ├── f09-devoluciones-cambios/     F9: Cambios y Vales de Compra (RF-23, RF-24, RF-25)
    ├── f10-contingencia-offline/     F10: Modo Offline e IndexedDB (RF-26, RF-27, RF-28)
    ├── f11-alertas-operativas/       F11: Alertas y Promociones (RF-29, RF-30, RF-31)
    └── f12-discrepancias-inventario/ F12: Mermas y Cuarentena de Stock (RF-32, RF-33, RF-34)
```

---

## 5. Metodología: Spec-Driven Development (SDD)

Cada funcionalidad del sistema sigue un ciclo riguroso de cuatro artefactos antes de considerar completado su desarrollo:

1. **Spec Funcional (`.md`):** Problema, objetivo de negocio, alcance, comportamiento detallado de backend y frontend, criterios de aceptación verificables y precondiciones.
2. **Spec de UI (`.ui.md`):** Usuario objetivo en mostrador, composición de vistas, atajos de teclado, estados de pantalla (vacío, cargando, error, contingencia) y alineación con los tokens de [`design-system.md`](specs/generales/design-system.md).
3. **Tasks (`.tasks.md`):** Desglose atómico de tareas técnicas para backend y frontend. Cada tarea se implementa individualmente y culmina con al menos un test unitario derivado de la spec antes de hacer commit.
4. **Plan (`.plan.md`):** Plan técnico de implementación, decisiones de arquitectura y registro de regularizaciones/bugs detectados.

---

## 6. 🗺️ Tabla Maestra / Índice de Specs

| # | Funcionalidad Macro | Responsable | Prioridad | Spec Funcional | Spec de UI | Tasks (TDD) | Plan Técnico |
|:---:|---|---|:---:|:---:|:---:|:---:|:---:|
| **G** | **Especificaciones Generales** | *Equipo G4* | Base | [overview](specs/generales/overview.md) · [contratos](specs/generales/api-contracts.md) | [design-system](specs/generales/design-system.md) | — | — |
| **F1** | Inicio de Sesión del Vendedor | Cristhian | Must Have | [f01-autenticacion](specs/f01-autenticacion-personal/f01-autenticacion.md) | [f01.ui](specs/f01-autenticacion-personal/f01-autenticacion.ui.md) | [f01.tasks](specs/f01-autenticacion-personal/f01-autenticacion.tasks.md) | [f01.plan](specs/f01-autenticacion-personal/f01-autenticacion.plan.md) |
| **F2** | Catálogo y Código de Barras | Kevin / Cristhian | Must Have | [f02-catalogo](specs/f02-catalogo-productos/f02-catalogo.md) | [f02.ui](specs/f02-catalogo-productos/f02-catalogo.ui.md) | [f02.tasks](specs/f02-catalogo-productos/f02-catalogo.tasks.md) | [f02.plan](specs/f02-catalogo-productos/f02-catalogo.plan.md) |
| **F3** | Búsqueda y Alta de Clientes | Guillermo / Kevin | Must Have | [f03-clientes](specs/f03-gestion-clientes/f03-clientes.md) | [f03.ui](specs/f03-gestion-clientes/f03-clientes.ui.md) | [f03.tasks](specs/f03-gestion-clientes/f03-clientes.tasks.md) | [f03.plan](specs/f03-gestion-clientes/f03-clientes.plan.md) |
| **F4** | Carrito de Compras Mostrador | Mihael / Kevin | Must Have | [f04-carrito](specs/f04-carrito-mostrador/f04-carrito.md) | [f04.ui](specs/f04-carrito-mostrador/f04-carrito.ui.md) | [f04.tasks](specs/f04-carrito-mostrador/f04-carrito.tasks.md) | [f04.plan](specs/f04-carrito-mostrador/f04-carrito.plan.md) |
| **F5** | Venta Asistida y Emisión Boleta | Miguel / Kevin | Must Have | [f05-orden-cobro](specs/f05-orden-cobro/f05-orden-cobro.md) | [f05.ui](specs/f05-orden-cobro/f05-orden-cobro.ui.md) | [f05.tasks](specs/f05-orden-cobro/f05-orden-cobro.tasks.md) | [f05.plan](specs/f05-orden-cobro/f05-orden-cobro.plan.md) |
| **F6** | Consulta Histórica de Pedidos | Maylle | Should Have | [f06-trazabilidad](specs/f06-trazabilidad-pedidos/f06-trazabilidad.md) | [f06.ui](specs/f06-trazabilidad-pedidos/f06-trazabilidad.ui.md) | [f06.tasks](specs/f06-trazabilidad-pedidos/f06-trazabilidad.tasks.md) | [f06.plan](specs/f06-trazabilidad-pedidos/f06-trazabilidad.plan.md) |
| **F7** | Retiro en Tienda (Store Pickup) | Maylle / Kevin | Must Have | [f07-pickup](specs/f07-retiro-tienda-pickup/f07-pickup.md) | [f07.ui](specs/f07-retiro-tienda-pickup/f07-pickup.ui.md) | [f07.tasks](specs/f07-retiro-tienda-pickup/f07-pickup.tasks.md) | [f07.plan](specs/f07-retiro-tienda-pickup/f07-pickup.plan.md) |
| **F8** | Turnos de Caja y Arqueo Ciego | Angie / Cristhian | Must Have | [f08-caja-turnos](specs/f08-caja-turnos/f08-caja-turnos.md) | [f08.ui](specs/f08-caja-turnos/f08-caja-turnos.ui.md) | [f08.tasks](specs/f08-caja-turnos/f08-caja-turnos.tasks.md) | [f08.plan](specs/f08-caja-turnos/f08-caja-turnos.plan.md) |
| **F9** | Cambios de Prenda y Vales | Guillermo | Should Have | [f09-devoluciones](specs/f09-devoluciones-cambios/f09-devoluciones.md) | [f09.ui](specs/f09-devoluciones-cambios/f09-devoluciones.ui.md) | [f09.tasks](specs/f09-devoluciones-cambios/f09-devoluciones.tasks.md) | [f09.plan](specs/f09-devoluciones-cambios/f09-devoluciones.plan.md) |
| **F10** | Modo Offline y Sincronización | Kevin / Cristhian | Should Have | [f10-contingencia](specs/f10-contingencia-offline/f10-contingencia-offline.md) | [f10.ui](specs/f10-contingencia-offline/f10-contingencia-offline.ui.md) | [f10.tasks](specs/f10-contingencia-offline/f10-contingencia-offline.tasks.md) | [f10.plan](specs/f10-contingencia-offline/f10-contingencia-offline.plan.md) |
| **F11** | Alertas de Stock y Promociones | Guillermo / Maylle | Could Have | [f11-alertas](specs/f11-alertas-operativas/f11-alertas.md) | [f11.ui](specs/f11-alertas-operativas/f11-alertas.ui.md) | [f11.tasks](specs/f11-alertas-operativas/f11-alertas.tasks.md) | [f11.plan](specs/f11-alertas-operativas/f11-alertas.plan.md) |
| **F12** | Discrepancias y Cuarentena Stock | Angie / Guillermo | Could Have | [f12-discrepancias](specs/f12-discrepancias-inventario/f12-discrepancias.md) | [f12.ui](specs/f12-discrepancias-inventario/f12-discrepancias.ui.md) | [f12.tasks](specs/f12-discrepancias-inventario/f12-discrepancias.tasks.md) | [f12.plan](specs/f12-discrepancias-inventario/f12-discrepancias.plan.md) |

---

## 7. Instrucciones para Desarrolladores

### 7.1 Espacio de Trabajo Unificado (VS Code Workspace)
El proyecto cuenta con el archivo de configuración multi-raíz `G4-Retail.code-workspace`. Al abrirlo en Visual Studio Code, se visualizarán los 3 repositorios sincronizados:
1. `G4-Retail - Specs y gobernanza` (`.`)
2. `G4-Retail-frontend`
3. `G4-Retail-backend`

### 7.2 Reglas para Agentes de IA y Contribuidores
Antes de escribir cualquier línea de código, leer obligatoriamente [`AGENTS.md`](AGENTS.md).
* No inventar rutas ni formatos JSON sin actualizar primero [`specs/generales/api-contracts.md`](specs/generales/api-contracts.md).
* Toda tarea implementada en backend o frontend debe incluir su test automatizado correspondiente.
* Consignar commits atómicos asociados a cada tarea (`feat: ...`, `test: ...`, `fix: ...`).

---

## 8. Equipo de Trabajo (Grupo 4)

* **Mihael** — *Product Owner (PO)*
* **Miguel** — *DevOps / Tech Lead*
* **Kevin** — *Frontend / UX*
* **Cristhian** — *Backend Developer Lead*
* **Maylle** — *Arquitectura de Software*
* **Guillermo** — *QA / Control de Calidad*
* **Angie** — *DBA (Database Administrator)*

---
*UNMSM — Facultad de Ingeniería de Sistemas e Informática — Taller de Construcción de Software Web (2026-II)*