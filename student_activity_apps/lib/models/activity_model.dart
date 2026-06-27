class Activitymodel {
  int? id;
  String? title;
  String? description;
  String? venue;
  String? activityDate;
  String? activityTime;
  String? organizerName;
  String? organizerPhone;
  String? maxParticipants;
  String? image;
  int? provideMerit;
  String? createdAt;

  Activitymodel({
    this.id,
    this.title,
    this.description,
    this.venue,
    this.activityDate,
    this.activityTime,
    this.organizerName,
    this.organizerPhone,
    this.maxParticipants,
    this.image,
    this.provideMerit,
    this.createdAt,
  });

  Activitymodel.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id'].toString());

    title = json['title']?.toString();
    description = json['description']?.toString();
    venue = json['venue']?.toString();

    activityDate = json['activity_date']?.toString();
    activityTime = json['activity_time']?.toString();

    organizerName = json['organizer_name']?.toString();
    organizerPhone = json['organizer_phone']?.toString();
    maxParticipants = json['max_participants']?.toString();

    image = json['image']?.toString() ?? "";
    provideMerit = int.tryParse(json['provide_merit'].toString());
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "venue": venue,
      "activity_date": activityDate,
      "activity_time": activityTime,
      "organizer_name": organizerName,
      "organizer_phone": organizerPhone,
      "max_participants": maxParticipants,
      "image": image,
      "provide_merit": provideMerit,
      "created_at": createdAt,
    };
  }
}
