# Spec — RF-02: Control de Acceso por Roles (RBAC) (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimiento Funcional: RF-02: Control de Acceso por Roles (RBAC)
### Funcionalidad Padre: F1: Inicio de Sesión del Vendedor
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
El ecosistema multicanal cuenta con múltiples roles (clientes compradores, administradores generales, encargados de almacén, repartidores). Si un usuario con rol de cliente o sin privilegios de mostrador intenta ingresar a la terminal Retail, podría acceder a información confidencial de ventas, modificar carritos o emitir comprobantes fraudulentos.

## ¿Para qué? (objetivo)
Garantizar que únicamente los usuarios que posean roles autorizados de operación física en tienda (`vendedor` o `cajero`) puedan acceder al sistema de Retail, denegando el paso de forma inmediata a cualquier otro rol y protegiendo las vistas y rutas operativas internas.

## ¿Hasta dónde? (alcance)
* **Incluido:** Validación de claims de rol dentro del payload del token JWT tras el login, discriminación entre roles autorizados (`vendedor`, `cajero`) y no autorizados (`cliente`, `invitado`, etc.), emisión de respuesta HTTP `403 Forbidden` cuando el rol no coincida, y guardianes de ruta (*Route Guards*) en el frontend.
* **Excluido:** Proceso inicial de autenticación de credenciales (cubierto en RF-01), manejo de expiración y almacenamiento del token (cubierto en RF-03), y asignación o cambio de roles en la base de datos central (administrado en *Seguridad y Usuarios*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/auth/login` (Sección 1)
* **Modelo:** `UsuarioRol` (`id`, `email`, `rol`: `"vendedor" | "cajero" | "cliente" | "admin"`, `tiendaId`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Intermediario de Autorización)
1. Al recibir la respuesta exitosa `200 OK` de *Seguridad y Usuarios*, inspecciona el campo `rol` del usuario asociado.
2. Si el rol es estrictamente `vendedor` o `cajero`:
   * Permite la finalización del flujo de inicio de sesión y entrega el token.
3. Si el rol no pertenece al personal autorizado de tienda (por ejemplo, rol `cliente` o usuario externo):
   * Intercepta la respuesta y deniega el acceso con `403 Forbidden`.
   * Retorna mensaje: `{"error": "FORBIDDEN", "mensaje": "Usuario no autorizado para operar la terminal de tienda"}`.
4. En cada endpoint interno de Retail que requiera autorización, valida que el claim `rol` del JWT corresponda a las acciones permitidas (ej. solo `cajero` para anulación o cobro especial si aplica).

### Frontend
1. Implementa guardianes de navegación (*Navigation Guards* / Middleware de ruta) que interceptan cada cambio de URL en la aplicación web.
2. Si un usuario sin rol autorizado intenta acceder manualmente a rutas como `/pos`, `/catalogo` o `/pickup`:
   * Redirige inmediatamente a la pantalla de `/login`.
   * Despliega un banner de advertencia en color rojo: *"Acceso Restringido: Sus credenciales no cuentan con perfil de Vendedor o Cajero"*.
3. En la interfaz principal, adapta los elementos visuales según el rol:
   * Vendedor: Acceso a consulta de catálogo, gestión de carrito y consulta de órdenes.
   * Cajero: Incluye además módulos de cuadre y cierre transaccional.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Login con credenciales válidas y rol `vendedor` → Acceso concedido al dashboard de mostrador.
- [ ] Login con credenciales válidas y rol `cajero` → Acceso concedido a las funciones operativas de caja.
- [ ] Login con credenciales válidas pero rol `cliente` → Respuesta 403 Forbidden y bloqueo de acceso con mensaje informativo.
- [ ] Intento de navegación directa a `/pos` sin rol autenticado → Redirección automática a `/login`.
- [ ] Manipulación del token JWT con rol alterado → Firma inválida, rechazo inmediato en middleware con 401/403.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El token JWT debe contener los claims de rol claramente tipificados en su carga útil.
* Regla de negocio: Solo los roles `vendedor` y `cajero` están autorizados para operar el Canal Retail.
* La clave secreta de verificación de firma JWT debe estar sincronizada con el servicio de autenticación.

## ¿Qué NO hará? (fuera de alcance)
* No permitirá modificar ni elevar privilegios de roles desde la interfaz de mostrador.
* No administrará jerarquías de permisos a nivel granular de base de datos (responsabilidad del módulo central de Seguridad).
