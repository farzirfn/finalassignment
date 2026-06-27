<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include 'db.php';

if ($_SERVER['REQUEST_METHOD'] != 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "failed", "message" => "Method Not Allowed"]);
    exit();
}

$id = $_POST['id'] ?? '';
$name = addslashes($_POST['name'] ?? '');
$phone = addslashes($_POST['phone'] ?? '');
$old_password = $_POST['old_password'] ?? '';
$new_password = $_POST['new_password'] ?? '';

if ($id == '' || $name == '' || $phone == '') {
    echo json_encode(["status" => "failed", "message" => "Missing required fields"]);
    exit();
}

try {
    $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode(["status" => "failed", "message" => "User not found"]);
        exit();
    }

    $updatePasswordQuery = "";
    $params = [$name, $phone];

    if (!empty($new_password)) {
        if (!password_verify($old_password, $user['password'])) {
            echo json_encode(["status" => "failed", "message" => "Incorrect old password"]);
            exit();
        }
        $updatePasswordQuery = ", password = ?";
        $params[] = password_hash($new_password, PASSWORD_DEFAULT);
    }

    $updateImageQuery = "";
    if (isset($_FILES['image']) && $_FILES['image']['error'] == UPLOAD_ERR_OK) {
        $uploadDir = "../uploads/profiles/";
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $imageName = "profile_" . $id . ".png";
        $targetFile = $uploadDir . $imageName;

        if (move_uploaded_file($_FILES['image']['tmp_name'], $targetFile)) {
            $updateImageQuery = ", profile_image = ?";
            $params[] = $imageName;
        }
    }

    $params[] = $id;

    $updateStmt = $db->prepare("
        UPDATE users 
        SET name = ?, phone = ? $updatePasswordQuery $updateImageQuery 
        WHERE id = ?
    ");

    $updateStmt->execute($params);

    $stmt = $db->prepare("SELECT id, name, email, phone, role, profile_image, created_at FROM users WHERE id = ?");
    $stmt->execute([$id]);
    $updatedUser = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "message" => "Profile updated successfully",
        "user" => $updatedUser
    ]);

} catch (PDOException $e) {
    echo json_encode(["status" => "failed", "message" => $e->getMessage()]);
}
?>
