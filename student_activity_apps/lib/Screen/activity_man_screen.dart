// ignore_for_file: file_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// test
import 'package:student_activity_apps/Screen/add_activity.dart';
import 'package:student_activity_apps/Screen/login_screen.dart';
import 'package:student_activity_apps/models/activity_model.dart';
import 'package:student_activity_apps/models/user_model.dart';
import 'package:student_activity_apps/service/api_path.dart';
import 'package:student_activity_apps/widgets/drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityManagementScreen extends StatefulWidget {
  final Usermodel user;

  const ActivityManagementScreen({super.key, required this.user});

  @override
  State<ActivityManagementScreen> createState() =>
      _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  List<Activitymodel> activities = [];
  List<Activitymodel> filteredActivities = [];
  final TextEditingController searchController = TextEditingController();
  int currentPage = 1;
  final int itemsPerPage = 5;
  Uint8List? imageBytes;
  XFile? imageFile;

  String status = "Loading...";
  late double screenWidth, screenHeight;
  DateFormat formatter = DateFormat('dd/MM/yyyy');

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final participantController = TextEditingController();
  final organizerController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedMerit;
  @override
  void initState() {
    super.initState();
    loadActivities('');
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
        title: const Text("Activity Management"),
        backgroundColor: const Color(0xff143A7B),
        foregroundColor: Colors.white,
        actions: [
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddActivityScreen(user: widget.user),
            ),
          );

          if (result == true) {
            loadActivities('');
          }
        },
      ),

      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xff143A7B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: searchController,
              onChanged: filterActivities,
              decoration: InputDecoration(
                hintText: "Search by title or description...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          filterActivities("");
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
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      loadActivities('');
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: filteredActivities.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: _buildEmptyState(),
                              ),
                            ],
                          )
                        : _buildActivityList(),
                  ),
                ),
                if (filteredActivities.isNotEmpty) _buildPaginationControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void filterActivities(String query) {
    setState(() {
      currentPage = 1;
      if (query.trim().isEmpty) {
        filteredActivities = List.from(activities);
      } else {
        filteredActivities = activities.where((act) {
          final title = (act.title ?? "").toLowerCase();
          final desc = (act.description ?? "").toLowerCase();
          final q = query.toLowerCase();
          return title.contains(q) || desc.contains(q);
        }).toList();
      }
    });
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
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredActivities.length) {
      endIndex = filteredActivities.length;
    }
    List<Activitymodel> paginatedList = filteredActivities.sublist(
      startIndex,
      endIndex,
    );

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: paginatedList.length,
      itemBuilder: (BuildContext context, int index) {
        final actualIndex = startIndex + index;
        return Card(
          color: const Color.fromRGBO(230, 234, 239, 1),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showDetailsDialog(actualIndex),
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
                        "${ApiPath.endpoint("")}uploads/activities/${paginatedList[index].image}",
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
                          paginatedList[index].title.toString(),
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
                          paginatedList[index].description.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showEditDialog(paginatedList[index]);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Update",
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                showDeleteActivityDialog(paginatedList[index]);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Delete",
                                style: const TextStyle(fontSize: 13),
                              ),
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

  Widget _buildPaginationControls() {
    int totalPages = (filteredActivities.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: currentPage > 1
                ? () {
                    setState(() {
                      currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text("Prev"),
          ),
          Text(
            "Page $currentPage of $totalPages",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: currentPage < totalPages
                ? () {
                    setState(() {
                      currentPage++;
                    });
                  }
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text("Next"),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ],
      ),
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

        filterActivities(searchController.text);

        setState(() {
          status = "";
        });
      } else {
        setState(() {
          activities.clear();
          filteredActivities.clear();
          status = jsonResponse['message'];
        });
      }
    } else {
      setState(() {
        status = "Failed to load activities";
      });
    }
  }

  void showDetailsDialog(int index) {
    final activity = filteredActivities[index];
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
                          "${ApiPath.endpoint("")}uploads/activities/${filteredActivities[index].image}",
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
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.blueGrey.withValues(alpha: 0.15),
        child: Icon(icon, color: Colors.blueGrey),
      ),
    );
  }

  void confirmUpdateDialog(Activitymodel updatedActivity) {
    if (updatedActivity.title!.isEmpty ||
        updatedActivity.venue!.isEmpty ||
        updatedActivity.activityTime!.isEmpty ||
        updatedActivity.description!.isEmpty ||
        updatedActivity.activityDate!.isEmpty ||
        updatedActivity.organizerName!.isEmpty ||
        updatedActivity.organizerPhone!.isEmpty ||
        updatedActivity.provideMerit == null ||
        updatedActivity.maxParticipants!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    final imgf = imageBytes == null ? 'NA' : base64Encode(imageBytes!);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final navigator = Navigator.of(dialogContext);
        final messenger = ScaffoldMessenger.of(context);

        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Are you sure you want to update this activity?'),
          actions: [
            TextButton(
              onPressed: () {
                navigator.pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.post(
                    Uri.parse(ApiPath.endpoint("api/update_activity.php")),
                    body: {
                      'id': updatedActivity.id.toString(),
                      'title': updatedActivity.title,
                      'venue': updatedActivity.venue,
                      'activityTime': updatedActivity.activityTime,
                      'description': updatedActivity.description,
                      'activityDate': updatedActivity.activityDate,
                      'organizerName': updatedActivity.organizerName,
                      'organizerPhone': updatedActivity.organizerPhone,
                      'provideMerit': updatedActivity.provideMerit.toString(),
                      'maxParticipants': updatedActivity.maxParticipants,
                      'image': imgf,
                    },
                  );

                  // Debug
                  print(response.statusCode);
                  print(response.body);

                  if (!mounted) return;

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);

                    if (data['status'] == 'success') {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Activity updated')),
                      );
                      loadActivities("");

                      if (!mounted) return;

                      navigator.pop();
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(data['message'] ?? 'Error')),
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Server Error (${response.statusCode})'),
                      ),
                    );
                  }
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void showEditDialog(Activitymodel activity) {
    imageFile = null;
    imageBytes = null;

    titleController.text = activity.title ?? "";
    descriptionController.text = activity.description ?? "";
    venueController.text = activity.venue ?? "";
    dateController.text = activity.activityDate ?? "";
    timeController.text = activity.activityTime ?? "";
    participantController.text = activity.maxParticipants ?? "";
    organizerController.text = activity.organizerName ?? "";
    phoneController.text = activity.organizerPhone ?? "";
    selectedMerit = activity.provideMerit == 1 ? "Yes" : "No";

    final imageUrl =
        "${ApiPath.endpoint("")}uploads/activities/${activity.image}";

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit ${activity.title}"),
              content: SizedBox(
                width: screenWidth,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Select Image Source"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text("Camera"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      openCamera(setDialogState);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text("Gallery"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      openGallery(setDialogState);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade200,
                          ),
                          child: imageBytes != null
                              ? Image.memory(imageBytes!, fit: BoxFit.cover)
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image, size: 80),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Title"),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: venueController,
                        decoration: const InputDecoration(labelText: "Venue"),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: "Date"),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: timeController,
                        decoration: const InputDecoration(labelText: "Time"),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: participantController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Max Participants",
                        ),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: selectedMerit,
                        decoration: const InputDecoration(
                          labelText: "Provide Merit",
                        ),
                        items: const [
                          DropdownMenuItem(value: "Yes", child: Text("Yes")),
                          DropdownMenuItem(value: "No", child: Text("No")),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMerit = value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: organizerController,
                        decoration: const InputDecoration(
                          labelText: "Organizer Name",
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Organizer Phone",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Activitymodel updatedActivity = Activitymodel(
                      id: activity.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      venue: venueController.text,
                      activityDate: dateController.text,
                      activityTime: timeController.text,
                      maxParticipants: participantController.text,
                      provideMerit: selectedMerit == "Yes" ? 1 : 0,
                      organizerName: organizerController.text,
                      organizerPhone: phoneController.text,
                      image: activity.image,
                      createdAt: activity.createdAt,
                    );

                    Navigator.pop(dialogContext);

                    confirmUpdateDialog(updatedActivity);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> openGallery(Function setDialogState) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (pickedFile == null) return;

    imageFile = pickedFile;
    imageBytes = await pickedFile.readAsBytes();

    setDialogState(() {});
  }

  Future<void> openCamera(Function setDialogState) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (pickedFile == null) return;

    imageFile = pickedFile;
    imageBytes = await pickedFile.readAsBytes();

    setDialogState(() {});
  }

  Future<void> cropImage(Function setDialogState) async {
    if (imageFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile!.path,
      aspectRatio: const CropAspectRatio(ratioX: 5, ratioY: 3),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (croppedFile != null) {
      imageFile = XFile(croppedFile.path);
      imageBytes = await imageFile!.readAsBytes();
      setDialogState(() {});
    }
  }

  void showDeleteActivityDialog(Activitymodel activity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);

        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this activity?'),
          actions: [
            TextButton(
              onPressed: () {
                navigator.pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                deleteActivity(activity.id!, navigator, messenger);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteActivity(
    int id,
    NavigatorState navigator,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPath.endpoint("api/delete_activity.php")),
        body: {"id": id.toString()},
      );

      print(response.statusCode);
      print(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          messenger.showSnackBar(
            const SnackBar(content: Text("Activity deleted")),
          );

          loadActivities("");

          navigator.pop();
        } else {
          messenger.showSnackBar(SnackBar(content: Text(data["message"])));
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
