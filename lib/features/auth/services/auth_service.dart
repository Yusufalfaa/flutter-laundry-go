
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _userIdKey = 'user_id';
  static const String _fullNameKey = 'full_name';
  static const String _phoneNumberKey = 'phone_number';
  static const String _roleKey = 'role';

  // Check whether a phone number is already registered.
  Future<Map<String, dynamic>?> checkPhoneNumber(
    String phoneNumber,
  ) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('phone_number', phoneNumber.trim())
        .maybeSingle();

    return response;
  }

  // Register a new customer.
  Future<Map<String, dynamic>> registerCustomer({
    required String fullName,
    required String phoneNumber,
  }) async {
    final existingUser = await checkPhoneNumber(phoneNumber);

    if (existingUser != null) {
      throw Exception('Phone number is already registered.');
    }

    final response = await _supabase
        .from('profiles')
        .insert({
          'full_name': fullName.trim(),
          'phone_number': phoneNumber.trim(),
          'role': 'customer',
        })
        .select()
        .single();

    await saveSession(response);

    return response;
  }

  // Register a new laundry partner.
  Future<Map<String, dynamic>> registerPartner({
    required String fullName,
    required String phoneNumber,
    required String businessName,
    required String address,
  }) async {
    final existingUser = await checkPhoneNumber(phoneNumber);

    if (existingUser != null) {
      throw Exception('Phone number is already registered.');
    }

    final profile = await _supabase
        .from('profiles')
        .insert({
          'full_name': fullName.trim(),
          'phone_number': phoneNumber.trim(),
          'role': 'partner',
        })
        .select()
        .single();

    try {
      await _supabase.from('partners').insert({
        'profile_id': profile['id'],
        'business_name': businessName.trim(),
        'address': address.trim(),
      });

      await saveSession(profile);

      return profile;
    } catch (error) {
      // Remove the profile if partner registration fails.
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', profile['id']);

      rethrow;
    }
  }

  // Log in using a registered phone number.
  Future<Map<String, dynamic>> login(String phoneNumber) async {
    final profile = await checkPhoneNumber(phoneNumber);

    if (profile == null) {
      throw Exception('Phone number is not registered.');
    }

    await saveSession(profile);

    return profile;
  }

  // Save the current user session locally.
  Future<void> saveSession(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, profile['id']);
    await prefs.setString(_fullNameKey, profile['full_name']);
    await prefs.setString(_phoneNumberKey, profile['phone_number']);
    await prefs.setString(_roleKey, profile['role']);
  }

  // Get the current local session.
  Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString(_userIdKey);

    if (userId == null) {
      return null;
    }

    return {
      'id': userId,
      'full_name': prefs.getString(_fullNameKey) ?? '',
      'phone_number': prefs.getString(_phoneNumberKey) ?? '',
      'role': prefs.getString(_roleKey) ?? '',
    };
  }

  // Check whether a user is logged in.
  Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session != null;
  }

  // Log out the current user.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_roleKey);
  }
}
