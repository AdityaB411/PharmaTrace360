<?php
/**
 * PharmaTrace 360 - Create Production Batch
 *
 * Allows authenticated manufacturers to initiate a new production batch.
 * Medicines and factories are strictly filtered to the logged-in manufacturer.
 * Calls procedure sp_create_batch.
 * On success, redirects to batch_detail.php.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole('Manufacturer');

$mfrId = (int)($_SESSION['manufacturer_id'] ?? 0);
if ($mfrId <= 0) {
    http_response_code(403);
    echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>No manufacturer associated with this account.</p></body></html>';
    exit;
}

$userId  = (int)$_SESSION['user_id'];
$mfrName = $_SESSION['manufacturer_name'] ?? 'Manufacturer';
$pdo     = dbApp();

$errorMsg = null;

// ─── Handle Batch Creation Submission ────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCsrf()) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Invalid security token.</p></body></html>';
        exit;
    }

    $batchNumber     = trim($_POST['batch_number'] ?? '');
    $medicineName    = trim($_POST['medicine_name'] ?? '');
    $factoryName     = trim($_POST['factory_name'] ?? '');
    $quantity        = (int)($_POST['quantity'] ?? 0);
    $manufactureDate = trim($_POST['manufacture_date'] ?? '');
    $expiryDate      = trim($_POST['expiry_date'] ?? '');

    if ($batchNumber === '' || $medicineName === '' || $factoryName === '' || $manufactureDate === '' || $expiryDate === '') {
        $errorMsg = 'All fields are required to create a batch.';
    } elseif ($quantity <= 0) {
        $errorMsg = 'Batch quantity must be greater than zero units.';
    } elseif ($expiryDate <= $manufactureDate) {
        $errorMsg = 'Expiry date must be strictly after the manufacture date.';
    } else {
        try {
            $stmt = $pdo->prepare('CALL sp_create_batch(?, ?, ?, ?, ?, ?, ?)');
            $stmt->execute([
                $userId,
                $batchNumber,
                $medicineName,
                $factoryName,
                $quantity,
                $manufactureDate,
                $expiryDate,
            ]);
            $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            // Redirect on success to newly created batch details
            header('Location: /app/batch_detail.php?batch=' . urlencode($batchNumber));
            exit;
        } catch (Throwable $e) {
            logAppError($e);
            $errorMsg = friendlyDbError($e);
        }
    }
}

// ─── Load Form Options Filtered to Logged-in Manufacturer ───
$medicines = [];
$factories = [];
try {
    $medStmt = $pdo->prepare('SELECT brand_name FROM v_form_medicines WHERE manufacturer_id = ? ORDER BY brand_name');
    $medStmt->execute([$mfrId]);
    $medicines = $medStmt->fetchAll(PDO::FETCH_COLUMN);
    $medStmt->closeCursor();

    $facStmt = $pdo->prepare('SELECT factory_name FROM v_form_factories WHERE manufacturer_id = ? ORDER BY factory_name');
    $facStmt->execute([$mfrId]);
    $factories = $facStmt->fetchAll(PDO::FETCH_COLUMN);
    $facStmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    if (!$errorMsg) {
        $errorMsg = 'Could not load registered medicines and factories.';
    }
}

pageHeader('New Production Batch', 'New Production Batch - ' . ($mfrName ?: 'Manufacturer'));
?>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
    <div>
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb mb-1 small">
                <li class="breadcrumb-item"><a href="/app/batches.php" class="text-decoration-none">My Batches</a></li>
                <li class="breadcrumb-item active" aria-current="page">New Batch</li>
            </ol>
        </nav>
        <p class="text-muted small mb-0">Initialize a new pharmaceutical batch. Batches are created in Pending status.</p>
    </div>
    <div>
        <a href="/app/batches.php" class="btn btn-outline-secondary btn-sm">
            &larr; Back to My Batches
        </a>
    </div>
</div>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger alert-dismissible fade show" role="alert" id="errorAlert">
        <strong>Validation Error:</strong> <?= e($errorMsg) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<div class="row justify-content-center">
    <div class="col-lg-8">
        <div class="card shadow-sm border-0 mb-4">
            <div class="card-body p-4">
                <h5 class="fw-bold mb-1">Batch Specifications</h5>
                <p class="text-muted small mb-4">
                    Once created, link active ingredient deliveries and record lab QA test results before final approval.
                </p>

                <form method="POST" action="batch_new.php" id="createBatchForm">
                    <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">

                    <div class="row g-3 mb-3">
                        <div class="col-md-6">
                            <label for="batch_number" class="form-label small fw-semibold">Batch Number</label>
                            <input type="text" name="batch_number" id="batch_number"
                                   class="form-control font-monospace"
                                   value="<?= isset($_POST['batch_number']) ? e((string)$_POST['batch_number']) : '' ?>"
                                   placeholder="e.g. BT-2026-099" maxlength="40" required>
                            <div class="form-text small">Unique batch identifier for tracking and serialization.</div>
                        </div>

                        <div class="col-md-6">
                            <label for="quantity" class="form-label small fw-semibold">Target Units (Quantity)</label>
                            <input type="number" min="1" step="1" name="quantity" id="quantity"
                                   class="form-control"
                                   value="<?= isset($_POST['quantity']) ? e((string)$_POST['quantity']) : '' ?>"
                                   placeholder="e.g. 5000" required>
                            <div class="form-text small">Total packaged units produced in this batch.</div>
                        </div>

                        <div class="col-md-6">
                            <label for="medicine_name" class="form-label small fw-semibold">Medicine Brand</label>
                            <select name="medicine_name" id="medicine_name" class="form-select" required>
                                <option value="">-- Select Registered Medicine --</option>
                                <?php foreach ($medicines as $med): ?>
                                    <option value="<?= e($med) ?>" <?= (isset($_POST['medicine_name']) && $_POST['medicine_name'] === $med) ? 'selected' : '' ?>>
                                        <?= e($med) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                            <div class="form-text small">Only medicines registered under your company.</div>
                        </div>

                        <div class="col-md-6">
                            <label for="factory_name" class="form-label small fw-semibold">Manufacturing Facility</label>
                            <select name="factory_name" id="factory_name" class="form-select" required>
                                <option value="">-- Select Licensed Facility --</option>
                                <?php foreach ($factories as $fac): ?>
                                    <option value="<?= e($fac) ?>" <?= (isset($_POST['factory_name']) && $_POST['factory_name'] === $fac) ? 'selected' : '' ?>>
                                        <?= e($fac) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                            <div class="form-text small">Only licensed plants belonging to your manufacturer.</div>
                        </div>

                        <div class="col-md-6">
                            <label for="manufacture_date" class="form-label small fw-semibold">Manufacture Date</label>
                            <input type="date" max="<?= date('Y-m-d') ?>" name="manufacture_date" id="manufacture_date"
                                   class="form-control"
                                   value="<?= isset($_POST['manufacture_date']) ? e((string)$_POST['manufacture_date']) : date('Y-m-d') ?>" required>
                            <div class="form-text small">Cannot be in the future.</div>
                        </div>

                        <div class="col-md-6">
                            <label for="expiry_date" class="form-label small fw-semibold">Expiry Date</label>
                            <input type="date" name="expiry_date" id="expiry_date"
                                   class="form-control"
                                   value="<?= isset($_POST['expiry_date']) ? e((string)$_POST['expiry_date']) : date('Y-m-d', strtotime('+2 years')) ?>" required>
                            <div class="form-text small">Must be after the manufacture date.</div>
                        </div>
                    </div>

                    <div class="alert alert-light border small text-muted mb-4">
                        <strong>Lifecycle Note:</strong> New batches enter <em>Pending</em> status. You will be redirected to the batch detail page to link raw material delivery certificates and submit QA test reports prior to approval and QR code issuance.
                    </div>

                    <div class="d-flex justify-content-end gap-2">
                        <a href="/app/batches.php" class="btn btn-outline-secondary px-3">Cancel</a>
                        <button type="submit" class="btn btn-primary px-4 fw-semibold">
                            Create Batch &rarr;
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<?php
pageFooter();
