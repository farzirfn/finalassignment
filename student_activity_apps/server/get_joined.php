<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once "db.php";

$user_id = $_GET['user_id'] ?? '';

try {
    $stmt = $db->prepare("
        SELECT activity_id
        FROM registrations
        WHERE user_id = ? AND status != 'Rejected'
    ");
    $stmt->execute([$user_id]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status"=>"success",
        "data"=>$rows
    ]);

} catch(PDOException $e){
    echo json_encode([
        "status"=>"failed",
        "message"=>$e->getMessage()
    ]);
}