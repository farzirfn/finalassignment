// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:student_activity_apps/Screen/activity_man_screen.dart';
import 'package:student_activity_apps/Screen/admin_dashboard.dart';
import 'package:student_activity_apps/Screen/login_screen.dart';
import 'package:student_activity_apps/Screen/regis_man_screen.dart';
import 'package:student_activity_apps/Screen/student_act_screen.dart';
import 'package:student_activity_apps/Screen/student_dashboard.dart';
import 'package:student_activity_apps/Screen/student_regis_screen.dart';
import 'package:student_activity_apps/Screen/profile_screen.dart';
import 'package:student_activity_apps/models/user_model.dart';
import 'package:student_activity_apps/service/api_path.dart';

enum DrawerSection {
  dashboard,
  activities,
  studentRegistrations,
  registrations,
  profile,
}

class Drawers extends StatelessWidget {
  final Usermodel user;
  final DrawerSection currentSection;

  const Drawers({super.key, required this.user, required this.currentSection});

  void _navigate(BuildContext context, DrawerSection section, Widget page) {
    Navigator.pop(context);

    if (currentSection == section) return;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = (user.role ?? "").toLowerCase() == "admin";

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF143A7B)),

            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child: (user.profileImage?.isNotEmpty ?? false)
                    ? Image.network(
                        '${ApiPath.endpoint("")}uploads/profiles/${user.profileImage}?v=${user.profileImage.hashCode}',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          (user.name?.isNotEmpty ?? false)
                              ? user.name![0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF143A7B),
                          ),
                        ),
                      )
                    : Text(
                        (user.name?.isNotEmpty ?? false)
                            ? user.name![0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF143A7B),
                        ),
                      ),
              ),
            ),

            accountName: Text(user.name ?? "User"),

            accountEmail: Text(user.email ?? ""),
          ),

          //==========================
          // Dashboard
          //==========================
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            selected: currentSection == DrawerSection.dashboard,
            onTap: () {
              if (isAdmin) {
                _navigate(
                  context,
                  DrawerSection.dashboard,
                  AdminDashboard(user: user),
                );
              } else {
                _navigate(
                  context,
                  DrawerSection.dashboard,
                  StudentDashboard(user: user),
                );
              }
            },
          ),

          //==========================
          // ADMIN MENU
          //==========================
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Activity Management"),
              selected: currentSection == DrawerSection.activities,
              onTap: () {
                _navigate(
                  context,
                  DrawerSection.activities,
                  ActivityManagementScreen(user: user),
                );
              },
            ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text("Student Registration Management"),
              selected: currentSection == DrawerSection.studentRegistrations,
              onTap: () {
                _navigate(
                  context,
                  DrawerSection.studentRegistrations,
                  RegisterManagementScreen(user: user),
                );
              },
            ),

          //==========================
          // STUDENT MENU
          //==========================
          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text("Activities"),
              selected: currentSection == DrawerSection.activities,
              onTap: () {
                _navigate(
                  context,
                  DrawerSection.activities,
                  StudentActivityScreen(user: user),
                );
              },
            ),

          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("My Registrations"),
              selected: currentSection == DrawerSection.registrations,
              onTap: () {
                _navigate(
                  context,
                  DrawerSection.registrations,
                  StudentRegisScreen(user: user),
                );
              },
            ),

          //==========================
          // PROFILE
          //==========================
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("My Profile"),
            selected: currentSection == DrawerSection.profile,
            onTap: () {
              _navigate(
                context,
                DrawerSection.profile,
                ProfileScreen(user: user),
              );
            },
          ),

          const Spacer(),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),

            title: const Text("Logout", style: TextStyle(color: Colors.red)),

            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
