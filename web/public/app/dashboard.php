<?php
/**
 * PharmaTrace 360 - Admin / Regulator Dashboard
 *
 * Displays high-level system KPIs and batch status breakdown.
 * Reads strictly from views: v_dashboard and v_batch_status_counts.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole('Admin/Regulator');

$pdo = dbApp();
$kpis = [
    'approved_batches' => 0,
    'failed_tests'     => 0,
    'suspicious_scans' => 0,
    'recalls'          => 0,
];
$statusCounts = [];
$errorMsg = null;

try {
    // 1. KPI Numbers
    $stmt = $pdo->prepare('SELECT * FROM v_dashboard LIMIT 1');
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
    if ($row) {
        $kpis = $row;
    }

    // 2. Status counts
    $stmt = $pdo->prepare('SELECT status, batch_count FROM v_batch_status_counts');
    $stmt->execute();
    $statusCounts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    $errorMsg = 'Could not load dashboard statistics.';
}

pageHeader('Dashboard', 'System Overview & Regulator Metrics');
?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger" role="alert"><?= e($errorMsg) ?></div>
<?php endif; ?>

<!-- KPI Summary Cards -->
<div class="row g-3 mb-4">
    <div class="col-sm-6 col-lg-3">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4 text-center">
                <div class="text-muted small fw-medium text-uppercase mb-2">Approved Batches</div>
                <div class="display-5 fw-bold text-success mb-1"><?= (int)$kpis['approved_batches'] ?></div>
                <div class="small text-muted">Passed QA & serialized</div>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4 text-center">
                <div class="text-muted small fw-medium text-uppercase mb-2">Failed QA Tests</div>
                <div class="display-5 fw-bold text-warning mb-1"><?= (int)$kpis['failed_tests'] ?></div>
                <div class="small text-muted">Quality check anomalies</div>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4 text-center">
                <div class="text-muted small fw-medium text-uppercase mb-2">Suspicious Scans</div>
                <div class="display-5 fw-bold text-danger mb-1"><?= (int)$kpis['suspicious_scans'] ?></div>
                <div class="small text-muted">Counterfeit / scan velocity</div>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3">
        <a href="/app/recalls.php" class="text-decoration-none" id="kpiRecallsLink">
        <div class="card shadow-sm border-0 h-100 card-hover">
            <div class="card-body p-4 text-center">
                <div class="text-muted small fw-medium text-uppercase mb-2">Product Recalls</div>
                <div class="display-5 fw-bold text-danger mb-1"><?= (int)$kpis['recalls'] ?></div>
                <div class="small text-muted">Active regulatory recalls</div>
            </div>
        </div>
        </a>
    </div>
</div>

<div class="row g-4 mb-4">
    <!-- Batch Status Distribution -->
    <div class="col-lg-6">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4">
                <h5 class="fw-bold mb-3">Batch Status Distribution</h5>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light small">
                            <tr>
                                <th scope="col">Status</th>
                                <th scope="col" class="text-end">Count</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($statusCounts as $sc): ?>
                                <?php
                                $status = $sc['status'];
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
                                        <span class="badge <?= $badgeClass ?> px-3 py-1"><?= e($status) ?></span>
                                    </td>
                                    <td class="text-end fw-bold"><?= (int)$sc['batch_count'] ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Actions Navigation -->
    <div class="col-lg-6">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4">
                <h5 class="fw-bold mb-3">Regulatory Operations</h5>
                <div class="list-group list-group-flush">
                    <a href="/app/all_batches.php" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center py-3">
                        <div>
                            <div class="fw-semibold">All Production Batches</div>
                            <small class="text-muted">Inspect batches across all manufacturers</small>
                        </div>
                        <span class="btn btn-sm btn-outline-primary">&rarr;</span>
                    </a>
                    <a href="/app/suspicious.php" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center py-3">
                        <div>
                            <div class="fw-semibold">Suspicious Scan Alerts</div>
                            <small class="text-muted">High-frequency scans (> 5 scans)</small>
                        </div>
                        <span class="btn btn-sm btn-outline-danger">&rarr;</span>
                    </a>
                    <a href="/app/audit.php" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center py-3">
                        <div>
                            <div class="fw-semibold">Recent Audit Logs</div>
                            <small class="text-muted">Immutable system audit trail</small>
                        </div>
                        <span class="btn btn-sm btn-outline-secondary">&rarr;</span>
                    </a>
                    <a href="/app/recalls.php" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center py-3" id="navRecallMonitor">
                        <div>
                            <div class="fw-semibold text-danger">Recalled Batches Monitor</div>
                            <small class="text-muted">View all recalls &amp; post-recall scan activity</small>
                        </div>
                        <span class="btn btn-sm btn-outline-danger">&rarr;</span>
                    </a>
                    <a href="/app/recall.php" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center py-3">
                        <div>
                            <div class="fw-semibold text-danger">Issue Batch Recall</div>
                            <small class="text-muted">Initiate recall order & calculate public impact</small>
                        </div>
                        <span class="btn btn-sm btn-danger">&rarr;</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
pageFooter();
