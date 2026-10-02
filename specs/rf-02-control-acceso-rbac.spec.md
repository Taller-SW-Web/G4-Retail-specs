# Spec — RF-02: Control de Acceso por Roles (RBAC) (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-02: Control de Acceso por Roles (RBAC)
### Funcionalidad Padre: F1: Inicio de Sesión del Vendedor
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
El ecosistema multicanal cuenta con múltiples roles (clientes compradores, administradores generales, encargados de almacén, repartidores). Si un usuario con rol de cliente o sin privilegios de mostrador intenta ingresar a la terminal Retail, podría acceder a información confidencial de ventas, modificar carritos o emitir comprobantes fraudulentos.

## ¿Para qué? (objetivo)
Garantizar que únicamente los usuarios autorizados para operar la terminal de tienda (`VENDEDOR`, `CAJERO` o `SUPERVISOR`) puedan acceder al sistema de Retail, denegando el paso de forma inmediata a cualquier otro usuario y protegiendo las vistas y rutas operativas internas.

## ¿Hasta dónde? (alcance)
* **Incluido:** Validación del claim de rol en el token JWT, verificación del perfil operativo en la base de datos local de Retail (`RET_PERSONAL_TIENDA`), discriminación entre perfiles operativos (`VENDEDOR`, `CAJERO`, `SUPERVISOR`), emisión de respuesta HTTP `403 Forbidden` cuando el usuario no posea perfil activo en la sucursal, y guardianes de ruta (*Route Guards*) en el frontend.
* **Excluido:** Proceso inicial de autenticación de credenciales (cubierto en RF-01), manejo de expiración y almacenamiento del token (cubierto en RF-03), y aprovisionamiento global de cuentas de usuario.

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/auth/login` (Sección 1)
* **Modelo:** `RET_PERSONAL_TIENDA` (`id_personal`, `usuario_id`, `tienda_id`, `codigo_vendedor`, `perfil_tienda`: `"VENDEDOR" | "CAJERO" | "SUPERVISOR"`, `activo`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Intermediario de Autorización)
1. Al recibir la respuesta exitosa `200 OK` del servicio de autenticación con el token JWT:
   * Valida que el claim de rol contenga `VENDEDOR`.
   * Si no contiene `VENDEDOR` (ej. rol `CLIENTE` u otros no autorizados), responde `403 Forbidden`.
2. Con el identificador del usuario (`sub`), consulta la tabla local `RET_PERSONAL_TIENDA`:
   * Verifica que exista un registro con `activo = true` para la sucursal correspondiente.
   * Si no existe o se encuentra inactivo, deniega el acceso con `403 Forbidden` y mensaje: `{"error": "FORBIDDEN", "mensaje": "Usuario sin perfil operativo activo en esta tienda"}`.
   * Obtiene el `perfil_tienda` asignado (`VENDEDOR`, `CAJERO` o `SUPERVISOR`) y lo asocia al contexto de sesión del personal.
3. En cada endpoint interno de Retail que requiera autorización:
   * Endpoints de mostrador/catálogo: accesibles para `VENDEDOR`, `CAJERO` y `SUPERVISOR`.
   * Endpoints de apertura/cierre de caja y arqueo: requieren perfil `CAJERO` o `SUPERVISOR`.
   * Endpoints de autorización de egresos menores o excepciones: requieren perfil `SUPERVISOR`.

### Frontend
1. Implementa guardianes de navegación (*Navigation Guards* / Middleware de ruta) que interceptan cada cambio de URL en la aplicación web.
2. Si un usuario sin perfil autorizado intenta acceder manualmente a rutas restringidas:
   * Redirige inmediatamente a la pantalla de `/login`.
   * Despliega un banner de advertencia en color rojo: *"Acceso Restringido: Sus credenciales no cuentan con los privilegios requeridos"*.
3. En la interfaz principal, adapta los elementos visuales según el perfil local:
   * Vendedor: Consulta de catálogo, gestión de carritos y consulta de órdenes.
   * Cajero: Módulos de cobro, cuadre y cierre transaccional de turno.
   * Supervisor: Aprobación de retiros menores, autorización de discrepancias y desbloqueo de contingencias.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Login con credenciales válidas y perfil local `VENDEDOR` → Acceso concedido al catálogo y venta asistida.
- [ ] Login con credenciales válidas y perfil local `CAJERO` → Acceso concedido a las funciones operativas de caja.
- [ ] Login con credenciales válidas y perfil local `SUPERVISOR` → Acceso concedido a la consola de supervisión y autorizaciones.
- [ ] Login con credenciales válidas pero sin registro en `RET_PERSONAL_TIENDA` → Respuesta 403 Forbidden.
- [ ] Login con usuario no autorizado (ej. `CLIENTE`) → Respuesta 403 Forbidden y bloqueo de acceso.
- [ ] Intento de navegación directa a `/pos` sin sesión autenticada → Redirección automática a `/login`.
- [ ] Manipulación del token JWT → Firma inválida, rechazo inmediato en middleware con 401.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El token JWT debe contener firma válida y rol base `VENDEDOR`.
* El usuario debe estar registrado y activo en `RET_PERSONAL_TIENDA`.
* Clave pública (JWKS) disponible para verificación local de tokens.

## ¿Qué NO hará? (fuera de alcance)
* No permitirá modificar ni elevar privilegios de roles desde la interfaz de mostrador.
* No administrará jerarquías de permisos a nivel granular de base de datos (responsabilidad del módulo central de Seguridad).
