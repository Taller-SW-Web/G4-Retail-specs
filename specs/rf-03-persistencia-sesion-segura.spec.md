# Spec — RF-03: Gestión y Persistencia de Sesión Segura (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimiento Funcional: RF-03: Gestión y Persistencia de Sesión Segura
### Funcionalidad Padre: F1: Inicio de Sesión del Vendedor
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
El vendedor o cajero opera durante turnos comerciales de hasta 8 horas, atendiendo decenas de transacciones continuas. Si la sesión se pierde aleatoriamente al refrescar la página, el operador pierde el contexto de atención. Por otro lado, si el token de sesión se almacena de forma insegura o no expira al culminar la jornada laboral, la terminal queda vulnerable a suplantación de identidad.

## ¿Para qué? (objetivo)
Gestionar el ciclo de vida del token de acceso JWT en el cliente, manteniéndolo persistido de forma segura durante la jornada de trabajo, inyectándolo automáticamente en cada petición HTTP hacia los microservicios mediante la cabecera `Authorization: Bearer <token>`, controlando su expiración y permitiendo el cierre voluntario de sesión.

## ¿Hasta dónde? (alcance)
* **Incluido:** Almacenamiento seguro del token JWT en memoria / sesión cifrada del cliente, interceptor HTTP para adjuntar cabecera `Authorization`, decodificación de datos de usuario para el header visual (nombre, tienda, rol), control de expiración de sesión (máximo 8 horas) y función de cierre de sesión (*Logout*) con purga de estado.
* **Excluido:** Generación y validación inicial de credenciales (cubierto en RF-01 y RF-02), y renovación de tokens mediante Refresh Tokens complejos externos (si expira, se solicita reingreso de clave por seguridad de caja).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/auth/login` (Sección 1)
* **Modelo:** `SesionVendedor` (`token`, `expiraEn`, `usuario`: `{id, email, nombres, rol, tiendaId}`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Interceptor de Peticiones)
1. Provee un middleware que intercepta todas las peticiones entrantes a endpoints protegidos de Retail.
2. Extrae la cabecera `Authorization: Bearer <token>`.
3. Valida la vigencia temporal del token (`exp` claim) y su firma criptográfica.
4. Si el token está expirado, revocado o malformado, responde de inmediato `401 Unauthorized` con cabecera `WWW-Authenticate`.
5. Si el token es válido, inyecta la información del vendedor (`vendedorId`, `tiendaId`) en el contexto de la petición para auditoría.

### Frontend
1. Al recibir el token tras el login exitoso:
   * Almacena el token y los datos de perfil en almacenamiento seguro de sesión (`sessionStorage` o almacenamiento en memoria con sincronización controlada).
   * Redirige al vendedor al panel principal de mostrador.
2. Configura un interceptor HTTP en el cliente (ej. Axios / Fetch client) que adjunta automáticamente `Authorization: Bearer <token>` en cada llamado a los microservicios.
3. Despliega en la barra superior (Header) de la terminal:
   * Nombre completo del vendedor.
   * Rol activo (`Vendedor` o `Cajero`).
   * Sede o Tienda física activa (ej. `Tienda Miraflores`).
   * Botón visible de *"Cerrar Sesión"*.
4. Al hacer clic en *"Cerrar Sesión"*:
   * Muestra diálogo de confirmación: *"¿Está seguro de cerrar el turno de caja?"*.
   * Si confirma, elimina el token JWT, limpia el estado del carrito en memoria y redirige a la pantalla `/login`.
5. Si cualquier microservicio responde `401 Unauthorized` por token vencido:
   * Intercepta la respuesta, muestra aviso *"Su sesión ha expirado por inactividad o fin de turno"* y redirige al login.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Tras login exitoso, recargar la página (F5) mantiene al usuario autenticado sin solicitar credenciales nuevamente.
- [ ] Todas las peticiones de red salientes incluyen la cabecera `Authorization: Bearer <token>` con el valor del JWT actual.
- [ ] El header de la aplicación muestra el nombre del usuario logueado y su tienda en todo momento.
- [ ] Al pulsar "Cerrar Sesión", el token se borra del almacenamiento y la navegación protegida queda completamente bloqueada.
- [ ] Intentar acceder con un token expirado genera respuesta 401 y retorno automático a la pantalla de login.
- [ ] No se almacena el token en cookies sin protección ni en almacenamiento no seguro expuesto a scripts cruzados.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El token JWT debe poseer fecha de expiración (`exp`) fijada al tiempo máximo del turno laboral (máximo 8 horas según RNF-03).
* Las peticiones deben viajar exclusivamente sobre HTTPS.
* Regla de negocio: Toda acción operativa en terminal debe estar asociada al identificador del vendedor autenticado.

## ¿Qué NO hará? (fuera de alcance)
* No mantiene sesiones concurrentes infinitas (cierre automático tras fin de turno).
* No comparte el token entre distintas ventanas privadas o terminales ajenas.
