import 'package:flutter/material.dart';

import 'app_data.dart';

const _screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AmenaOpsApp());
}

class AmenaOpsApp extends StatelessWidget {
  const AmenaOpsApp({super.key, this.initialStore});

  final OpsStore? initialStore;

  @override
  Widget build(BuildContext context) {
    final store = initialStore;
    if (store != null) {
      return _MaterialShell(store: store);
    }

    return FutureBuilder<OpsStore>(
      future: OpsStore.load(screenshotMode: _screenshotMode),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _MaterialShell(store: snapshot.requireData);
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: const _LoadingScreen(),
        );
      },
    );
  }
}

ThemeData _buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2B5672),
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF6F8F4),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: const Color(0xFF173747),
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E7E3)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2B5672),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2B5672),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: const Color(0xFFD8E7DE),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _MaterialShell extends StatelessWidget {
  const _MaterialShell({required this.store});

  final OpsStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: OpsHome(store: store),
    );
  }
}

class OpsHome extends StatefulWidget {
  const OpsHome({super.key, required this.store});

  final OpsStore store;

  @override
  State<OpsHome> createState() => _OpsHomeState();
}

class _OpsHomeState extends State<OpsHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              appTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardScreen(store: widget.store),
              PatientsScreen(store: widget.store),
              AppointmentsScreen(store: widget.store),
              TrainingScreen(store: widget.store),
              SettingsScreen(store: widget.store),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_shared_outlined),
                selectedIcon: Icon(Icons.folder_shared),
                label: 'Patients',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Training',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
          floatingActionButton: _floatingAction(context),
        );
      },
    );
  }

  Widget? _floatingAction(BuildContext context) {
    if (_selectedIndex == 1) {
      return FloatingActionButton.extended(
        heroTag: 'new-patient',
        key: const Key('newPatientButton'),
        onPressed: () => _showPatientSheet(context, widget.store),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New patient'),
      );
    }
    if (_selectedIndex == 2) {
      return FloatingActionButton.extended(
        heroTag: 'new-booking',
        key: const Key('newAppointmentButton'),
        onPressed: () => _showAppointmentSheet(context, widget.store),
        icon: const Icon(Icons.add_task),
        label: const Text('Book'),
      );
    }
    if (_selectedIndex == 3) {
      return FloatingActionButton.extended(
        heroTag: 'new-training',
        onPressed: () => _showTrainingSheet(context, widget.store),
        icon: const Icon(Icons.playlist_add_check),
        label: const Text('Assign'),
      );
    }
    return null;
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store});

  final OpsStore store;

  @override
  Widget build(BuildContext context) {
    final nextAppointment =
        store.appointments.where((record) => record.status == 'Booked').toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const AppHeader(
            title: 'Operations desk',
            subtitle:
                'Appointments, patient records, staff courses, and audit notes stay local to this device.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricTile(
                label: 'Patients',
                value: store.patients.length.toString(),
                icon: Icons.folder_shared,
                color: const Color(0xFF2B5672),
              ),
              MetricTile(
                label: 'Booked',
                value: store.bookedAppointments.toString(),
                icon: Icons.event_available,
                color: const Color(0xFF3C7B68),
              ),
              MetricTile(
                label: 'Completed',
                value: store.completedAppointments.toString(),
                icon: Icons.task_alt,
                color: const Color(0xFFB86A3A),
              ),
              MetricTile(
                label: 'Training due',
                value: store.overdueTraining.toString(),
                icon: Icons.school,
                color: const Color(0xFF7A4E88),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionTitle('Next appointment'),
          if (nextAppointment.isEmpty)
            const EmptyState(
              icon: Icons.event_busy,
              title: 'No booked appointments',
              body: 'New bookings will appear here as the team schedules them.',
            )
          else
            AppointmentCard(
              record: nextAppointment.first,
              onComplete: () =>
                  store.completeAppointment(nextAppointment.first.id),
              emphasize: true,
            ),
          const SizedBox(height: 18),
          const SectionTitle('Recent audit notes'),
          ...store.audit.take(3).map((entry) => AuditCard(entry: entry)),
        ],
      ),
    );
  }
}

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key, required this.store});

  final OpsStore store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          const AppHeader(
            title: 'Patient records',
            subtitle:
                'Track priority, last contact, and the care plan for each local record.',
          ),
          const SizedBox(height: 16),
          ...store.patients.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PatientCard(
                record: record,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PatientDetailScreen(record: record),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key, required this.record});

  final PatientRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(record.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppHeader(
              title: record.priority,
              subtitle: 'Last visit: ${formatDate(record.lastVisit)}',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care plan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(record.carePlan),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Stored locally on this device. No account or cloud sync is required.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key, required this.store});

  final OpsStore store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          const AppHeader(
            title: 'Appointment board',
            subtitle:
                'Book, monitor, and close daily appointments from one local queue.',
          ),
          const SizedBox(height: 16),
          ...store.appointments.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppointmentCard(
                record: record,
                onComplete: record.status == 'Booked'
                    ? () => store.completeAppointment(record.id)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key, required this.store});

  final OpsStore store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          const AppHeader(
            title: 'Staff training',
            subtitle:
                'Assign operational courses and update progress during daily reviews.',
          ),
          const SizedBox(height: 16),
          ...store.training.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TrainingCard(
                record: record,
                onAdvance: record.progress < 100
                    ? () => store.advanceTraining(record.id)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SectionTitle('Audit log'),
          ...store.audit.take(4).map((entry) => AuditCard(entry: entry)),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final OpsStore store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const AppHeader(
            title: 'Workspace settings',
            subtitle:
                'Review local storage behavior and reset the sample workspace when needed.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Support: $supportEmail'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Records and preferences stay in local app storage on this Android device. The app has no account sign-in, cloud sync, analytics, or advertising identifiers.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: store.restoreSampleData,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore sample workspace'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Latest audit entries'),
          ...store.audit.map((entry) => AuditCard(entry: entry)),
        ],
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF173747),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFE8F1ED)),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 42) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF173747),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF173747),
        ),
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  const PatientCard({super.key, required this.record, required this.onTap});

  final PatientRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(record.name),
        subtitle: Text('${record.priority} - ${record.carePlan}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.record,
    this.onComplete,
    this.emphasize = false,
  });

  final AppointmentRecord record;
  final VoidCallback? onComplete;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final statusColor = record.status == 'Completed'
        ? const Color(0xFF3C7B68)
        : const Color(0xFFB86A3A);

    return Card(
      color: emphasize ? const Color(0xFFFFFCF6) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.patientName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  label: Text(record.status),
                  side: BorderSide(color: statusColor),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(record.service),
            const SizedBox(height: 4),
            Text(formatDateTime(record.date)),
            if (onComplete != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark completed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TrainingCard extends StatelessWidget {
  const TrainingCard({super.key, required this.record, this.onAdvance});

  final TrainingCourse record;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('${record.attendee} - due ${formatShortDate(record.dueDate)}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: record.progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${record.progress}% complete'),
                const Spacer(),
                if (onAdvance != null)
                  TextButton.icon(
                    onPressed: onAdvance,
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Advance'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuditCard extends StatelessWidget {
  const AuditCard({super.key, required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.history),
          title: Text(entry.action),
          subtitle: Text('${entry.area} - ${formatDateTime(entry.time)}'),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF2B5672)),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Future<void> _showPatientSheet(BuildContext context, OpsStore store) async {
  final nameController = TextEditingController();
  final planController = TextEditingController();
  var priority = 'Routine';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New patient record',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('patientNameField'),
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient name',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('patientCarePlanField'),
                    controller: planController,
                    decoration: const InputDecoration(labelText: 'Care plan'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Routine', 'High', 'New intake']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value),
                            selected: priority == value,
                            onSelected: (_) =>
                                setSheetState(() => priority = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const Key('savePatientButton'),
                    onPressed: () {
                      final name = nameController.text.trim();
                      final carePlan = planController.text.trim();
                      if (name.isEmpty || carePlan.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop();
                      store.addPatient(
                        name: name,
                        carePlan: carePlan,
                        priority: priority,
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save record'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showAppointmentSheet(BuildContext context, OpsStore store) async {
  final patientController = TextEditingController();
  var service = 'Care coordination';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book appointment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: patientController,
                    decoration: const InputDecoration(
                      labelText: 'Patient name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: service,
                    decoration: const InputDecoration(labelText: 'Service'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Care coordination',
                        child: Text('Care coordination'),
                      ),
                      DropdownMenuItem(
                        value: 'Patient record review',
                        child: Text('Patient record review'),
                      ),
                      DropdownMenuItem(
                        value: 'Administrative intake',
                        child: Text('Administrative intake'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => service = value);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      final name = patientController.text.trim();
                      if (name.isEmpty) {
                        return;
                      }
                      final now = DateTime.now();
                      Navigator.of(context).pop();
                      store.addAppointment(
                        patientName: name,
                        service: service,
                        date: DateTime(now.year, now.month, now.day + 1, 9, 30),
                      );
                    },
                    icon: const Icon(Icons.event_available),
                    label: const Text('Create booking'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showTrainingSheet(BuildContext context, OpsStore store) async {
  final titleController = TextEditingController();
  final attendeeController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign training',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Course title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: attendeeController,
                decoration: const InputDecoration(
                  labelText: 'Team or attendee',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  final title = titleController.text.trim();
                  final attendee = attendeeController.text.trim();
                  if (title.isEmpty || attendee.isEmpty) {
                    return;
                  }
                  final now = DateTime.now();
                  Navigator.of(context).pop();
                  store.addTraining(
                    title: title,
                    attendee: attendee,
                    dueDate: DateTime(now.year, now.month, now.day + 14),
                  );
                },
                icon: const Icon(Icons.school_outlined),
                label: const Text('Save assignment'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
