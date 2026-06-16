enum ConfigType {
  string,
  number,
  boolean;

  static ConfigType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'number':
        return ConfigType.number;
      case 'boolean':
        return ConfigType.boolean;
      case 'string':
      default:
        return ConfigType.string;
    }
  }

  String toJson() => name;
}

class Project {
  final int? id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  Project({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class FeatureFlag {
  final int? id;
  final String key;
  final String? description;
  final bool isEnabled;
  final int rolloutPercentage;
  final Map<String, dynamic> targetingRules;
  final int projectId;
  final DateTime? updatedAt;

  FeatureFlag({
    this.id,
    required this.key,
    this.description,
    this.isEnabled = false,
    this.rolloutPercentage = 100,
    this.targetingRules = const {},
    required this.projectId,
    this.updatedAt,
  });

  FeatureFlag copyWith({
    int? id,
    String? key,
    String? description,
    bool? isEnabled,
    int? rolloutPercentage,
    Map<String, dynamic>? targetingRules,
    int? projectId,
    DateTime? updatedAt,
  }) {
    return FeatureFlag(
      id: id ?? this.id,
      key: key ?? this.key,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      rolloutPercentage: rolloutPercentage ?? this.rolloutPercentage,
      targetingRules: targetingRules ?? this.targetingRules,
      projectId: projectId ?? this.projectId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] as int?,
      key: json['key'] as String,
      description: json['description'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? false,
      rolloutPercentage: json['rollout_percentage'] as int? ?? 100,
      targetingRules: json['targeting_rules'] as Map<String, dynamic>? ?? const {},
      projectId: json['project_id'] as int,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'key': key,
      if (description != null) 'description': description,
      'is_enabled': isEnabled,
      'rollout_percentage': rolloutPercentage,
      'targeting_rules': targetingRules,
      'project_id': projectId,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class RemoteConfig {
  final int? id;
  final String key;
  final String? description;
  final ConfigType valueType;
  final String value;
  final int projectId;
  final DateTime? updatedAt;

  RemoteConfig({
    this.id,
    required this.key,
    this.description,
    this.valueType = ConfigType.string,
    required this.value,
    required this.projectId,
    this.updatedAt,
  });

  RemoteConfig copyWith({
    int? id,
    String? key,
    String? description,
    ConfigType? valueType,
    String? value,
    int? projectId,
    DateTime? updatedAt,
  }) {
    return RemoteConfig(
      id: id ?? this.id,
      key: key ?? this.key,
      description: description ?? this.description,
      valueType: valueType ?? this.valueType,
      value: value ?? this.value,
      projectId: projectId ?? this.projectId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  dynamic get typedValue {
    switch (valueType) {
      case ConfigType.boolean:
        return value.toLowerCase() == 'true' || value == '1';
      case ConfigType.number:
        return num.tryParse(value) ?? value;
      case ConfigType.string:
        return value;
    }
  }

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      id: json['id'] as int?,
      key: json['key'] as String,
      description: json['description'] as String?,
      valueType: ConfigType.fromString(json['value_type'] as String? ?? 'string'),
      value: json['value'] as String? ?? '',
      projectId: json['project_id'] as int,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'key': key,
      if (description != null) 'description': description,
      'value_type': valueType.toJson(),
      'value': value,
      'project_id': projectId,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
