import 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart'
    as db_factory;

Future<void> configureDatabaseFactory() =>
    db_factory.configureDatabaseFactory();
