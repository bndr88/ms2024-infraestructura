<?php

const USERS = [
    'admin' => 'password123',
    'user' => 'secret'
];

const SECRET_KEY = 'supersecretkey';

function authenticate($username, $password) {
    return isset(USERS[$username]) && USERS[$username] === $password;
}

// Función para codificar en Base64URL (según RFC 7515)
function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function generateToken($username) {
    $payload = [
        'iss' => $username,
        'iat' => time(),
        'exp' => time() + 3600
    ];

    $header = base64url_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $body   = base64url_encode(json_encode($payload));
    $signature = base64url_encode(hash_hmac('sha256', "$header.$body", SECRET_KEY, true));

    return "$header.$body.$signature";
}

