enum BusinessType {
  ferreteria,
  muebleria,
  kiosco,
  indumentaria,
  taller,
  estudio,
}

extension BusinessTypeX on BusinessType {
  String get code => switch (this) {
    BusinessType.ferreteria => 'FERRETERIA',
    BusinessType.muebleria => 'MUEBLERIA',
    BusinessType.kiosco => 'KIOSCO_ALMACEN',
    BusinessType.indumentaria => 'INDUMENTARIA',
    BusinessType.taller => 'TALLER_MECANICO',
    BusinessType.estudio => 'SERVICIOS_ESTUDIO_JURIDICO',
  };

  String get label => switch (this) {
    BusinessType.ferreteria => 'Ferretería',
    BusinessType.muebleria => 'Mueblería',
    BusinessType.kiosco => 'Kiosco/Almacén',
    BusinessType.indumentaria => 'Indumentaria',
    BusinessType.taller => 'Taller mecánico',
    BusinessType.estudio => 'Servicios/Estudio jurídico',
  };
}
