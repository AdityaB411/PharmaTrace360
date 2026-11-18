<?php
/**
 * PharmaTrace 360 - Logout
 *
 * Logs LOGOUT via sp_log_event, then destroys the session.
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/db.php';

startSecureSession();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit('Method not allowed.');
}

if (!verifyCsrf()) {
    http_response_code(403);
    exit('Invalid security token.');
}

if (!empty($_SESSION['user_id'])) {
    try {
        $pdo  = dbApp();
        $stmt = $pdo->prepare('CALL sp_log_event(?, ?, ?)');
        $stmt->execute([$_SESSION['user_id'], 'LOGOUT', 'User logged out.']);
        $stmt->closeCursor();
    } catch (Throwable $ignore) {
        // don't block logout on logging failure
    }
}

$_SESSION = [];
if (ini_get('session.use_cookies')) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', [
        'expires'  => time() - 42000,
        'path'     => $params['path'] ?? '/',
        'domain'   => $params['domain'] ?? '',
        'secure'   => (bool)($params['secure'] ?? false),
        'httponly' => (bool)($params['httponly'] ?? true),
        'samesite' => $params['samesite'] ?? 'Lax',
    ]);
}
session_destroy();

header('Location: /login.php');
exit;
