<?php
/**
 * PharmaTrace 360 - Printable Batch QR Sheet
 *
 * 4-column printable label sheet for unit-level QR codes.
 * Enforces identical role, ownership (manufacturer_id), and 404 rules as batch_detail.php.
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

$batchNumber = trim($_GET['batch'] ?? '');
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

// 404 rule: If batch does not exist or does not belong to the manufacturer:
// Show plain "Batch not found" page with HTTP 404 and show NO data.
if (!$batch) {
    http_response_code(404);
    echo '<!DOCTYPE html><html><head><title>Batch Not Found</title></head><body><h1>404 Batch Not Found</h1><p>Batch not found.</p></body></html>';
    exit;
}

// ─── Fetch QR Codes for this Batch ────────────────────────────
$qrCodes = [];
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

$config = getAppConfig();
$publicBaseUrl = rtrim((string)($config['PUBLIC_BASE_URL'] ?? 'http://localhost:8000'), '/');
$status = $batch['status'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QR Sheet - Batch <?= e($batchNumber) ?> - PharmaTrace 360</title>
    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5.3 -->
    <link rel="stylesheet" href="/assets/vendor/bootstrap/bootstrap.min.css">
    <!-- Local qrcodejs library -->
    <script src="/assets/vendor/qrcode/qrcode.min.js"></script>

    <style>
        :root {
            --sheet-bg: #f8fafc;
            --sheet-card-bg: #ffffff;
            --sheet-border: #cbd5e1;
            --sheet-text: #0f172a;
        }

        body {
            background-color: var(--sheet-bg);
            color: var(--sheet-text);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            padding: 0;
        }

        .sheet-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 24px 16px;
        }

        /* 4-column printable grid */
        .qr-sheet-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
        }

        .qr-sheet-card {
            background: var(--sheet-card-bg);
            border: 1px solid var(--sheet-border);
            border-radius: 12px;
            padding: 14px 12px;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            break-inside: avoid;
            page-break-inside: avoid;
        }

        .qr-code-box {
            width: 108px;
            height: 108px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 8px;
            background: #ffffff;
            padding: 4px;
        }

        .qr-code-box canvas,
        .qr-code-box img {
            max-width: 100%;
            height: auto;
            display: block;
        }

        .qr-code-text {
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
            font-size: 0.82rem;
            font-weight: 700;
            letter-spacing: 0.2px;
            color: #0f172a;
            margin-bottom: 4px;
            word-break: break-all;
        }

        .qr-card-meta {
            font-size: 0.72rem;
            color: #475569;
            line-height: 1.35;
            width: 100%;
            border-top: 1px dashed #e2e8f0;
            padding-top: 6px;
            margin-top: 2px;
        }

        .qr-card-meta strong {
            color: #0f172a;
        }

        /* Responsive breakpoints for screen view */
        @media (max-width: 992px) {
            .qr-sheet-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 576px) {
            .qr-sheet-grid {
                grid-template-columns: 1fr;
            }
        }

        /* ─── PRINT STYLES ────────────────────────────────────────── */
        @media print {
            body {
                background: #ffffff !important;
                color: #000000 !important;
                padding: 0 !important;
                margin: 0 !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }

            .sheet-container {
                max-width: 100% !important;
                padding: 0 !important;
                margin: 0 !important;
            }

            .no-print {
                display: none !important;
            }

            .print-header {
                display: block !important;
                margin-bottom: 12px;
                padding-bottom: 8px;
                border-bottom: 2px solid #000000;
            }

            .qr-sheet-grid {
                display: grid !important;
                grid-template-columns: repeat(4, 1fr) !important;
                gap: 5mm !important;
            }

            .qr-sheet-card {
                border: 1.2px solid #000000 !important;
                border-radius: 4px !important;
                box-shadow: none !important;
                padding: 3mm !important;
                background: #ffffff !important;
                break-inside: avoid !important;
                page-break-inside: avoid !important;
            }

            .qr-code-box {
                width: 95px !important;
                height: 95px !important;
                margin-bottom: 3px !important;
                padding: 0 !important;
            }

            .qr-code-text {
                font-size: 8.5pt !important;
                color: #000000 !important;
                margin-bottom: 2px !important;
            }

            .qr-card-meta {
                font-size: 7.5pt !important;
                color: #000000 !important;
                border-top: 1px solid #94a3b8 !important;
                padding-top: 2px !important;
            }

            @page {
                size: A4 portrait;
                margin: 10mm;
            }
        }
    </style>
</head>
<body>

<div class="sheet-container">
    <!-- Screen Navigation & Controls (hidden during print) -->
    <div class="no-print bg-white p-4 rounded-3 border shadow-sm mb-4">
        <div class="d-flex justify-content-between align-items-center flex-wrap gap-3">
            <div>
                <a href="/app/batch_detail.php?batch=<?= urlencode($batchNumber) ?>" class="btn btn-outline-secondary btn-sm mb-2">
                    &larr; Back to Batch Details
                </a>
                <h1 class="h4 fw-bold mb-1">Batch <?= e($batchNumber) ?> &bull; Printable QR Sheet</h1>
                <div class="text-muted small">
                    <strong><?= e($batch['medicine']) ?></strong> &bull;
                    Manufacturer: <?= e($batch['manufacturer']) ?> &bull;
                    Expiry: <strong><?= e($batch['expiry_date']) ?></strong> &bull;
                    Total: <span class="badge bg-primary"><?= count($qrCodes) ?> units</span>
                </div>
            </div>
            <div class="d-flex align-items-center gap-2">
                <button type="button" onclick="window.print()" class="btn btn-primary btn-sm px-3 d-flex align-items-center gap-1">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <polyline points="6 9 6 2 18 2 18 9"></polyline>
                        <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                        <rect x="6" y="14" width="12" height="8"></rect>
                    </svg>
                    Print Sheet
                </button>
            </div>
        </div>
    </div>

    <!-- Print-Only Header -->
    <div class="print-header d-none">
        <div class="d-flex justify-content-between align-items-end">
            <div>
                <div class="fw-bold fs-6">PharmaTrace 360 &bull; Serialized Packaging Sheet</div>
                <div class="small">
                    <strong>Medicine:</strong> <?= e($batch['medicine']) ?> |
                    <strong>Batch:</strong> <?= e($batchNumber) ?> |
                    <strong>Expiry:</strong> <?= e($batch['expiry_date']) ?>
                </div>
            </div>
            <div class="text-end small">
                <div><strong>Manufacturer:</strong> <?= e($batch['manufacturer']) ?></div>
                <div><?= count($qrCodes) ?> Unit Codes Issued</div>
            </div>
        </div>
    </div>

    <!-- QR Codes Grid or Empty Notice -->
    <?php if (empty($qrCodes)): ?>
        <div class="alert alert-warning text-center p-4">
            <h5 class="fw-bold mb-2">No QR Codes Found</h5>
            <p class="mb-3 text-muted">No QR codes are associated with batch <?= e($batchNumber) ?> yet. Codes are generated when a batch is Approved.</p>
            <a href="/app/batch_detail.php?batch=<?= urlencode($batchNumber) ?>" class="btn btn-primary btn-sm">Return to Batch Details</a>
        </div>
    <?php else: ?>
        <div class="qr-sheet-grid" id="qrSheetGrid">
            <?php foreach ($qrCodes as $qr):
                $codeVal = $qr['qr_code'];
                $scanUrl = $publicBaseUrl . '/?code=' . urlencode($codeVal);
            ?>
                <div class="qr-sheet-card">
                    <div class="qr-code-box" data-qr-payload="<?= e($scanUrl) ?>"></div>
                    <div class="qr-code-text"><?= e($codeVal) ?></div>
                    <div class="qr-card-meta">
                        <div><strong>Batch:</strong> <?= e($batchNumber) ?></div>
                        <div><strong>Exp:</strong> <?= e($batch['expiry_date']) ?></div>
                        <div class="text-truncate" style="max-width: 100%;" title="<?= e($batch['medicine']) ?>">
                            <?= e($batch['medicine']) ?>
                        </div>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</div>

<script>
document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.qr-code-box').forEach(function (container) {
        var payload = container.getAttribute('data-qr-payload');
        if (payload) {
            new QRCode(container, {
                text: payload,
                width: 96,
                height: 96,
                colorDark: '#000000',
                colorLight: '#ffffff',
                correctLevel: QRCode.CorrectLevel.M
            });
        }
    });
});
</script>

</body>
</html>
