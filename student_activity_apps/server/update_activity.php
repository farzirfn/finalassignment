<?php

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include 'db.php';

if ($_SERVER['REQUEST_METHOD'] != 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "failed",
        "message" => "Method Not Allowed"
    ]);
    exit();
}

$id = $_POST['id'] ?? '';
$title = addslashes($_POST['title'] ?? '');
$description = addslashes($_POST['description'] ?? '');
$venue = $_POST['venue'] ?? '';
$activity_date = $_POST['activityDate'] ?? '';
$activity_time = $_POST['activityTime'] ?? '';
$max_participants = $_POST['maxParticipants'] ?? '';
$provide_merit = $_POST['provideMerit'] ?? '';
$organizer_name = $_POST['organizerName'] ?? '';
$organizer_phone = $_POST['organizerPhone'] ?? '';
$image = $_POST['image'] ?? 'NA';

if (
    $id == '' ||
    $title == '' ||
    $description == '' ||
    $venue == '' ||
    $activity_date == '' ||
    $activity_time == '' ||
    $max_participants == '' ||
    $organizer_name == '' ||
    $organizer_phone == '' ||
    $provide_merit === ''
) {
    echo json_encode([
        "status" => "failed",
        "message" => "Please fill all fields."
    ]);
    exit();
}

try {

    // Get current image
    $check = $db->prepare("
        SELECT image
        FROM activities
        WHERE id = ?
    ");

    $check->execute([$id]);

    $activity = $check->fetch(PDO::FETCH_ASSOC);

    if (!$activity) {
        echo json_encode([
            "status" => "failed",
            "message" => "Activity not found."
        ]);
        exit();
    }

    $imageName = $activity['image'];

    // Update image if new image selected
    if ($image != "NA") {

        $imageName = "activity_" . $id . ".png";

        $uploadDir = "../uploads/activities/";

        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        file_put_contents(
            $uploadDir . $imageName,
            base64_decode($image)
        );
    }

    $update = $db->prepare("
        UPDATE activities
        SET
            title = ?,
            description = ?,
            venue = ?,
            activity_date = ?,
            activity_time = ?,
            organizer_name = ?,
            organizer_phone = ?,
            max_participants = ?,
            provide_merit = ?,
            image = ?
        WHERE id = ?
    ");

    $update->execute([
        $title,
        $description,
        $venue,
        $activity_date,
        $activity_time,
        $organizer_name,
        $organizer_phone,
        $max_participants,
        $provide_merit,
        $imageName,
        $id
    ]);

    // Return updated activity
    $activity = $db->prepare("
        SELECT *
        FROM activities
        WHERE id = ?
    ");

    $activity->execute([$id]);

    echo json_encode([
        "status" => "success",
        "message" => "Activity updated successfully.",
        "data" => $activity->fetch(PDO::FETCH_ASSOC)
    ]);

} catch (PDOException $e) {

    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);
}
?>