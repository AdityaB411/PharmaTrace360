<?php
/**
 * PharmaTrace 360 - Change Account Password
 *
 * Allows any authenticated user (Manufacturer or Admin/Regulator) to update
 * their account password.
 * Verifies current password via sp_login_lookup and password_verify().
 * Hashes new password with password_hash(PASSWORD_DEFAULT).
 * Calls sp_change_password(user_id, new_hash).
 * Plaintext passwords are never logged, printed, or stored.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole(['Manufacturer', 'Admin/Regulator']);

$userId   = (int)($_SESSION['user_id'] ?? 0);
$email    = (string)($_SESSION['email'] ?? '');
$roleName = (string)($_SESSION['role_name'] ?? '');

if ($userId <= 0 || $email === '') {
    header('Location: /login.php');
    exit;
}

$pdo = dbApp();
$successMsg = null;
$errorMsg   = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCsrf()) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Invalid security token.</p></body></html>';
        exit;
    }

    $currentPassword = (string)($_POST['current_password'] ?? '');
    $newPassword     = (string)($_POST['new_password'] ?? '');
    $confirmPassword = (string)($_POST['confirm_password'] ?? '');

    if ($currentPassword === '' || $newPassword === '' || $confirmPassword === '') {
        $errorMsg = 'Current password is incorrect or password could not be changed.';
    } elseif (strlen($newPassword) < 10) {
        $errorMsg = 'Current password is incorrect or password could not be changed.';
    } elseif ($newPassword !== $confirmPassword) {
        $errorMsg = 'Current password is incorrect or password could not be changed.';
    } else {
        try {
            // Verify current password via sp_login_lookup
            $stmt = $pdo->prepare('CALL sp_login_lookup(?)');
            $stmt->execute([$email]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            if (
                !$user
                || empty($user['is_active'])
                || !password_verify($currentPassword, (string)$user['password_hash'])
            ) {
                // Generic failure message to prevent enumeration / timing feedback
                $errorMsg = 'Current password is incorrect or password could not be changed.';
            } else {
                // Hash new password using standard bcrypt (PASSWORD_DEFAULT)
                $newHash = password_hash($newPassword, PASSWORD_DEFAULT);

                // Update hash via procedure sp_change_password
                $chgStmt = $pdo->prepare('CALL sp_change_password(?, ?)');
                $chgStmt->execute([$userId, $newHash]);
                $chgStmt->fetch(PDO::FETCH_ASSOC);
                $chgStmt->closeCursor();

                $successMsg = 'Your password has been changed successfully.';
            }
        } catch (Throwable $e) {
            logAppError($e);
            $errorMsg = 'Current password is incorrect or password could not be changed.';
        }
    }
}

pageHeader('Change Password', 'Security & Account Password');
?>

<div class="row justify-content-center">
    <div class="col-md-8 col-lg-6">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0 small">
                    <li class="breadcrumb-item">
                        <a href="<?= $roleName === 'Manufacturer' ? '/app/batches.php' : '/app/dashboard.php' ?>" class="text-decoration-none">
                            Home
                        </a>
                    </li>
                    <li class="breadcrumb-item active" aria-current="page">Change Password</li>
                </ol>
            </nav>
        </div>

        <?php if ($successMsg !== null): ?>
            <div class="alert alert-success alert-dismissible fade show" role="alert" id="successAlert">
                <strong>Success:</strong> <?= e($successMsg) ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        <?php endif; ?>

        <?php if ($errorMsg !== null): ?>
            <div class="alert alert-danger alert-dismissible fade show" role="alert" id="errorAlert">
                <strong>Error:</strong> <?= e($errorMsg) ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        <?php endif; ?>

        <div class="card shadow-sm border-0 mb-4">
            <div class="card-body p-4 p-md-5">
                <div class="d-flex align-items-center gap-3 mb-4">
                    <div class="site-brand-logo" style="width: 48px; height: 48px;">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                        </svg>
                    </div>
                    <div>
                        <h4 class="fw-bold mb-0">Change Password</h4>
                        <small class="text-muted">Account: <?= e($email) ?></small>
                    </div>
                </div>

                <form method="POST" action="change_password.php" id="changePasswordForm" autocomplete="off">
                    <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">

                    <div class="mb-3">
                        <label for="current_password" class="form-label small fw-semibold">Current Password</label>
                        <input type="password" name="current_password" id="current_password"
                               class="form-control" required autocomplete="current-password" autofocus>
                    </div>

                    <div class="mb-3">
                        <label for="new_password" class="form-label small fw-semibold">New Password</label>
                        <input type="password" name="new_password" id="new_password"
                               class="form-control" minlength="10" required autocomplete="new-password">
                        <div class="form-text small">Minimum 10 characters required.</div>
                    </div>

                    <div class="mb-4">
                        <label for="confirm_password" class="form-label small fw-semibold">Confirm New Password</label>
                        <input type="password" name="confirm_password" id="confirm_password"
                               class="form-control" minlength="10" required autocomplete="new-password">
                        <div class="form-text small">Re-type your new password to verify.</div>
                    </div>

                    <div class="d-flex justify-content-between align-items-center">
                        <a href="<?= $roleName === 'Manufacturer' ? '/app/batches.php' : '/app/dashboard.php' ?>" class="btn btn-outline-secondary btn-sm">
                            Cancel
                        </a>
                        <button type="submit" class="btn btn-primary px-4 fw-semibold">
                            Update Password
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<?php
pageFooter();
