# Spec — RF-01: Autenticación de Personal de Tienda (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimiento Funcional: RF-01: Autenticación de Personal de Tienda
### Funcionalidad Padre: F1: Inicio de Sesión del Vendedor
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
El personal de tienda (vendedores y cajeros) requiere ingresar a la terminal POS de mostrador de forma segura para operar el sistema. Sin un mecanismo de autenticación con credenciales institucionales, no es posible validar la identidad del usuario ni generar el token de acceso para la interacción con los microservicios del sistema.

## ¿Para qué? (objetivo)
Permitir al usuario ingresar su correo corporativo institucional y contraseña, validar la sintaxis de los datos, enviar la solicitud al microservicio de *Seguridad y Usuarios* y obtener un token JWT de acceso válido junto con los datos de perfil y la tienda asignada.

## ¿Hasta dónde? (alcance)
* **Incluido:** Formulario de autenticación en la interfaz de Retail, validación de formato de credenciales en cliente y backend, delegación de la autenticación hacia el endpoint de *Seguridad y Usuarios* (`POST /api/v1/auth/login`), y retorno del token JWT con datos básicos del usuario (`id`, `email`, `nombres`, `tiendaId`).
* **Excluido:** Control de autorización por roles específicos (cubierto en RF-02), almacenamiento y gestión de la sesión en el cliente (cubierto en RF-03), y registro de nuevos usuarios o recuperación de claves (administrados centralmente por *Seguridad y Usuarios*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/auth/login`
* **Modelo:** `CredencialesLogin` (`email`, `password`), `RespuestaLogin` (`token`, `usuario`: `{id, email, nombres, apellidos, rol, tiendaId}`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Gateway hacia Seguridad)
1. Expone o enruta `POST /api/v1/auth/login` hacia el microservicio de *Seguridad y Usuarios*.
2. Valida estrictamente la entrada:
   * `email`: obligatorio, tipo string, formato de correo electrónico válido corporativo (`@deportesretail.com` o similar).
   * `password`: obligatorio, no vacío, longitud mínima requerida.
3. Si los datos no cumplen la estructura, responde `400 Bad Request` indicando los campos inválidos.
4. Si las credenciales no coinciden o la cuenta está inactiva en *Seguridad y Usuarios*, propaga el error `401 Unauthorized` con mensaje genérico de seguridad.
5. Si la autenticación es exitosa, retorna `200 OK` con el token JWT emitido y la información del usuario y tienda.

### Frontend
1. Presenta la vista de Login con campos: Correo Institucional, Contraseña y selector visual de Tienda asignada.
2. Aplica validación reactiva en tiempo real sobre el campo de correo electrónico y contraseña.
3. El botón *"Ingresar a Terminal"* se mantiene deshabilitado hasta que ambos campos tengan valores con formato válido.
4. Al enviar el formulario, entra en estado de carga (*loading spinner*) deshabilitando los campos para evitar reenvíos accidentales.
5. Ante respuesta `401 Unauthorized`, muestra un mensaje amigable: *"Credenciales incorrectas. Verifique su correo y contraseña"*.
6. Ante error de conectividad con el microservicio, muestra notificación: *"Servicio de autenticación no disponible. Intente nuevamente en unos minutos"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Envío de credenciales válidas y existentes → Retorna 200 OK con token JWT no vacío y datos del usuario.
- [ ] Envío con correo mal formateado (sin arroba o dominio incompleto) → Frontend bloquea el envío y muestra advertencia de formato.
- [ ] Envío con contraseña errónea → Retorna 401 Unauthorized y el frontend despliega mensaje de error sin revelar detalles internos del sistema.
- [ ] Envío con payload vacío o campos nulos al backend → Retorna 400 Bad Request.
- [ ] Durante la petición de login, el botón muestra spinner y previene múltiples clics.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El microservicio de *Seguridad y Usuarios* debe estar operativo y disponible en la red.
* El empleado debe existir previamente registrado y en estado activo en el módulo de Seguridad.
* Comunicación cifrada exclusivamente bajo protocolo HTTPS / TLS 1.3.

## ¿Qué NO hará? (fuera de alcance)
* No creará nuevos usuarios ni administradores desde el canal Retail.
* No implementará flujo de "Olvidé mi contraseña" en mostrador (gestión en portal de Seguridad).
* No almacenará contraseñas en texto plano ni en bases de datos locales de Retail.
