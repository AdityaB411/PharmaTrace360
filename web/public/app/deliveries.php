<?php
/**
 * PharmaTrace 360 - Manufacturer Deliveries
 *
 * Displays inbound raw material deliveries for the current manufacturer.
 * Allows recording new deliveries via sp_record_delivery.
 * Access restricted strictly to Manufacturer role.
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

$successMsg = null;
$errorMsg   = null;

// ─── Handle Record Delivery Submission ──────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCsrf()) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>Invalid security token.</p></body></html>';
        exit;
    }

    $supplierName      = trim($_POST['supplier_name'] ?? '');
    $ingredientName    = trim($_POST['ingredient_name'] ?? '');
    $quantityKg        = (float)($_POST['quantity_kg'] ?? 0);
    $receivedDate      = trim($_POST['received_date'] ?? '');
    $certificateNumber = trim($_POST['certificate_number'] ?? '');

    if ($supplierName === '' || $ingredientName === '' || $certificateNumber === '' || $receivedDate === '') {
        $errorMsg = 'All fields are required to record a delivery.';
    } elseif ($quantityKg <= 0) {
        $errorMsg = 'Delivery quantity must be greater than zero.';
    } else {
        try {
            $stmt = $pdo->prepare('CALL sp_record_delivery(?, ?, ?, ?, ?, ?)');
            $stmt->execute([$userId, $supplierName, $ingredientName, $quantityKg, $receivedDate, $certificateNumber]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            $successMsg = $row['result'] ?? "Delivery recorded under certificate {$certificateNumber}.";
        } catch (Throwable $e) {
            logAppError($e);
            $errorMsg = friendlyDbError($e);
        }
    }
}

// ─── Load Form Options (from database views) ────────────────
$suppliers   = [];
$ingredients = [];
try {
    $suppliers = $pdo->query('SELECT supplier_name FROM v_form_suppliers')->fetchAll(PDO::FETCH_COLUMN);
    $ingredients = $pdo->query('SELECT ingredient_name FROM v_form_ingredients')->fetchAll(PDO::FETCH_COLUMN);
} catch (Throwable $e) {
    logAppError($e);
}

// ─── Load Current Deliveries for Manufacturer ────────────────
$deliveries = [];
try {
    $stmt = $pdo->prepare('SELECT * FROM v_my_deliveries WHERE manufacturer_id = ? ORDER BY received_date DESC, certificate_number ASC');
    $stmt->execute([$mfrId]);
    $deliveries = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    if (!$errorMsg) {
        $errorMsg = 'Could not load delivery records.';
    }
}

pageHeader('Material Deliveries', 'Material Deliveries - ' . ($mfrName ?: 'Manufacturer'));
?>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
    <div>
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb mb-1 small">
                <li class="breadcrumb-item"><a href="/app/batches.php" class="text-decoration-none">My Batches</a></li>
                <li class="breadcrumb-item active" aria-current="page">Deliveries</li>
            </ol>
        </nav>
        <p class="text-muted small mb-0">Record and track raw active pharmaceutical ingredients (API) received at your facilities.</p>
    </div>
    <div class="d-flex gap-2">
        <a href="/app/batch_new.php" class="btn btn-outline-primary btn-sm d-inline-flex align-items-center gap-1">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            New Batch
        </a>
    </div>
</div>

<?php if ($successMsg): ?>
    <div class="alert alert-success alert-dismissible fade show" role="alert" id="successAlert">
        <strong>Success:</strong> <?= e($successMsg) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger alert-dismissible fade show" role="alert" id="errorAlert">
        <strong>Validation Error:</strong> <?= e($errorMsg) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<!-- Record Delivery Form Card -->
<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <h5 class="fw-bold mb-1">Record Inbound Delivery</h5>
        <p class="text-muted small mb-3">Add incoming material delivery accompanied by a supplier Certificate of Analysis (CoA).</p>

        <form method="POST" action="deliveries.php" id="recordDeliveryForm">
            <input type="hidden" name="csrf_token" value="<?= e(csrfToken()) ?>">

            <div class="row g-3 mb-3">
                <div class="col-md-6 col-lg-4">
                    <label for="supplier_name" class="form-label small fw-semibold">Supplier Name</label>
                    <select name="supplier_name" id="supplier_name" class="form-select form-select-sm" required>
                        <option value="">-- Select Qualified Supplier --</option>
                        <?php foreach ($suppliers as $s): ?>
                            <option value="<?= e($s) ?>" <?= (isset($_POST['supplier_name']) && $_POST['supplier_name'] === $s) ? 'selected' : '' ?>>
                                <?= e($s) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="col-md-6 col-lg-4">
                    <label for="ingredient_name" class="form-label small fw-semibold">Raw Material / Active Ingredient</label>
                    <select name="ingredient_name" id="ingredient_name" class="form-select form-select-sm" required>
                        <option value="">-- Select Ingredient --</option>
                        <?php foreach ($ingredients as $ing): ?>
                            <option value="<?= e($ing) ?>" <?= (isset($_POST['ingredient_name']) && $_POST['ingredient_name'] === $ing) ? 'selected' : '' ?>>
                                <?= e($ing) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="col-md-4 col-lg-4">
                    <label for="quantity_kg" class="form-label small fw-semibold">Delivered Quantity (kg)</label>
                    <input type="number" step="0.001" min="0.001" name="quantity_kg" id="quantity_kg"
                           class="form-control form-control-sm"
                           value="<?= isset($_POST['quantity_kg']) ? e((string)$_POST['quantity_kg']) : '' ?>"
                           placeholder="e.g. 100.000" required>
                </div>

                <div class="col-md-4 col-lg-4">
                    <label for="received_date" class="form-label small fw-semibold">Received Date</label>
                    <input type="date" max="<?= date('Y-m-d') ?>" name="received_date" id="received_date"
                           class="form-control form-control-sm"
                           value="<?= isset($_POST['received_date']) ? e((string)$_POST['received_date']) : date('Y-m-d') ?>" required>
                    <div class="form-text small">Cannot be in the future.</div>
                </div>

                <div class="col-md-8 col-lg-8">
                    <label for="certificate_number" class="form-label small fw-semibold">Certificate Number / CoA</label>
                    <input type="text" name="certificate_number" id="certificate_number"
                           class="form-control form-control-sm font-monospace"
                           value="<?= isset($_POST['certificate_number']) ? e((string)$_POST['certificate_number']) : '' ?>"
                           placeholder="e.g. COA-2026-API-099" maxlength="60" required>
                    <div class="form-text small">Unique certificate identifier from manufacturer test laboratory.</div>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-sm px-4">
                Record Delivery
            </button>
        </form>
    </div>
</div>

<!-- Current Deliveries Inventory Card -->
<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
            <div>
                <h5 class="fw-bold mb-1">Company Delivery Inventory</h5>
                <p class="text-muted small mb-0">Balance of active ingredients available for production linking.</p>
            </div>
            <span class="badge bg-secondary px-3 py-2"><?= count($deliveries) ?> Delivery Records</span>
        </div>

        <?php if (empty($deliveries)): ?>
            <div class="alert alert-light border small text-muted mb-0">
                No material deliveries recorded for your manufacturer account yet. Use the form above to add your first delivery.
            </div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col">Certificate No.</th>
                            <th scope="col">Raw Material</th>
                            <th scope="col">Supplier</th>
                            <th scope="col">Received Date</th>
                            <th scope="col" class="text-end">Delivered (kg)</th>
                            <th scope="col" class="text-end">Used (kg)</th>
                            <th scope="col" class="text-end">Remaining (kg)</th>
                            <th scope="col" class="text-center">Status</th>
                        </tr>
                    </thead>
                    <tbody class="small">
                        <?php foreach ($deliveries as $d):
                            $delivKg = (float)$d['quantity_kg'];
                            $usedKg  = (float)$d['used_kg'];
                            $remKg   = (float)$d['remaining_kg'];
                            $isExhausted = ($remKg <= 0.0001);
                        ?>
                            <tr>
                                <td><code class="fw-bold text-dark"><?= e($d['certificate_number']) ?></code></td>
                                <td class="fw-semibold text-primary"><?= e($d['ingredient_name']) ?></td>
                                <td><?= e($d['supplier_name']) ?></td>
                                <td><?= e($d['received_date']) ?></td>
                                <td class="text-end"><?= number_format($delivKg, 3) ?></td>
                                <td class="text-end text-muted"><?= number_format($usedKg, 3) ?></td>
                                <td class="text-end fw-bold <?= $isExhausted ? 'text-danger' : 'text-success' ?>">
                                    <?= number_format($remKg, 3) ?>
                                </td>
                                <td class="text-center">
                                    <?php if ($isExhausted): ?>
                                        <span class="badge bg-secondary rounded-pill px-2 py-1">Fully Consumed</span>
                                    <?php else: ?>
                                        <span class="badge bg-success rounded-pill px-2 py-1">Available</span>
                                    <?php endif; ?>
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
