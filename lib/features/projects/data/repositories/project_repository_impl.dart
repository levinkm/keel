import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/projects/data/datasources/project_local_datasource.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/projects/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDatasource _datasource;
  ProjectRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Project>>> getProjects() async {
    try {
      final rows = await _datasource.getProjects();
      return Right(rows.map(_rowToProject).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Project?>> getProjectById(String id) async {
    try {
      final row = await _datasource.getProjectById(id);
      return Right(row != null ? _rowToProject(row) : null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Project>> createProject(Project project) async {
    try {
      await _datasource.insertProject(_projectToRow(project));
      return Right(project);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Project>> updateProject(Project project) async {
    try {
      await _datasource.updateProject(_projectToRow(project));
      return Right(project);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProject(String id) async {
    try {
      await _datasource.deleteProject(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> tagEntry(
      String projectId, String journalEntryId) async {
    try {
      await _datasource.tagEntry(projectId, journalEntryId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> untagEntry(
      String projectId, String journalEntryId) async {
    try {
      await _datasource.untagEntry(projectId, journalEntryId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getEntryIdsForProject(
      String projectId) async {
    try {
      return Right(await _datasource.getEntryIdsForProject(projectId));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getProjectIdsForEntry(
      String journalEntryId) async {
    try {
      return Right(await _datasource.getProjectIdsForEntry(journalEntryId));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Project>>> getProjectsForAsset(String assetId) async {
    try {
      final rows = await _datasource.getProjectsForAsset(assetId);
      return Right(rows.map(_rowToProject).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Map<String, dynamic> _projectToRow(Project p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'type': p.type.name,
        'status': p.status.name,
        'budget_minor': p.budgetMinor,
        'revenue_target_minor': p.revenueTargetMinor,
        'currency': p.currency,
        'funding_account_id': p.fundingAccountId,
        'asset_account_id': p.assetAccountId,
        'asset_id': p.assetId,
        'start_date': p.startDate.toIso8601String(),
        'end_date': p.endDate?.toIso8601String(),
        'tags': p.tags.join(','),
        'created_at': p.createdAt.toIso8601String(),
      };

  Project _rowToProject(Map<String, dynamic> r) => Project(
        id: r['id'] as String,
        name: r['name'] as String,
        description: r['description'] as String?,
        type: ProjectType.values.byName(r['type'] as String),
        status: ProjectStatus.values.byName(r['status'] as String),
        budgetMinor: r['budget_minor'] as int,
        revenueTargetMinor: r['revenue_target_minor'] as int?,
        currency: r['currency'] as String,
        fundingAccountId: r['funding_account_id'] as String?,
        assetAccountId: r['asset_account_id'] as String?,
        assetId: r['asset_id'] as String?,
        startDate: DateTime.parse(r['start_date'] as String),
        endDate: r['end_date'] != null
            ? DateTime.parse(r['end_date'] as String)
            : null,
        tags: (r['tags'] as String? ?? '')
            .split(',')
            .where((t) => t.isNotEmpty)
            .toList(),
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}
