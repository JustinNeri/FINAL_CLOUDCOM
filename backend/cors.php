<?php
// Lets the web app (served from Vercel) call these APIs from a browser.
// Add this as the FIRST line of every *_api.php file on the server:
//
//     require_once __DIR__ . '/cors.php';

$allowedOrigins = [
    'https://pokemon-ip-tau.vercel.app',
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$isLocalDev = (bool) preg_match('#^http://(localhost|127\.0\.0\.1)(:\d+)?$#', $origin);

if (in_array($origin, $allowedOrigins, true) || $isLocalDev) {
    header("Access-Control-Allow-Origin: $origin");
    header('Vary: Origin');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Max-Age: 86400');
}

// Browsers send an OPTIONS "preflight" before some requests; answer it and stop.
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}
