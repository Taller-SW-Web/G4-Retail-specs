# Guía Maestra de Despliegue e Integración en Producción
**Módulo Retail (Grupo 4) — Railway, Supabase, Vercel, Seguridad (G7) y Ventas (G5)**

Este documento es el manual definitivo paso a paso para dejar el sistema 100% conectado en la nube una vez que el equipo esté disponible.

---

## 1. Resumen de Integraciones y Estado Actual

| Componente | Proveedor / Dueño | Estado / Mecanismo | Configuración en Producción |
| :--- | :--- | :--- | :--- |
| **Backend POS** | **Railway** (Grupo 4) | Desplegado y saludable (`Tomcat 8080`). Resiliente con H2 y listo para Supabase. | `g4-retail-backend-production.up.railway.app` |
| **Frontend POS** | **Vercel** (Grupo 4) | Desplegado en `g4-retail-frontend-gamma.vercel.app`. Requiere actualizar variable de API. | Apuntará a Railway (`VITE_API_URL`). |
| **Base de Datos** | **Supabase** (Angie - G4) | PostgreSQL en la nube. Esquema físico listo en `schema.sql`. | Requiere `PROJECT_REF` en el usuario del pooler. |
| **Seguridad / Auth** | **Módulo G7** (Render) | Gestiona credenciales y JWT oficial. Usuario acordado: `miguel.solis@unmsm.edu.pe`. | Su CORS solo admite `g4-retail-frontend-gamma.vercel.app` (en local usamos proxy Vite). |
| **Ventas / Pedidos** | **Módulo G5** (Render) | Integración síncrona `POST /api/v1/pedidos`. Retail adopta su `pedidoId` con fallback local si G5 duerme. | Conectado vía `VentasClient` (`RETAIL_VENTAS_URL`). |

---

## 2. Paso a Paso en Railway (Backend)

Ingresa a [Railway Dashboard](https://railway.com/) > Proyecto Retail > Servicio **`ms-retail`** > Pestaña **Variables**.

### A. Para conectar a Supabase Oficial (Persistencia Real)
El identificador de proyecto (**`PROJECT_REF`**) de Supabase ya está confirmado: **`sengrwjntjhrinpyqmen`**.

Configura las siguientes variables exactas:

```env
SPRING_PROFILES_ACTIVE=supabase,mock
SUPABASE_DB_URL=jdbc:postgresql://aws-0-us-west-2.pooler.supabase.com:5432/postgres
SUPABASE_DB_USER=postgres.sengrwjntjhrinpyqmen
SUPABASE_DB_PASSWORD=KOUZd6VJSqqX9dtl
SPRING_JPA_HIBERNATE_DDL_AUTO=none
RETAIL_CORS_ORIGENES_PERMITIDOS=https://g4-retail-frontend-gamma.vercel.app,http://localhost:5173
PORT=8080
JAVA_TOOL_OPTIONS=-Xms128m -Xmx384m -XX:MaxMetaspaceSize=128m -XX:+UseSerialGC
RETAIL_VENTAS_URL=https://g5-servicio-ventas.onrender.com
RETAIL_VENTAS_HABILITADO=true
RETAIL_SEGURIDAD_JWKS_URI=https://g7-auth-service.onrender.com/api/v1/auth/.well-known/jwks.json
```

> **¿Por qué `SUPABASE_DB_USER=postgres.sengrwjntjhrinpyqmen`?**  
> El pooler Supavisor (`aws-0-us-west-2.pooler.supabase.com`) comparte el puerto 5432 entre múltiples proyectos. Si se coloca solo `postgres`, Supabase rechaza con `FATAL: (ENOIDENTIFIER) no tenant identifier provided`. El sufijo `.sengrwjntjhrinpyqmen` le indica exactamente a qué base de datos rutear la conexión.

---

## 3. Paso a Paso en Vercel (Frontend)

El compañero encargado de Vercel debe realizar lo siguiente en [Vercel Dashboard](https://vercel.com/):

1. Seleccionar el proyecto **`g4-retail-frontend-gamma`**.
2. Ir a **Settings** > **Environment Variables**.
3. Definir las siguientes variables para los entornos **Production** y **Preview**:

| Variable | Valor | Explicación |
| :--- | :--- | :--- |
| `VITE_API_URL` | `https://g4-retail-backend-production.up.railway.app` | Conecta la SPA con el backend en Railway. |
| `VITE_USE_MOCKS` | `false` | Apaga los mocks de caja, inventario, ventas y pickups. |
| `VITE_USE_AUTH_MOCK` | `false` | Permite el login directo contra el servicio real de Seguridad G7. |
| `VITE_AUTH_URL` | `https://g7-auth-service.onrender.com` | URL del microservicio de autenticación de G7. |
| `VITE_TERMINAL_POS` | `POS-01` | Código del terminal en mostrador. |

4. Ir a la pestaña **Deployments**, hacer clic en los tres puntos `...` del último commit y seleccionar **Redeploy**.

---

## 4. Validación de la Integración con Seguridad (G7)

### El usuario `miguel.solis@unmsm.edu.pe`
- **En Seguridad (G7):** G7 valida la contraseña y emite un token JWT firmado (RS256) que contiene:
  ```json
  {
    "sub": "b9e222a5-cf86-4c95-9611-891886160821",
    "email": "miguel.solis@unmsm.edu.pe",
    "nombre": "Miguel Solis"
  }
  ```
- **En Retail Backend:** Al arrancar el servidor (tanto en H2 local como en Supabase), `PersonalTiendaInitializer` auto-registra a este usuario en la tabla `RET_PERSONAL_TIENDA`:
  - `usuario_id`: `b9e222a5-cf86-4c95-9611-891886160821`
  - `codigo_vendedor`: `VEN-002`
  - `perfil_tienda`: `VENDEDOR`
  - `tienda_id`: `11111111-1111-1111-1111-111111111111` (Tienda Miraflores)
- **CORS de G7:** En Vercel (`https://g4-retail-frontend-gamma.vercel.app`) el login funciona directo porque G7 tiene ese dominio en su lista permitida. En desarrollo local (`localhost:5173`), el proxy configurado en `vite.config.ts` reenvía la llamada por detrás sin bloqueos.

---

## 5. Validación de la Integración con Ventas y Postventa (G5)

### ¿Cómo funciona la integración?
El backend cuenta con [`VentasClient.java`](file:///c:/Users/Mihae/Programacion/Activos/G4-Retail-specs/G4-Retail-backend/src/main/java/pe/edu/unmsm/fisi/retail/client/VentasClient.java) conectado a `https://g5-servicio-ventas.onrender.com`:

1. **Flujo Feliz (Online G5):**
   - Cuando el cajero procesa una venta (`POST /api/v1/retail/ventas`), Retail invoca síncronamente `POST /api/v1/pedidos` en Ventas con modalidad `RETAIL` y la cabecera `Idempotency-Key`.
   - Ventas orquesta la reserva de stock y devuelve su identificador oficial (ej. `pedidoId: PED-2026-00091`).
   - Retail adopta dicho `pedidoId` y emite el comprobante fiscal térmico (`B001`/`F001`).

2. **Resiliencia y Fallback (G5 en reposo o caído):**
   - El cliente tiene un timeout estricto de **3500 ms** (`retail.integracion.ventas.timeout-ms`).
   - Si el servicio de Ventas en Render está "dormido", caído o responde con error, `VentaService` activa el **fallback local**:
     - Registra un log de advertencia: `Fallo en la comunicación con Ventas (activando fallback local)`.
     - Genera un `pedidoId` de contingencia (`VNT-YYYYMMDD-XXXXX`).
     - **La venta física NUNCA se interrumpe** y el comprobante se emite con éxito en mostrador (cumpliendo Hito 3 y RF-13).

---

## 6. Checklist de Verificación Final (Prueba 100% Producción)

- [ ] **Healthcheck Backend:**  
  Entrar a `https://g4-retail-backend-production.up.railway.app/api/v1/retail/health` y recibir `200 OK`.
- [ ] **Login Vercel:**  
  Entrar a `https://g4-retail-frontend-gamma.vercel.app`, digitar `miguel.solis@unmsm.edu.pe` y su contraseña.
- [ ] **Resolución de Perfil:**  
  En DevTools (`F12`), verificar que `GET /api/v1/retail/perfil` devuelva `200 OK` con `codigoVendedor: VEN-002`.
- [ ] **Apertura de Caja:**  
  Ingresar saldo inicial (ej. S/ 150.00) y verificar `POST /api/v1/retail/caja/turnos` con `201 Created`.
- [ ] **Cobro de Venta:**  
  Agregar productos al carrito, cobrar en efectivo y confirmar que se emite la boleta `B001-XXXXX` con desglose de IGV 18%.
