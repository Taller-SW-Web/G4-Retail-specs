# Spec — Inicio de Sesión del Vendedor (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimientos Funcionales asociados: RF-01, RF-02, RF-03

---

## ¿Por qué? (problema)
Actualmente, el personal de mostrador no cuenta con un acceso autenticado ni controlado a la terminal de Retail. Sin una sesión autenticada con token JWT no es posible identificar quién realiza cada venta, atribuir la responsabilidad del cobro de caja ni consultar de forma segura las APIs protegidas del ecosistema de microservicios.

## ¿Para qué? (objetivo)
Permitir al vendedor o cajero autenticarse con sus credenciales institucionales, validar que posea los roles autorizados para operar la tienda (`vendedor` o `cajero`), y obtener un token JWT que identifique sus operaciones y firme sus peticiones a los demás microservicios.

## ¿Hasta dónde? (alcance)
* **Incluido:** Formulario de login en el frontend de Retail, consumo del endpoint de autenticación de *Seguridad y Usuarios*, almacenamiento seguro del token JWT en sesión, validación de rol de empleado y cierre de sesión.
* **Excluido:** Creación de nuevos usuarios empleados, reseteo de contraseñas, administración de políticas de contraseñas y doble factor (MFA/OTP), los cuales son responsabilidad del módulo de *Seguridad y Usuarios*.

## Referencias
* **Contrato:** [specs/api-contracts.md](file:///c:/Users/Mihae/Programacion/Activos/modulo-retail/specs/api-contracts.md) — `POST /api/v1/auth/login`
* **Modelo:** `CredencialesLogin` (`email`, `password`), `SesionVendedor` (`token`, `usuario`: `{id, email, nombres, rol, tiendaId}`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Gateway hacia Seguridad)
1. Expone o enruta `POST /api/v1/auth/login` hacia el microservicio de *Seguridad y Usuarios*.
2. Valida formato de entrada: `email` no vacío con sintaxis válida de correo y `password` no vacío.
3. Si el microservicio de seguridad responde `200 OK`, verifica que el rol del usuario sea `vendedor` o `cajero`. Si el rol no coincide (ej. es rol `cliente`), responde `403 Forbidden`.
4. Si las credenciales son incorrectas, propaga el `401 Unauthorized` con mensaje genérico de error.
5. Devuelve el token JWT emitido junto con la información básica del perfil y la tienda asignada.

### Frontend
1. Pantalla de bienvenida / Login con campos: Correo Institucional, Contraseña y selección o detección de Tienda.
2. No habilita el botón "Ingresar" hasta que ambos campos cumplan con el formato básico.
3. Al recibir `200 OK`, almacena el token JWT en memoria/almacenamiento de sesión seguro y redirige al dashboard de mostrador.
4. Muestra permanentemente en el header de la terminal el nombre del vendedor, su rol y la tienda activa.
5. Si el backend responde `401` o `403`, muestra un banner de error claro: *"Credenciales incorrectas o usuario no autorizado para operar la terminal de tienda"*.
6. Incluye botón de "Cerrar Sesión" que purga el token y devuelve al usuario a la pantalla de login.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] POST con credenciales válidas de un usuario con rol `vendedor` → 200 OK y devuelve el token JWT con los datos de usuario.
- [ ] POST con credenciales correctas pero rol `cliente` → 403 Forbidden.
- [ ] POST con contraseña o correo incorrecto → 401 Unauthorized.
- [ ] POST con campos vacíos → 400 Bad Request.
- [ ] El frontend no permite enviar el formulario con campos incompletos.
- [ ] Tras login exitoso, el frontend almacena el JWT y redirige a la vista principal mostrando el nombre del vendedor.
- [ ] El frontend muestra mensaje de error sin exponer detalles de base de datos ante respuestas 401 o 403.
- [ ] Al pulsar "Cerrar Sesión", el token se elimina y se bloquea la navegación protegida.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El microservicio de *Seguridad y Usuarios* debe estar operativo y responder al endpoint de login.
* Deben existir usuarios de prueba precargados con rol `vendedor` y `cajero`.
* Regla de negocio: Solo los roles `vendedor` y `cajero` pueden acceder al Canal Retail.
* Regla de seguridad: El token expira al finalizar el turno comercial (máximo 8 horas).

## ¿Qué NO hará? (fuera de alcance)
* No permite registrar nuevos vendedores desde esta pantalla.
* No implementa la recuperación de contraseña ("Olvidé mi clave" se gestiona en el portal central de Seguridad).
* No almacena credenciales ni contraseñas en bases de datos de Retail.
