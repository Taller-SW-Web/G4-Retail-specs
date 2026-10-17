# Tareas — F1: Inicio de Sesión del Vendedor

**Fuentes:** `f01-autenticacion.md` (RF-01, RF-02, RF-03), `f01-autenticacion.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-01): DTOs de Perfil de Tienda y Salud Operativa
- **Archivos:** `dto/PerfilPersonalResponse.java`, `dto/HealthResponse.java`.
- **Qué hace:** Estructuras de datos de salida para `GET /api/v1/retail/perfil` (`usuarioId`, `codigoVendedor`, `perfilTienda`, `tiendaId`, `activo`) y `GET /api/v1/retail/health` (`status`, `timestamp`, `service`).
- **Criterio que verifica:** Cumplimiento de contratos oficiales estipulados en `specs/generales/api-contracts.md` (§5.1 y §5.10).
- **Test:** `PerfilPersonalResponseTest.java` — Valida serialización/deserialización correcta de campos JSON.

### [ ] Tarea B2 (RF-01, RF-02): Servicio de Perfil Operativo y Validación RBAC
- **Archivos:** `service/RetailPerfilService.java`, `service/impl/RetailPerfilServiceImpl.java`, `repository/PersonalTiendaRepository.java`.
- **Qué hace:** Consulta `RET_PERSONAL_TIENDA` filtrando por `usuario_id` y `activo = true`. Si no existe o está inactivo, lanza excepción de negocio con código `FORBIDDEN_USUARIO_SIN_TIENDA` (403). Mapea el perfil operativo (`VENDEDOR`, `SUPERVISOR`, Decisión D-08).
- **Criterios que verifica:** "Usuario sin registro activo en RET_PERSONAL_TIENDA retorna 403 Forbidden" (RF-01) y "Resolución de perfil operativo RBAC" (RF-02).
- **Test:** `RetailPerfilServiceTest.java` — Prueba recuperación de perfil exitoso y lanzamiento de 403 ante usuario sin tienda.

### [ ] Tarea B3 (RF-01, RF-02): Controladores REST `GET /api/v1/retail/perfil` y `GET /api/v1/retail/health`
- **Archivos:** `controller/PerfilController.java`, `controller/HealthController.java`, `exception/GlobalExceptionHandler.java`.
- **Qué hace:** Expone las rutas REST bajo `/api/v1/retail/`, extrae el `usuarioId` del contexto de seguridad autenticado, invoca el servicio y mapea errores al formato homogéneo RFC 7807 (`problem+json`).
- **Criterios que verifica:** "GET /retail/perfil con token válido retorna 200 OK con perfil" y "Error 403 con código FORBIDDEN_USUARIO_SIN_TIENDA" (RF-01, RF-02).
- **Test:** `PerfilControllerTest.java` (MockMvc) — Comprueba contratos HTTP 200, 401 y 403.

### [ ] Tarea B4 (RF-03): Middleware Interceptor de Seguridad y Validación de Token JWT
- **Archivos:** `security/JwtAuthenticationFilter.java`, `security/JwtTokenValidator.java`, `config/SecurityConfig.java`.
- **Qué hace:** Intercepta peticiones protegidas, extrae `Authorization: Bearer <token>`, valida firma/expiración e inyecta el `usuarioId` en el SecurityContext. Permite acceso anónimo exclusivamente a `/api/v1/retail/health`.
- **Criterio que verifica:** "Token no presente o expirado responde 401 Unauthorized" (RF-03).
- **Test:** `JwtAuthenticationFilterTest.java` — Verifica acceso con token válido y rechazo 401 ante token ausente o expirado.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-01): Tipos, Cliente HTTP Centralizado y Servicio de Autenticación/Perfil
- **Archivos:** `types/auth.ts`, `api/http.ts`, `api/authApi.ts`.
- **Qué hace:** Declara tipos `LoginCredentials`, `AuthTokenResponse`, `PerfilPersonalResponse`. Implementa cliente HTTP (`http.ts`) con inyección automática de cabecera Bearer, control de errores `problem+json` y redirección ante 401. Implementa llamadas a `POST /api/v1/auth/login` (G7 / mock) y `GET /api/v1/retail/perfil` (Retail).
- **Criterio que verifica:** Conexión con contratos oficiales y manejo de códigos 200, 401 y 403.
- **Test:** `authApi.test.ts` — Mock de respuestas de red exitosa y error 401/403.

### [ ] Tarea F2 (RF-01): Componente `LoginForm` con Validación Reactiva
- **Archivos:** `components/organisms/LoginForm.tsx`.
- **Qué hace:** Formulario con selector de tienda, inputs de correo/contraseña con validación y botón con spinner de carga. Invoca el login y luego la carga de perfil.
- **Criterios que verifica:** "Botón de ingreso muestra spinner y bloquea múltiples clics" y "Validación de credenciales" (RF-01).
- **Test:** `LoginForm.test.tsx` — Valida bloqueo del botón ante datos incompletos y renderizado del spinner.

### [ ] Tarea F3 (RF-02): Guardianes de Ruta (`RequireAuth`) y Control de Acceso por Roles
- **Archivos:** `router/RequireAuth.tsx`, `router/AppRouter.tsx`.
- **Qué hace:** Intercepta navegación; redirige a `/login` si no hay sesión activa o si el rol operativo (`VENDEDOR`, `SUPERVISOR`) no cuenta con privilegios para la vista.
- **Criterios que verifica:** "Intento de navegación directa a /pos sin sesión redirige a /login" (RF-02).
- **Test:** `RequireAuth.test.tsx` — Verifica redirección ante usuario no autenticado o rol no permitido.

### [ ] Tarea F4 (RF-03): Store de Autenticación (Zustand), Persistencia y Cierre de Sesión
- **Archivos:** `store/authStore.ts`, `components/organisms/AppHeader.tsx`.
- **Qué hace:** Guarda token y perfil operativo en `sessionStorage` mediante Zustand, inyecta sesión en la cabecera `AppHeader` y gestiona Logout con diálogo de confirmación y purga de estado.
- **Criterios que verifica:** "Recargar página mantiene usuario autenticado" y "Cerrar sesión purga token y bloquea navegación" (RF-03).
- **Test:** `authStore.test.ts` — Valida persistencia en recarga y limpieza total en logout.
