<?php
/**
 * Shared layout helpers for the authenticated section.
 * Provides the navigation bar, page header, and page footer.
 */

declare(strict_types=1);

function pageHeader(string $title, string $pageTitle = ''): void
{
    $role = e($_SESSION['role_name'] ?? '');
    $name = e($_SESSION['full_name'] ?? '');
    $pageTitle = $pageTitle ?: $title;
    ?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= e($title) ?> - PharmaTrace 360</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/vendor/bootstrap/bootstrap.min.css">
    <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
    <header class="site-header py-2 text-white">
        <div class="container d-flex align-items-center justify-content-between flex-wrap gap-2">
            <div class="d-flex align-items-center gap-3">
                <div class="site-brand-logo">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                         stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        <path d="m9 12 2 2 4-4"/>
                    </svg>
                </div>
                <div>
                    <a href="/" class="text-white text-decoration-none fw-bold">PharmaTrace 360</a>
                </div>
            </div>
            <nav class="d-flex align-items-center gap-3 flex-wrap">
                <?php if ($_SESSION['role_name'] === 'Manufacturer'): ?>
                    <a href="/app/batches.php" class="text-white-50 text-decoration-none small">My Batches</a>
                    <a href="/app/deliveries.php" class="text-white-50 text-decoration-none small">Deliveries</a>
                    <a href="/app/batch_new.php" class="text-white-50 text-decoration-none small">New batch</a>
                <?php endif; ?>
                <?php if ($_SESSION['role_name'] === 'Admin/Regulator'): ?>
                    <a href="/app/dashboard.php" class="text-white-50 text-decoration-none small">Dashboard</a>
                    <a href="/app/all_batches.php" class="text-white-50 text-decoration-none small">All Batches</a>
                    <a href="/app/suspicious.php" class="text-white-50 text-decoration-none small">Suspicious</a>
                    <a href="/app/audit.php" class="text-white-50 text-decoration-none small">Audit Log</a>
                    <a href="/app/recall.php" class="text-white-50 text-decoration-none small">Recall</a>
                    <a href="/app/recalls.php" class="text-white-50 text-decoration-none small">Recalls</a>
                <?php endif; ?>
                <a href="/app/change_password.php" class="text-white-50 text-decoration-none small">Change password</a>
                <span class="badge rounded-pill bg-light text-dark px-3 py-2 fw-medium"><?= $role ?></span>
                <span class="text-white-50 small"><?= $name ?></span>
                <form method="POST" action="/logout.php" class="m-0">
                    <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                    <button type="submit" class="btn btn-outline-light btn-sm">Logout</button>
                </form>
            </nav>
        </div>
    </header>
    <main class="container my-4" style="max-width: 1100px;">
        <h2 class="h4 fw-bold mb-4"><?= e($pageTitle) ?></h2>
    <?php
}

function pageFooter(): void
{
    ?>
    </main>
    <footer class="site-footer py-3 text-center">
        <div class="container">
            <div>PharmaTrace 360 &copy; <?= date('Y') ?> &bull; Smart Pharmaceutical Traceability System</div>
        </div>
    </footer>
</body>
</html>
    <?php
}
