<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json");

require_once "db.php";

// Read JSON input
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (
    empty($data["email"]) ||
    empty($data["password"])
) {
    echo json_encode([
        "status" => "error",
        "message" => "Email and password are required."
    ]);
    exit;
}

$email = trim($data["email"]);
$password = $data["password"];

try {

    // Find user by email
    $stmt = $db->prepare("
        SELECT
            id,
            name,
            email,
            phone,
            password,
            role,
            profile_image,
            created_at
        FROM users
        WHERE email = ?
        LIMIT 1
    ");

    $stmt->execute([$email]);

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode([
            "status" => "error",
            "message" => "Invalid email or password."
        ]);
        exit;
    }

    // Verify password
    if (!password_verify($password, $user["password"])) {

        echo json_encode([
            "status" => "error",
            "message" => "Invalid email or password."
        ]);
        exit;
    }

    // Remove password before sending response
    unset($user["password"]);

    echo json_encode([
        "status" => "success",
        "message" => "Login successful.",
        "user" => $user
    ]);

} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);

}
?>