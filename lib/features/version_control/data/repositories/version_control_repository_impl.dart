import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_version.dart';
import '../../domain/repositories/i_version_control_repository.dart';
import '../datasources/version_control_remote_data_source.dart';

class VersionControlRepositoryImpl implements IVersionControlRepository {
  final VersionControlRemoteDataSource _dataSource;

  VersionControlRepositoryImpl(this._dataSource);

  @override
  Future<AppVersion> fetchLatestVersion() async {
    final dto = await _dataSource.fetchLatestVersion();
    return dto.toEntity();
  }
}

final versionControlRepositoryProvider =
    Provider<IVersionControlRepository>((ref) {
      final dataSource = ref.watch(versionControlRemoteDataSourceProvider);
      return VersionControlRepositoryImpl(dataSource);
    });
