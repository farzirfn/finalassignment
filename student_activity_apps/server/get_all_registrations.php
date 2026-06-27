<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once "db.php";

try {
    $stmt = $db->prepare("
        SELECT 
            r.user_id,
            r.activity_id,
            u.name as student_name,
            u.email as student_email,
            u.phone as student_phone,
            a.title as activity_title,
            a.activity_date,
            a.activity_time
        FROM registrations r
        JOIN users u ON r.user_id = u.id
        JOIN activities a ON r.activity_id = a.id
        WHERE r.status != 'Rejected'
        ORDER BY a.activity_date ASC, a.activity_time ASC
    ");
    $stmt->execute();
    $registrations = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $registrations
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);
}
