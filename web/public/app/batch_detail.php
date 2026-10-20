<?php
/**
 * PharmaTrace 360 - Batch Detail, Traceability & QA Management
 *
 * Shows full batch details, material traceability, and QA test history.
 * Provides forms for authorized manufacturers to record QA tests, approve,
 * or reject the batch.
 * All logic and permissions are enforced by the database layer.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole(['Manufacturer', 'Admin/Regulator']);

$role = $_SESSION['role_name'] ?? '';
$isManufacturer = ($role === 'Manufacturer');
$mfrId = (int)($_SESSION['manufacturer_id'] ?? 0);

if ($isManufacturer && $mfrId <= 0) {
    http_response_code(403);
    echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>No manufacturer associated with this account.</p></body></html>';
    exit;
}

$batchNumber = trim($_POST['batch_number'] ?? $_GET['batch'] ?? '');
if ($batchNumber === '') {
    header('Location: ' . ($isManufacturer ? '/app/batches.php' : '/app/all_batches.php'));
    exit;
}

$pdo = dbApp();

// ─── Ownership Verification on Read & Initial Lookup ──────────
// For Manufacturer: MUST filter by manufacturer_id, never by name.
// Admin/Regulator may view all batches.
$batch = null;
try {
    if ($isManufacturer) {
        $stmt = $pdo->prepare('SELECT * FROM v_batch_overview WHERE batch_number = ? AND manufacturer_id = ? LIMIT 1');
        $stmt->execute([$batchNumber, $mfrId]);
    } else {
        $stmt = $pdo->prepare('SELECT * FROM v_batch_overview WHERE batch_number = ? LIMIT 1');
        $stmt->execute([$batchNumber]);
    }
    $batch = $stmt->fetch(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
}

// If batch does not exist or does not belong to the manufacturer:
// Show plain "Batch not found" page with HTTP 404 and show NO data.
if (!$batch) {
    http_response_code(404);
    echo '<!DOCTYPE html><html><head><title>Batch Not Found</title></head><body><h1>404 Batch Not Found</h1><p>Batch not found.</p></body></html>';
    exit;
}

$successMsg = null;
$errorMsg = null;

// Clean up MySQL exception message to display friendly text
function friendlyDbError(Throwable $e): string
{
    $msg = $e->getMessage();
    // Typical PDO format: "SQLSTATE[45000]: <<custom error>>: 1644 Actual text"
    if (preg_match('/1644\s+(.+)$/i', $msg, $m)) {
        return trim($m[1]);
    }
    if (str_contains($msg, 'SQLSTATE[45000]')) {
        $parts = explode(':', $msg);
        return trim(end($parts));
    }
    return 'Action could not be completed due to business rule validation.';
}

// ─── Handle Form Submissions (Manufacturer only) ─────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 1. Verify role: an admin opening/submitting batch forms must return 403
    if (!$isManufacturer) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Only manufacturers can manage batches.</p></body></html>';
        exit;
    }

    // 2. Verify CSRF token
    if (!verifyCsrf()) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Invalid security token.</p></body></html>';
        exit;
    }

    // 3. Batch ownership was verified above ($batch was found matching $mfrId).
    // Now call the appropriate stored procedure.
    $action = $_POST['action'] ?? '';
    $userId = (int)$_SESSION['user_id'];

    if ($action === 'record_test') {
        $purity = (float)($_POST['purity'] ?? 0);
        $dissolution = (float)($_POST['dissolution'] ?? 0);
        $weightVar = (float)($_POST['weight_variation'] ?? 0);
        $result = trim($_POST['result'] ?? '');
        $remarks = trim($_POST['remarks'] ?? '');

        if (!in_array($result, ['Pass', 'Fail'], true)) {
            $errorMsg = 'Test result must be Pass or Fail.';
        } else {
            try {
                $stmt = $pdo->prepare('CALL sp_record_test(?, ?, ?, ?, ?, ?, ?)');
                $stmt->execute([$batchNumber, $userId, $purity, $dissolution, $weightVar, $result, $remarks]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                $stmt->closeCursor();
                $successMsg = $row['result'] ?? 'Quality test report recorded successfully.';
            } catch (Throwable $e) {
                logAppError($e);
                $errorMsg = friendlyDbError($e);
            }
        }
    } elseif ($action === 'approve_batch') {
        $packCount = (int)($_POST['pack_count'] ?? 10);
        if ($packCount < 1 || $packCount > 50) {
            $errorMsg = 'Pack count must be between 1 and 50.';
        } else {
            try {
                $stmt = $pdo->prepare('CALL sp_approve_batch(?, ?, ?)');
                $stmt->execute([$batchNumber, $userId, $packCount]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                $stmt->closeCursor();
                $successMsg = $row['result'] ?? 'Batch approved and QR codes generated.';
            } catch (Throwable $e) {
                logAppError($e);
                $errorMsg = friendlyDbError($e);
            }
        }
    } elseif ($action === 'reject_batch') {
        try {
            $stmt = $pdo->prepare('CALL sp_reject_batch(?, ?)');
            $stmt->execute([$batchNumber, $userId]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            $successMsg = $row['result'] ?? 'Batch rejected successfully.';
        } catch (Throwable $e) {
            logAppError($e);
            $errorMsg = friendlyDbError($e);
        }
    } elseif ($action === 'add_material') {
        $certNum = trim($_POST['certificate_number'] ?? '');
        $quantityUsed = (float)($_POST['quantity_used_kg'] ?? 0);

        if ($certNum === '' || $quantityUsed <= 0) {
            $errorMsg = 'Please select a delivery certificate and enter a quantity greater than zero.';
        } else {
            try {
                $stmt = $pdo->prepare('CALL sp_add_batch_material(?, ?, ?, ?)');
                $stmt->execute([$userId, $batchNumber, $certNum, $quantityUsed]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                $stmt->closeCursor();
                $successMsg = $row['result'] ?? "Material linked to batch {$batchNumber}.";
            } catch (Throwable $e) {
                logAppError($e);
                $errorMsg = friendlyDbError($e);
            }
        }
    }

    // Refresh batch overview after action
    try {
        $stmt = $pdo->prepare('SELECT * FROM v_batch_overview WHERE batch_number = ? AND manufacturer_id = ? LIMIT 1');
        $stmt->execute([$batchNumber, $mfrId]);
        $batch = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();
    } catch (Throwable $e) {
        logAppError($e);
    }
}

// ─── Load Traceability and Test Reports ──────────────────────
$traceability = [];
$tests = [];

try {
    // Traceability
    $stmt = $pdo->prepare('SELECT * FROM v_batch_traceability WHERE batch_number = ?');
    $stmt->execute([$batchNumber]);
    $traceability = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();

    // QA Tests
    $stmt = $pdo->prepare('SELECT * FROM v_batch_tests WHERE batch_number = ? ORDER BY test_date DESC');
    $stmt->execute([$batchNumber]);
    $tests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    $errorMsg = 'Could not load batch details.';
}

// ─── Load Batch Timeline History ─────────────────────────────
$timeline = [];
try {
    $stmt = $pdo->prepare(
        'SELECT event_time, event_type, description
           FROM v_batch_timeline
          WHERE batch_number = ?
          ORDER BY event_time ASC'
    );
    $stmt->execute([$batchNumber]);
    $timeline = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
}

$status = $batch['status'];
$badgeClass = match ($status) {
    'Approved' => 'bg-success',
    'Pending'  => 'bg-warning text-dark',
    'Recalled' => 'bg-danger',
    'Rejected' => 'bg-secondary',
    default    => 'bg-dark',
};

// Forms are ONLY available to the owning Manufacturer
$canManage = $isManufacturer;

// QR codes section is visible for Approved and Recalled batches:
// Manufacturer owner only, or Admin/Regulator
$canViewQr = in_array($status, ['Approved', 'Recalled'], true)
    && (!$isManufacturer || ((int)($batch['manufacturer_id'] ?? 0) === $mfrId) || $role === 'Admin/Regulator');

$qrCodes = [];
$config = getAppConfig();
$publicBaseUrl = rtrim((string)($config['PUBLIC_BASE_URL'] ?? 'http://localhost:8000'), '/');

if ($canViewQr) {
    try {
        if ($isManufacturer) {
            $stmt = $pdo->prepare('SELECT * FROM v_batch_qr_codes WHERE batch_number = ? AND manufacturer_id = ? ORDER BY issued_at ASC, qr_code ASC');
            $stmt->execute([$batchNumber, $mfrId]);
        } else {
            $stmt = $pdo->prepare('SELECT * FROM v_batch_qr_codes WHERE batch_number = ? ORDER BY issued_at ASC, qr_code ASC');
            $stmt->execute([$batchNumber]);
        }
        $qrCodes = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $stmt->closeCursor();
    } catch (Throwable $e) {
        logAppError($e);
    }
}

// Available deliveries for linking (for Manufacturer on Pending batch)
$availableDeliveries = [];
if ($canManage && $status === 'Pending') {
    try {
        $stmt = $pdo->prepare('SELECT certificate_number, ingredient_name, supplier_name, remaining_kg FROM v_my_deliveries WHERE manufacturer_id = ? AND remaining_kg > 0 ORDER BY received_date DESC, certificate_number ASC');
        $stmt->execute([$mfrId]);
        $availableDeliveries = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $stmt->closeCursor();
    } catch (Throwable $e) {
        logAppError($e);
    }
}

pageHeader('Batch ' . $batchNumber, 'Batch ' . $batchNumber . ' Details');
?>

<div class="mb-3">
    <a href="<?= $isManufacturer ? '/app/batches.php' : '/app/all_batches.php' ?>" class="btn btn-outline-secondary btn-sm">
        &larr; Back to <?= $isManufacturer ? 'My Batches' : 'All Batches' ?>
    </a>
</div>

<?php if ($successMsg): ?>
    <div class="alert alert-success alert-dismissible fade show" role="alert" id="successAlert">
        <strong>Success:</strong> <?= e($successMsg) ?>
    </div>
<?php endif; ?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger alert-dismissible fade show" role="alert" id="errorAlert">
        <strong>Rule Check / Error:</strong> <?= e($errorMsg) ?>
    </div>
<?php endif; ?>

<!-- Batch Summary Card -->
<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
            <div>
                <h4 class="fw-bold mb-1"><?= e($batch['medicine']) ?></h4>
                <div class="text-muted small">Batch: <strong><?= e($batch['batch_number']) ?></strong></div>
            </div>
            <span class="badge <?= $badgeClass ?> fs-6 px-3 py-2"><?= e($status) ?></span>
        </div>

        <div class="row g-3 mt-1">
            <div class="col-sm-6 col-md-3">
                <div class="text-muted small">Manufacturer</div>
                <div class="fw-semibold"><?= e($batch['manufacturer']) ?></div>
            </div>
            <div class="col-sm-6 col-md-3">
                <div class="text-muted small">Manufacturing Facility</div>
                <div class="fw-semibold"><?= e($batch['factory']) ?></div>
            </div>
            <div class="col-sm-6 col-md-3">
                <div class="text-muted small">Manufacture Date</div>
                <div class="fw-semibold"><?= e($batch['manufacture_date']) ?></div>
            </div>
            <div class="col-sm-6 col-md-3">
                <div class="text-muted small">Expiry Date</div>
                <div class="fw-semibold"><?= e($batch['expiry_date']) ?></div>
            </div>
            <div class="col-sm-6 col-md-3">
                <div class="text-muted small">Issued QR Codes</div>
                <div class="fw-semibold fs-5 text-primary"><?= (int)$batch['qr_count'] ?></div>
            </div>
        </div>
    </div>
</div>

<?php if ($canViewQr): ?>
<!-- QR Codes Section (Manufacturer owner or Admin/Regulator for Approved & Recalled batches) -->
<div class="card shadow-sm border-0 mb-4" id="qrCodesSection">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
            <div>
                <h5 class="fw-bold mb-1">QR Codes &amp; Serial Unit Verification</h5>
                <p class="text-muted small mb-0">
                    Serialized pack codes for public authentication. Each code encodes <code><?= e($publicBaseUrl) ?>/?code=&lt;code&gt;</code>
                </p>
            </div>
            <div class="d-flex align-items-center gap-2">
                <span class="badge bg-primary px-3 py-2"><?= count($qrCodes) ?> Codes Issued</span>
                <?php if (!empty($qrCodes)): ?>
                    <a href="/app/qr_sheet.php?batch=<?= urlencode($batchNumber) ?>" target="_blank" class="btn btn-outline-primary btn-sm">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1" aria-hidden="true">
                            <polyline points="6 9 6 2 18 2 18 9"></polyline>
                            <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                            <rect x="6" y="14" width="12" height="8"></rect>
                        </svg>
                        Print QR Sheet
                    </a>
                <?php endif; ?>
            </div>
        </div>

        <?php if (empty($qrCodes)): ?>
            <div class="alert alert-light border small text-muted mb-0">
                No QR codes have been issued for this batch yet.
            </div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col" style="width: 100px;">QR Image</th>
                            <th scope="col">Code String</th>
                            <th scope="col">Issued At</th>
                            <th scope="col" class="text-center">Scan Count</th>
                            <th scope="col">Last Scan</th>
                            <th scope="col" class="text-end">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="small">
                        <?php foreach ($qrCodes as $qr):
                            $codeVal = $qr['qr_code'];
                            $checkUrl = $publicBaseUrl . '/?code=' . urlencode($codeVal);
                        ?>
                            <tr>
                                <td>
                                    <div class="qr-canvas d-inline-flex align-items-center justify-content-center p-1 bg-white border rounded shadow-sm"
                                         data-qr-payload="<?= e($checkUrl) ?>"
                                         style="width: 82px; height: 82px;"
                                         title="Scan with phone camera">
                                    </div>
                                </td>
                                <td>
                                    <code class="fw-bold text-dark fs-6"><?= e($codeVal) ?></code>
                                </td>
                                <td><?= e($qr['issued_at']) ?></td>
                                <td class="text-center">
                                    <?php if ((int)$qr['scan_count'] > 5): ?>
                                        <span class="badge bg-danger px-2 py-1" title="High scan count: potentially suspicious"><?= (int)$qr['scan_count'] ?> scans</span>
                                    <?php elseif ((int)$qr['scan_count'] > 0): ?>
                                        <span class="badge bg-info text-dark px-2 py-1"><?= (int)$qr['scan_count'] ?> scans</span>
                                    <?php else: ?>
                                        <span class="badge bg-light text-secondary border px-2 py-1">0 scans</span>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <?= !empty($qr['last_scan']) ? e($qr['last_scan']) : '<span class="text-muted">Never scanned</span>' ?>
                                </td>
                                <td class="text-end">
                                    <div class="d-inline-flex gap-2">
                                        <a href="<?= e($checkUrl) ?>"
                                           target="_blank"
                                           rel="noopener noreferrer"
                                           class="btn btn-outline-primary btn-sm d-inline-flex align-items-center gap-1"
                                           title="Open public check page">
                                            Open public check
                                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></polyline><line x1="10" y1="14" x2="21" y2="3"></line></svg>
                                        </a>
                                        <button type="button"
                                                class="btn btn-outline-secondary btn-sm btn-copy-code"
                                                data-copy="<?= e($codeVal) ?>"
                                                title="Copy code string">
                                            Copy
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>

<!-- Manufacturer Management Actions (Only for Manufacturer role on Pending batch) -->
<?php if ($canManage && $status === 'Pending'): ?>
<!-- Add Material Form Card -->
<div class="card shadow-sm border-0 mb-4" id="addMaterialSection">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
            <div>
                <h5 class="fw-bold mb-1">Link Active Raw Material</h5>
                <p class="text-muted small mb-0">Select an inbound raw material delivery from your inventory to link to this batch.</p>
            </div>
            <a href="/app/deliveries.php" class="btn btn-outline-primary btn-sm">
                Manage Deliveries
            </a>
        </div>

        <?php if (empty($availableDeliveries)): ?>
            <div class="alert alert-light border small text-muted mb-0">
                No material deliveries with remaining balance found.
                <a href="/app/deliveries.php" class="fw-semibold text-primary">Record an inbound delivery</a> to link ingredients.
            </div>
        <?php else: ?>
            <form method="POST" action="batch_detail.php?batch=<?= urlencode($batchNumber) ?>" id="addMaterialForm">
                <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                <input type="hidden" name="action" value="add_material">
                <input type="hidden" name="batch_number" value="<?= e($batchNumber) ?>">

                <div class="row g-3 align-items-end">
                    <div class="col-md-7 col-lg-8">
                        <label for="certificate_number" class="form-label small fw-semibold">Delivery Certificate &amp; Ingredient</label>
                        <select name="certificate_number" id="certificate_number" class="form-select form-select-sm" required>
                            <option value="">-- Select Delivery (Certificate &bull; Ingredient &bull; Remaining) --</option>
                            <?php foreach ($availableDeliveries as $deliv): ?>
                                <option value="<?= e($deliv['certificate_number']) ?>">
                                    <?= e($deliv['certificate_number']) ?> &bull; <?= e($deliv['ingredient_name']) ?> (Remaining: <?= number_format((float)$deliv['remaining_kg'], 3) ?> kg &mdash; <?= e($deliv['supplier_name']) ?>)
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="col-md-3 col-lg-2">
                        <label for="quantity_used_kg" class="form-label small fw-semibold">Quantity Used (kg)</label>
                        <input type="number" step="0.001" min="0.001" name="quantity_used_kg" id="quantity_used_kg"
                               class="form-control form-control-sm" placeholder="e.g. 25.000" required>
                    </div>

                    <div class="col-md-2 col-lg-2">
                        <button type="submit" class="btn btn-primary btn-sm w-100">
                            Link Material
                        </button>
                    </div>
                </div>
            </form>
        <?php endif; ?>
    </div>
</div>

<div class="row g-4 mb-4">
    <!-- Record Test Form -->
    <div class="col-lg-7">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4">
                <h5 class="fw-bold mb-3">Record Quality Test Report</h5>
                <form method="POST" action="batch_detail.php?batch=<?= urlencode($batchNumber) ?>" id="recordTestForm">
                    <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                    <input type="hidden" name="action" value="record_test">
                    <input type="hidden" name="batch_number" value="<?= e($batchNumber) ?>">

                    <div class="row g-2 mb-3">
                        <div class="col-md-4">
                            <label class="form-label small fw-medium">Purity (%)</label>
                            <input type="number" step="0.01" min="0" max="100" name="purity" class="form-control form-control-sm" required placeholder="e.g. 99.20">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-medium">Dissolution (%)</label>
                            <input type="number" step="0.01" min="0" max="100" name="dissolution" class="form-control form-control-sm" required placeholder="e.g. 92.50">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-medium">Weight Var (%)</label>
                            <input type="number" step="0.01" min="0" max="100" name="weight_variation" class="form-control form-control-sm" required placeholder="e.g. 1.20">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-medium">Test Result</label>
                        <select name="result" class="form-select form-select-sm" required>
                            <option value="Pass">Pass</option>
                            <option value="Fail">Fail</option>
                        </select>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-medium">Remarks</label>
                        <textarea name="remarks" rows="2" class="form-control form-control-sm" placeholder="Enter QA lab notes..." required></textarea>
                    </div>

                    <button type="submit" class="btn btn-primary btn-sm px-3">Record Test Report</button>
                </form>
            </div>
        </div>
    </div>

    <!-- Approve or Reject Actions -->
    <div class="col-lg-5">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4 d-flex flex-column justify-content-between">
                <div>
                    <h5 class="fw-bold mb-2">Approve Batch</h5>
                    <p class="text-muted small mb-3">
                        Approval checks that the most recent QA test is <strong>Pass</strong>, sets status to <em>Approved</em>, and generates serial QR codes.
                    </p>
                    <form method="POST" action="batch_detail.php?batch=<?= urlencode($batchNumber) ?>" id="approveBatchForm" class="mb-4">
                        <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                        <input type="hidden" name="action" value="approve_batch">
                        <input type="hidden" name="batch_number" value="<?= e($batchNumber) ?>">

                        <div class="mb-3">
                            <label class="form-label small fw-medium">Pack Count (1 - 50)</label>
                            <input type="number" min="1" max="50" name="pack_count" value="10" class="form-control form-control-sm" required>
                        </div>

                        <button type="submit" class="btn btn-success btn-sm w-100" onclick="return confirm('Approve this batch and generate QR codes?');">
                            Approve Batch & Generate QR Codes
                        </button>
                    </form>
                </div>

                <div class="border-top pt-3">
                    <h6 class="fw-bold text-danger mb-1">Reject Batch</h6>
                    <p class="text-muted small mb-2">
                        Rejection requires the most recent test to be <strong>Fail</strong>.
                    </p>
                    <form method="POST" action="batch_detail.php?batch=<?= urlencode($batchNumber) ?>" id="rejectBatchForm">
                        <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">
                        <input type="hidden" name="action" value="reject_batch">
                        <input type="hidden" name="batch_number" value="<?= e($batchNumber) ?>">

                        <button type="submit" class="btn btn-outline-danger btn-sm w-100" onclick="return confirm('Are you sure you want to reject this batch?');">
                            Reject Batch
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>

<!-- Quality Test History -->
<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <h5 class="fw-bold mb-3">Quality Assurance Test Reports</h5>
        <?php if (empty($tests)): ?>
            <div class="alert alert-light border small text-muted mb-0">No quality test reports have been recorded for this batch yet.</div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col">Test Date</th>
                            <th scope="col">Result</th>
                            <th scope="col">Purity</th>
                            <th scope="col">Dissolution</th>
                            <th scope="col">Weight Var</th>
                            <th scope="col">Remarks</th>
                        </tr>
                    </thead>
                    <tbody class="small">
                        <?php foreach ($tests as $t): ?>
                            <tr>
                                <td><?= e($t['test_date']) ?></td>
                                <td>
                                    <span class="badge <?= $t['result'] === 'Pass' ? 'bg-success' : 'bg-danger' ?> px-2 py-1">
                                        <?= e($t['result']) ?>
                                    </span>
                                </td>
                                <td><?= number_format((float)$t['purity'], 2) ?>%</td>
                                <td><?= number_format((float)$t['dissolution'], 2) ?>%</td>
                                <td><?= number_format((float)$t['weight_variation'], 2) ?>%</td>
                                <td><?= e($t['remarks']) ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<!-- Material Traceability -->
<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <h5 class="fw-bold mb-3">Supply Chain Traceability</h5>
        <?php if (empty($traceability)): ?>
            <div class="alert alert-light border small text-muted mb-0">No raw material delivery records associated with this batch.</div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col">Raw Material</th>
                            <th scope="col">Supplier</th>
                            <th scope="col">Certificate No.</th>
                            <th scope="col">Delivered (kg)</th>
                            <th scope="col">Used (kg)</th>
                            <th scope="col">Received Date</th>
                        </tr>
                    </thead>
                    <tbody class="small">
                        <?php foreach ($traceability as $tr): ?>
                            <tr>
                                <td class="fw-semibold"><?= e($tr['material']) ?></td>
                                <td><?= e($tr['supplier']) ?></td>
                                <td><code><?= e($tr['certificate_number']) ?></code></td>
                                <td><?= number_format((float)$tr['delivered_kg'], 2) ?></td>
                                <td><?= number_format((float)$tr['used_kg'], 2) ?></td>
                                <td><?= e($tr['received_date']) ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>


<!-- Batch Lifecycle History Timeline -->
<div class="card shadow-sm border-0 mb-4" id="batchHistorySection">
    <div class="card-body p-4">
        <h5 class="fw-bold mb-4">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-2" aria-hidden="true">
                <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
            </svg>
            Batch Lifecycle History
        </h5>
        <?php if (empty($timeline)): ?>
            <p class="text-muted small mb-0">No timeline events found for this batch.</p>
        <?php else: ?>
            <div class="pt-timeline">
                <?php
                foreach ($timeline as $evt) {
                    $evtType = $evt['event_type'] ?? '';
                    // Map event_type to Bootstrap badge class and icon
                    [$badgeCls, $iconSvg, $labelTxt] = match (true) {
                        $evtType === 'BATCH_MANUFACTURED' => [
                            'bg-primary',
                            '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>',
                            'Manufactured',
                        ],
                        $evtType === 'MATERIAL_RECEIVED' => [
                            'bg-info',
                            '<rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/>',
                            'Material Received',
                        ],
                        $evtType === 'MATERIAL_LINKED' => [
                            'bg-secondary',
                            '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
                            'Material Linked',
                        ],
                        $evtType === 'QA_TEST' => [
                            'bg-warning text-dark',
                            '<path d="M14.5 10c-.83 0-1.5-.67-1.5-1.5v-5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5v5c0 .83-.67 1.5-1.5 1.5z"/><path d="M20.5 10H19V8.5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/><path d="M9.5 14c.83 0 1.5.67 1.5 1.5v5c0 .83-.67 1.5-1.5 1.5S8 21.33 8 20.5v-5c0-.83.67-1.5 1.5-1.5z"/><path d="M3.5 14H5v1.5c0 .83-.67 1.5-1.5 1.5S2 16.33 2 15.5 2.67 14 3.5 14z"/><path d="M14 14.5v1c0 .83-.67 1.5-1.5 1.5h-5c-.83 0-1.5-.67-1.5-1.5v-1c0-.83.67-1.5 1.5-1.5h5c.83 0 1.5.67 1.5 1.5z"/><path d="M15.5 8.5h1c.83 0 1.5.67 1.5 1.5v5c0 .83-.67 1.5-1.5 1.5h-1c-.83 0-1.5-.67-1.5-1.5v-5c0-.83.67-1.5 1.5-1.5z"/>',
                            'QA Test',
                        ],
                        $evtType === 'QR_ISSUED' => [
                            'bg-success',
                            '<polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><line x1="12" y1="22" x2="12" y2="7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/>',
                            'QR Codes Issued',
                        ],
                        str_starts_with($evtType, 'STATUS_RECALLED') || $evtType === 'RECALL_ISSUED' => [
                            'bg-danger',
                            '<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>',
                            'Recall',
                        ],
                        str_starts_with($evtType, 'STATUS_APPROVED') => [
                            'bg-success',
                            '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>',
                            'Approved',
                        ],
                        str_starts_with($evtType, 'STATUS_REJECTED') => [
                            'bg-dark',
                            '<circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>',
                            'Rejected',
                        ],
                        default => [
                            'bg-secondary',
                            '<circle cx="12" cy="12" r="10"/>',
                            e($evtType),
                        ],
                    };
                    $timeFormatted = $evt['event_time']
                        ? date('d M Y, H:i', strtotime($evt['event_time']))
                        : '';
                ?>
                <div class="pt-timeline-item">
                    <div class="pt-timeline-dot">
                        <span class="badge rounded-circle p-2 <?= $badgeCls ?>">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                 stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                                <?= $iconSvg ?>
                            </svg>
                        </span>
                    </div>
                    <div class="pt-timeline-content">
                        <div class="d-flex align-items-center gap-2 mb-1">
                            <span class="badge <?= $badgeCls ?> small"><?= e($labelTxt) ?></span>
                            <span class="text-muted small"><?= e($timeFormatted) ?></span>
                        </div>
                        <div class="small text-secondary"><?= e($evt['description']) ?></div>
                    </div>
                </div>
                <?php } ?>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php if ($canViewQr && !empty($qrCodes)): ?>
<script src="/assets/vendor/qrcode/qrcode.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function () {
    // Render QR codes
    document.querySelectorAll('.qr-canvas').forEach(function (container) {
        var payload = container.getAttribute('data-qr-payload');
        if (payload) {
            new QRCode(container, {
                text: payload,
                width: 74,
                height: 74,
                colorDark: '#0f172a',
                colorLight: '#ffffff',
                correctLevel: QRCode.CorrectLevel.M
            });
        }
    });

    // Copy button with visual feedback
    document.querySelectorAll('.btn-copy-code').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var text = this.getAttribute('data-copy');
            if (!text) return;
            var origText = this.innerText;
            var button = this;

            var markCopied = function () {
                button.innerText = 'Copied!';
                button.classList.remove('btn-outline-secondary');
                button.classList.add('btn-success');
                setTimeout(function () {
                    button.innerText = origText;
                    button.classList.remove('btn-success');
                    button.classList.add('btn-outline-secondary');
                }, 1500);
            };

            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(markCopied).catch(function () {
                    fallbackCopy(text, markCopied);
                });
            } else {
                fallbackCopy(text, markCopied);
            }
        });
    });

    function fallbackCopy(text, cb) {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        try {
            document.execCommand('copy');
            cb();
        } catch (e) {
            console.error('Copy fallback failed', e);
        }
        document.body.removeChild(ta);
    }
});
</script>
<?php endif; ?>

<?php
pageFooter();
