# CoolTrack Flutter Migration - TODO

## Status: ✅ Plan Approved | 📁 Project Created | ⏳ Implementation In Progress

### 1. Project Setup [✅ COMPLETE]
- [x] Create `Cooltrack-flutter/` project
- [x] Add core dependencies (pubspec.yaml)
- [x] Flutter pub get
- [x] Basic structure (lib/core, models, etc.)
- [x] Hive setup + models generation

### 2. Core Foundation [0/6]
- [ ] Core: theme.dart, constants.dart (OrderStatus from lib/order-status.ts)
- [ ] API Client: dio_client.dart (migrate API calls)
- [ ] Models: Migrate lib/types.ts → models/*.dart (User, Equipment, Order, Quote, Part) + Freezed/Hive
- [ ] Auth Provider: auth_provider.dart (migrate AuthContext + NextAuth logic)
- [ ] Offline Repos: Base Hive service (migrate repositories pattern)
- [ ] Navigation: GoRouter + role guards (migrate _layout.tsx)

### 3. Features by Role [0/3]
- [ ] Admin: Dashboard, Clients CRUD, Quotes/Orders (app/(admin)/ → features/admin/)
- [ ] Technician: Jobs list/detail, Photo/Signature/Parts (app/(technician)/ + components)
- [ ] Client: Equipment/Orders view (app/(client)/)

### 4. Components/UI [0/5]
- [ ] UI Primitives: Button, Card, Modal (components/ui/)
- [ ] Domain: SignatureCanvas, PhotoCapture, PartsSelector
- [ ] Theme: Material 3 + Tailwind colors (#0D1B2A primary)

### 5. Services [0/4]
- [ ] Geolocation (expo-location → geolocator)
- [ ] Sync Service (background via WorkManager)
- [ ] PDF Generation (quotes)
- [ ] Photo Upload (Cloudinary?)

### 6. Testing/Polish [0/3]
- [ ] Offline/online tests
- [ ] Platforms: Android/iOS/Web builds
- [ ] Migrate assets/fonts

**Next Step: Core Foundation → constants.dart + api_client.dart**

