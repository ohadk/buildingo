import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'models.dart';
import 'realtime.dart';

/// App-level session state layered on top of Firebase Auth: after OTP
/// sign-in it exchanges the ID token with the backend (which creates or
/// fetches the Supabase `users` row and consumes pending invitations),
/// then keeps the profile + building context in memory.
class SessionController extends ChangeNotifier {
  AppUser? user;
  Building? building;
  Apartment? apartment;
  JoinRequest? joinRequest;
  bool loading = false;
  String? error;

  bool get signedIn => FirebaseAuth.instance.currentUser != null;

  /// Token exchange after OTP verification (or on app start when a
  /// Firebase user is already cached on the device).
  Future<void> bootstrap({String? inviteCode}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
      await api.post('/api/auth/session', {
        'idToken': idToken,
        if (inviteCode != null && inviteCode.isNotEmpty)
          'inviteCode': inviteCode,
      });
      await refreshMe();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMe() async {
    final data = await api.get('/api/auth/me');
    user = AppUser.fromJson(data['user']);
    building = data['building'] != null
        ? Building.fromJson(data['building'])
        : null;
    apartment = data['apartment'] != null
        ? Apartment.fromJson(data['apartment'])
        : null;
    joinRequest = data['joinRequest'] != null
        ? JoinRequest.fromJson(data['joinRequest'])
        : null;
    realtime.setBuilding(building?.id);
    notifyListeners();
  }

  /// Vaad self-service: create a building and become its committee.
  /// Returns the WhatsApp-shareable join link.
  Future<String> createBuilding(Map<String, dynamic> body) async {
    final res = await api.post('/api/buildings/self-serve', body);
    await refreshMe();
    return res['joinLink'] as String;
  }

  /// Join by code — either a personal invite code or a building
  /// join link code shared by the Vaad.
  Future<void> joinWithCode(
    String code, {
    int? apartmentNumber,
    String? fullName,
  }) async {
    await api.post('/api/join', {
      'code': code,
      'apartmentNumber': ?apartmentNumber,
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
    });
    await refreshMe();
  }

  /// Tenant asks to join a building found by address; Vaad approves.
  Future<void> requestJoin({
    required String buildingId,
    required int apartmentNumber,
    required String fullName,
  }) async {
    await api.post('/api/join-requests', {
      'buildingId': buildingId,
      'apartmentNumber': apartmentNumber,
      'fullName': fullName,
    });
    await refreshMe();
  }

  Future<void> completeOnboarding({
    required String fullName,
    required int numOccupants,
  }) async {
    await api.post('/api/onboarding', {
      'fullName': fullName,
      'numOccupants': numOccupants,
    });
    await refreshMe();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    realtime.setBuilding(null);
    user = null;
    building = null;
    apartment = null;
    joinRequest = null;
    notifyListeners();
  }
}
