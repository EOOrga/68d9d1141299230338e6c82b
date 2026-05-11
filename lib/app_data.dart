import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appTitle = 'ASS DEVEL AMENA MOYENNE VALLEE';
const companyName = 'ASS DEVEL AMENA MOYENNE VALLEE HERAULT';
const supportEmail = 'contact@amena-moyenne-vallee.fr';

const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(DateTime value) {
  return '${_months[value.month - 1]} ${value.day}, ${value.year}';
}

String formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${formatDate(value)} at $hour:$minute';
}

String formatShortDate(DateTime value) {
  return '${_months[value.month - 1]} ${value.day}';
}

String _id(String prefix) {
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

class PatientRecord {
  const PatientRecord({
    required this.id,
    required this.name,
    required this.carePlan,
    required this.priority,
    required this.lastVisit,
  });

  final String id;
  final String name;
  final String carePlan;
  final String priority;
  final DateTime lastVisit;

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    return PatientRecord(
      id: json['id'] as String? ?? _id('patient'),
      name: json['name'] as String? ?? 'Patient',
      carePlan: json['carePlan'] as String? ?? 'Follow up',
      priority: json['priority'] as String? ?? 'Routine',
      lastVisit:
          DateTime.tryParse(json['lastVisit'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'carePlan': carePlan,
      'priority': priority,
      'lastVisit': lastVisit.toIso8601String(),
    };
  }
}

class AppointmentRecord {
  const AppointmentRecord({
    required this.id,
    required this.patientName,
    required this.service,
    required this.date,
    required this.status,
  });

  final String id;
  final String patientName;
  final String service;
  final DateTime date;
  final String status;

  AppointmentRecord copyWith({String? status}) {
    return AppointmentRecord(
      id: id,
      patientName: patientName,
      service: service,
      date: date,
      status: status ?? this.status,
    );
  }

  factory AppointmentRecord.fromJson(Map<String, dynamic> json) {
    return AppointmentRecord(
      id: json['id'] as String? ?? _id('appointment'),
      patientName: json['patientName'] as String? ?? 'Patient',
      service: json['service'] as String? ?? 'Consultation',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'Booked',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'service': service,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}

class TrainingCourse {
  const TrainingCourse({
    required this.id,
    required this.title,
    required this.attendee,
    required this.progress,
    required this.dueDate,
  });

  final String id;
  final String title;
  final String attendee;
  final int progress;
  final DateTime dueDate;

  TrainingCourse copyWith({int? progress}) {
    return TrainingCourse(
      id: id,
      title: title,
      attendee: attendee,
      progress: progress ?? this.progress,
      dueDate: dueDate,
    );
  }

  factory TrainingCourse.fromJson(Map<String, dynamic> json) {
    return TrainingCourse(
      id: json['id'] as String? ?? _id('training'),
      title: json['title'] as String? ?? 'Training',
      attendee: json['attendee'] as String? ?? 'Staff member',
      progress: json['progress'] as int? ?? 0,
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'attendee': attendee,
      'progress': progress,
      'dueDate': dueDate.toIso8601String(),
    };
  }
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.area,
    required this.time,
  });

  final String id;
  final String action;
  final String area;
  final DateTime time;

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'] as String? ?? _id('audit'),
      action: json['action'] as String? ?? 'Updated record',
      area: json['area'] as String? ?? 'Operations',
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'area': area,
      'time': time.toIso8601String(),
    };
  }
}

class OpsStore extends ChangeNotifier {
  OpsStore._({
    required SharedPreferences? preferences,
    required this.screenshotMode,
    required List<PatientRecord> patients,
    required List<AppointmentRecord> appointments,
    required List<TrainingCourse> training,
    required List<AuditEntry> audit,
  }) : _preferences = preferences,
       _patients = patients,
       _appointments = appointments,
       _training = training,
       _audit = audit;

  static const _prefKey = 'amena_vallee_ops_v1';

  final SharedPreferences? _preferences;
  final bool screenshotMode;
  final List<PatientRecord> _patients;
  final List<AppointmentRecord> _appointments;
  final List<TrainingCourse> _training;
  final List<AuditEntry> _audit;

  List<PatientRecord> get patients => List.unmodifiable(_patients);
  List<AppointmentRecord> get appointments => List.unmodifiable(_appointments);
  List<TrainingCourse> get training => List.unmodifiable(_training);
  List<AuditEntry> get audit => List.unmodifiable(_audit);

  int get bookedAppointments =>
      _appointments.where((record) => record.status == 'Booked').length;

  int get completedAppointments =>
      _appointments.where((record) => record.status == 'Completed').length;

  int get overdueTraining {
    final today = DateTime(2026, 5, 11);
    return _training
        .where(
          (record) => record.progress < 100 && record.dueDate.isBefore(today),
        )
        .length;
  }

  static Future<OpsStore> load({bool screenshotMode = false}) async {
    if (screenshotMode) {
      return OpsStore.seeded(screenshotMode: true);
    }

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_prefKey);
    if (raw == null || raw.isEmpty) {
      final store = OpsStore.seeded(preferences: preferences);
      store._save();
      return store;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return OpsStore._(
        preferences: preferences,
        screenshotMode: false,
        patients: (decoded['patients'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PatientRecord.fromJson)
            .toList(),
        appointments: (decoded['appointments'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AppointmentRecord.fromJson)
            .toList(),
        training: (decoded['training'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TrainingCourse.fromJson)
            .toList(),
        audit: (decoded['audit'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AuditEntry.fromJson)
            .toList(),
      );
    } on FormatException {
      return OpsStore.seeded(preferences: preferences);
    } on TypeError {
      return OpsStore.seeded(preferences: preferences);
    }
  }

  factory OpsStore.seeded({
    SharedPreferences? preferences,
    bool screenshotMode = false,
  }) {
    final base = DateTime(2026, 5, 10);
    return OpsStore._(
      preferences: preferences,
      screenshotMode: screenshotMode,
      patients: [
        PatientRecord(
          id: 'patient-001',
          name: 'Mira Laurent',
          carePlan: 'Post-visit check and transport assistance',
          priority: 'High',
          lastVisit: base.subtract(const Duration(days: 1)),
        ),
        PatientRecord(
          id: 'patient-002',
          name: 'Jean Pelletier',
          carePlan: 'Monthly appointment and medication review',
          priority: 'Routine',
          lastVisit: base.subtract(const Duration(days: 6)),
        ),
        PatientRecord(
          id: 'patient-003',
          name: 'Samira Bousquet',
          carePlan: 'New patient intake and document verification',
          priority: 'New intake',
          lastVisit: base,
        ),
      ],
      appointments: [
        AppointmentRecord(
          id: 'appointment-001',
          patientName: 'Mira Laurent',
          service: 'Care coordination',
          date: DateTime(2026, 5, 10, 9, 30),
          status: 'Booked',
        ),
        AppointmentRecord(
          id: 'appointment-002',
          patientName: 'Jean Pelletier',
          service: 'Patient record review',
          date: DateTime(2026, 5, 10, 14),
          status: 'Booked',
        ),
        AppointmentRecord(
          id: 'appointment-003',
          patientName: 'Samira Bousquet',
          service: 'Administrative intake',
          date: DateTime(2026, 5, 9, 11),
          status: 'Completed',
        ),
      ],
      training: [
        TrainingCourse(
          id: 'training-001',
          title: 'Patient record handling',
          attendee: 'Front desk team',
          progress: 75,
          dueDate: base.add(const Duration(days: 4)),
        ),
        TrainingCourse(
          id: 'training-002',
          title: 'Appointment triage workflow',
          attendee: 'Care coordinators',
          progress: 40,
          dueDate: base.add(const Duration(days: 8)),
        ),
        TrainingCourse(
          id: 'training-003',
          title: 'Internal audit checklist',
          attendee: 'Operations leads',
          progress: 100,
          dueDate: base.subtract(const Duration(days: 3)),
        ),
      ],
      audit: [
        AuditEntry(
          id: 'audit-001',
          action: 'Completed administrative intake',
          area: 'Appointments',
          time: DateTime(2026, 5, 9, 11, 45),
        ),
        AuditEntry(
          id: 'audit-002',
          action: 'Updated post-visit care plan',
          area: 'Patients',
          time: DateTime(2026, 5, 9, 16, 10),
        ),
        AuditEntry(
          id: 'audit-003',
          action: 'Advanced internal audit training',
          area: 'Training',
          time: DateTime(2026, 5, 8, 13, 20),
        ),
        AuditEntry(
          id: 'audit-004',
          action: 'Reviewed privacy and local storage settings',
          area: 'Settings',
          time: DateTime(2026, 5, 8, 9, 5),
        ),
      ],
    );
  }

  void addPatient({
    required String name,
    required String carePlan,
    required String priority,
  }) {
    _patients.insert(
      0,
      PatientRecord(
        id: _id('patient'),
        name: name,
        carePlan: carePlan,
        priority: priority,
        lastVisit: DateTime.now(),
      ),
    );
    _addAudit('Created patient record for $name', 'Patients');
    _commit();
  }

  void addAppointment({
    required String patientName,
    required String service,
    required DateTime date,
  }) {
    _appointments.insert(
      0,
      AppointmentRecord(
        id: _id('appointment'),
        patientName: patientName,
        service: service,
        date: date,
        status: 'Booked',
      ),
    );
    _addAudit('Booked $service for $patientName', 'Appointments');
    _commit();
  }

  void completeAppointment(String id) {
    final index = _appointments.indexWhere((record) => record.id == id);
    if (index == -1) {
      return;
    }
    final record = _appointments[index];
    _appointments[index] = record.copyWith(status: 'Completed');
    _addAudit(
      'Completed ${record.service} for ${record.patientName}',
      'Appointments',
    );
    _commit();
  }

  void addTraining({
    required String title,
    required String attendee,
    required DateTime dueDate,
  }) {
    _training.insert(
      0,
      TrainingCourse(
        id: _id('training'),
        title: title,
        attendee: attendee,
        progress: 0,
        dueDate: dueDate,
      ),
    );
    _addAudit('Assigned $title to $attendee', 'Training');
    _commit();
  }

  void advanceTraining(String id) {
    final index = _training.indexWhere((record) => record.id == id);
    if (index == -1) {
      return;
    }
    final record = _training[index];
    final nextProgress = (record.progress + 25).clamp(0, 100);
    _training[index] = record.copyWith(progress: nextProgress);
    _addAudit('Updated ${record.title} to $nextProgress%', 'Training');
    _commit();
  }

  void restoreSampleData() {
    final sample = OpsStore.seeded(
      preferences: _preferences,
      screenshotMode: screenshotMode,
    );
    _patients
      ..clear()
      ..addAll(sample._patients);
    _appointments
      ..clear()
      ..addAll(sample._appointments);
    _training
      ..clear()
      ..addAll(sample._training);
    _audit
      ..clear()
      ..addAll(sample._audit);
    _addAudit('Restored local sample workspace', 'Settings');
    _commit();
  }

  void _addAudit(String action, String area) {
    _audit.insert(
      0,
      AuditEntry(
        id: _id('audit'),
        action: action,
        area: area,
        time: DateTime.now(),
      ),
    );
    if (_audit.length > 50) {
      _audit.removeRange(50, _audit.length);
    }
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  void _save() {
    if (screenshotMode) {
      return;
    }
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    preferences.setString(
      _prefKey,
      jsonEncode({
        'patients': _patients.map((record) => record.toJson()).toList(),
        'appointments': _appointments.map((record) => record.toJson()).toList(),
        'training': _training.map((record) => record.toJson()).toList(),
        'audit': _audit.map((record) => record.toJson()).toList(),
      }),
    );
  }
}
