# UI Spec — F1: Inicio de Sesión del Vendedor

**Pantalla:** Login POS / Autenticación de Terminal  
**Ruta:** `/login`  
**Spec Funcional:** `f01-autenticacion.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Vendedor o cajero que inicia su jornada laboral frente a la terminal física de tienda. Requiere una pantalla limpia, sin distracciones, con foco inmediato en el campo de correo y soporte para avanzar con la tecla `Enter`.

## 2. Objetivo de la Pantalla
Permitir el ingreso rápido y seguro a la terminal POS validando las credenciales corporativas y seleccionando la sucursal física correspondiente.

## 3. Composición y Layout (`AuthLayout`)
- Contenedor centrado vertical y horizontalmente sobre fondo sutil `--color-surface-cloud` (`#F7F5F0`).
- Tarjeta de autenticación (`Card` / `rounded-2xl`, borde `--color-border-default`, sombra suave).
- Cabecera con logo de la marca deportiva y título *"Terminal POS — Acceso a Tienda"*.
- Selector de Tienda física (`Select`): por defecto muestra la tienda principal (`TIENDA-MIRAFLORES`).
- Campo de Correo Corporativo (`Input` con icono de usuario/mail).
- Campo de Contraseña (`Input` de tipo `password` con icono de candado y opción de alternar visibilidad).
- Botón principal *"Ingresar a Terminal"* (`Button` variante `Primary` / `action-primary`).
- Pie de tarjeta con leyenda de soporte técnico institucional y versión del software.

## 4. Ciclo de Estados de la Interfaz

| Estado | Comportamiento Visual |
|---|---|
| **Inicial (Idle)** | Input de correo enfocado automáticamente. Botón "Ingresar a Terminal" deshabilitado hasta que ambos campos tengan contenido con formato válido. |
| **Validación en Vivo** | Si el correo no contiene `@` ni dominio válido, borde rojo semántico (`--color-semantic-error`) y texto de ayuda en pie de campo. |
| **En Envío (Loading)** | Botón principal pasa a estado deshabilitado con `Spinner` giratorio y texto *"Verificando credenciales..."*. Inputs bloqueados en modo `disabled`. |
| **Error (401 / 403)** | Alerta semántica superior (`Alert` variante `Error` con fondo `#FFF5F5` y borde `#E03131`): *"Credenciales incorrectas o usuario no asignado a esta tienda"*. El campo de contraseña se limpia y reenfoca. |
| **Éxito (200 OK)** | Breve transición visual y redirección inmediata a `/pos` o `/apertura-caja`. |

## 5. Tono Visual y Mapeo al Design System

| Elemento UI | Token / Clase del Design System |
|---|---|
| Tarjeta principal | `bg-white border border-border-default rounded-2xl p-8 max-w-md shadow-sm` |
| Tipografía Título | `font-display text-2xl uppercase tracking-wide text-text-primary` (Oswald) |
| Labels e Inputs | `text-sm font-semibold text-text-primary`, inputs `px-4 py-2 rounded-lg border-border-default` |
| Foco de Inputs | `focus:ring-2 focus:ring-accent-signal focus:border-transparent` |
| Botón Primario | `bg-action-primary text-text-primary hover:bg-action-primary-hover hover:text-text-inverse font-semibold py-3 rounded-lg` |

## 6. Restricciones y Atajos de Teclado
- Al presionar `Enter` en el campo de contraseña, se dispara el submit del formulario si la validación es satisfactoria.
- El formulario no permite auto-completado de contraseñas si la terminal se configura en modo kiosko público.
