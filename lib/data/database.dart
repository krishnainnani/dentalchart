import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../features/patient_intake/patient_model.dart';

part 'database.g.dart';

// Define the Patients table
@UseRowClass(Patient)
class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get age => integer()();
  TextColumn get sex => text().withLength(min: 1, max: 20)();

  // Medical Information
  TextColumn get medicalHistory => text().named('medical_history')();
  TextColumn get currentMedications => text().named('current_medications')();
  TextColumn get allergies => text()();
  TextColumn get habits => text()();
  BoolColumn get isPregnant => boolean().named('is_pregnant')();

  // Clinical Notes (handwritten notes as JSON)
  TextColumn get clinicalNotes => text().named('clinical_notes')();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

@DriftDatabase(tables: [Patients])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      // For development: recreate all tables on schema change
      // This will delete existing data but ensures clean migration
      await migrator.deleteTable(patients.actualTableName);
      await migrator.createTable(patients);
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dental_chart_db');
  }

  // ================= Patient CRUD Operations =================

  // Get all patients
  Future<List<Patient>> getAllPatients() async {
    return await select(patients).get();
  }

  // Get a single patient by ID
  Future<Patient?> getPatient(int id) async {
    return await (select(patients)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  // Insert a new patient
  Future<int> insertPatient(PatientsCompanion patient) async {
    return await into(patients).insert(patient);
  }

  // Update an existing patient
  Future<bool> updatePatient(Patient patient) async {
    final companion = patientToCompanion(patient);
    return await update(patients).replace(companion);
  }

  // Delete a patient
  Future<int> deletePatient(int id) async {
    return await (delete(patients)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Search patients by name
  Future<List<Patient>> searchPatients(String query) async {
    return await (select(patients)
          ..where((tbl) => tbl.name.like('%$query%')))
        .get();
  }

  // Helper method to convert from Patient to PatientsCompanion
  PatientsCompanion patientToCompanion(Patient patient) {
    return PatientsCompanion(
      id: patient.id != null ? Value(patient.id!) : const Value.absent(),
      name: Value(patient.name),
      age: Value(patient.age),
      sex: Value(patient.sex),
      medicalHistory: Value(patient.medicalHistory),
      currentMedications: Value(patient.currentMedications),
      allergies: Value(patient.allergies),
      habits: Value(patient.habits),
      isPregnant: Value(patient.isPregnant),
      clinicalNotes: Value(patient.clinicalNotes),
      createdAt: Value(patient.createdAt),
    );
  }
}
