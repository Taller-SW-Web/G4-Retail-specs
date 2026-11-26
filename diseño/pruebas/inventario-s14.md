# Inventario estático de pruebas — S14

No es evidencia de ejecución ni cobertura. Los métodos parametrizados pueden producir varios casos.
Clasificación preliminar por anotaciones; Mockito y slices no equivalen a servicios reales.

Backend: 42 clases. Frontend: 39 archivos.

| Clase backend | Tipo observado | Métodos de prueba declarados |
|---|---|---:|
| `VentasClientTest` | Contrato HTTP simulado | 4 |
| `DocumentacionApiTest` | Contexto Spring completo | 4 |
| `PersonalTiendaInitializerTest` | Unidad o componente aislado | 2 |
| `SeguridadConfigTest` | HTTP local/JWKS | 5 |
| `AuthControllerTest` | Contexto Spring completo | 6 |
| `CajaControllerTest` | Contexto Spring completo | 12 |
| `CambioControllerTest` | Contexto Spring completo | 17 |
| `CarritoControllerTest` | Slice MVC; revisar mocks/filtros | 3 |
| `CatalogoControllerTest` | Contexto Spring completo | 11 |
| `ClienteControllerTest` | Slice MVC; revisar mocks/filtros | 8 |
| `ContingenciaControllerTest` | Contexto Spring completo | 6 |
| `HistorialPedidosControllerTest` | Contexto Spring completo | 13 |
| `PickupControllerTest` | Contexto Spring completo | 12 |
| `SaludControllerTest` | Contexto Spring completo | 1 |
| `VentaBoletaCambioTest` | Contexto Spring completo | 1 |
| `ManejoDeErroresTest` | Contexto Spring completo | 4 |
| `PosDependenciasIntegrationTest` | Contexto Spring completo | 8 |
| `ProductosMockTest` | Unidad o componente aislado | 12 |
| `TokenServicioG7Test` | Contrato HTTP simulado | 5 |
| `PedidosVentasHttpTest` | Contrato HTTP simulado | 4 |
| `PickupVentasHttpTest` | Contrato HTTP simulado | 6 |
| `RegistroPedidosMostradorTest` | Unidad o componente aislado | 2 |
| `CobroTurnoRepositoryTest` | Persistencia JPA | 4 |
| `PersonalTiendaRepositoryTest` | Persistencia JPA | 3 |
| `RegistroVentaSqlTest` | Unidad o componente aislado | 1 |
| `RetailApplicationTests` | Contexto Spring completo | 2 |
| `AuthServiceTest` | Unidad o componente aislado | 4 |
| `CajaCobroServiceTest` | Unidad o componente aislado | 23 |
| `CajaMovimientoServiceTest` | Unidad o componente aislado | 9 |
| `CajaServiceTest` | Unidad o componente aislado | 12 |
| `CarritoServiceTest` | Unidad o componente aislado | 6 |
| `ClienteValidationTest` | Unidad o componente aislado | 25 |
| `HashContingenciaTest` | Unidad o componente aislado | 2 |
| `HistorialPedidosServiceTest` | Unidad o componente aislado | 16 |
| `PickupServiceTest` | Unidad o componente aislado | 5 |
| `PoliticaInspeccionPrendaTest` | Unidad o componente aislado | 8 |
| `PoliticaPlazoCambioTest` | Unidad o componente aislado | 7 |
| `VentaCobroCorteZIntegrationTest` | Contexto Spring completo | 5 |
| `VentaReintentosIntegrationTest` | Contexto Spring completo | 5 |
| `VentaServiceCobroTest` | Unidad o componente aislado | 3 |
| `VentaServiceTest` | Unidad o componente aislado | 24 |
| `VentaTiendaCodigoTest` | Unidad o componente aislado | 3 |

## Frontend

- `src/api/catalogoApi.test.ts`
- `src/api/pedidoApi.mocks.test.ts`
- `src/api/pedidoApi.test.ts`
- `src/api/pickupApi.mocks.test.ts`
- `src/api/pickupApi.test.ts`
- `src/api/seguridad.g7.test.ts`
- `src/api/seguridad.test.ts`
- `src/api/ventas.test.ts`
- `src/components/molecules/OfflineBanner.test.tsx`
- `src/components/organisms/carrito/CartPanel.test.tsx`
- `src/components/organisms/catalogo/ProductDetailModal.test.tsx`
- `src/components/organisms/clientes/CustomerSection.test.tsx`
- `src/components/organisms/cobro/PaymentModal.offline.test.tsx`
- `src/components/organisms/cobro/PaymentModal.test.tsx`
- `src/components/organisms/cobro/Receipt.offline.test.tsx`
- `src/components/organisms/historial/OrderHistoryModal.test.tsx`
- `src/components/organisms/pickup/DeliveryModal.test.tsx`
- `src/context/ContingenciaContext.test.tsx`
- `src/hooks/useCatalogoTienda.test.tsx`
- `src/hooks/useEnfoqueInicial.test.tsx`
- `src/lib/cart.test.ts`
- `src/lib/cartStorage.test.ts`
- `src/lib/catalog.test.ts`
- `src/lib/documento.test.ts`
- `src/lib/format.test.ts`
- `src/lib/inspeccion.test.ts`
- `src/lib/inventory.test.ts`
- `src/lib/offlineHash.test.ts`
- `src/lib/offlineStorage.indexeddb.test.ts`
- `src/lib/offlineStorage.test.ts`
- `src/lib/pedidos.test.ts`
- `src/lib/scanner.test.ts`
- `src/lib/token.test.ts`
- `src/pages/ExchangePage.test.tsx`
- `src/pages/OrdersHistoryPage.test.tsx`
- `src/pages/PickupPage.test.tsx`
- `src/router/ProtectedRoute.test.tsx`
- `src/store/authStore.test.ts`
- `src/store/cart.test.ts`
