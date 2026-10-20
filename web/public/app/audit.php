<?php
/**
 * PharmaTrace 360 - Recent System Audit Log
 *
 * Displays the 20 most recent immutable audit log records.
 * Reads strictly from view v_recent_audit.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/layout.php';

requireRole('Admin/Regulator');

$pdo = dbApp();
$logs = [];
$errorMsg = null;

try {
    $stmt = $pdo->prepare('SELECT * FROM v_recent_audit ORDER BY logged_at DESC, log_id DESC');
    $stmt->execute();
    $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();
} catch (Throwable $e) {
    logAppError($e);
    $errorMsg = 'Could not load audit log entries.';
}

pageHeader('Audit Log', 'System Audit Trail');
?>

<?php if ($errorMsg): ?>
    <div class="alert alert-danger" role="alert"><?= e($errorMsg) ?></div>
<?php endif; ?>

<div class="card shadow-sm border-0 mb-4">
    <div class="card-body p-4">
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
            <div>
                <h5 class="card-title fw-bold mb-1">Recent Audit Trail</h5>
                <p class="text-muted small mb-0">
                    Append-only security and operational audit records (most recent 20 events).
                </p>
            </div>
            <span class="badge bg-secondary px-3 py-2"><?= count($logs) ?> Events Logged</span>
        </div>

        <?php if (empty($logs)): ?>
            <div class="alert alert-info mb-0">No audit log entries recorded yet.</div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light small">
                        <tr>
                            <th scope="col">Timestamp</th>
                            <th scope="col">User</th>
                            <th scope="col">Action</th>
                            <th scope="col">Target Table</th>
                            <th scope="col">Details</th>
                        </tr>
                    </thead>
                    <tbody class="small">
                        <?php foreach ($logs as $l): ?>
                            <?php
                            $action = $l['action'];
                            $actionBadge = match (true) {
                                str_starts_with($action, 'STATUS_APPROVED') => 'bg-success',
                                str_starts_with($action, 'STATUS_RECALLED') || $action === 'INSERT_RECALL' => 'bg-danger',
                                str_starts_with($action, 'STATUS_REJECTED') => 'bg-secondary',
                                $action === 'LOGIN' => 'bg-primary',
                                $action === 'LOGIN_FAILED' => 'bg-warning text-dark',
                                $action === 'LOGOUT' => 'bg-secondary',
                                default => 'bg-dark',
                            };
                            ?>
                            <tr>
                                <td class="text-nowrap text-muted"><?= e($l['logged_at']) ?></td>
                                <td class="fw-medium">
                                    <?= e($l['user_name'] ?: ($l['user_id'] ? 'User #' . $l['user_id'] : 'System')) ?>
                                </td>
                                <td>
                                    <span class="badge <?= $actionBadge ?> px-2 py-1"><?= e($action) ?></span>
                                </td>
                                <td class="text-muted">
                                    <code><?= e($l['table_name']) ?></code>
                                    <?php if ($l['record_id']): ?>
                                        <small class="text-muted">#<?= (int)$l['record_id'] ?></small>
                                    <?php endif; ?>
                                </td>
                                <td><?= e($l['details']) ?></td>
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
