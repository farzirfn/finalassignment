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

$title = addslashes($_POST['title'] ?? '');
$description = addslashes($_POST['description'] ?? '');
$venue = $_POST['venue'] ?? '';
$activity_date = $_POST['activity_date'] ?? '';
$activity_time = $_POST['activity_time'] ?? '';
$max_participants = $_POST['max_participants'] ?? '';
$provide_merit = $_POST['provide_merit'] ?? '';
$organizer_name = $_POST['organizer_name'] ?? '';
$organizer_phone = $_POST['organizer_phone'] ?? '';
$image = $_POST['image'] ?? 'NA';

if (
    $title == '' ||
    $description == '' ||
    $venue == '' ||
    $activity_date == '' ||
    $activity_time == '' ||
    $max_participants == '' ||
    $organizer_name == '' ||
    $organizer_phone == '' ||
    $provide_merit === '' ||
    $image == 'NA' || $image == ''
) {
    echo json_encode([
        "status" => "failed",
        "message" => "Please fill all fields."
    ]);
    exit();
}

try {
    $insert = $db->prepare("
        INSERT INTO activities (
            title, description, venue, activity_date, activity_time, 
            organizer_name, organizer_phone, max_participants, provide_merit, image, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now', 'localtime'))
    ");

    $insert->execute([
        $title,
        $description,
        $venue,
        $activity_date,
        $activity_time,
        $organizer_name,
        $organizer_phone,
        $max_participants,
        $provide_merit,
        ""
    ]);

    $id = $db->lastInsertId();
    $imageName = "activity_" . $id . ".png";

    $update = $db->prepare("UPDATE activities SET image = ? WHERE id = ?");
    $update->execute([$imageName, $id]);

    $uploadDir = "../uploads/activities/";

    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    file_put_contents(
        $uploadDir . $imageName,
        base64_decode($image)
    );

    echo json_encode([
        "status" => "success",
        "message" => "Activity added successfully."
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);
}
?>