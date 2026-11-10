import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/project.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<Project>>> getProjects();
  Future<Either<Failure, Project?>> getProjectById(String id);
  Future<Either<Failure, Project>> createProject(Project project);
  Future<Either<Failure, Project>> updateProject(Project project);
  Future<Either<Failure, void>> deleteProject(String id);

  // project_entries join table
  Future<Either<Failure, void>> tagEntry(String projectId, String journalEntryId);
  Future<Either<Failure, void>> untagEntry(String projectId, String journalEntryId);
  Future<Either<Failure, List<String>>> getEntryIdsForProject(String projectId);
  Future<Either<Failure, List<String>>> getProjectIdsForEntry(String journalEntryId);
  Future<Either<Failure, List<Project>>> getProjectsForAsset(String assetId);
}
