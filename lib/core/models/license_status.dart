enum LicenseStatus { trial, active, expired, tamper }

extension LicenseStatusX on LicenseStatus {
  String get dbValue => switch (this) {
    LicenseStatus.trial => 'TRIAL',
    LicenseStatus.active => 'ACTIVE',
    LicenseStatus.expired => 'EXPIRED',
    LicenseStatus.tamper => 'TAMPER',
  };

  static LicenseStatus fromDb(String value) {
    return switch (value) {
      'ACTIVE' => LicenseStatus.active,
      'EXPIRED' => LicenseStatus.expired,
      'TAMPER' => LicenseStatus.tamper,
      _ => LicenseStatus.trial,
    };
  }
}
