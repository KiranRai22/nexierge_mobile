/// Needs attention item from dashboard/needs_attention API.
class NeedsAttentionItem {
  final String id;
  final int createdAt;
  final String departmentId;
  final String status;
  final int dueAt;
  final String room;
  final String guestName;
  final int acknowledgedAt;
  final DepartmentInfo department;
  final String onbRoomNumber;

  const NeedsAttentionItem({
    required this.id,
    required this.createdAt,
    required this.departmentId,
    required this.status,
    required this.dueAt,
    required this.room,
    required this.guestName,
    required this.acknowledgedAt,
    required this.department,
    required this.onbRoomNumber,
  });

  factory NeedsAttentionItem.fromJson(Map<String, dynamic> json) {
    return NeedsAttentionItem(
      id: json['id'] as String,
      createdAt: json['created_at'] as int,
      departmentId: json['department_id'] as String,
      status: json['status'] as String,
      dueAt: json['due_at'] as int,
      room: json['room'] as String,
      guestName: json['guest_name'] as String,
      acknowledgedAt: json['acknowledged_at'] as int,
      department: DepartmentInfo.fromJson(
        json['_department'] as Map<String, dynamic>,
      ),
      onbRoomNumber: json['onb_room_number'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt,
      'department_id': departmentId,
      'status': status,
      'due_at': dueAt,
      'room': room,
      'guest_name': guestName,
      'acknowledged_at': acknowledgedAt,
      '_department': department.toJson(),
      'onb_room_number': onbRoomNumber,
    };
  }
}

class DepartmentInfo {
  final String name;
  final String mobileIcon;
  final IconInfo icon;

  const DepartmentInfo({
    required this.name,
    required this.mobileIcon,
    required this.icon,
  });

  factory DepartmentInfo.fromJson(Map<String, dynamic> json) {
    return DepartmentInfo(
      name: json['name'] as String,
      mobileIcon: json['mobile_icon'] as String,
      icon: IconInfo.fromJson(json['icon'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile_icon': mobileIcon,
      'icon': icon.toJson(),
    };
  }
}

class IconInfo {
  final String url;

  const IconInfo({required this.url});

  factory IconInfo.fromJson(Map<String, dynamic> json) {
    return IconInfo(url: json['url'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'url': url};
  }
}
