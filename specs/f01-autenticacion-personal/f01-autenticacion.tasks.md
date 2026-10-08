# Tareas — F1: Inicio de Sesión del Vendedor

**Fuentes:** `f01-autenticacion.md` (RF-01, RF-02, RF-03), `f01-autenticacion.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-01): DTOs y Validaciones de Entrada de Login
- **Archivos:** `dto/LoginRequest.java`, `dto/LoginResponse.java`, `dto/UsuarioPerfilDto.java`.
- **Qué hace:** Estructuras de datos con validación Bean Validation (`@NotBlank`, `@Email`, `@NotNull` para tienda).
- **Criterio que verifica:** "Payload vacío o email inválido retorna 400 Bad Request" (RF-01).
- **Test:** `LoginRequestTest.java` — Valida rechazo de correos mal formados y campos nulos.

### [ ] Tarea B2 (RF-01, RF-02): Servicio de Autenticación y Resolución de Perfil RBAC
- **Archivos:** `service/AuthService.java`, `service/impl/AuthServiceImpl.java`, `repository/PersonalTiendaRepository.java`.
- **Qué hace:** Valida credenciales contra Seguridad (mock), comprueba `RET_PERSONAL_TIENDA` activo para la tienda seleccionada y asigna perfil (`VENDEDOR`, `CAJERO`, `SUPERVISOR`).
- **Criterios que verifica:** "Credenciales válidas retornan 200 OK" (RF-01) y "Usuario sin registro en RET_PERSONAL_TIENDA recibe 403 Forbidden" (RF-02).
- **Test:** `AuthServiceTest.java` — Prueba login exitoso y rechazo de usuarios sin tienda asignada.

### [ ] Tarea B3 (RF-01, RF-02): Controlador REST `POST /api/v1/auth/login` y Formato de Errores
- **Archivos:** `controller/AuthController.java`, `exception/GlobalExceptionHandler.java`.
- **Qué hace:** Expone la ruta REST, genera JWT y mapea errores 400, 401 y 403 al formato homogéneo `{ error: { codigo, mensaje, detalles } }`.
- **Criterios que verifica:** "Credenciales erróneas retornan 401 con código CREDENCIALES_INVALIDAS" (RF-01) y "Respuesta 403 Forbidden" (RF-02).
- **Test:** `AuthControllerTest.java` (MockMvc) — Comprueba contratos HTTP 200, 400, 401 y 403.

### [ ] Tarea B4 (RF-03): Middleware Interceptor de Seguridad y Validación de Token
- **Archivos:** `security/JwtAuthenticationFilter.java`, `security/JwtTokenProvider.java`, `config/SecurityConfig.java`.
- **Qué hace:** Intercepta peticiones protegidas, extrae `Authorization: Bearer <token>`, valida firma/expiración e inyecta el contexto de seguridad.
- **Criterio que verifica:** "Token expirado genera respuesta 401 y retorno al login" (RF-03).
- **Test:** `JwtAuthenticationFilterTest.java` — Verifica acceso con token válido y rechazo 401 ante token vencido.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-01): Tipos y Cliente de API Auth
- **Archivos:** `types/auth.ts`, `api/authApi.ts`.
- **Qué hace:** Declara tipos `LoginCredentials`, `AuthResponse` y método `login()`.
- **Criterio que verifica:** Conexión con contrato de backend y manejo de códigos 200 y 401.
- **Test:** `authApi.test.ts` — Mock de respuestas de red exitosa y error 401.

### [ ] Tarea F2 (RF-01): Componente `LoginForm` con Validación Reactiva
- **Archivos:** `components/organisms/LoginForm.tsx`.
- **Qué hace:** Formulario con selector de tienda, inputs con formato y botón con spinner de carga.
- **Criterios que verifica:** "Botón de ingreso muestra spinner y bloquea múltiples clics" y "Validación de correo corporativo" (RF-01).
- **Test:** `LoginForm.test.tsx` — Valida bloqueo del botón ante datos incompletos y renderizado del spinner.

### [ ] Tarea F3 (RF-02): Guardianes de Ruta (`RequireAuth`) y Control de Acceso por Roles
- **Archivos:** `router/RequireAuth.tsx`, `router/AppRouter.tsx`.
- **Qué hace:** Intercepta navegación; redirige a `/login` si no hay sesión o si el rol no tiene privilegios para la vista.
- **Criterios que verifica:** "Intento de navegación directa a /pos sin sesión redirige a /login" (RF-02).
- **Test:** `RequireAuth.test.tsx` — Verifica redirección ante usuario no autenticado o rol no permitido.

### [ ] Tarea F4 (RF-03): Store de Autenticación, Persistencia y Cierre de Sesión
- **Archivos:** `store/auth.ts`, `components/organisms/AppHeader.tsx`.
- **Qué hace:** Guarda sesión en `sessionStorage`, inyecta token en interceptor HTTP, muestra datos en AppHeader y gestiona Logout con diálogo de confirmación.
- **Criterios que verifica:** "Recargar página mantiene usuario autenticado" y "Cerrar sesión purga token y bloquea navegación" (RF-03).
- **Test:** `authStore.test.ts` — Valida persistencia en recarga y limpieza total en logout.
