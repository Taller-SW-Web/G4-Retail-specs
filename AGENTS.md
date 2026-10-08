# Reglas de Proyecto — Spec-Driven Development (SDD) con IA

Este documento establece las directrices obligatorias para asistentes de IA (Antigravity, Claude Code, Copilot, etc.) y desarrolladores que interactúen con el repositorio del **Módulo Retail (Grupo 4)**.

---

## 1. Principios de Spec-Driven Development (SDD)

1. **La Spec es la Fuente Única de Verdad:**
   - Todo desarrollo nace de una especificación ubicada en `/specs`.
   - Está terminantemente **prohibido escribir código** (backend o frontend) sin una spec funcional y de interfaz que lo justifique.
2. **Ciclo de TDD y Validación Estricta:**
   - Cada tarea técnica de desarrollo termina obligatoriamente con **al menos un test automatizado** derivado de un criterio de aceptación de la spec.
   - El test se escribe a partir del criterio de negocio de la spec, nunca leyendo retrospectivamente el código ya implementado.
   - No se avanza a la siguiente tarea mientras los tests de la tarea actual no pasen en verde.
3. **Desarrollo Incremental y Trazabilidad:**
   - Se implementa **una sola tarea a la vez**.
   - Cada tarea completada y verificada debe consolidarse en un commit propio y descriptivo (`feat: ...`, `fix: ...`, `test: ...`).
   - Todo componente visual, endpoint o servicio debe ser trazable a un requisito funcional de las specs.

---

## 2. Convenciones de Frontend (`G4-Retail-frontend`)

1. **Stack Oficial:**
   - React 18+ + TypeScript + Vite.
   - Tailwind CSS configurado con los tokens definidos en `specs/generales/design-system.md`.
   - Testing con Vitest y `@testing-library/react`.
2. **Respeto a los Contratos de API:**
   - El frontend **nunca inventa endpoints, rutas ni estructuras de payload**.
   - Solo se comunica con el backend mediante las firmas estipuladas en `specs/generales/api-contracts.md`.
   - Si se requiere un nuevo campo o endpoint, primero se propone la modificación en el contrato, se aprueba y luego se implementa en código.
3. **Alineación con el Design System y Atomic Design:**
   - Todas las vistas y componentes deben construirse respetando `specs/generales/design-system.md` (colores semánticos, espaciados en escala de 4px, radios y tipografías Inter/Oswald).
   - Se reutilizan los átomos y moléculas transversales (`Button`, `Input`, `Badge`, `Modal`, `EmptyState`, etc.).
4. **Reglas de Gestión de Estado en React:**
   - El estado de la aplicación se clasifica estrictamente en tres niveles:
     1. **Local del componente (`useState`):** formularios en edición, filtros temporales, toggles y estados visuales.
     2. **Elevado al padre común (`useState` / props):** sincronización entre componentes hermanos a menos de 3 niveles.
     3. **Global en el Store (Redux Toolkit / Zustand):** reservado **únicamente** para:
        - Sesión del vendedor/cajero autenticado (`authStore`).
        - Turno de caja actualmente abierto (`cajaStore`).
        - Carrito de compras activo en terminal (`cartStore`).
   - **Prohibido en el Store Global:**
     - Texto que el usuario está escribiendo en inputs de formulario.
     - Errores de validación de campos.
     - Visibilidad de modales, dropdowns o acordeones.
     - Pestaña activa o selecciones puramente cosméticas.

---

## 3. Convenciones de Backend (`G4-Retail-backend`)

1. **Stack Oficial:**
   - Java 17 o 21 con **Spring Boot 3.x**.
   - Persistencia: **Spring Data JPA** con Hibernate sobre PostgreSQL (alojado en Supabase).
   - Build Tool: Maven con Maven Wrapper (`./mvnw`).
   - Testing: JUnit 5 + Mockito + Spring Boot Test.
2. **Estructura en Capas Limpias:**
   - Paquete canónico base: `pe.edu.unmsm.fisi.retail.*`
   - Separación estricta de responsabilidades:
     - `controller/`: Endpoints REST, mapeo de rutas y códigos HTTP.
     - `service/`: Lógica de negocio, cálculos de impuestos (IGV 18%) y reglas de validación.
     - `repository/`: Interfaces que extienden `JpaRepository`.
     - `model/` o `entity/`: Entidades JPA anotadas con `@Entity`, `@Table`, `@Id`.
     - `dto/`: Objetos de transferencia (`Request` y `Response`) independientes de las entidades de base de datos.
     - `exception/`: Clases de error de negocio y `GlobalExceptionHandler` con `@RestControllerAdvice`.
     - `config/`: CORS, WebSecurity y configuraciones globales.
3. **Consistencia Transaccional y Validaciones:**
   - Operaciones críticas (aperturas de caja, registro de órdenes, cobros y cierres con arqueo) deben decorarse con `@Transactional`.
   - Validar entradas mediante Bean Validation (`@Valid`, `@NotNull`, `@NotBlank`, `@Positive`).
4. **Formato Homogéneo de Excepciones:**
   - Toda respuesta de error debe devolver la estructura canónica del proyecto:
     ```json
     {
       "error": {
         "codigo": "NOMBRE_DEL_ERROR",
         "mensaje": "Descripción legible para el usuario o cliente",
         "detalles": [ "Detalle opcional o campo inválido" ]
       }
     }
     ```

---

## 4. Reglas para Agentes de IA

1. **No asumir ni inventar requisitos:** Ante ambigüedad de reglas de negocio en mostrador, consultar con el usuario o basarse estrictamente en la matriz `FUNCIONALIDADES-RF.md`.
2. **Propuesta previa:** Antes de ejecutar refactorizaciones destructivas o cambios mayores de arquitectura, presentar un diff o propuesta de cambios para aprobación del usuario.
3. **Idioma:** Código, comentarios, commits, contratos y respuestas deben mantenerse en español.
4. **Preservación de gobernanza:** No eliminar archivos de especificación ni modificar esquemas de bases de datos sin actualizar su correspondiente documentación en `/specs` y `/diseño`.
