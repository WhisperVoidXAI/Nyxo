import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../services/database_service.dart';

class AppLockProvider extends ChangeNotifier {
  final _db = DatabaseService();

  bool _enabled = false;
  String _pin = '';

  bool get isEnabled => _enabled;
  bool get hasPin => _pin.isNotEmpty;

  Future<void> load() async {
    _enabled = _db.getSetting<bool>(AppConstants.appLockEnabledKey, defaultValue: false) ?? false;
    _pin = _db.getSetting<String>(AppConstants.appLockPinKey, defaultValue: '') ?? '';
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    _pin = pin;
    await _db.saveSetting(AppConstants.appLockPinKey, pin);
    if (!_enabled) {
      _enabled = true;
      await _db.saveSetting(AppConstants.appLockEnabledKey, true);
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _db.saveSetting(AppConstants.appLockEnabledKey, enabled);
    notifyListeners();
  }

  bool verify(String pin) => _pin.isNotEmpty && _pin == pin;

  Future<void> disableAndClear() async {
    _enabled = false;
    _pin = '';
    await _db.saveSetting(AppConstants.appLockEnabledKey, false);
    await _db.saveSetting(AppConstants.appLockPinKey, '');
    notifyListeners();
  }
}
