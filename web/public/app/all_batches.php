<?php
/**
 * PharmaTrace 360 - All Production Batches (Admin / Regulator)
 *
 * Provides full visibility into all batches across all manufacturers.
 * Reads strictly from view v_batch_overview.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole('Admin/Regulator');

$pdo = dbApp();
$batches = [];
$errorMsg = null;

try {
    $stmt = $pdo->prepare('SELECT * FROM v_batch_overview ORDER BY manufacture_date DESC');
    $stmt->execute();
    $batches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    $errorMsg = 'Could not load batches.';
}

pageHeader('All Batches', 'All Production Batches');
?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger" role="alert"><?= e($errorMsg) ?></div>
<?php endif; ?>

<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
            <div>
                <h5 class="card-title fw-bold mb-1">System-Wide Batch Registry</h5>
                <p class="text-muted small mb-0">Total of <?= count($batches) ?> production batches across all pharmaceutical manufacturers.</p>
            </div>
            <a href="/app/recall.php" class="btn btn-sm btn-outline-danger">Issue Recall</a>
        </div>

        <?php if (empty($batches)): ?>
            <div class="alert alert-info mb-0">No batches recorded in the database.</div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col">Batch Number</th>
                            <th scope="col">Medicine</th>
                            <th scope="col">Manufacturer</th>
                            <th scope="col">Factory</th>
                            <th scope="col">Status</th>
                            <th scope="col">Mfg Date</th>
                            <th scope="col">Expiry Date</th>
                            <th scope="col" class="text-center">QR Codes</th>
                            <th scope="col" class="text-end">Action</th>
                        </tr>
                    </thead>
                    <tbody class="small">
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
                                <td><?= e($b['manufacturer']) ?></td>
                                <td class="text-muted"><?= e($b['factory']) ?></td>
                                <td>
                                    <span class="badge <?= $badgeClass ?> px-2 py-1"><?= e($status) ?></span>
                                </td>
                                <td><?= e($b['manufacture_date']) ?></td>
                                <td><?= e($b['expiry_date']) ?></td>
                                <td class="text-center fw-semibold"><?= (int)$b['qr_count'] ?></td>
                                <td class="text-end">
                                    <a href="/app/batch_detail.php?batch=<?= urlencode($b['batch_number']) ?>" class="btn btn-sm btn-outline-secondary">
                                        Inspect
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
