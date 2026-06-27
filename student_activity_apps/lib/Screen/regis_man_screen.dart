import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:student_activity_apps/models/user_model.dart';
import 'package:student_activity_apps/service/api_path.dart';
import 'package:student_activity_apps/widgets/drawer.dart';

class RegisterManagementScreen extends StatefulWidget {
  final Usermodel user;

  const RegisterManagementScreen({super.key, required this.user});

  @override
  State<RegisterManagementScreen> createState() =>
      _RegisterManagementScreenState();
}

class _RegisterManagementScreenState extends State<RegisterManagementScreen> {
  List registrations = [];
  List filteredRegistrations = [];
  bool isLoading = true;
  String statusMessage = "";
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadRegistrations();
  }

  Future<void> loadRegistrations() async {
    setState(() {
      isLoading = true;
      statusMessage = "Loading registrations...";
    });

    try {
      final response = await http.get(
        Uri.parse(ApiPath.endpoint("api/get_all_registrations.php")),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          setState(() {
            registrations = data["data"];
            filteredRegistrations = List.from(registrations);
            isLoading = false;
            if (registrations.isEmpty) {
              statusMessage = "No registrations found.";
            }
          });
        } else {
          setState(() {
            isLoading = false;
            statusMessage = data["message"] ?? "Failed to load registrations.";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          statusMessage =
              "Failed to load registrations (HTTP ${response.statusCode}).";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = "Error loading data: $e";
      });
    }
  }

  void filterRegistrations(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredRegistrations = List.from(registrations);
      } else {
        filteredRegistrations = registrations.where((reg) {
          final studentName = (reg["student_name"] ?? "").toLowerCase();
          final activityTitle = (reg["activity_title"] ?? "").toLowerCase();
          final q = query.toLowerCase();
          return studentName.contains(q) || activityTitle.contains(q);
        }).toList();
      }
    });
  }

  void showCancelDialog(Map reg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Registration"),
        content: Text(
          "Are you sure you want to cancel the registration for student '${reg["student_name"]}' from activity '${reg["activity_title"]}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              cancelRegistration(reg);
            },
            child: const Text(
              "Cancel Registration",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> cancelRegistration(Map reg) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPath.endpoint("api/cancel_activity.php")),
        body: {
          "user_id": reg["user_id"].toString(),
          "activity_id": reg["activity_id"].toString(),
          "action": "admin_cancel",
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Registration cancelled successfully.",
            ),
          ),
        );
        loadRegistrations(); // Refresh list after cancellation
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Failed to cancel registration."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration Management"),
        backgroundColor: const Color(0xff143A7B),
        foregroundColor: Colors.white,
      ),
      drawer: Drawers(
        user: widget.user,
        currentSection: DrawerSection.studentRegistrations,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xff143A7B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: searchController,
              onChanged: filterRegistrations,
              decoration: InputDecoration(
                hintText: "Search by student name or activity...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          filterRegistrations("");
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? Center(
                    child: Text(
                      statusMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : filteredRegistrations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          searchController.text.isNotEmpty
                              ? "No matches found."
                              : statusMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadRegistrations,
                    child: Builder(
                      builder: (context) {
                        // Group registrations by activity
                        Map<String, List<dynamic>> groupedRegs = {};
                        for (var reg in filteredRegistrations) {
                          String activityId = reg["activity_id"].toString();
                          if (!groupedRegs.containsKey(activityId)) {
                            groupedRegs[activityId] = [];
                          }
                          groupedRegs[activityId]!.add(reg);
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: groupedRegs.length,
                          itemBuilder: (context, index) {
                            final activityId = groupedRegs.keys.elementAt(index);
                            final students = groupedRegs[activityId]!;
                            final activityTitle =
                                students[0]["activity_title"] ?? "Unknown Activity";
                            final activityDate = students[0]["activity_date"] ?? "";
                            final activityTime = students[0]["activity_time"] ?? "";

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ExpansionTile(
                                collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade50,
                                  child: const Icon(Icons.event, color: Colors.orange),
                                ),
                                title: Text(
                                  activityTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "$activityDate • $activityTime",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${students.length} Joined",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                children: [
                                  const Divider(height: 1),
                                  Container(
                                    color: Colors.grey.shade50,
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: students.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1, indent: 70),
                                      itemBuilder: (context, sIndex) {
                                        final reg = students[sIndex];
                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.blue.shade100,
                                            child: Text(
                                              (reg["student_name"] ?? "U")[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            reg["student_name"] ?? "Unknown Student",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "${reg["student_email"]}\n${reg["student_phone"]}",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              height: 1.3,
                                            ),
                                          ),
                                          isThreeLine: true,
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => showCancelDialog(reg),
                                            tooltip: "Cancel Registration",
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
