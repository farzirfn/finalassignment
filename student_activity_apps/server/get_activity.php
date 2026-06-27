<?php

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include 'db.php';

$search = isset($_GET['search']) ? trim($_GET['search']) : "";
$filter = isset($_GET['filter']) ? trim($_GET['filter']) : "";

try {

    $sql = "SELECT * FROM activities WHERE 1=1";
    $params = [];

    if (!empty($search)) {
        $sql .= " AND (
            title LIKE ?
            OR description LIKE ?
            OR venue LIKE ?
        )";

        $keyword = "%" . $search . "%";
        $params[] = $keyword;
        $params[] = $keyword;
        $params[] = $keyword;
    }

    // Reserved for future filtering
    if (!empty($filter) && $filter != "All") {
        // Example:
        // $sql .= " AND provide_merit = ?";
        // $params[] = ($filter == "Yes") ? 1 : 0;
    }

    $sql .= " ORDER BY created_at DESC";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);

    $activities = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($activities) > 0) {

        echo json_encode([
            "status" => "success",
            "data" => $activities
        ]);

    } else {

        echo json_encode([
            "status" => "failed",
            "message" => "No activities found.",
            "data" => []
        ]);

    }

} catch (Exception $e) {

    echo json_encode([
        "status" => "failed",
        "message" => $e->getMessage()
    ]);

}

?>