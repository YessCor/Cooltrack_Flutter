# CoolTrack Flutter Migration - Plan de Ejecución

## Objetivo
Migrar el proyecto completo de React Native (CoolTrack-Pro) a Flutter (Cooltrack_Flutter)

---

## 🔄 FASE 1: Core Foundation [COMPLETADO ✅]

### 1.1 Constantes y Tipos [✅ COMPLETO]
- [x] constants.dart - OrderStatus, UserRole, EquipmentType, QuoteStatus, NotificationType
- [x] API base URL configurada

### 1.2 Tema y Estilos [✅ COMPLETO]
- [x] theme.dart - Material 3 con colores de CoolTrack (#0D1B2A primary, #00B4D8 secondary)

### 1.3 Cliente HTTP [✅ COMPLETO]
- [x] api_client.dart con Dio, interceptors, manejo de errores

### 1.4 Modelos de Datos [✅ COMPLETO]
- [x] user.dart
- [x] client.dart
- [x] equipment.dart
- [x] service_order.dart
- [x] quote.dart, quote_item.dart
- [x] technician_location.dart
- [x] notification.dart
- [x] dashboard_stats.dart

### 1.5 Autenticación [✅ COMPLETO]
- [x] auth_provider.dart con StateNotifier (Riverpod)

### 1.6 Navegación [✅ COMPLETO]
- [x] router.dart con GoRouter + role guards

---

## 🔄 FASE 2: Pantallas de Auth y Admin [COMPLETADO ✅]

### 2.1 Auth [✅ COMPLETO]
- [x] login_screen.dart - Formulario de inicio de sesión
- [x] forgot_password_screen.dart - Recuperar contraseña

### 2.2 Admin - Layout y Dashboard [✅ COMPLETO]
- [x] admin_layout.dart - Bottom navigation con 5 tabs
- [x] admin_dashboard_screen.dart - Stats cards, quick actions, recent orders

### 2.3 Admin - Clients CRUD [✅ COMPLETO]
- [x] admin_clients_screen.dart - Lista de clientes con búsqueda
- [x] admin_client_new_screen.dart - Formulario para crear cliente

### 2.4 Admin - Technicians [✅ COMPLETO]
- [x] admin_technicians_screen.dart - Lista de técnicos

### 2.5 Admin - Orders [✅ COMPLETO]
- [x] admin_orders_screen.dart - Lista de órdenes con filtros de estado

### 2.6 Admin - Quotes [✅ COMPLETO]
- [x] admin_quotes_screen.dart - Lista de cotizaciones

### 2.7 Admin - Equipment [✅ COMPLETO]
- [x] admin_equipment_screen.dart - Lista de equipos

---

## 🔄 FASE 3: Pantallas Technician [PENDIENTE ⏳]

### 3.1 Technician Layout
- [ ] tech_layout.dart - Bottom navigation (Jobs, Profile)

### 3.2 Technician Jobs List
- [ ] tech_jobs_screen.dart - Lista de trabajos asignados
- [ ] Provider: tech_jobs_provider.dart

### 3.3 Technician Job Detail
- [ ] tech_job_detail_screen.dart - Detalle del trabajo
- [ ] Estados: accept, in_transit, in_progress, complete
- [ ] Provider: job_detail_provider.dart

### 3.4 Technician Photo Capture
- [ ] photo_capture_component.dart - Cámara para evidencia
- [ ] Dependencia: image_picker

### 3.5 Technician Signature
- [ ] signature_component.dart - Canvas para firma del cliente
- [ ] Dependencia: signature

### 3.6 Technician Parts Selector
- [ ] parts_selector_component.dart - Selector de refacciones
- [ ] Provider: parts_provider.dart

### 3.7 Technician Quote
- [ ] tech_quote_detail_screen.dart - Ver/crear cotización desde trabajo

### 3.8 Technician Profile
- [ ] tech_profile_screen.dart - Perfil del técnico

---

## 🔄 FASE 4: Pantallas Client [PENDIENTE ⏳]

### 4.1 Client Layout
- [ ] client_layout.dart - Bottom navigation (Home, Equipment, Services)

### 4.2 Client Home
- [ ] client_home_screen.dart - Dashboard del cliente

### 4.3 Client Equipment
- [ ] client_equipment_screen.dart - Lista de equipos del cliente
- [ ] Provider: client_equipment_provider.dart
- [ ] client_equipment_detail_screen.dart - Detalle de equipo

### 4.4 Client New Equipment
- [ ] client_equipment_new_screen.dart - Agregar nuevo equipo

### 4.5 Client New Request
- [ ] client_new_request_screen.dart - Solicitar servicio
- [ ] Formulario: descripción, tipo de servicio, prioridad

### 4.6 Client Service Detail
- [ ] client_service_detail_screen.dart - Ver estado de servicio

### 4.7 Client Quote Detail
- [ ] client_quote_detail_screen.dart - Ver cotizaciones

---

## 🔄 FASE 5: Componentes UI Reutilizables [PENDIENTE ⏳]

### 5.1 Primitivas Base
- [ ] button.dart - AppButton variant (primary, secondary, outline, text)
- [ ] card.dart - AppCard
- [ ] input.dart - AppInput (TextField con validación)
- [ ] modal.dart - AppModal
- [ ] toast.dart - AppToast (snackbar)

### 5.2 Componentes de Dominio
- [ ] status_badge.dart - Badge para estados (OrderStatus, QuoteStatus)
- [ ] list_item.dart - ListItem personalizado
- [ ] avatar.dart - Avatar de usuario

### 5.3 Iconos
- [ ] icons.dart - Iconos de la app

---

## 🔄 FASE 6: Servicios y Funcionalidades [PENDIENTE ⏳]

### 6.1 Geolocalización
- [ ] location_service.dart - Servicio de GPS
- [ ] Provider: location_provider.dart

### 6.2 Sincronización Offline
- [ ] sync_service.dart - Sincronización de datos
- [ ] Repositorio offline con Hive

### 6.3 Carga de Fotos
- [ ] photo_upload_service.dart - Subir fotos a Cloudinary
- [ ] Provider: photo_upload_provider.dart

### 6.4 Generación PDF
- [ ] pdf_service.dart - Generar cotizaciones en PDF

---

## 🔄 FASE 7: Pantallas de Detalle Admin [PENDIENTE ⏳]

### 7.1 Client Detail
- [ ] admin_client_detail_screen.dart - Ver/edit cliente + equipos

### 7.2 Order Detail
- [ ] admin_order_detail_screen.dart - Ver/edit orden, asignar técnico

### 7.3 Quote New
- [ ] admin_quote_new_screen.dart - Crear cotización

### 7.4 Equipment New
- [ ] admin_equipment_new_screen.dart - Crear equipo

### 7.5 Equipment Detail
- [ ] admin_equipment_detail_screen.dart - Ver/edit equipo

### 7.6 Create Technician
- [ ] admin_create_technician_screen.dart - Crear técnico

---

## 📋 Archivos del Proyecto React Native de Referencia

```
CoolTrack-Pro/
├── lib/
│   ├── types.ts                    → Migrar a models/
│   ├── order-status.ts             → constants.dart
│   ├── api.ts                      → api_client.dart
│   ├── auth.ts                     → auth_provider.dart
│   └── storage.ts                  → Hive service
├── components/
│   ├── PhotoCapture.tsx            → Phase 3.4
│   ├── SignatureCanvas.tsx         → Phase 3.5
│   ├── PartsSelector.tsx           → Phase 3.5
│   └── ui/*                        → Phase 5
├── app/
│   ├── (auth)/login.tsx            → Phase 2.1 ✅
│   ├── (auth)/forgot-password.tsx  → Phase 2.1 ✅
│   ├── (admin)/*                   → Phase 2.2-2.7 ✅
│   ├── (technician)/*              → Phase 3
│   └── (client)/*                  → Phase 4
```

---

## ⚡ Próximo Paso Inmediato (Para opencode)

Ejecutar **FASE 3** en orden:

1. Crear `lib/features/tech/views/tech_layout.dart`
2. Crear `lib/features/tech/views/tech_jobs_screen.dart`
3. Crear `lib/features/tech/views/tech_job_detail_screen.dart`
4. Crear componentes: `photo_capture_component.dart`, `signature_component.dart`, `parts_selector_component.dart`
5. Actualizar `lib/core/router.dart` con las nuevas rutas

---

## 🎯 Objetivo Final

Proyecto Flutter funcional con:
- ✅ Autenticación completa
- ✅ Role-based navigation (Admin, Technician, Client)
- ✅ CRUD de clientes, técnicos, órdenes, cotizaciones, equipos
- ✅ Flujo de trabajo del técnico (aceptar, iniciar, completar)
- ✅ Captura de fotos y firmas digitales
- ✅ UI consistente con tema Material 3