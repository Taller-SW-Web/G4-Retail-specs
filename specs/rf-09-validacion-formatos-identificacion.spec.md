# Spec — RF-09: Validación Estricta de Formatos de Identificación (v0.1)

### Responsable: Guillermo (QA / Calidad)
### Requerimiento Funcional: RF-09: Validación Estricta de Formatos de Identificación
### Funcionalidad Padre: F3: Búsqueda y Registro Rápido de Clientes
### Prioridad: Should have (Importante)

---

## ¿Por qué? (problema)
La emisión de comprobantes de pago electrónicos en Perú (SUNAT) exige que el número de identificación del cliente cumpla reglas fiscales estrictas. Si se permite ingresar DNIs con letras, con menos o más de 8 dígitos, o RUCs que no tengan 11 dígitos o no empiecen con dígitos autorizados (10, 20), el sistema fallará más adelante durante la facturación electrónica o generará sanciones tributarias.

## ¿Para qué? (objetivo)
Implementar una capa de validación estricta en el frontend y en el backend que garantice que los números de documento ingresados (DNI o RUC) y los correos electrónicos cumplan con las reglas sintácticas oficiales peruanas antes de permitir su consulta o persistencia.

## ¿Hasta dónde? (alcance)
* **Incluido:** Validación de longitud exacta (DNI: 8 dígitos numéricos; RUC: 11 dígitos numéricos), validación de prefijo de RUC (debe comenzar con 10, 15, 17 o 20), máscara de entrada numérica en inputs (impide escribir letras), validación de formato de correo con expresión regular RFC-5322 simplificada, y mensajes de retroalimentación inmediata en la UI.
* **Excluido:** Validación contra bases de datos en vivo de RENIEC o padrón reducido de SUNAT (fuera de alcance de esta iteración académica).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/clientes` (Sección 1)
* **Modelo:** `ReglasValidacionDocumento` (`tipo`: `"DNI" | "RUC"`, `longitud`: `8 | 11`, `regex`: `string`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Middleware de Validación)
1. Expone función o middleware de validación para cualquier endpoint que reciba `tipoDocumento` y `numeroDocumento`:
   * Si `tipoDocumento == "DNI"`:
     * Exige que `numeroDocumento` contenga exactamente 8 caracteres numéricos (`^\d{8}$`).
     * Si no cumple, rechaza con `400 Bad Request` y mensaje: `"El DNI debe contener exactamente 8 dígitos numéricos"`.
   * Si `tipoDocumento == "RUC"`:
     * Exige que `numeroDocumento` contenga exactamente 11 caracteres numéricos (`^\d{11}$`).
     * Exige que inicie con `10`, `15`, `17` o `20`.
     * Si no cumple, rechaza con `400 Bad Request` y mensaje: `"El RUC debe tener 11 dígitos y comenzar con un prefijo fiscal válido (10, 20)"`.
   * Si viene campo `email`:
     * Valida sintaxis estándar con arroba y dominio (`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`).

### Frontend
1. En los inputs de documento (tanto en la barra de búsqueda como en el modal de alta rápida):
   * Aplica máscara de caracteres: solo permite ingresar teclas del `0` al `9` (bloquea letras y caracteres especiales).
   * Define atributo `maxlength="8"` cuando el tipo seleccionado es DNI.
   * Define atributo `maxlength="11"` cuando el tipo seleccionado es RUC.
2. Retroalimentación visual inmediata (*Inline Validation*):
   * Mientras el usuario escribe su DNI, si tiene menos de 8 dígitos muestra texto tenue: *"Ingrese 8 dígitos (faltan X)"*.
   * Al completar los 8 dígitos, el borde del campo cambia a color verde de validación.
   * Si es RUC y no inicia con 10 o 20, muestra borde rojo y mensaje: *"Un RUC debe comenzar con 10 o 20"*.
3. En el campo de correo electrónico:
   * Valida en el evento `blur` (al salir del campo) que contenga formato válido. Si no cumple, muestra: *"Ingrese un correo electrónico válido (ej. cliente@correo.com)"*.
4. El botón de envío o guardado permanece inhabilitado mientras cualquiera de estos campos tenga error de validación.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Intentar escribir letras ("abc") en el campo de documento → La interfaz no registra los caracteres y el campo permanece vacío.
- [ ] Ingresar DNI de 7 dígitos e intentar buscar o guardar → Botón inhabilitado y mensaje de longitud insuficiente.
- [ ] Ingresar DNI de 8 dígitos válidos → Campo marcado en verde y botón habilitado.
- [ ] Ingresar RUC de 11 dígitos que empieza con "30" → Validación muestra error de prefijo no reconocido.
- [ ] Ingresar correo sin arroba (`cliente.com`) → Error inline de formato de correo inválido.
- [ ] Envío directo por API de payload con DNI de 6 dígitos → Backend responde 400 Bad Request.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Regla de Negocio RN-01: Cumplimiento tributario en comprobantes de pago según normativa SUNAT.

## ¿Qué NO hará? (fuera de alcance)
* No valida el dígito verificador matemático ni realiza consulta en tiempo real a los servidores de SUNAT/RENIEC.
