# UI Spec — F3: Búsqueda y Registro Rápido de Clientes

**Pantalla:** Sección de Cliente en POS y Modal de Alta Rápida  
**Ubicación:** Cabecera del panel derecho en `/pos`  
**Spec Funcional:** `f03-clientes.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Cajero/Vendedor atendiendo en mostrador. Necesita ingresar el DNI del cliente en 3 segundos para que la boleta salga con su nombre, o registrarlo sin salir del flujo de cobro si es cliente nuevo.

## 2. Objetivo de la Pantalla
Permitir la identificación rápida del cliente en terminal y alta express en caso de no encontrarse registrado.

## 3. Composición y Componentes
- **Barra de Cliente (`CustomerSection`):**
  - Selector compacto de Tipo de Documento: DNI, RUC, CE.
  - Input numérico con máscara (8 dígitos exactos para DNI).
  - Indicador de estado:
    - Estado vacío: *"Cliente no identificado (Boleta anónima)"*.
    - Cliente asignado: Nombre en negrita, DNI en gris y botón `ActionIcon` para remover cliente.
- **Modal de Alta Rápida (`QuickCustomerModal`):**
  - Título: *"Registrar Nuevo Cliente"*.
  - Campo Documento (deshabilitado, con el valor buscado).
  - Campos: Nombres, Apellidos, Correo Electrónico (opcional pero recomendado), Teléfono.
  - Botón *"Guardar y Vincular"* (variante `Confirm`).
  - Botón *"Cancelar"* (variante `Secondary`).

## 4. Ciclo de Estados de la Interfaz

| Estado | Comportamiento Visual |
|---|---|
| **No Identificado** | Input en blanco; leyenda indicando que la venta procederá como *Cliente Varios / Sin DNI*. |
| **Buscando** | Spinner dentro del campo de documento mientras consulta a la API. |
| **Encontrado** | Tarjeta pequeña con check verde: *"Cliente verificado: Juan Pérez"* y botón para cambiar. |
| **No Encontrado** | Mensaje de advertencia amigable y botón destacado: *"+ Registrar cliente express"*. |
| **Guardando Registro** | Spinner en el botón del modal y bloqueo de campos. |

## 5. Tono Visual y Mapeo al Design System

| Elemento UI | Token / Clase del Design System |
|---|---|
| Input Documento | `border border-border-default rounded-lg px-3 py-1.5 font-mono text-sm` |
| Cliente Verificado | `bg-surface-cloud-subtle border border-border-default rounded-lg p-2 flex items-center justify-between` |
| Modal Alta | `bg-white rounded-2xl p-6 shadow-xl max-w-lg border border-border-default` |
| Botón Guardar | `bg-accent-signal text-text-inverse hover:opacity-90 font-semibold px-4 py-2 rounded-lg` |
