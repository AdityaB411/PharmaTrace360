<?php
/**
 * PharmaTrace 360 - Login Page
 *
 * Uses sp_login_lookup and password_verify.
 * Shows only "Invalid email or password" on any failure.
 * Logs LOGIN, LOGIN_FAILED with sp_log_event (never logs passwords).
 * Inactive users cannot log in.
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/db.php';

startSecureSession();

// Already logged in?
if (!empty($_SESSION['user_id'])) {
    header('Location: /app/' . ($_SESSION['role_name'] === 'Manufacturer' ? 'batches.php' : 'dashboard.php'));
    exit;
}

$errorMessage = null;
$demoModeActive = false;
$demoAccounts = [];
$hasLocalDemoPasswords = false;

try {
    $config = getAppConfig();
    $demoModeActive = !empty($config['DEMO_MODE']);
    if ($demoModeActive) {
        $localDemoPasswords = is_array($config['DEMO_LOGIN_PASSWORDS'] ?? null)
            ? $config['DEMO_LOGIN_PASSWORDS']
            : [];

        $seedDemoAccounts = [
            [
                'label' => 'Priya Sharma',
                'role'  => 'Admin / Regulator',
                'badge' => 'admin',
                'email' => 'priya.admin@demo.test',
            ],
            [
                'label' => 'Cipla Ltd',
                'role'  => 'Manufacturer',
                'badge' => 'manufacturer',
                'email' => 'rahul.mfr@demo.test',
            ],
            [
                'label' => 'Alkem Laboratories Ltd',
                'role'  => 'Manufacturer',
                'badge' => 'manufacturer',
                'email' => 'anjali.mfr@demo.test',
            ],
            [
                'label' => 'Alembic Pharmaceuticals Ltd',
                'role'  => 'Manufacturer',
                'badge' => 'manufacturer',
                'email' => 'vikram.mfr@demo.test',
            ],
        ];

        foreach ($seedDemoAccounts as $acct) {
            $pw = $localDemoPasswords[$acct['email']] ?? '';
            $pwStr = is_string($pw) ? $pw : '';
            if ($pwStr !== '') {
                $hasLocalDemoPasswords = true;
            }
            $acct['password'] = $pwStr;
            $demoAccounts[] = $acct;
        }
    }
} catch (Throwable $ignore) {
    // Keep login form usable; DB errors are handled on POST submission.
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCsrf()) {
        $errorMessage = 'Invalid form submission. Please try again.';
    } else {
        $email    = trim($_POST['email'] ?? '');
        $password = $_POST['password'] ?? '';

        try {
            $pdo  = dbApp();
            $stmt = $pdo->prepare('CALL sp_login_lookup(?)');
            $stmt->execute([$email]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            if (
                $user
                && $user['is_active']
                && password_verify($password, $user['password_hash'])
            ) {
                // Successful login
                session_regenerate_id(true);
                $_SESSION['user_id']         = (int)$user['user_id'];
                $_SESSION['email']           = $user['email'];
                $_SESSION['role_name']       = $user['role_name'];
                $_SESSION['manufacturer_id'] = $user['manufacturer_id'] !== null ? (int)$user['manufacturer_id'] : null;
                $_SESSION['full_name']       = $user['full_name'] ?? $user['email'];
                $_SESSION['manufacturer_name'] = '';
                $_SESSION['last_activity']   = time();

                if (!empty($user['manufacturer_id'])) {
                    $mfrStmt = $pdo->prepare('SELECT manufacturer FROM v_batch_overview WHERE manufacturer_id = ? LIMIT 1');
                    $mfrStmt->execute([$user['manufacturer_id']]);
                    $mfrRow = $mfrStmt->fetch(PDO::FETCH_ASSOC);
                    if ($mfrRow && !empty($mfrRow['manufacturer'])) {
                        $_SESSION['manufacturer_name'] = $mfrRow['manufacturer'];
                        $_SESSION['full_name'] = $mfrRow['manufacturer'];
                    }
                    $mfrStmt->closeCursor();
                }
                // Log LOGIN
                $logStmt = $pdo->prepare('CALL sp_log_event(?, ?, ?)');
                $logStmt->execute([$user['user_id'], 'LOGIN', 'User logged in.']);
                $logStmt->closeCursor();

                $dest = $user['role_name'] === 'Manufacturer' ? '/app/batches.php' : '/app/dashboard.php';
                header('Location: ' . $dest);
                exit;
            } else {
                // Failed login — log if we found the user
                if ($user) {
                    try {
                        $logStmt = $pdo->prepare('CALL sp_log_event(?, ?, ?)');
                        $logStmt->execute([$user['user_id'], 'LOGIN_FAILED', 'Failed login attempt.']);
                        $logStmt->closeCursor();
                    } catch (Throwable $ignore) {
                        // don't expose logging failures
                    }
                }
                $errorMessage = 'Invalid email or password.';
            }
        } catch (Throwable $ex) {
            logAppError($ex);
            $errorMessage = 'Something went wrong, please try again.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - PharmaTrace 360</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/vendor/bootstrap/bootstrap.min.css">
    <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
    <header class="site-header py-3 text-white">
        <div class="container d-flex align-items-center justify-content-between">
            <div class="d-flex align-items-center gap-3">
                <div class="site-brand-logo">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                         stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        <path d="m9 12 2 2 4-4"/>
                    </svg>
                </div>
                <div>
                    <h1 class="h5 mb-0 fw-bold">PharmaTrace 360</h1>
                    <small class="text-white-50">Staff Login</small>
                </div>
            </div>
            <a href="/" class="btn btn-outline-light btn-sm">Public Portal</a>
        </div>
    </header>

    <main class="container my-5" style="max-width: 480px;">
        <div class="main-card p-4 p-md-5">
            <h2 class="h4 fw-bold text-center mb-4">Sign in</h2>

            <?php if ($errorMessage): ?>
                <div class="alert alert-danger" role="alert" id="loginError"><?= e($errorMessage) ?></div>
            <?php endif; ?>

            <form method="POST" action="login.php" id="loginForm" autocomplete="on">
                <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">

                <div class="mb-3">
                    <label for="email" class="form-label fw-medium">Email</label>
                    <input type="email" name="email" id="email" class="form-control" required autofocus
                           autocomplete="username"
                           value="<?= e($_POST['email'] ?? '') ?>">
                </div>

                <div class="mb-4">
                    <label for="password" class="form-label fw-medium">Password</label>
                    <input type="password" name="password" id="password" class="form-control" required
                           autocomplete="current-password">
                </div>

                <button type="submit" class="btn btn-check-code w-100" id="loginButton">Sign in</button>
            </form>

            <?php if ($demoModeActive && !empty($demoAccounts)): ?>
                <section class="demo-box mt-4" aria-label="Demo staff accounts">
                    <div class="d-flex align-items-center gap-2 mb-1">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                             stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                             class="text-primary flex-shrink-0" aria-hidden="true">
                            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                            <circle cx="9" cy="7" r="4"/>
                            <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
                            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                        </svg>
                        <h3 class="h6 fw-bold mb-0">Demo Staff Accounts</h3>
                    </div>
                    <p class="small mb-3" style="color: #475569;">
                        <?php if ($hasLocalDemoPasswords): ?>
                            Click any account below to auto-fill its email and password.
                        <?php else: ?>
                            Click any account below to fill its email (add local demo passwords in <code>web/config.local.php</code> to auto-fill both).
                        <?php endif; ?>
                    </p>

                    <div class="demo-account-list" role="group" aria-label="Choose a demo staff account">
                        <?php foreach ($demoAccounts as $idx => $acct): ?>
                            <button type="button"
                                    class="demo-account-btn"
                                    data-demo-index="<?= (int)$idx ?>"
                                    aria-pressed="false">
                                <span class="demo-account-meta">
                                    <span class="demo-account-header">
                                        <span class="demo-account-name"><?= e($acct['label']) ?></span>
                                        <span class="demo-role-badge <?= e($acct['badge']) ?>"><?= e($acct['role']) ?></span>
                                    </span>
                                    <span class="demo-account-email"><?= e($acct['email']) ?></span>
                                </span>
                                <span class="demo-account-action">
                                    <span class="demo-action-label">Use</span>
                                </span>
                            </button>
                        <?php endforeach; ?>
                    </div>

                    <p id="demoFillStatus" class="small mt-2 mb-0" style="color: #0369a1; min-height: 1.25rem;" aria-live="polite"></p>
                </section>

                <script id="demoAccountsPayload" type="application/json"><?= json_encode(
                    array_map(
                        static fn(array $a): array => [
                            'email'    => $a['email'],
                            'password' => $a['password'],
                            'label'    => $a['label'],
                        ],
                        $demoAccounts
                    ),
                    JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT
                ) ?></script>
                <script>
                    (function () {
                        var payloadEl = document.getElementById('demoAccountsPayload');
                        var emailInput = document.getElementById('email');
                        var passwordInput = document.getElementById('password');
                        var loginButton = document.getElementById('loginButton');
                        var statusEl = document.getElementById('demoFillStatus');
                        var buttons = document.querySelectorAll('.demo-account-btn');
                        if (!payloadEl || !emailInput || !passwordInput || !buttons.length) {
                            return;
                        }

                        var accounts = JSON.parse(payloadEl.textContent || '[]');

                        buttons.forEach(function (btn) {
                            btn.addEventListener('click', function () {
                                var idx = parseInt(btn.getAttribute('data-demo-index') || '-1', 10);
                                var acct = accounts[idx];
                                if (!acct) {
                                    return;
                                }

                                emailInput.value = acct.email || '';
                                if (acct.password) {
                                    passwordInput.value = acct.password;
                                } else {
                                    passwordInput.value = '';
                                }

                                buttons.forEach(function (other) {
                                    var selected = other === btn;
                                    other.classList.toggle('is-selected', selected);
                                    other.setAttribute('aria-pressed', selected ? 'true' : 'false');
                                    var labelEl = other.querySelector('.demo-action-label');
                                    if (labelEl) {
                                        labelEl.textContent = selected ? 'Filled' : 'Use';
                                    }
                                });

                                if (acct.password) {
                                    if (statusEl) {
                                        statusEl.textContent = 'Filled email and password for ' + acct.label + '. Click Sign in to continue.';
                                    }
                                    if (loginButton) {
                                        loginButton.focus();
                                    }
                                } else {
                                    if (statusEl) {
                                        statusEl.textContent = 'Filled email for ' + acct.label + '. Enter password to sign in.';
                                    }
                                    passwordInput.focus();
                                }
                            });
                        });
                    })();
                </script>
            <?php endif; ?>
        </div>
    </main>

    <footer class="site-footer py-3 text-center">
        <div class="container">
            <div>PharmaTrace 360 &copy; <?= date('Y') ?> &bull; Smart Pharmaceutical Traceability System</div>
        </div>
    </footer>
</body>
</html>
