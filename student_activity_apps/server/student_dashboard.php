<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include 'db.php';

$user_id = $_GET['user_id'] ?? '';

try {
    $today = date("Y-m-d");

    // Upcoming Activities (All available upcoming)
    $stmt = $db->prepare("
        SELECT COUNT(*) AS total
        FROM activities
        WHERE date(
            substr(activity_date,7,4) || '-' ||
            substr(activity_date,4,2) || '-' ||
            substr(activity_date,1,2)
        ) >= date(?)
    ");
    $stmt->execute([$today]);
    $upcoming_activities = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // My Registrations (Total joined)
    $stmt = $db->prepare("
        SELECT COUNT(*) AS total
        FROM registrations
        WHERE user_id = ? AND status != 'Rejected'
    ");
    $stmt->execute([$user_id]);
    $my_registrations = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Pending (Joined and >= today)
    $stmt = $db->prepare("
        SELECT COUNT(*) AS total
        FROM registrations r
        JOIN activities a ON r.activity_id = a.id
        WHERE r.user_id = ? AND r.status != 'Rejected' AND date(
            substr(a.activity_date,7,4) || '-' ||
            substr(a.activity_date,4,2) || '-' ||
            substr(a.activity_date,1,2)
        ) >= date(?)
    ");
    $stmt->execute([$user_id, $today]);
    $pending = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Completed (Joined and < today)
    $stmt = $db->prepare("
        SELECT COUNT(*) AS total
        FROM registrations r
        JOIN activities a ON r.activity_id = a.id
        WHERE r.user_id = ? AND r.status != 'Rejected' AND date(
            substr(a.activity_date,7,4) || '-' ||
            substr(a.activity_date,4,2) || '-' ||
            substr(a.activity_date,1,2)
        ) < date(?)
    ");
    $stmt->execute([$user_id, $today]);
    $completed = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Nearest Upcoming Activities available in the system
    $stmt = $db->prepare("
        SELECT
            title,
            activity_date,
            activity_time
        FROM activities
        WHERE date(
            substr(activity_date,7,4) || '-' ||
            substr(activity_date,4,2) || '-' ||
            substr(activity_date,1,2)
        ) >= date(?)
        ORDER BY date(
            substr(activity_date,7,4) || '-' ||
            substr(activity_date,4,2) || '-' ||
            substr(activity_date,1,2)
        ) ASC
        LIMIT 3
    ");
    $stmt->execute([$today]);
    $latest = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "upcoming_activities" => (int)$upcoming_activities,
        "my_registrations" => (int)$my_registrations,
        "pending" => (int)$pending,
        "completed" => (int)$completed,
        "latest" => $latest
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);
}
