<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once "db.php";

$user_id = $_POST['user_id'] ?? '';
$activity_id = $_POST['activity_id'] ?? '';
$action = $_POST['action'] ?? '';

if(empty($user_id) || empty($activity_id)) {
    echo json_encode([
        "status" => "failed",
        "message" => "Missing user_id or activity_id"
    ]);
    exit;
}

try {
    if ($action === 'admin_cancel') {
        $stmt = $db->prepare("UPDATE registrations SET status = 'Rejected' WHERE user_id = ? AND activity_id = ?");
    } else {
        $stmt = $db->prepare("DELETE FROM registrations WHERE user_id = ? AND activity_id = ?");
    }
    $stmt->execute([$user_id, $activity_id]);

    if($stmt->rowCount() > 0) {
        echo json_encode([
            "status" => "success",
            "message" => "Registration cancelled successfully"
        ]);
    } else {
        echo json_encode([
            "status" => "failed",
            "message" => "No registration found or already cancelled"
        ]);
    }
} catch(PDOException $e){
    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);
}
