<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once "db.php";

$user_id = $_POST['user_id'] ?? '';
$activity_id = $_POST['activity_id'] ?? '';

if ($user_id == '' || $activity_id == '') {
    echo json_encode([
        "status" => "failed",
        "message" => "Missing parameters"
    ]);
    exit;
}

try {
    // Check registration status
    $stmt = $db->prepare("
        SELECT status 
        FROM registrations
        WHERE user_id = ?
        AND activity_id = ?
    ");
    $stmt->execute([$user_id, $activity_id]);
    $regStatus = $stmt->fetchColumn();

    if ($regStatus !== false) {
        if ($regStatus === 'Rejected') {
            echo json_encode([
                "status" => "failed",
                "message" => "You cannot join this activity. Your registration was cancelled by an admin."
            ]);
        } else {
            echo json_encode([
                "status" => "failed",
                "message" => "You have already joined this activity."
            ]);
        }
        exit;
    }

    // Get activity max participants
    $stmt = $db->prepare("SELECT max_participants FROM activities WHERE id = ?");
    $stmt->execute([$activity_id]);
    $activity = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$activity) {
        echo json_encode(["status" => "failed", "message" => "Activity not found."]);
        exit;
    }

    $maxParticipants = (int)$activity["max_participants"];

    // Count current participants
    $stmt = $db->prepare("SELECT COUNT(*) FROM registrations WHERE activity_id = ? AND status != 'Rejected'");
    $stmt->execute([$activity_id]);
    $currentParticipants = (int)$stmt->fetchColumn();

    // Check full
    if ($currentParticipants >= $maxParticipants) {
        echo json_encode(["status" => "failed", "message" => "Sorry, this activity is already full."]);
        exit;
    }

    // Insert registration
    $stmt = $db->prepare("
        INSERT INTO registrations (user_id, activity_id, status)
        VALUES (?, ?, 'Registered')
    ");
    $stmt->execute([$user_id, $activity_id]);

    echo json_encode([
        "status" => "success",
        "message" => "Successfully joined activity."
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);
}