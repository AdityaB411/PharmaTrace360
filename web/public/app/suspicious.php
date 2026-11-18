<?php
/**
 * PharmaTrace 360 - Suspicious Scans & Counterfeit Detection
 *
 * Shows QR codes that have exceeded the velocity scan threshold (> 5 scans),
 * indicating potential cloning, counterfeiting, or suspicious activity.
 * Reads strictly from view v_suspicious_codes.
 * Provides Admin/Regulator review status management (New, Reviewed, Blocked).
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole('Admin/Regulator');

$pdo = dbApp();
$suspicious = [];
$errorMsg = null;
$successMsg = null;

// Handle Review Status Update Action (Admin/Regulator only)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (($_SESSION['role_name'] ?? '') !== 'Admin/Regulator') {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Only regulators and administrators can update review status.</p></body></html>';
        exit;
    }

    if (!verifyCsrf()) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Invalid security token.</p></body></html>';
        exit;
    }

    $targetCode = trim((string)($_POST['code'] ?? ''));
    $newStatus  = trim((string)($_POST['review_status'] ?? ''));
    $userId     = (int)($_SESSION['user_id'] ?? 0);

    $allowedStatuses = ['New', 'Reviewed', 'Blocked'];

    if ($targetCode === '') {
        $errorMsg = 'Scanned code is required.';
    } elseif (!in_array($newStatus, $allowedStatuses, true)) {
        $errorMsg = 'Invalid review status. Allowed values: New, Reviewed, Blocked.';
    } else {
        try {
            $stmt = $pdo->prepare('CALL sp_update_suspicious_review(?, ?, ?)');
            $stmt->execute([$targetCode, $newStatus, $userId]);
            $stmt->closeCursor();
            $successMsg = "Review status for code {$targetCode} updated to {$newStatus}.";
        } catch (Throwable $e) {
            logAppError($e);
            $errorMsg = 'Could not update review status. Please try again.';
        }
    }
}

// Fetch Suspicious Codes
try {
    $stmt = $pdo->prepare('SELECT * FROM v_suspicious_codes ORDER BY scan_count DESC');
    $stmt->execute();
    $suspicious = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    $errorMsg = 'Could not load suspicious codes report.';
}

pageHeader('Suspicious Scans', 'Suspicious QR Code Alerts');
?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert" id="errorAlert">
        <div class="d-flex align-items-center gap-2">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
            <div><?= e($errorMsg) ?></div>
        </div>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<?php if ($successMsg): ?>
    <div class="alert alert-success alert-dismissible fade show mb-4" role="alert" id="successAlert">
        <div class="d-flex align-items-center gap-2">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            <div><?= e($successMsg) ?></div>
        </div>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
            <div>
                <h5 class="card-title fw-bold mb-1">Cloned / High-Frequency Scans</h5>
                <p class="text-muted small mb-0">
                    Codes scanned more than 10 times within 48 hours may indicate photocopied packaging or duplicate QR distribution. Admin/Regulator review statuses allow triage without altering public verification verdicts.
                </p>
            </div>
            <span class="badge bg-danger px-3 py-2"><?= count($suspicious) ?> Flagged Codes</span>
        </div>

        <?php if (empty($suspicious)): ?>
            <div class="alert alert-success mb-0">
                <strong>No suspicious scans detected.</strong> All scanned QR codes are within the configured velocity threshold (10 or fewer scans in 48 hours).
            </div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col">Scanned Code</th>
                            <th scope="col" class="text-center">Total Scans</th>
                            <th scope="col">First Scan Detected</th>
                            <th scope="col">Most Recent Scan</th>
                            <th scope="col" class="text-center">Review Status</th>
                            <th scope="col" class="text-center">Action</th>
                            <th scope="col" class="text-end">Verification</th>
                        </tr>
                    </thead>
                    <tbody class="small">
                        <?php foreach ($suspicious as $idx => $s): ?>
                            <?php
                                $curStatus = (string)($s['review_status'] ?? 'New');
                                $statusBadgeClass = match ($curStatus) {
                                    'Reviewed' => 'bg-success text-white',
                                    'Blocked'  => 'bg-danger text-white',
                                    default    => 'bg-warning text-dark',
                                };
                                $statusIcon = match ($curStatus) {
                                    'Reviewed' => '✓ ',
                                    'Blocked'  => '✕ ',
                                    default    => '● ',
                                };
                            ?>
                            <tr>
                                <td>
                                    <code class="fw-bold text-danger"><?= e($s['scanned_code']) ?></code>
                                </td>
                                <td class="text-center">
                                    <span class="badge bg-danger rounded-pill px-3 py-1 fs-6">
                                        <?= (int)$s['scan_count'] ?> scans
                                    </span>
                                </td>
                                <td class="text-muted"><?= e($s['first_scan']) ?></td>
                                <td class="text-muted"><?= e($s['last_scan']) ?></td>
                                <td class="text-center">
                                    <span class="badge <?= $statusBadgeClass ?> px-2 py-1 small fw-semibold">
                                        <?= $statusIcon ?><?= e($curStatus) ?>
                                    </span>
                                </td>
                                <td class="text-center">
                                    <form method="POST" action="suspicious.php" class="d-inline-flex align-items-center justify-content-center gap-1">
                                        <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                                        <input type="hidden" name="code" value="<?= e($s['scanned_code']) ?>">
                                        <label for="status_select_<?= $idx ?>" class="visually-hidden">
                                            Update review status for <?= e($s['scanned_code']) ?>
                                        </label>
                                        <select name="review_status" id="status_select_<?= $idx ?>" class="form-select form-select-sm" style="width: auto; min-width: 105px;">
                                            <option value="New" <?= $curStatus === 'New' ? 'selected' : '' ?>>New</option>
                                            <option value="Reviewed" <?= $curStatus === 'Reviewed' ? 'selected' : '' ?>>Reviewed</option>
                                            <option value="Blocked" <?= $curStatus === 'Blocked' ? 'selected' : '' ?>>Blocked</option>
                                        </select>
                                        <button type="submit" class="btn btn-sm btn-outline-primary px-2" title="Save review status">
                                            Save
                                        </button>
                                    </form>
                                </td>
                                <td class="text-end">
                                    <a href="/?code=<?= urlencode($s['scanned_code']) ?>" target="_blank" rel="noopener noreferrer" class="btn btn-sm btn-outline-danger">
                                        Verify in Portal &rarr;
                                    </a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php
pageFooter();
