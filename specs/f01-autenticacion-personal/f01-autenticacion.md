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
Permitir al usuario ingresar su correo corporativo institucional y contraseña, validar la sintaxis de los datos, autenticar contra el módulo de *Seguridad y Usuarios* (G7), obtener un token JWT de acceso válido, verificar los roles asignados (`VENDEDOR`, `CAJERO`, `SUPERVISOR_TIENDA`) contra la base local `RET_PERSONAL_TIENDA`, inyectar la cabecera `Authorization: Bearer <token>` en las peticiones y persistir la sesión de forma segura y recuperable.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Formulario de autenticación en la interfaz de Retail y selector de tienda física.
  * Validación de credenciales y emisión de token JWT con vigencia de turno (8 horas).
  * Validación de perfiles y permisos operativos en mostrador (RBAC).
  * Persistencia segura de sesión en `sessionStorage` / memoria y recuperación automática tras recarga.
  * Cierre voluntario de sesión (*Logout*) y expiración automática ante inactividad o fin de turno.
* **Excluido:**
  * Registro de nuevos usuarios o recuperación de claves (administrados centralmente por el módulo de Seguridad G7).
  * Políticas complejas de Refresh Tokens externos (al expirar el turno se solicita reingreso de contraseña).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `POST /api/v1/auth/login`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_PERSONAL_TIENDA`, `RET_TIENDAS`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-01"></a>RF-01: Autenticación de Personal de Tienda
* **Backend:**
  1. Expone `POST /api/v1/auth/login` recibiendo `{ email, password, tiendaId }`.
  2. Valida estrictamente formato de correo corporativo (`@deportesretail.com`) y contraseña no vacía.
  3. Si los datos no cumplen la estructura, responde `400 Bad Request` indicando los campos inválidos.
  4. Valida credenciales contra Seguridad G7 (o mock local controlado). Si son erróneas o la cuenta está inactiva, responde `401 Unauthorized` con código `CREDENCIALES_INVALIDAS`.
  5. Retorna `200 OK` con token JWT, tiempo de expiración y datos básicos del usuario.
* **Frontend:**
  1. Formulario de Login con Correo Corporativo, Contraseña y selector de Tienda asignada.
  2. Botón *"Ingresar a Terminal"* deshabilitado hasta cumplir formato válido en ambos campos.
  3. Estado de carga (*loading spinner*) al enviar el formulario para evitar dobles clics.
  4. Ante error 401, muestra alerta amigable: *"Credenciales incorrectas. Verifique su correo y contraseña"*.
* **Criterios de Aceptación (RF-01):**
  - [ ] Credenciales válidas retornan 200 OK con token JWT no vacío y datos del usuario.
  - [ ] Credenciales erróneas retornan 401 Unauthorized con código `CREDENCIALES_INVALIDAS`.
  - [ ] Payload vacío o email inválido retorna 400 Bad Request.
  - [ ] El botón de ingreso muestra spinner y bloquea múltiples clics accidentales.

---

### <a id="rf-02"></a>RF-02: Control de Acceso por Roles (RBAC)
* **Backend:**
  1. Al validar el JWT, verifica que el usuario posea rol autorizado para operar en tienda.
  2. Consulta la tabla `RET_PERSONAL_TIENDA`:
     * Verifica que el usuario tenga un registro con `activo = true` en la tienda seleccionada.
     * Si no existe o está inactivo, deniega el paso con `403 Forbidden` (`FORBIDDEN_USUARIO_SIN_TIENDA`).
     * Determina el perfil operativo: `VENDEDOR`, `CAJERO` o `SUPERVISOR`.
  3. Protege los endpoints internos según el perfil:
     * Catálogo y carritos: accesible para `VENDEDOR`, `CAJERO` y `SUPERVISOR`.
     * Cobro, apertura y cierre de caja: requiere `CAJERO` o `SUPERVISOR`.
     * Autorización de egresos o excepciones: requiere `SUPERVISOR`.
* **Frontend:**
  1. Guardianes de ruta (*Route Guards* / `RequireAuth`) que interceptan la navegación.
  2. Si un usuario sin perfil autorizado intenta acceder a `/pos` o `/caja`, redirige a `/login` con advertencia de acceso denegado.
  3. Adapta la botonera y opciones según el perfil activo (oculta cierre de caja a vendedores simples).
* **Criterios de Aceptación (RF-02):**
  - [ ] Usuario con perfil `VENDEDOR` accede al catálogo y venta, pero tiene bloqueado el arqueo de caja.
  - [ ] Usuario con perfil `CAJERO` accede a terminal de cobro y apertura/cierre de caja.
  - [ ] Usuario sin registro en `RET_PERSONAL_TIENDA` o con rol ajeno recibe 403 Forbidden.
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
