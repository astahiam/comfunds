import 'package:flutter_test/flutter_test.dart';
import 'package:comfunds_web/providers/project_provider.dart';
import 'package:comfunds_web/models/project.dart';

void main() {
  group('ProjectProvider Unit Tests', () {
    late ProjectProvider projectProvider;

    setUp(() {
      projectProvider = ProjectProvider();
    });

    test('initial state should be empty', () {
      expect(projectProvider.projects, isEmpty);
      expect(projectProvider.isLoading, false);
      expect(projectProvider.error, isNull);
    });

    test('fetchProjects should load projects successfully', () async {
      // Act
      await projectProvider.fetchProjects();

      // Assert
      expect(projectProvider.projects, isNotEmpty);
      expect(projectProvider.isLoading, false);
      expect(projectProvider.error, isNull);
    });

    test('createProject should add new project to list', () async {
      // Arrange
      final newProject = Project(
        id: 'test-project-1',
        title: 'Test Project',
        description: 'A test project for funding',
        targetAmount: 1000000,
        raisedAmount: 0,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await projectProvider.createProject(newProject);

      // Assert
      expect(projectProvider.projects, contains(newProject));
      expect(projectProvider.projects.length, 1);
    });

    test('updateProject should modify existing project', () async {
      // Arrange
      final project = Project(
        id: 'test-project-1',
        title: 'Original Title',
        description: 'Original description',
        targetAmount: 1000000,
        raisedAmount: 0,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await projectProvider.createProject(project);

      final updatedProject = project.copyWith(
        title: 'Updated Title',
        description: 'Updated description',
      );

      // Act
      await projectProvider.updateProject(updatedProject);

      // Assert
      final updatedProjectInList = projectProvider.projects.firstWhere(
        (p) => p.id == project.id,
      );
      expect(updatedProjectInList.title, 'Updated Title');
      expect(updatedProjectInList.description, 'Updated description');
    });

    test('deleteProject should remove project from list', () async {
      // Arrange
      final project = Project(
        id: 'test-project-1',
        title: 'Test Project',
        description: 'A test project',
        targetAmount: 1000000,
        raisedAmount: 0,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await projectProvider.createProject(project);
      expect(projectProvider.projects.length, 1);

      // Act
      await projectProvider.deleteProject(project.id);

      // Assert
      expect(projectProvider.projects, isEmpty);
    });

    test('getProjectById should return correct project', () async {
      // Arrange
      final project = Project(
        id: 'test-project-1',
        title: 'Test Project',
        description: 'A test project',
        targetAmount: 1000000,
        raisedAmount: 0,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await projectProvider.createProject(project);

      // Act
      final foundProject = projectProvider.getProjectById(project.id);

      // Assert
      expect(foundProject, isNotNull);
      expect(foundProject!.id, project.id);
      expect(foundProject.title, project.title);
    });

    test('getProjectById should return null for non-existent project', () {
      // Act
      final foundProject = projectProvider.getProjectById('non-existent-id');

      // Assert
      expect(foundProject, isNull);
    });

    test('getProjectsByCategory should filter projects correctly', () async {
      // Arrange
      final techProject = Project(
        id: 'tech-project',
        title: 'Tech Project',
        description: 'Technology project',
        targetAmount: 1000000,
        raisedAmount: 0,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final agricultureProject = Project(
        id: 'agri-project',
        title: 'Agriculture Project',
        description: 'Agriculture project',
        targetAmount: 500000,
        raisedAmount: 0,
        category: 'Agriculture',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await projectProvider.createProject(techProject);
      await projectProvider.createProject(agricultureProject);

      // Act
      final techProjects = projectProvider.getProjectsByCategory('Technology');
      final agriProjects = projectProvider.getProjectsByCategory('Agriculture');

      // Assert
      expect(techProjects.length, 1);
      expect(techProjects.first.title, 'Tech Project');
      expect(agriProjects.length, 1);
      expect(agriProjects.first.title, 'Agriculture Project');
    });

    test('getProjectsByStatus should filter projects correctly', () async {
      // Arrange
      final activeProject = Project(
        id: 'active-project',
        title: 'Active Project',
        description: 'Active project',
        targetAmount: 1000000,
        raisedAmount: 0,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final draftProject = Project(
        id: 'draft-project',
        title: 'Draft Project',
        description: 'Draft project',
        targetAmount: 500000,
        raisedAmount: 0,
        category: 'Agriculture',
        status: 'draft',
        cooperativeId: 'coop-1',
        businessId: 'business-2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await projectProvider.createProject(activeProject);
      await projectProvider.createProject(draftProject);

      // Act
      final activeProjects = projectProvider.getProjectsByStatus('active');
      final draftProjects = projectProvider.getProjectsByStatus('draft');

      // Assert
      expect(activeProjects.length, 1);
      expect(activeProjects.first.title, 'Active Project');
      expect(draftProjects.length, 1);
      expect(draftProjects.first.title, 'Draft Project');
    });

    test('calculateFundingProgress should return correct percentage', () {
      // Arrange
      final project = Project(
        id: 'test-project',
        title: 'Test Project',
        description: 'Test project',
        targetAmount: 1000000,
        raisedAmount: 500000,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final progress = projectProvider.calculateFundingProgress(project);

      // Assert
      expect(progress, 50.0);
    });

    test('calculateFundingProgress should return 0 for zero target amount', () {
      // Arrange
      final project = Project(
        id: 'test-project',
        title: 'Test Project',
        description: 'Test project',
        targetAmount: 0,
        raisedAmount: 500000,
        category: 'Technology',
        status: 'active',
        cooperativeId: 'coop-1',
        businessId: 'business-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final progress = projectProvider.calculateFundingProgress(project);

      // Assert
      expect(progress, 0.0);
    });
  });
}
