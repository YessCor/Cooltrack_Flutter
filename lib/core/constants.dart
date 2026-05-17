// API Configuration
const String apiBaseUrl = 'http://localhost:8080/api';

// Supabase Configuration
const String supabaseUrl = 'https://ycblykplwavtrmhggmgf.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_pElMPEafQ7OfXk0Vm4Rkgw_-TOaqKiR';

// User Roles
enum UserRole { admin, technician, client }

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.technician:
      return 'technician';
    case UserRole.client:
      return 'client';
  }
}

UserRole? userRoleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'technician':
      return UserRole.technician;
    case 'client':
      return UserRole.client;
    default:
      return null;
  }
}

// Order Status -同步 con DB enum order_status
enum OrderStatus {
  pending,
  assigned,
  accepted,
  inTransit,
  inProgress,
  completed,
  cancelled,
}

const Map<OrderStatus, String> orderStatusValues = {
  OrderStatus.pending: 'pending',
  OrderStatus.assigned: 'assigned',
  OrderStatus.accepted: 'accepted',
  OrderStatus.inTransit: 'in_transit',
  OrderStatus.inProgress: 'in_progress',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};

String orderStatusToString(OrderStatus status) => orderStatusValues[status]!;

OrderStatus? orderStatusFromString(String value) {
  for (final entry in orderStatusValues.entries) {
    if (entry.value == value.toLowerCase()) return entry.key;
  }
  return null;
}

// Etiquetas en español para UI
const Map<OrderStatus, String> orderStatusLabels = {
  OrderStatus.pending: 'Pendiente',
  OrderStatus.assigned: 'Asignado',
  OrderStatus.accepted: 'Aceptado',
  OrderStatus.inTransit: 'En Camino',
  OrderStatus.inProgress: 'En Progreso',
  OrderStatus.completed: 'Completado',
  OrderStatus.cancelled: 'Cancelado',
};

// Transiciones permitidas por rol
const Map<UserRole, List<OrderStatus>> allowedTransitions = {
  UserRole.admin: [OrderStatus.assigned, OrderStatus.cancelled],
  UserRole.technician: [
    OrderStatus.accepted,
    OrderStatus.inTransit,
    OrderStatus.inProgress,
    OrderStatus.completed,
  ],
  UserRole.client: [],
};

// Siguiente estado del técnico en el flujo lineal
const Map<OrderStatus, OrderStatus> technicianNextStatus = {
  OrderStatus.assigned: OrderStatus.accepted,
  OrderStatus.accepted: OrderStatus.inTransit,
  OrderStatus.inTransit: OrderStatus.inProgress,
  OrderStatus.inProgress: OrderStatus.completed,
};

// Equipment Types
enum EquipmentType { split, central, miniSplit, chiller, fanCoil, other }

const Map<EquipmentType, String> equipmentTypeValues = {
  EquipmentType.split: 'split',
  EquipmentType.central: 'central',
  EquipmentType.miniSplit: 'mini_split',
  EquipmentType.chiller: 'chiller',
  EquipmentType.fanCoil: 'fan_coil',
  EquipmentType.other: 'other',
};

String equipmentTypeToString(EquipmentType type) => equipmentTypeValues[type]!;

EquipmentType? equipmentTypeFromString(String value) {
  for (final entry in equipmentTypeValues.entries) {
    if (entry.value == value.toLowerCase()) return entry.key;
  }
  return null;
}

const Map<EquipmentType, String> equipmentTypeLabels = {
  EquipmentType.split: 'Split',
  EquipmentType.central: 'Central',
  EquipmentType.miniSplit: 'Mini Split',
  EquipmentType.chiller: 'Chiller',
  EquipmentType.fanCoil: 'Fan Coil',
  EquipmentType.other: 'Otro',
};

// Quote Status
enum QuoteStatus { draft, sent, approved, rejected, expired }

const Map<QuoteStatus, String> quoteStatusValues = {
  QuoteStatus.draft: 'draft',
  QuoteStatus.sent: 'sent',
  QuoteStatus.approved: 'approved',
  QuoteStatus.rejected: 'rejected',
  QuoteStatus.expired: 'expired',
};

String quoteStatusToString(QuoteStatus status) => quoteStatusValues[status]!;

QuoteStatus? quoteStatusFromString(String value) {
  for (final entry in quoteStatusValues.entries) {
    if (entry.value == value.toLowerCase()) return entry.key;
  }
  return null;
}

const Map<QuoteStatus, String> quoteStatusLabels = {
  QuoteStatus.draft: 'Borrador',
  QuoteStatus.sent: 'Enviado',
  QuoteStatus.approved: 'Aprobado',
  QuoteStatus.rejected: 'Rechazado',
  QuoteStatus.expired: 'Expirado',
};

// Notification Types
enum NotificationType { order, quote, info, alert }

// Storage Keys
const String tokenKey = 'auth_token';
const String userKey = 'user_data';
