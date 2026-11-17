
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rebsspace/core/app_colors.dart';
import 'package:rebsspace/core/database/app_database.dart';
import 'package:rebsspace/core/network/api_client.dart';
import 'package:rebsspace/core/services/location_services.dart';
import 'package:rebsspace/features/attendance/data/datasource/attendance_remote_datasource.dart';
import 'package:rebsspace/features/attendance/presentation/controllers/attendance_controllers.dart';
import 'package:rebsspace/features/attendance/presentation/screen_attendance.dart';
import 'package:rebsspace/features/dashboard/presentation/controllers/dashboard_controllor.dart';
import 'package:rebsspace/features/dashboard/presentation/dashboard.dart';
import 'package:rebsspace/features/leave/data/datasources/leave_local_data_source.dart';
import 'package:rebsspace/features/leave/data/datasources/leave_remote_data_source.dart';
import 'package:rebsspace/features/leave/presentation/controllers/leave_controller.dart';
import 'package:rebsspace/features/leave/presentation/leave_screen.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
await AppDatabase.instance.clearDemoData();

  final apiClient = ApiClient();
  final database = AppDatabase.instance;

  // ATTENDANCE CONTROLLER
  Get.put<AttendanceController>(
    AttendanceController(
      remoteDataSource: AttendanceRemoteDataSource(apiClient),
      locationService: LocationService(),
      database: database,
    ),
    permanent: true,
  );

  // DASHBOARD CONTROLLER
  Get.put<DashboardController>(
    DashboardController(
      apiClient: apiClient,
    ),
    permanent: true,
  );

  // LEAVE CONTROLLER
  Get.put<LeaveController>(
    LeaveController(
      remoteDataSource: LeaveRemoteDataSource(
        apiClient: apiClient,
      ),
      localDataSource: LeaveLocalDataSource(
        database: database,
      ),
    ),
    permanent: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REBS HRMS',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    DashboardScreen(),
    AttendanceScreen(),
    LeaveScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.secondary,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Leave',
          ),
        ],
      ),
    );
  }
}
