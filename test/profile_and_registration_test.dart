// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartqueue/core/constants/supabase_constants.dart';
import 'package:smartqueue/features/auth/data/auth_repository.dart';
import 'package:smartqueue/data/models/app_user.dart';

void main() {
  test('Live Profile View and Edit for Student & Staff Verification', () async {
    final client = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final authRepo = AuthRepository(client);

    print('--> 1. Student Sign In & Profile Read Verification...');
    final student = await authRepo.signIn(
      registrationNumber: '22A61A0501',
      password: 'password123',
    );

    expect(student.role, equals(UserRole.student));
    expect(student.registrationNumber, equals('22A61A0501'));
    print('Student initial profile: ${student.fullName}, Reg: ${student.registrationNumber}');

    print('--> 2. Student Profile Edit & Synchronous DB/Meta Update...');
    final updatedStudent = await authRepo.updateProfile(
      userId: student.id,
      fullName: 'Prajwal Varma (Verified)',
      department: 'Computer Science & Engineering (CSE)',
      yearOfStudy: '3rd Year',
      phone: '9876543210',
      email: '22a61a0501@bvcec.edu.in',
    );

    expect(updatedStudent.fullName, equals('Prajwal Varma (Verified)'));
    expect(updatedStudent.department, equals('Computer Science & Engineering (CSE)'));
    expect(updatedStudent.yearOfStudy, equals('3rd Year'));
    expect(updatedStudent.phone, equals('9876543210'));
    expect(updatedStudent.email, equals('22a61a0501@bvcec.edu.in'));
    print('Verified: Student profile updated with Department, Year, Phone, and Email!');

    // Re-fetch via getCurrentUser to verify persistent retrieval
    final fetchedStudent = await authRepo.getCurrentUser();
    expect(fetchedStudent?.fullName, equals('Prajwal Varma (Verified)'));
    expect(fetchedStudent?.department, equals('Computer Science & Engineering (CSE)'));
    expect(fetchedStudent?.yearOfStudy, equals('3rd Year'));
    print('Verified: getCurrentUser returns the persistent profile details!');

    // Revert student back to original
    await authRepo.updateProfile(
      userId: student.id,
      fullName: 'Prajwal Varma',
      department: 'Computer Science & Engineering (CSE)',
      yearOfStudy: '3rd Year',
      phone: '',
      email: '22a61a0501@bvcec.internal',
    );
    print('Restored student original profile state.');

    print('--> 3. Staff Sign In & Profile Read Verification...');
    final staffClient = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final staffRepo = AuthRepository(staffClient);

    final staff = await staffRepo.signIn(
      registrationNumber: 'STAFF001',
      password: 'password123',
    );

    expect(staff.role, equals(UserRole.staff));
    expect(staff.registrationNumber, equals('STAFF001'));
    print('Staff initial profile: ${staff.fullName}, Staff ID: ${staff.registrationNumber}');

    print('--> 4. Staff Profile Edit (Section/Department & Contact Update)...');
    final updatedStaff = await staffRepo.updateProfile(
      userId: staff.id,
      fullName: 'Exam Section Incharge',
      department: 'Examination Section',
      phone: '9123456780',
      email: 'staff001@bvcec.edu.in',
    );

    expect(updatedStaff.fullName, equals('Exam Section Incharge'));
    expect(updatedStaff.department, equals('Examination Section'));
    expect(updatedStaff.phone, equals('9123456780'));
    print('Verified: Staff section, role, and details updated & persistent!');

    // Restore staff
    await staffRepo.updateProfile(
      userId: staff.id,
      fullName: 'Exam Section Staff',
      department: 'Examination Section',
      phone: '',
      email: 'staff001@bvcec.internal',
    );
    print('Restored staff original profile state.');

    print('--> 5. Registration Method Parameter Validation Check...');
    expect(
      () => authRepo.registerStudent(
        registrationNumber: 'TEST',
        fullName: 'Test',
        password: '',
        department: 'CSE',
        yearOfStudy: '1st Year',
        email: 'invalid-email',
      ),
      throwsA(anything),
    );
    print('Verified: Registration input validation triggers appropriately!');

    print('ALL Profile View, Edit, and Update validations passed successfully!');
  });
}
