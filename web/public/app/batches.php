<?php
/**
 * PharmaTrace 360 - Manufacturer Batches
 *
 * Displays batches owned by the currently logged-in manufacturer.
 * Reads solely from view v_batch_overview filtered by manufacturer name.
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

$mfrName = $_SESSION['manufacturer_name'] ?? '';
$batches = [];
$errorMsg = null;

try {
    $pdo = dbApp();
    $stmt = $pdo->prepare('SELECT * FROM v_batch_overview WHERE manufacturer_id = ? ORDER BY manufacture_date DESC');
    $stmt->execute([$mfrId]);
    $batches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    $errorMsg = 'Could not load batches. Please try again.';
}

pageHeader('My Batches', 'My Batches - ' . ($mfrName ?: 'Manufacturer'));
?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger" role="alert"><?= e($errorMsg) ?></div>
<?php endif; ?>

<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
            <div>
                <h5 class="card-title fw-bold mb-1">Production Batches</h5>
                <p class="text-muted small mb-0">Overview of batches manufactured at your facilities.</p>
            </div>
            <span class="badge bg-primary px-3 py-2"><?= count($batches) ?> Total Batches</span>
        </div>

        <?php if (empty($batches)): ?>
            <div class="alert alert-info mb-0">No batches found for your manufacturer account.</div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th scope="col">Batch Number</th>
                            <th scope="col">Medicine</th>
                            <th scope="col">Factory</th>
                            <th scope="col">Status</th>
                            <th scope="col">Mfg Date</th>
                            <th scope="col">Expiry Date</th>
                            <th scope="col" class="text-center">QR Codes</th>
                            <th scope="col" class="text-end">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($batches as $b): ?>
                            <?php
                            $status = $b['status'];
                            $badgeClass = match ($status) {
                                'Approved' => 'bg-success',
                                'Pending'  => 'bg-warning text-dark',
                                'Recalled' => 'bg-danger',
                                'Rejected' => 'bg-secondary',
                                default    => 'bg-dark',
                            };
                            ?>
                            <tr>
                                <td>
                                    <a href="/app/batch_detail.php?batch=<?= urlencode($b['batch_number']) ?>" class="fw-bold text-decoration-none text-primary">
                                        <?= e($b['batch_number']) ?>
                                    </a>
                                </td>
                                <td><?= e($b['medicine']) ?></td>
                                <td class="small text-muted"><?= e($b['factory']) ?></td>
                                <td>
                                    <span class="badge <?= $badgeClass ?> rounded-pill px-3 py-1"><?= e($status) ?></span>
                                </td>
                                <td class="small"><?= e($b['manufacture_date']) ?></td>
                                <td class="small"><?= e($b['expiry_date']) ?></td>
                                <td class="text-center fw-medium"><?= (int)$b['qr_count'] ?></td>
                                <td class="text-end">
                                    <a href="/app/batch_detail.php?batch=<?= urlencode($b['batch_number']) ?>" class="btn btn-sm btn-outline-primary">
                                        View Details
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
