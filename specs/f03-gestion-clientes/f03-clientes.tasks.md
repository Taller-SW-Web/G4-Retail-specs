# Tareas — F3: Búsqueda y Registro Rápido de Clientes

**Fuentes:** `f03-clientes.md` (RF-07, RF-08, RF-09), `f03-clientes.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-07, RF-09): Entidad Cliente y Repositorio con Búsqueda Indexada
- **Archivos:** `model/Cliente.java`, `repository/ClienteRepository.java`.
- **Qué hace:** Mapea la tabla `RET_CLIENTES` con índice único sobre `(tipo_documento, documento)` para búsqueda rápida en mostrador.
- **Criterio que verifica:** "Búsqueda por DNI retorna cliente en < 500 ms" (RF-07).
- **Test:** `ClienteRepositoryTest.java` — Verifica búsqueda por documento exacto y restricciones de unicidad.

### [ ] Tarea B2 (RF-08, RF-09): Servicio de Clientes con Validación Estricta de Formatos
- **Archivos:** `service/ClienteService.java`, `service/impl/ClienteServiceImpl.java`, `validation/DocumentoFiscalValidator.java`, DTOs.
- **Qué hace:** Valida que DNI tenga exactamente 8 dígitos, que RUC tenga 11 e inicie con 10/20, y gestiona excepciones `ClienteNoEncontradoException` y `DocumentoDuplicadoException`.
- **Criterios que verifica:** "Validación estricta de DNI/RUC" (RF-09) y "Registro express sin duplicar" (RF-08).
- **Test:** `ClienteServiceTest.java` — Valida rechazo de DNI de 7 dígitos o RUC con prefijo no permitido y alta correcta.

### [ ] Tarea B3 (RF-07, RF-08): Controlador REST de Clientes
- **Archivos:** `controller/ClienteController.java`.
- **Qué hace:** Expone `GET /api/v1/clientes?documento=` y `POST /api/v1/clientes`.
- **Criterios que verifica:** Respuestas HTTP 200, 201, 400, 404 y 409 según contrato.
- **Test:** `ClienteControllerTest.java` (MockMvc) — Comprueba llamadas REST completas y formato de errores canónico.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-07, RF-08): Tipos y Cliente API de Clientes
- **Archivos:** `types/cliente.ts`, `api/clienteApi.ts`.
- **Qué hace:** Declara tipos `Cliente`, `NuevoClientePayload` y métodos de consulta y registro.
- **Test:** `clienteApi.test.ts` — Comprueba serialización de datos y manejo de 404 (no encontrado) sin romper la app.

### [ ] Tarea F2 (RF-07, RF-09): Componente `CustomerSection` con Máscara de Entrada
- **Archivos:** `components/organisms/CustomerSection.tsx`.
- **Qué hace:** Campo de búsqueda por documento con selector DNI/RUC, bloqueo de tipeo de letras y tecla `Enter`.
- **Criterios que verifica:** "Intentar escribir letras no produce caracteres" y "Buscar con Enter autocompleta cliente" (RF-07, RF-09).
- **Test:** `CustomerSection.test.tsx` — Valida bloqueo de caracteres alfabéticos y emisión del evento de búsqueda al ingresar 8 dígitos.

### [ ] Tarea F3 (RF-08, RF-09): Componente `QuickCustomerModal` con Validación Inline
- **Archivos:** `components/organisms/QuickCustomerModal.tsx`.
- **Qué hace:** Formulario modal de alta rápida con documento precargado, validación de email y vinculación al carrito.
- **Criterios que verifica:** "Búsqueda fallida precarga modal" y "Guardar asocia cliente manteniendo carrito intacto" (RF-08).
- **Test:** `QuickCustomerModal.test.tsx` — Valida que al enviar el formulario se guarde el cliente y se cierre el modal.
