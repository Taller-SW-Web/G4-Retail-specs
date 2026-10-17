# Spec — F1: Inicio de Sesión del Vendedor (v1.0)

### Responsable: Cristhian (Backend Developer)
### Requerimientos Funcionales Incluidos: RF-01, RF-02, RF-03
### Prioridad: Must have (Crítico para Hito 3)

---

## 1. ¿Por qué? (Problema de Negocio)
El personal de tienda (vendedores y cajeros) requiere ingresar a la terminal POS de mostrador de forma segura para operar el sistema durante jornadas laborales de hasta 8 horas. Sin un mecanismo de autenticación con credenciales institucionales, control de acceso por roles (RBAC) y persistencia segura de sesión:
1. No es posible validar la identidad del usuario ni asociar la tienda física correspondiente.
2. Usuarios con roles no autorizados (como clientes o externos) podrían ingresar a funciones de caja y ventas.
3. Si la sesión se pierde al recargar el navegador, se interrumpe la atención de clientes en la fila de mostrador.

---

## 2. ¿Para qué? (Objetivo)
Permitir al usuario ingresar su correo corporativo institucional y contraseña, autenticar contra el módulo de *Seguridad y Usuarios* (G7) para obtener un token JWT de acceso válido, verificar los roles asignados (`VENDEDOR`, `SUPERVISOR`) contra la base operativa local `RET_PERSONAL_TIENDA` mediante el endpoint `GET /api/v1/retail/perfil`, inyectar la cabecera `Authorization: Bearer <token>` en las peticiones y persistir la sesión de forma segura y recuperable.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Formulario de autenticación en la interfaz de Retail conectado al servicio de autenticación de Seguridad (G7).
  * Exposición de `GET /api/v1/retail/perfil` en el backend de Retail para resolver el perfil operativo del vendedor y su tienda asignada.
  * Interceptor de seguridad en backend para validar el token JWT emitido por Seguridad (G7).
  * Validación de perfiles y permisos operativos en mostrador (RBAC: `VENDEDOR` y `SUPERVISOR`).
  * Persistencia segura de sesión en `sessionStorage` / memoria y recuperación automática tras recarga.
  * Cierre voluntario de sesión (*Logout*) y expiración automática ante inactividad o fin de turno.
* **Excluido:**
  * Almacenamiento y validación local de contraseñas o hashes (delegado 100% al módulo de Seguridad G7).
  * Registro de nuevos usuarios o recuperación de claves (administrados centralmente por G7).
  * Políticas complejas de Refresh Tokens externos (al expirar el turno se solicita reingreso de contraseña).

---

## 4. Referencias y Contratos
* **Contrato de API Retail:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `GET /api/v1/retail/perfil` y `GET /api/v1/retail/health`
* **Contrato de API Seguridad (G7):** `POST /api/v1/auth/login`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_PERSONAL_TIENDA`, `RET_TIENDAS`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-01"></a>RF-01: Autenticación de Personal de Tienda y Resolución de Perfil
* **Backend (`ms-retail`):**
  1. No almacena ni valida contraseñas de personal (responsabilidad exclusiva de Seguridad G7).
  2. Expone `GET /api/v1/retail/perfil` protegido por cabecera `Authorization: Bearer <token>`.
  3. Extrae el identificador de usuario (`usuarioId` / `sub`) del token JWT emitido por G7.
  4. Consulta la tabla operativa `RET_PERSONAL_TIENDA` filtrando por `usuario_id` y `activo = true`.
  5. Si el token no es válido o no está presente, responde `401 Unauthorized` (`TOKEN_INVALIDO`).
  6. Si el usuario no tiene registro de personal o está inactivo, responde `403 Forbidden` (`FORBIDDEN_USUARIO_SIN_TIENDA`).
  7. Retorna `200 OK` con `{ usuarioId, codigoVendedor, perfilTienda, tiendaId, activo }`.
* **Frontend:**
  1. Formulario de Login con Correo Corporativo y Contraseña.
  2. Invoca el endpoint de Seguridad (G7) `POST /api/v1/auth/login` (o mock controlado en desarrollo) para obtener el token JWT.
  3. Al obtener el token, invoca inmediatamente al backend de Retail: `GET /api/v1/retail/perfil` inyectando el Bearer token.
  4. Guarda el perfil operativo y el token en el store de sesión (`authStore` / `sessionStorage`).
  5. Ante credenciales erróneas en G7 (401), muestra alerta: *"Credenciales incorrectas. Verifique su correo y contraseña"*.
  6. Ante usuario no asignado en Retail (403), muestra alerta: *"Usuario no registrado o inactivo en esta tienda"*.
* **Criterios de Aceptación (RF-01):**
  - [ ] Credenciales válidas en G7 retornan token JWT que permite consultar `GET /api/v1/retail/perfil` exitosamente con 200 OK.
  - [ ] Credenciales erróneas en G7 retornan 401 Unauthorized con código `CREDENCIALES_INVALIDAS`.
  - [ ] Petición a `GET /api/v1/retail/perfil` sin Bearer token retorna 401 Unauthorized.
  - [ ] Usuario sin registro activo en `RET_PERSONAL_TIENDA` retorna 403 Forbidden con código `FORBIDDEN_USUARIO_SIN_TIENDA`.
  - [ ] El botón de ingreso muestra spinner y bloquea múltiples clics accidentales.

---

### <a id="rf-02"></a>RF-02: Control de Acceso por Roles (RBAC)
* **Backend:**
  1. Al validar el JWT, verifica que el usuario posea rol autorizado para operar en tienda.
  2. Consulta la tabla `RET_PERSONAL_TIENDA`:
     * Verifica que el usuario tenga un registro con `activo = true` en la tienda seleccionada.
     * Si no existe o está inactivo, deniega el paso con `403 Forbidden` (`FORBIDDEN_USUARIO_SIN_TIENDA`).
     * Determina el perfil operativo: `VENDEDOR` o `SUPERVISOR` (Decisión D-08).
  3. Protege los endpoints internos según el perfil:
     * Catálogo, venta, cobro, apertura y cierre de caja: accesible para `VENDEDOR` y `SUPERVISOR`.
     * Autorización de egresos especiales o excepciones administrativas: requiere `SUPERVISOR`.
* **Frontend:**
  1. Guardianes de ruta (*Route Guards* / `RequireAuth`) que interceptan la navegación.
  2. Si un usuario sin perfil autorizado intenta acceder a `/pos` o `/caja`, redirige a `/login` con advertencia de acceso denegado.
  3. Adapta la botonera y opciones según el perfil activo (funciones de supervisión restringidas).
* **Criterios de Aceptación (RF-02):**
  - [ ] Usuario con perfil `VENDEDOR` accede a la terminal POS para ventas, cobro y operaciones de caja.
  - [ ] Usuario con perfil `SUPERVISOR` accede a funciones de supervisión y anulación/egresos.
  - [ ] Usuario sin registro en `RET_PERSONAL_TIENDA` o con rol ajeno recibe 403 Forbidden (`FORBIDDEN_USUARIO_SIN_TIENDA`).
  - [ ] Intento de navegación directa a `/pos` sin sesión autenticada redirige inmediatamente a `/login`.

---

### <a id="rf-03"></a>RF-03: Gestión y Persistencia de Sesión Segura
* **Backend:**
  1. Provee un filtro/interceptor que valida la cabecera `Authorization: Bearer <token>` en cada endpoint protegido.
  2. Valida expiración (`exp`) y firma criptográfica.
  3. Si el token expiró, responde `401 Unauthorized` con cabecera `WWW-Authenticate`.
* **Frontend:**
  1. Almacena el token y perfil en `sessionStorage` para aislar la terminal de pestañas ajenas.
  2. Interceptor HTTP que inyecta automáticamente `Authorization: Bearer <token>` en cada llamado.
  3. Muestra en el Header: nombre del vendedor, rol activo y tienda física activa.
  4. Botón *"Cerrar Sesión"* con modal de confirmación; al confirmar, purga el token y el carrito y redirige a `/login`.
  5. Al recibir 401 por token expirado, muestra notificación y redirige al login.
* **Criterios de Aceptación (RF-03):**
  - [ ] Recargar la página (F5) mantiene al usuario autenticado sin solicitar clave nuevamente.
  - [ ] Todas las peticiones HTTP salientes incluyen la cabecera `Authorization: Bearer <token>`.
  - [ ] Cerrar sesión borra el token de memoria/almacenamiento y bloquea la navegación protegida.
  - [ ] Token expirado fuerza el retorno a `/login` con aviso de fin de sesión.

---

## 6. Precondiciones y Dependencias
* El personal debe existir registrado en el módulo de Seguridad (G7) y activo en `RET_PERSONAL_TIENDA`.
* Comunicación exclusivamente bajo protocolo HTTPS / TLS 1.3.
