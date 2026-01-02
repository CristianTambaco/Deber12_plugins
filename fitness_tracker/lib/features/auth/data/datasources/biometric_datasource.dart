import 'package:local_auth/local_auth.dart';
import '../../domain/entities/auth_result.dart';

abstract class BiometricDataSource {
  Future<bool> canAuthenticate();
  Future<AuthResult> authenticate();
}

class BiometricDataSourceImpl implements BiometricDataSource {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported() &&
             await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate() async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Usa tu huella para autenticarte',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: false,
        ),
      );
      return AuthResult(
        success: didAuthenticate,
        message: didAuthenticate ? 'Autenticación exitosa' : 'Cancelado',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: e.toString(),
      );
    }
  }
}