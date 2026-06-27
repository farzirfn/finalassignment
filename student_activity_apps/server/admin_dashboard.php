<?php

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include 'db.php';

try {

    // Total Activities
    $stmt = $db->query("
        SELECT COUNT(*) AS total
        FROM activities
    ");
    $activities = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Total Students
    $stmt = $db->query("
        SELECT COUNT(*) AS total
        FROM users
        WHERE role = 'Student'
    ");
    $students = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Today's date (YYYY-MM-DD)
    $today = date("Y-m-d");

    // Upcoming Activities (Today and Future)
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

    $upcoming = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Total Registrations
    $stmt = $db->query("
        SELECT COUNT(*) AS total
        FROM registrations
        WHERE status != 'Rejected'
    ");

    $registrations = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Nearest Upcoming Activities
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
        "activities" => (int)$activities,
        "students" => (int)$students,
        "upcoming" => (int)$upcoming,
        "registrations" => (int)$registrations,
        "latest" => $latest
    ]);

} catch (PDOException $e) {

    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);

}
?>