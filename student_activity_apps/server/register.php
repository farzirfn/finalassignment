<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json");

date_default_timezone_set('Asia/Kuala_Lumpur');

require_once "db.php";

// Read JSON input
$data = json_decode(file_get_contents("php://input"), true);

// Validate required fields
if (
    empty($data["name"]) ||
    empty($data["email"]) ||
    empty($data["phone"]) ||
    empty($data["password"]) ||
    empty($data["role"])
) {
    echo json_encode([
        "status" => "error",
        "message" => "All fields are required."
    ]);
    exit;
}

// Get input
$name = trim($data["name"]);
$email = trim($data["email"]);
$phone = trim($data["phone"]);
$password = $data["password"];
$role = trim($data["role"]);
$createdAt = date("Y-m-d H:i:s");

// Validate email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode([
        "status" => "error",
        "message" => "Invalid email address."
    ]);
    exit;
}

// Validate phone
if (!preg_match('/^[0-9+\-\s]{8,20}$/', $phone)) {
    echo json_encode([
        "status" => "error",
        "message" => "Invalid phone number."
    ]);
    exit;
}

// Validate password length
if (strlen($password) < 6) {
    echo json_encode([
        "status" => "error",
        "message" => "Password must be at least 6 characters."
    ]);
    exit;
}

// Hash password
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

try {

    // Check duplicate email
    $check = $db->prepare("
        SELECT id
        FROM users
        WHERE email = ?
        LIMIT 1
    ");

    $check->execute([$email]);

    if ($check->fetch()) {
        echo json_encode([
            "status" => "error",
            "message" => "Email already registered."
        ]);
        exit;
    }

    // Insert user
    $insert = $db->prepare("
        INSERT INTO users
        (
            name,
            email,
            phone,
            password,
            role,
            profile_image,
            created_at
        )
        VALUES
        (
            ?, ?, ?, ?, ?, ?, ?
        )
    ");

    $insert->execute([
        $name,
        $email,
        $phone,
        $hashedPassword,
        $role,
        "",
        $createdAt
    ]);

    $userId = $db->lastInsertId();

    echo json_encode([
        "status" => "success",
        "message" => "Registration successful.",
        "user" => [
            "id" => $userId,
            "name" => $name,
            "email" => $email,
            "phone" => $phone,
            "role" => $role
        ]
    ]);

} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        "status" => "error",
        "message" => "Database error.",
        "error" => $e->getMessage()
    ]);

}
?>