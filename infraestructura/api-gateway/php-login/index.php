<?php
require 'auth.php';

header('Content-Type: application/json');
$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['username']) || !isset($data['password'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Username and password are required.']);
    exit;
}

if (authenticate($data['username'], $data['password'])) {
    $token = generateToken($data['username']);
    echo json_encode(['token' => $token]);
} else {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid credentials.']);
}
