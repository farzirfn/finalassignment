import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:student_activity_apps/Screen/login_screen.dart';
import 'package:student_activity_apps/models/activity_model.dart';
import 'package:student_activity_apps/models/user_model.dart';
import 'package:student_activity_apps/service/api_path.dart';
import 'package:student_activity_apps/widgets/drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentActivityScreen extends StatefulWidget {
  final Usermodel user;

  const StudentActivityScreen({super.key, required this.user});

  @override
  State<StudentActivityScreen> createState() => _StudentActivityScreenState();
}

class _StudentActivityScreenState extends State<StudentActivityScreen> {
  List<Activitymodel> activities = [];
  String status = "Loading...";
  late double screenWidth, screenHeight;
  DateFormat formatter = DateFormat('dd/MM/yyyy');
  Set<int> joinedActivities = {};
  @override
  void initState() {
    super.initState();
    loadActivities('');
    loadJoinedActivities();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    if (screenWidth > 600) {
      screenWidth = 600;
    } else {
      screenWidth = screenWidth;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("List of Activities"),
        backgroundColor: const Color(0xff143A7B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearchDialog();
            },
          ),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            icon: Icon(Icons.login),
          ),
        ],
      ),

      drawer: Drawers(
        user: widget.user,
        currentSection: DrawerSection.activities,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          loadActivities('');
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: activities.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmptyState(),
                  ),
                ],
              )
            : _buildActivityList(),
      ),
    );
  }

  void showSearchDialog() {
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Search',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: searchController,
              autofocus: true, // auto-focus when dialog opens
              textInputAction:
                  TextInputAction.search, // keyboard shows "Search"
              onSubmitted: (value) {
                String search = value.trim();
                loadActivities(search);
                Navigator.of(context).pop();
              },
              decoration: InputDecoration(
                hintText: 'Enter search query',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () => searchController.clear(),
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Search'),
              onPressed: () {
                String search = searchController.text.trim();
                if (search.isEmpty) {
                  loadActivities('');
                } else {
                  loadActivities(search);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> loadActivities(String searchQuery) async {
    activities.clear();

    setState(() {
      status = "Loading...";
    });

    final uri = Uri.parse(
      '${ApiPath.endpoint("api/get_activity.php")}?search=$searchQuery',
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        activities.clear();

        for (var item in jsonResponse['data']) {
          activities.add(Activitymodel.fromJson(item));
        }

        setState(() {
          status = "";
        });
      } else {
        setState(() {
          activities.clear();
          status = jsonResponse['message'];
        });
      }
    } else {
      setState(() {
        status = "Failed to load activities";
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.find_in_page_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (BuildContext context, int index) {
        return Card(
          color: const Color.fromRGBO(230, 234, 239, 1),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showDetailsDialog(index),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: screenWidth * 0.28, // more responsive
                      height: screenWidth * 0.28, // balanced aspect ratio
                      color: Colors.grey[200],
                      child: Image.network(
                        // path to retrieve image from server
                        "${ApiPath.endpoint("")}uploads/activities/${activities[index].image}",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // TEXT AREA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE
                        Text(
                          activities[index].title.toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // DESCRIPTION
                        Text(
                          activities[index].description.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            // JOIN BUTTON
                            joinedActivities.contains(activities[index].id)
                                ? ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      disabledBackgroundColor: Colors.green,
                                    ),
                                    child: const Text(
                                      "Joined",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      showJoinDialog(activities[index]);
                                    },
                                    child: const Text("Join"),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showDetailsDialog(int index) {
    final activity = activities[index];
    final formattedDateCreated = formatter.format(
      DateFormat("yyyy-MM-dd HH:mm:ss").parse(activity.createdAt!),
    );
    final formattedDateEvent = formatter.format(
      DateFormat("dd/MM/yyyy").parse(activity.activityDate.toString()),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DRAG HANDLE
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 5 / 3,
                        child: Image.network(
                          "${ApiPath.endpoint("")}uploads/activities/${activities[index].image}",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TITLE
                    Text(
                      activity.title.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const SizedBox(height: 14),

                    // DESCRIPTION
                    Text(
                      activity.description.toString(),
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 20),

                    const Divider(),

                    // INFO SECTION
                    _infoRow("Activity Name : ", activity.title),
                    _infoRow("Venue : ", activity.venue),
                    _infoRow("Organizer : ", activity.organizerName),
                    _infoRow("Date : ", formattedDateEvent),
                    _infoRow("Time : ", activity.activityTime),
                    _infoRow(
                      "Provide Merit : ",
                      activity.provideMerit.toString() == "1" ? "Yes" : "No",
                    ),
                    _infoRow("Posted On : ", formattedDateCreated),
                    const SizedBox(height: 20),

                    // CONTACT ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionIcon(
                          Icons.call,
                          () => launchUrl(
                            Uri.parse('tel:${activity.organizerPhone}'),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        _actionIcon(
                          Icons.message,
                          () => launchUrl(
                            Uri.parse('sms:${activity.organizerPhone}'),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        _actionIcon(
                          Icons.wechat,
                          () => launchUrl(
                            Uri.parse(
                              'https://wa.me/${activity.organizerPhone}?text=Hello%20${activity.title},%20I%20am%20interested%20in%20your%20activity.',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value ?? "-")),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue),
      ),
    );
  }

  void showJoinDialog(Activitymodel activity) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Join Activity"),
        content: Text("Are you sure you want to join '${activity.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              joinActivity(activity);
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  Future<void> joinActivity(Activitymodel activity) async {
    final response = await http.post(
      Uri.parse(ApiPath.endpoint("api/join_activity.php")),
      body: {
        "user_id": widget.user.id.toString(),
        "activity_id": activity.id.toString(),
      },
    );

    final data = jsonDecode(response.body);

    if (data["status"] == "success") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data["message"])));

      loadActivities('');
      loadJoinedActivities();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data["message"])));
    }
  }

  Future<void> loadJoinedActivities() async {
    final response = await http.get(
      Uri.parse(
        "${ApiPath.endpoint("api/get_joined.php")}?user_id=${widget.user.id}",
      ),
    );

    final data = jsonDecode(response.body);

    joinedActivities.clear();

    if (data["status"] == "success") {
      for (var item in data["data"]) {
        joinedActivities.add(int.parse(item["activity_id"].toString()));
      }

      setState(() {});
    }
  }
}
