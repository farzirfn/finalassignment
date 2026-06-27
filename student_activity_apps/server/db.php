<?php
// db.php

$db_file = __DIR__ . "/student_activity.db";

try {

    // Create SQLite connection
    $db = new PDO("sqlite:" . $db_file);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Enable Foreign Keys
    $db->exec("PRAGMA foreign_keys = ON");

    /*
    |--------------------------------------------------------------------------
    | USERS TABLE
    |--------------------------------------------------------------------------
    */

    $db->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            phone TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            profile_image TEXT DEFAULT '',
            created_at DATETIME DEFAULT (datetime('now','localtime'))
        )
    ");

    $userColumns = $db->query("PRAGMA table_info(users)")
        ->fetchAll(PDO::FETCH_ASSOC);

    $userColumnNames = array_column($userColumns, "name");

    if (!in_array("profile_image", $userColumnNames)) {
        $db->exec("ALTER TABLE users ADD COLUMN profile_image TEXT DEFAULT ''");
    }

    if (!in_array("created_at", $userColumnNames)) {
        $db->exec("ALTER TABLE users ADD COLUMN created_at DATETIME");
    }


    /*
    |--------------------------------------------------------------------------
    | ACTIVITIES TABLE
    |--------------------------------------------------------------------------
    */

    $db->exec("
        CREATE TABLE IF NOT EXISTS activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            venue TEXT NOT NULL,
            activity_date TEXT NOT NULL,
            activity_time TEXT NOT NULL,
            max_participants INTEGER DEFAULT 50,
            provide_merit INTEGER DEFAULT 0,
            organizer_name TEXT,
            organizer_phone TEXT,
            image TEXT DEFAULT '',
            created_at DATETIME DEFAULT (datetime('now','localtime'))
        )
    ");

    $activityColumns = $db->query("PRAGMA table_info(activities)")
        ->fetchAll(PDO::FETCH_ASSOC);

    $activityColumnNames = array_column($activityColumns, "name");

    if (!in_array("provide_merit", $activityColumnNames)) {
        $db->exec("ALTER TABLE activities ADD COLUMN provide_merit INTEGER DEFAULT 0");
    }

    if (!in_array("organizer_name", $activityColumnNames)) {
        $db->exec("ALTER TABLE activities ADD COLUMN organizer_name TEXT");
    }

    if (!in_array("organizer_phone", $activityColumnNames)) {
        $db->exec("ALTER TABLE activities ADD COLUMN organizer_phone TEXT");
    }

    if (!in_array("image", $activityColumnNames)) {
        $db->exec("ALTER TABLE activities ADD COLUMN image TEXT DEFAULT ''");
    }

    if (!in_array("created_at", $activityColumnNames)) {
        $db->exec("ALTER TABLE activities ADD COLUMN created_at DATETIME");
    }


    /*
    |--------------------------------------------------------------------------
    | REGISTRATIONS TABLE
    |--------------------------------------------------------------------------
    */

    $db->exec("
        CREATE TABLE IF NOT EXISTS registrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            activity_id INTEGER NOT NULL,
            status TEXT DEFAULT 'Registered',
            registered_at DATETIME DEFAULT (datetime('now','localtime')),
            UNIQUE(user_id, activity_id),
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(activity_id) REFERENCES activities(id) ON DELETE CASCADE
        )
    ");

} catch (PDOException $e) {

    header('Content-Type: application/json');

    echo json_encode([
        "status" => false,
        "message" => $e->getMessage()
    ]);

    exit;
}
?>