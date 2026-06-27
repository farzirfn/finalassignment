import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:student_activity_apps/models/activity_model.dart';
import 'package:student_activity_apps/models/user_model.dart';
import 'package:student_activity_apps/service/api_path.dart';
import 'package:student_activity_apps/widgets/drawer.dart';

class StudentRegisScreen extends StatefulWidget {
  final Usermodel user;

  const StudentRegisScreen({super.key, required this.user});

  @override
  State<StudentRegisScreen> createState() => _StudentRegisScreenState();
}

class _StudentRegisScreenState extends State<StudentRegisScreen> {
  List<Activitymodel> joinedActivitiesData = [];
  String status = "Loading...";
  late double screenWidth;
  DateFormat formatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    loadJoinedActivities();
  }

  Future<void> loadJoinedActivities() async {
    setState(() {
      status = "Loading...";
      joinedActivitiesData.clear();
    });

    try {
      // 1. Get joined activity IDs
      final joinedResponse = await http.get(
        Uri.parse("${ApiPath.endpoint("api/get_joined.php")}?user_id=${widget.user.id}"),
      );
      final joinedData = jsonDecode(joinedResponse.body);
      
      if (joinedData["status"] != "success") {
        setState(() => status = joinedData["message"] ?? "Failed to load registrations");
        return;
      }

      Set<int> joinedIds = {};
      for (var item in joinedData["data"]) {
        joinedIds.add(int.parse(item["activity_id"].toString()));
      }

      if (joinedIds.isEmpty) {
        setState(() => status = "You have not joined any activities yet.");
        return;
      }

      // 2. Get all activities and filter
      final activityResponse = await http.get(
        Uri.parse(ApiPath.endpoint("api/get_activity.php")),
      );
      final activityData = jsonDecode(activityResponse.body);

      if (activityData['status'] == 'success') {
        for (var item in activityData['data']) {
          final act = Activitymodel.fromJson(item);
          if (joinedIds.contains(act.id)) {
            joinedActivitiesData.add(act);
          }
        }

        setState(() {
          status = joinedActivitiesData.isEmpty ? "You have not joined any activities yet." : "";
        });
      } else {
        setState(() => status = activityData['message'] ?? "Failed to load activities");
      }
    } catch (e) {
      setState(() => status = "Error loading data: $e");
    }
  }

  void showCancelDialog(Activitymodel activity) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Registration"),
        content: Text("Are you sure you want to cancel your registration for '${activity.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              cancelActivity(activity);
            },
            child: const Text("Cancel Registration", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> cancelActivity(Activitymodel activity) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPath.endpoint("api/cancel_activity.php")),
        body: {
          "user_id": widget.user.id.toString(),
          "activity_id": activity.id.toString(),
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
        loadJoinedActivities();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to cancel")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) screenWidth = 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Registrations"),
        backgroundColor: const Color(0xff143A7B),
        foregroundColor: Colors.white,
      ),
      drawer: Drawers(
        user: widget.user,
        currentSection: DrawerSection.registrations,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          loadJoinedActivities();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: joinedActivitiesData.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: joinedActivitiesData.length,
                itemBuilder: (context, index) {
                  final activity = joinedActivitiesData[index];
                  return Card(
                    color: const Color.fromRGBO(230, 234, 239, 1),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: screenWidth * 0.28,
                              height: screenWidth * 0.28,
                              color: Colors.grey[200],
                              child: Image.network(
                                "${ApiPath.endpoint("")}uploads/activities/${activity.image}",
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // TEXT AREA
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title ?? "No Title",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  activity.description ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => showCancelDialog(activity),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
