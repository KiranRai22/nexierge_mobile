import '../entities/app_version.dart';

abstract class IVersionControlRepository {
  Future<AppVersion> fetchLatestVersion();
}
