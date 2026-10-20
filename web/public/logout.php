<?php
/**
 * PharmaTrace 360 - Logout
 *
 * Logs LOGOUT via sp_log_event, then destroys the session.
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/db.php';

startSecureSession();

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

session_unset();
session_destroy();

header('Location: /login.php');
exit;
