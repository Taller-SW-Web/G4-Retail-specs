# Plan de Implementación — F1: Inicio de Sesión del Vendedor

> Documento de regularización y decisiones de arquitectura para la autenticación de terminal.

---

## 1. Decisiones Técnicas Confirmadas
1. **Delegación a Módulo Seguridad:** El módulo Retail no almacena contraseñas con hash propio ni gestiona altas de personal; se conecta vía REST con el módulo de Seguridad (G7) y mapea localmente el personal en `RET_PERSONAL_TIENDA`. Para Semana 8 se emplea un mock con usuarios precargados en `seed.sql`.
2. **Formato de Token:** JWT firmado con HMAC-SHA256 conteniendo claims: `sub` (email), `userId`, `rol`, `tiendaId`, con vigencia de 8 horas (turno completo de mostrador).
3. **Persistencia en Cliente:** El token se guarda en `sessionStorage` para aislar la terminal de pestañas ajenas, cerrando sesión si se cierra la ventana del navegador.

## 2. Componentes e Integraciones
- **Backend:**
  - `AuthController`: expone `POST /api/v1/auth/login`.
  - `AuthService`: resuelve validación y token.
  - `SecurityConfig`: permite acceso anónimo a `/api/v1/auth/login` y exige `Bearer` en el resto de endpoints.
- **Frontend:**
  - `LoginPage` montada en la ruta `/login`.
  - `RequireAuth` protege las rutas operativas (`/pos`, `/caja`, `/pickup`).

## 3. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
