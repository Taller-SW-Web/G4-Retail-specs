# Plan de Implementación — F1: Inicio de Sesión del Vendedor

> Documento de regularización y decisiones de arquitectura para la autenticación de terminal.

---

## 1. Decisiones Técnicas Confirmadas
1. **Delegación a Módulo Seguridad (G7):** El módulo Retail no almacena contraseñas ni expone endpoints de login de credenciales. La SPA en React invoca directamente a Seguridad (G7 `POST /api/v1/auth/login`) y, con el token obtenido, consulta el perfil de mostrador en Retail (`GET /api/v1/retail/perfil`). Para desarrollo local en Semana 8 se emplea un mock en frontend de G7 con usuarios precargados en `seed.sql`.
2. **Formato de Token y Validación:** Token JWT emitido por Seguridad (G7) con algoritmo estándar (RS256 / claims `sub`, `roles`). En `ms-retail` se valida la cabecera `Authorization: Bearer <token>` para extraer la identidad del usuario y mapearla con `RET_PERSONAL_TIENDA`.
3. **Persistencia en Cliente:** El token y perfil se guardan en el store de sesión (`authStore` / `sessionStorage`), aislando la terminal de pestañas ajenas.
4. **Perfil Único de Mostrador (D-08):** Se elimina el perfil `CAJERO`; el `VENDEDOR` opera la venta y la caja. El perfil `SUPERVISOR` autoriza excepciones.

## 2. Componentes e Integraciones
- **Backend (`ms-retail`):**
  - `PerfilController`: expone `GET /api/v1/retail/perfil` (protegido) y `GET /api/v1/retail/health` (público).
  - `RetailPerfilService`: resuelve datos operativos consultando `PersonalTiendaRepository`.
  - `SecurityConfig` / `JwtAuthenticationFilter`: intercepta peticiones protegidas y valida el token Bearer.
- **Frontend (`G4-Retail-frontend`):**
  - `http.ts`: cliente HTTP Axios/Fetch centralizado con inyección de cabecera Bearer, control de errores RFC 7807 (`problem+json`) y redirección ante 401.
  - `LoginPage` montada en la ruta `/login`.
  - `RequireAuth` protege las rutas operativas (`/pos`, `/caja`, `/pickup`).
  - `authStore`: estado global de autenticación en Zustand.

## 3. Registro de Incidencias y Regularizaciones
- **REG-01 (Semana 8):** Eliminación de `POST /api/v1/auth/login` y `clave_hash` del backend y BD de Retail. Se ratifica la propiedad de credenciales en G7 (Decisión D-02) y la adopción de `GET /api/v1/retail/perfil`.
