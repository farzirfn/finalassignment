import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:student_activity_apps/models/user_model.dart';
import 'package:student_activity_apps/service/api_path.dart';
import 'package:student_activity_apps/widgets/drawer.dart';

class AdminDashboard extends StatefulWidget {
  final Usermodel user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalActivities = 0;
  int totalStudents = 0;
  int totalUpcoming = 0;
  int totalRegistrations = 0;

  List latestActivities = [];
  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Widget dashboardCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget actionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xff143A7B),
        foregroundColor: Colors.white,
      ),

      drawer: Drawers(
        user: widget.user,
        currentSection: DrawerSection.dashboard,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await loadDashboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${widget.user.name}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Manage all student activities here.",
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  dashboardCard(
                    "Activities",
                    totalActivities.toString(),
                    Icons.event,
                    Colors.blue,
                  ),

                  const SizedBox(width: 15),

                  dashboardCard(
                    "Students",
                    totalStudents.toString(),
                    Icons.people,
                    Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  dashboardCard(
                    "Upcoming",
                    totalUpcoming.toString(),
                    Icons.calendar_month,
                    Colors.orange,
                  ),

                  const SizedBox(width: 15),

                  dashboardCard(
                    "Registrations",
                    totalRegistrations.toString(),
                    Icons.assignment_turned_in,
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              const Text(
                "Recent Activities",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              latestActivities.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No activities available"),
                      ),
                    )
                  : Column(
                      children: latestActivities.map((activity) {
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.event),
                            ),
                            title: Text(activity["title"]),
                            subtitle: Text(
                              "${activity["activity_date"]} • ${activity["activity_time"]}",
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loadDashboard() async {
    final response = await http.get(
      Uri.parse(ApiPath.endpoint("api/admin_dashboard.php")),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        if (!mounted) return;

        setState(() {
          totalActivities = data["activities"];
          totalStudents = data["students"];
          totalUpcoming = data["upcoming"];
          totalRegistrations = data["registrations"];
          latestActivities = data["latest"];
        });
      }
    }
  }
}
