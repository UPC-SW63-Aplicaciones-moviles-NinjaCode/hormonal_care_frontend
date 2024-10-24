import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trabajo_moviles_ninjacode/scr/core/utils/usecases/jwt_storage.dart';
import 'package:trabajo_moviles_ninjacode/scr/features/profile/data/data_sources/remote/patient_service.dart';
import 'package:trabajo_moviles_ninjacode/scr/features/profile/data/data_sources/remote/profile_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MedicalAppointmentApi {
  static const String _baseUrl = 'http://localhost:8080/api/v1';

  MedicalAppointmentApi() {
    tz.initializeTimeZones();
  }

  Future<String?> _getToken() async {
    return await JwtStorage.getToken();
  }

  Future<String?> _getUserId() async {
    return await JwtStorage.getUserId();
  }

  Future<ProfileService?> getProfile(int profileId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/profile/profile/$profileId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return ProfileService.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<PatientService?> getPatient(int patientId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/medical-record/patient/$patientId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return PatientService.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentsForToday(int doctorId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/medicalAppointment?doctorId=$doctorId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<Map<String, dynamic>> appointments = List<Map<String, dynamic>>.from(json.decode(response.body));
      final limaTimeZone = tz.getLocation('America/Lima');
      final today = tz.TZDateTime.now(limaTimeZone);
      final todayAppointments = appointments.where((appointment) {
        final eventDate = tz.TZDateTime.from(DateTime.parse(appointment['eventDate']), limaTimeZone);
        return eventDate.year == today.year && eventDate.month == today.month && eventDate.day == today.day;
      }).toList();
      return todayAppointments;
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  Future<bool> createMedicalAppointment(Map<String, dynamic> appointmentData) async {
    final token = await _getToken();
    final userId = await _getUserId();
    appointmentData['userId'] = userId; // Add userId to the appointment data

    final response = await http.post(
      Uri.parse('$_baseUrl/medicalAppointment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(appointmentData),
    );

    return response.statusCode == 201;
  }
}