<?php

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include "db.php";

if ($_SERVER["REQUEST_METHOD"] != "POST") {
    http_response_code(405);

    echo json_encode([
        "status" => "failed",
        "message" => "Method Not Allowed"
    ]);

    exit();
}

$id = $_POST["id"] ?? "";

if ($id == "") {

    echo json_encode([
        "status" => "failed",
        "message" => "Activity ID is required."
    ]);

    exit();
}

try {

    // Get image name
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

    // Delete image
    if (!empty($activity["image"])) {

        $imagePath = "../uploads/activities/" . $activity["image"];

        if (file_exists($imagePath)) {
            unlink($imagePath);
        }
    }

    // Delete related registrations first to avoid Foreign Key constraint violation
    $deleteReg = $db->prepare("DELETE FROM registrations WHERE activity_id = ?");
    $deleteReg->execute([$id]);

    // Delete activity
    $delete = $db->prepare("
        DELETE FROM activities
        WHERE id = ?
    ");

    $delete->execute([$id]);

    echo json_encode([
        "status" => "success",
        "message" => "Activity deleted successfully."
    ]);

} catch (PDOException $e) {

    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);
}
?>