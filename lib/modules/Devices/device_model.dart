class DeviceModel {
  final int id;
  final String hardwareIdentifier;
  final String deviceName;
  final String deviceRole;
  final bool meshAlert;
  final String latitude; // keep as String for display & map parsing later
  final String longitude; // keep as String for display & map parsing later
  final String status;
  final String effectiveStatus;
  final String registeredAt;
  final String lastSeen;
  final bool online;
  final int ownerId;
  final String ownerEmail;
  final String ownerPhone;

  DeviceModel({
    required this.id,
    required this.hardwareIdentifier,
    required this.deviceName,
    required this.deviceRole,
    required this.meshAlert,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.effectiveStatus,
    required this.registeredAt,
    required this.lastSeen,
    required this.online,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerPhone,
  });

  /// Flexible factory:
  /// - Works with full device payloads used in your device module
  /// - AND the lightweight devices inside /auth/me
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    // Helper to coerce any (num | String | null) to String
    String _asString(dynamic v) {
      if (v == null) return '';
      return v is String ? v : v.toString();
    }

    // Some backends use null/empty for last_seen; normalize to ''
    final rawLastSeen = json['last_seen'];

    // Derive a sane "online" flag if backend doesn't provide it
    // Prefer explicit json['online'], else infer from status/effective_status == 'alive'
    final bool inferredOnline = (() {
      if (json['online'] is bool) return json['online'] as bool;
      final s = (_asString(json['status'])).toLowerCase();
      final es = (_asString(json['effective_status'])).toLowerCase();
      return s == 'alive' || es == 'alive';
    })();

    return DeviceModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(_asString(json['id'])) ?? 0,

      hardwareIdentifier: _asString(json['hardware_identifier']),
      deviceName: _asString(json['device_name']),
      deviceRole: _asString(json['device_role']),

      meshAlert: json['mesh_alert'] is bool ? json['mesh_alert'] as bool : false,

      // latitude/longitude can be strings or numbers in different endpoints
      latitude: _asString(json['latitude']),
      longitude: _asString(json['longitude']),

      status: _asString(json['status']),
      effectiveStatus: _asString(json['effective_status']),

      registeredAt: _asString(json['registered_at']),
      lastSeen: rawLastSeen == null ? '' : _asString(rawLastSeen),

      online: inferredOnline,

      ownerId: json['owner_id'] is int
          ? json['owner_id'] as int
          : int.tryParse(_asString(json['owner_id'])) ?? 0,

      ownerEmail: _asString(json['owner_email']),
      ownerPhone: _asString(json['owner_phone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hardware_identifier': hardwareIdentifier,
      'device_name': deviceName,
      'device_role': deviceRole,
      'mesh_alert': meshAlert,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'effective_status': effectiveStatus,
      'registered_at': registeredAt,
      'last_seen': lastSeen,
      'online': online,
      'owner_id': ownerId,
      'owner_email': ownerEmail,
      'owner_phone': ownerPhone,
    };
  }

  DeviceModel copyWith({
    int? id,
    String? hardwareIdentifier,
    String? deviceName,
    String? deviceRole,
    bool? meshAlert,
    String? latitude,
    String? longitude,
    String? status,
    String? effectiveStatus,
    String? registeredAt,
    String? lastSeen,
    bool? online,
    int? ownerId,
    String? ownerEmail,
    String? ownerPhone,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      hardwareIdentifier: hardwareIdentifier ?? this.hardwareIdentifier,
      deviceName: deviceName ?? this.deviceName,
      deviceRole: deviceRole ?? this.deviceRole,
      meshAlert: meshAlert ?? this.meshAlert,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      effectiveStatus: effectiveStatus ?? this.effectiveStatus,
      registeredAt: registeredAt ?? this.registeredAt,
      lastSeen: lastSeen ?? this.lastSeen,
      online: online ?? this.online,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }

  static List<DeviceModel> fromList(List<dynamic>? raw) {
    if (raw == null) return <DeviceModel>[];
    return raw
        .where((e) => e != null)
        .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'DeviceModel(id: $id, name: $deviceName, role: $deviceRole, status: $status, online: $online)';
  }
}
