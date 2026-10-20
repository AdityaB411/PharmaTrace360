<?php
/**
 * PharmaTrace 360 - Issue Product Recall (Admin / Regulator)
 *
 * Allows regulatory authorities to issue an urgent product recall.
 * Calls procedure sp_issue_recall(batch_number, reason, user_id).
 * Shows public impact assessment report upon success.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole('Admin/Regulator');

$pdo = dbApp();
$successMsg = null;
$errorMsg = null;
$impact = null;

// Clean up MySQL exception message to display friendly text
function friendlyDbError(Throwable $e): string
{
    $msg = $e->getMessage();
    if (preg_match('/1644\s+(.+)$/i', $msg, $m)) {
        return trim($m[1]);
    }
    if (str_contains($msg, 'SQLSTATE[45000]')) {
        $parts = explode(':', $msg);
        return trim(end($parts));
    }
    return 'Action could not be completed due to regulatory rule validation.';
}

// ─── Handle Recall Submission ────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if ($_SESSION['role_name'] !== 'Admin/Regulator') {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Only regulators can issue recalls.</p></body></html>';
        exit;
    }

    if (!verifyCsrf()) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Invalid security token.</p></body></html>';
        exit;
    }

    $batchNumber = trim($_POST['batch_number'] ?? '');
    $reason      = trim($_POST['reason'] ?? '');
    $userId      = (int)$_SESSION['user_id'];

    if ($batchNumber === '' || $reason === '') {
        $errorMsg = 'Batch number and recall reason are required.';
    } else {
        // Verify batch exists before calling the procedure
        $chkStmt = $pdo->prepare('SELECT batch_number, manufacturer FROM v_batch_overview WHERE batch_number = ? LIMIT 1');
        $chkStmt->execute([$batchNumber]);
        $targetBatch = $chkStmt->fetch(PDO::FETCH_ASSOC);
        $chkStmt->closeCursor();

        if (!$targetBatch) {
            $errorMsg = 'Batch not found.';
        } else {
            try {
                $stmt = $pdo->prepare('CALL sp_issue_recall(?, ?, ?)');
                $stmt->execute([$batchNumber, $reason, $userId]);
                $impact = $stmt->fetch(PDO::FETCH_ASSOC);
                $stmt->closeCursor();

                $successMsg = "Recall successfully issued for batch {$batchNumber}.";
            } catch (Throwable $e) {
                logAppError($e);
                $errorMsg = friendlyDbError($e);
            }
        }
    }
}

// Fetch list of non-recalled batches to assist selection
$availableBatches = [];
try {
    $stmt = $pdo->prepare("SELECT batch_number, medicine, manufacturer, status FROM v_batch_overview WHERE status != 'Recalled' ORDER BY batch_number ASC");
    $stmt->execute();
    $availableBatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
}

pageHeader('Issue Recall', 'Regulatory Product Recall');
?>

<?php if ($successMsg): ?>
    <div class="alert alert-success alert-dismissible fade show mb-4" role="alert" id="recallSuccess">
        <strong>Confirmed:</strong> <?= e($successMsg) ?>
    </div>
<?php endif; ?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert" id="recallError">
        <strong>Notice:</strong> <?= e($errorMsg) ?>
    </div>
<?php endif; ?>

<?php if ($impact): ?>
<!-- Post-Recall Impact Assessment Report -->
<div class="card shadow-sm border-danger border-2 mb-4">
    <div class="card-header bg-danger text-white py-3">
        <h5 class="card-title mb-0 fw-bold">Recall Impact Assessment Report</h5>
    </div>
    <div class="card-body p-4">
        <p class="text-muted mb-4">
            The batch has been placed under status <strong>Recalled</strong> in the central database.
            Consumer scans for this batch will now display an immediate <strong>Recalled</strong> warning badge.
        </p>

        <div class="row g-4">
            <div class="col-sm-6 col-md-4">
                <div class="text-muted small">Batch Number</div>
                <div class="fw-bold fs-5 text-danger"><?= e($impact['batch_number'] ?? '') ?></div>
            </div>
            <div class="col-sm-6 col-md-4">
                <div class="text-muted small">Medicine Brand</div>
                <div class="fw-bold fs-5"><?= e($impact['medicine'] ?? '') ?></div>
            </div>
            <div class="col-sm-6 col-md-4">
                <div class="text-muted small">Raw Material Supplier</div>
                <div class="fw-semibold"><?= e($impact['supplier'] ?? 'N/A') ?></div>
            </div>
            <div class="col-sm-6 col-md-4">
                <div class="text-muted small">Certificate of Analysis</div>
                <div><code><?= e($impact['certificate_number'] ?? 'N/A') ?></code></div>
            </div>
            <div class="col-sm-6 col-md-4">
                <div class="text-muted small">Total QR Codes in Circulation</div>
                <div class="fw-bold fs-5 text-primary"><?= (int)($impact['qr_count'] ?? 0) ?> units</div>
            </div>
            <div class="col-sm-6 col-md-4">
                <div class="text-muted small">Prior Consumer Scans</div>
                <div class="fw-bold fs-5 text-warning"><?= (int)($impact['total_scans'] ?? 0) ?> scans logged</div>
            </div>
        </div>

        <div class="mt-4 pt-3 border-top d-flex gap-2">
            <a href="/app/audit.php" class="btn btn-sm btn-outline-secondary">View in Audit Trail</a>
            <a href="/app/all_batches.php" class="btn btn-sm btn-outline-primary">Return to All Batches</a>
        </div>
    </div>
</div>
<?php endif; ?>

<div class="row g-4">
    <!-- Recall Form -->
    <div class="col-lg-7">
        <div class="card shadow-sm border-0">
            <div class="card-body p-4">
                <h5 class="fw-bold mb-3">Initiate Recall Order</h5>
                <form method="POST" action="recall.php" id="recallForm">
                    <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">

                    <div class="mb-3">
                        <label for="batch_number" class="form-label fw-medium">Batch Number</label>
                        <input type="text" name="batch_number" id="batch_number" class="form-control"
                               placeholder="e.g. BT-2026-001" required
                               value="<?= e($_POST['batch_number'] ?? '') ?>" list="batchList">
                        <datalist id="batchList">
                            <?php foreach ($availableBatches as $ab): ?>
                                <option value="<?= e($ab['batch_number']) ?>"><?= e($ab['medicine']) ?> (<?= e($ab['manufacturer']) ?> - <?= e($ab['status']) ?>)</option>
                            <?php endforeach; ?>
                        </datalist>
                        <div class="form-text small">Enter or select the production batch to recall.</div>
                    </div>

                    <div class="mb-4">
                        <label for="reason" class="form-label fw-medium">Reason for Recall</label>
                        <textarea name="reason" id="reason" rows="4" class="form-control" required
                                  placeholder="State the regulatory basis, quality deviation, or contamination notice..."><?= e($_POST['reason'] ?? '') ?></textarea>
                        <div class="form-text small">This reason will be stored in the immutable Product_Recalls audit record.</div>
                    </div>

                    <button type="submit" class="btn btn-danger px-4" onclick="return confirm('Are you sure you want to issue a recall for this batch? This action cannot be reversed.');">
                        Issue Recall Notice
                    </button>
                </form>
            </div>
        </div>
    </div>

    <!-- Regulatory Policy Notice -->
    <div class="col-lg-5">
        <div class="card shadow-sm border-0 bg-light">
            <div class="card-body p-4">
                <h6 class="fw-bold text-dark mb-2">Regulatory Protocol & Constraints</h6>
                <ul class="small text-muted ps-3 mb-0">
                    <li class="mb-2"><strong>Role Enforcement:</strong> Only active <em>Admin/Regulator</em> users are authorized by the database stored procedure to execute recalls.</li>
                    <li class="mb-2"><strong>Database Trigger Rule:</strong> Batch status is atomically set to <code>Recalled</code> and cannot be reverted to any other status.</li>
                    <li class="mb-2"><strong>Consumer Verification:</strong> Any subsequent public scans immediately report <code>Recalled</code> with safety advisories.</li>
                    <li><strong>Audit Logging:</strong> The action is logged to <code>Audit_Logs</code> with full timestamp and administrator ID.</li>
                </ul>
            </div>
        </div>
    </div>
</div>

<?php
pageFooter();
