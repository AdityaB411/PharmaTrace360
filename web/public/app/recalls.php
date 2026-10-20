<?php
/**
 * PharmaTrace 360 - Recall Monitor (Admin / Regulator)
 *
 * Displays every product recall from v_recall_list ordered by most recent first.
 * Provides KPI totals (total recalls, post-recall scans) and links to each
 * affected batch's detail page. Read-only — no mutations are performed here.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole('Admin/Regulator');

$pdo      = dbApp();
$recalls  = [];
$errorMsg = null;

try {
    $stmt = $pdo->prepare(
        'SELECT recall_id, batch_number, medicine, manufacturer,
                reason, recall_date, issued_by_email,
                qr_count, total_scans, scans_after_recall
           FROM v_recall_list
          ORDER BY recall_date DESC'
    );
    $stmt->execute();
    $recalls = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    $errorMsg = 'Could not load recall data.';
}

// Compute totals
$totalRecalls          = count($recalls);
$totalScansAfterRecall = 0;
foreach ($recalls as $r) {
    $totalScansAfterRecall += (int)$r['scans_after_recall'];
}

pageHeader('Recall Monitor', 'Product Recall Monitor');
?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger" role="alert"><?= e($errorMsg) ?></div>
<?php endif; ?>

<!-- KPI Summary Cards -->
<div class="row g-3 mb-4">
    <div class="col-sm-6 col-lg-4">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4 text-center">
                <div class="text-muted small fw-medium text-uppercase mb-2">Total Recalls</div>
                <div class="display-5 fw-bold text-danger mb-1"><?= $totalRecalls ?></div>
                <div class="small text-muted">All-time regulatory recalls</div>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-lg-4">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4 text-center">
                <div class="text-muted small fw-medium text-uppercase mb-2">Post-Recall Scans</div>
                <div class="display-5 fw-bold text-warning mb-1"><?= $totalScansAfterRecall ?></div>
                <div class="small text-muted">Scans on recalled batches after recall date</div>
            </div>
        </div>
    </div>
    <div class="col-sm-12 col-lg-4">
        <div class="card shadow-sm border-0 h-100">
            <div class="card-body p-4 d-flex flex-column justify-content-center align-items-center gap-3">
                <div class="small text-muted fw-semibold text-uppercase">Actions</div>
                <a href="/app/recall.php" class="btn btn-danger w-100 fw-semibold" id="btnIssueRecall">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                         stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"
                         class="me-1" aria-hidden="true">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    Issue Urgent Recall
                </a>
            </div>
        </div>
    </div>
</div>

<!-- Recall Table -->
<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <h5 class="fw-bold mb-3">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="me-2 text-danger" aria-hidden="true">
                <polygon points="7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2"/>
                <line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            All Product Recalls
        </h5>

        <?php if (empty($recalls)): ?>
            <p class="text-muted small mb-0">No recalls have been issued yet.</p>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0" id="recallTable">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col">Batch</th>
                            <th scope="col">Medicine</th>
                            <th scope="col">Manufacturer</th>
                            <th scope="col">Reason</th>
                            <th scope="col">Recall Date</th>
                            <th scope="col">Issued By</th>
                            <th scope="col" class="text-end">QR Codes</th>
                            <th scope="col" class="text-end">Total Scans</th>
                            <th scope="col" class="text-end">Post-Recall Scans</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($recalls as $rec): ?>
                            <tr>
                                <td>
                                    <a href="/app/batch_detail.php?batch=<?= urlencode($rec['batch_number']) ?>"
                                       class="fw-semibold text-decoration-none font-monospace small"
                                       title="Open batch detail for <?= e($rec['batch_number']) ?>">
                                        <?= e($rec['batch_number']) ?>
                                    </a>
                                </td>
                                <td class="small"><?= e($rec['medicine']) ?></td>
                                <td class="small"><?= e($rec['manufacturer']) ?></td>
                                <td class="small" style="max-width: 240px; word-break: break-word;">
                                    <?= e($rec['reason']) ?>
                                </td>
                                <td class="small text-nowrap">
                                    <?= e($rec['recall_date'] ? date('d M Y', strtotime($rec['recall_date'])) : '—') ?>
                                </td>
                                <td class="small"><?= e($rec['issued_by_email']) ?></td>
                                <td class="text-end small"><?= (int)$rec['qr_count'] ?></td>
                                <td class="text-end small"><?= (int)$rec['total_scans'] ?></td>
                                <td class="text-end">
                                    <?php $postRecall = (int)$rec['scans_after_recall']; ?>
                                    <?php if ($postRecall > 0): ?>
                                        <span class="badge bg-danger"><?= $postRecall ?></span>
                                    <?php else: ?>
                                        <span class="text-muted small">0</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                    <tfoot class="table-light fw-semibold small">
                        <tr>
                            <td colspan="6">Totals</td>
                            <td class="text-end">
                                <?= array_sum(array_column($recalls, 'qr_count')) ?>
                            </td>
                            <td class="text-end">
                                <?= array_sum(array_column($recalls, 'total_scans')) ?>
                            </td>
                            <td class="text-end">
                                <?php $grandPost = array_sum(array_column($recalls, 'scans_after_recall')); ?>
                                <?php if ($grandPost > 0): ?>
                                    <span class="badge bg-danger"><?= $grandPost ?></span>
                                <?php else: ?>
                                    0
                                <?php endif; ?>
                            </td>
                        </tr>
                    </tfoot>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php
pageFooter();
