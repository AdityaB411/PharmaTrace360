<?php
/**
 * PharmaTrace 360 - Public Drug Verification Portal
 *
 * Public QR code authentication and consumer drug information.
 * Uses PDO prepared statements and calls ONLY stored procedure sp_verify_scan(?)
 * through the pt_public database connection (least privilege).
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/db.php';

sendSecurityHeaders(false);

$rawCode = $_GET['code'] ?? $_POST['code'] ?? '';
$code = is_string($rawCode) ? trim($rawCode) : '';
$scanResult = null;
$errorMessage = null;
if (!is_string($rawCode)) {
    $errorMessage = 'Please enter a valid QR code.';
} elseif (strlen($code) > 64) {
    $code = '';
    $errorMessage = 'QR codes must be 64 characters or fewer.';
}
$demoCodes = [];
$demoModeActive = false;

// Attempt database connection & optional DEMO_MODE codes lookup
try {
    $config = getAppConfig();
    $demoModeActive = !empty($config['DEMO_MODE']);
    $pdo = dbPublic();

    if ($demoModeActive) {
        $demoCodes = getDemoCodes($pdo);
    }

    if ($code !== '') {
        // Execute strictly CALL sp_verify_scan(?)
        $stmt = $pdo->prepare('CALL sp_verify_scan(?)');
        $stmt->execute([$code]);

        // Result Set 1: Main Info / Verdict
        $mainInfo = $stmt->fetch(PDO::FETCH_ASSOC);

        $uses = [];
        $sideEffects = [];
        $avoidWith = [];

        // If known code, fetch subsequent result sets
        if ($mainInfo && !empty($mainInfo['medicine_name'])) {
            if ($stmt->nextRowset()) {
                $uses = $stmt->fetchAll(PDO::FETCH_COLUMN, 0);
            }
            if ($stmt->nextRowset()) {
                $sideEffects = $stmt->fetchAll(PDO::FETCH_COLUMN, 0);
            }
            if ($stmt->nextRowset()) {
                $avoidWith = $stmt->fetchAll(PDO::FETCH_COLUMN, 0);
            }
        }

        $stmt->closeCursor();

        if ($mainInfo) {
            $scanCount = null;
            if (isset($mainInfo['scan_count'])) {
                $scanCount = (int)$mainInfo['scan_count'];
            } elseif (isset($mainInfo['total_scans'])) {
                $scanCount = (int)$mainInfo['total_scans'];
            } elseif (isset($mainInfo['scans'])) {
                $scanCount = (int)$mainInfo['scans'];
            } elseif (isset($mainInfo['recent_scans'])) {
                $scanCount = (int)$mainInfo['recent_scans'];
            } elseif (isset($mainInfo['count'])) {
                $scanCount = (int)$mainInfo['count'];
            }

            $verdict = (string)($mainInfo['verdict'] ?? 'Suspicious');
            $recallReason = null;
            $recallDate = null;
            $recallInstruction = null;

            if (strcasecmp($verdict, 'Recalled') === 0) {
                $recallReason = !empty($mainInfo['recall_reason']) ? (string)$mainInfo['recall_reason'] : (!empty($mainInfo['reason']) ? (string)$mainInfo['reason'] : null);
                $recallDate = !empty($mainInfo['recall_date']) ? (string)$mainInfo['recall_date'] : null;
                $recallInstruction = 'Stop using the medicine and return it to the pharmacy.';
            }

            $scanResult = [
                'is_known'           => !empty($mainInfo['medicine_name']),
                'verdict'            => $verdict,
                'medicine_name'      => $mainInfo['medicine_name'] ?? null,
                'strength'           => $mainInfo['strength'] ?? null,
                'ingredient'         => $mainInfo['ingredient'] ?? null,
                'manufacturer'       => $mainInfo['manufacturer'] ?? null,
                'batch_number'       => $mainInfo['batch_number'] ?? null,
                'mfg_date'           => $mainInfo['manufacture_date'] ?? null,
                'exp_date'           => $mainInfo['expiry_date'] ?? null,
                'storage_note'       => $mainInfo['storage_note'] ?? null,
                'advisory'           => $mainInfo['advisory'] ?? 'Demo data - general information only, ask a doctor or pharmacist.',
                'scan_count'         => $scanCount,
                'uses'               => $uses,
                'side_effects'       => $sideEffects,
                'avoid_with'         => $avoidWith,
                'recall_reason'      => $recallReason,
                'recall_date'        => $recallDate,
                'recall_instruction' => $recallInstruction,
            ];
        } else {
            $scanResult = [
                'is_known'   => false,
                'verdict'    => 'Suspicious',
                'advisory'   => 'Demo data - general information only, ask a doctor or pharmacist.',
                'scan_count' => null,
            ];
        }
    }
} catch (Throwable $e) {
    logAppError($e);
    $errorMessage = 'Something went wrong, please try again';
}

// Verdict metadata dictionary
$verdictLookup = [
    'genuine' => [
        'title'       => 'Genuine',
        'badge_class' => 'genuine',
        'banner_class'=> 'genuine',
        'sentence'    => 'This medicine is verified genuine, active, and within its expiry period.',
        'icon'        => '✓',
    ],
    'expired' => [
        'title'       => 'Expired',
        'badge_class' => 'expired',
        'banner_class'=> 'expired',
        'sentence'    => 'This medicine has passed its expiry date. Do not use expired medicine.',
        'icon'        => '⏱',
    ],
    'recalled' => [
        'title'       => 'Recalled',
        'badge_class' => 'recalled',
        'banner_class'=> 'recalled',
        'sentence'    => 'This batch has been recalled by the manufacturer or regulator. Do not use this medicine.',
        'icon'        => '⚠',
    ],
    'not approved' => [
        'title'       => 'Not approved',
        'badge_class' => 'not-approved',
        'banner_class'=> 'not-approved',
        'sentence'    => 'This batch is not approved for distribution. Do not consume this medicine.',
        'icon'        => '✕',
    ],
    'suspicious' => [
        'title'       => 'Suspicious',
        'badge_class' => 'suspicious',
        'banner_class'=> 'suspicious',
        'sentence'    => 'This code could not be verified. Do not use this medicine until you check with a pharmacist.',
        'icon'        => '⚠',
    ],
];

$activeVerdictMeta = null;
if ($scanResult !== null) {
    $vKey = strtolower(trim($scanResult['verdict']));
    $activeVerdictMeta = $verdictLookup[$vKey] ?? $verdictLookup['suspicious'];

    if ($vKey === 'suspicious') {
        if (!empty($scanResult['is_known'])) {
            $activeVerdictMeta['sentence'] = 'This code has been scanned unusually often and may indicate a copied pack.';
        } else {
            $activeVerdictMeta['sentence'] = 'This code could not be verified. Do not use this medicine until you check with a pharmacist.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PharmaTrace 360 - Check your medicine</title>
    <meta name="description" content="Verify the authenticity, batch safety, and expiry status of your medicine with PharmaTrace 360.">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5.3 -->
    <link rel="stylesheet" href="/assets/vendor/bootstrap/bootstrap.min.css">
    <!-- Custom Stylesheet -->
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>

    <!-- Header Navigation -->
    <header class="site-header py-3 text-white">
        <div class="container d-flex align-items-center justify-content-between">
            <div class="d-flex align-items-center gap-3">
                <div class="site-brand-logo">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        <path d="m9 12 2 2 4-4"/>
                    </svg>
                </div>
                <div>
                    <h1 class="h5 mb-0 fw-bold tracking-tight">PharmaTrace 360</h1>
                    <small class="text-white-50">Drug Authentication &amp; Traceability</small>
                </div>
            </div>
            <div class="d-flex align-items-center gap-2">
                <span class="badge rounded-pill bg-light text-dark px-3 py-2 fw-medium">Public Portal</span>
                <a href="/login.php" class="btn btn-outline-light btn-sm">Staff Login</a>
            </div>
        </div>
    </header>

    <!-- Main Content Container -->
    <main class="container my-4 my-md-5" style="max-width: 860px;">

        <!-- Verification Search Card -->
        <div class="main-card p-4 p-md-5 mb-4">
            <div class="text-center mb-4">
                <h2 class="h3 fw-bold text-dark mb-2">Check your medicine</h2>
                <p class="text-muted mb-0">Enter the QR code string printed on your packaging to verify batch authenticity and safety.</p>
            </div>

            <!-- Generic visitor error alert (never reveals database internals) -->
            <?php if ($errorMessage !== null): ?>
                <div class="alert alert-danger d-flex align-items-center gap-2 mb-4" role="alert" id="errorAlert">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <circle cx="12" cy="12" r="10"></circle>
                        <line x1="12" y1="8" x2="12" y2="12"></line>
                        <line x1="12" y1="16" x2="12.01" y2="16"></line>
                    </svg>
                    <div><?= e($errorMessage) ?></div>
                </div>
            <?php endif; ?>

            <!-- QR Verification Form -->
            <form action="index.php" method="GET" class="mb-3" id="verificationForm">
                <div class="search-input-group d-flex flex-column flex-sm-row gap-2">
                    <label for="qrCodeInput" class="visually-hidden">QR Code String</label>
                    <input
                        type="text"
                        name="code"
                        id="qrCodeInput"
                        class="form-control search-input flex-grow-1"
                        placeholder="e.g. PT360-20515ECBE7F2"
                        value="<?= e($code) ?>"
                        required
                        autocomplete="off"
                        autofocus
                    >
                    <button type="submit" class="btn btn-check-code d-flex align-items-center justify-content-center gap-2" id="checkButton">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                            <circle cx="11" cy="11" r="8"></circle>
                            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                        </svg>
                        <span>Check</span>
                    </button>
                </div>
            </form>

            <!-- DEMO_MODE Helper Box (Sample Codes) -->
            <?php if ($demoModeActive && !empty($demoCodes)): ?>
                <div class="demo-box mt-3" id="demoCodesBox">
                    <div class="d-flex align-items-center justify-content-between mb-2">
                        <span class="badge bg-secondary text-uppercase fw-semibold" style="letter-spacing: 0.5px; font-size: 0.72rem;">Demo only</span>
                        <small class="text-muted">Click a sample code to test verification:</small>
                    </div>
                    <div class="d-flex flex-wrap gap-2 pt-1">
                        <?php foreach ($demoCodes as $type => $data): ?>
                            <button
                                type="button"
                                class="demo-chip"
                                onclick="fillDemoCode('<?= e($data['code']) ?>')"
                                title="Click to fill <?= e($type) ?> code (Batch <?= e($data['batch_number']) ?>)"
                            >
                                <strong><?= e($type) ?>:</strong>
                                <span><?= e($data['code']) ?></span>
                            </button>
                        <?php endforeach; ?>
                    </div>
                </div>
            <?php endif; ?>
        </div>

        <!-- Verification Results Card -->
        <?php if ($scanResult !== null && $activeVerdictMeta !== null): ?>
            <div class="main-card p-4 p-md-5" id="resultCard">

                <!-- Verdict Banner -->
                <div class="verdict-banner <?= e($activeVerdictMeta['banner_class']) ?>">
                    <div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-2">
                        <div class="d-flex align-items-center gap-2">
                            <span class="badge-verdict <?= e($activeVerdictMeta['badge_class']) ?>">
                                <span><?= e($activeVerdictMeta['icon']) ?></span>
                                <span><?= e($activeVerdictMeta['title']) ?></span>
                            </span>
                        </div>
                        <div class="text-muted small">
                            Code: <code class="fw-semibold text-dark"><?= e($code) ?></code>
                        </div>
                    </div>
                    <p class="mb-0 fs-6 fw-medium pt-1">
                        <?= e($activeVerdictMeta['sentence']) ?>
                    </p>
                    <?php if (isset($scanResult['scan_count']) && $scanResult['scan_count'] !== null): ?>
                        <p class="mb-0 small mt-2 fw-semibold">
                            Total scans recorded: <?= (int)$scanResult['scan_count'] ?>
                        </p>
                    <?php endif; ?>
                </div>

                <?php if ($vKey === 'recalled'): ?>
                    <!-- Recalled Batch Alert & Customer Instructions -->
                    <div class="recall-notice-box p-3 p-md-4 mb-4 rounded-3 border border-danger-subtle bg-danger-subtle text-danger-emphasis" id="recallNoticeBox" role="alert">
                        <div class="d-flex align-items-center gap-2 mb-3">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="text-danger flex-shrink-0" aria-hidden="true">
                                <circle cx="12" cy="12" r="10"></circle>
                                <line x1="12" y1="8" x2="12" y2="12"></line>
                                <line x1="12" y1="16" x2="12.01" y2="16"></line>
                            </svg>
                            <h4 class="h5 mb-0 fw-bold text-danger">Product Recall Notice</h4>
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-sm-6 col-md-4">
                                <div class="bg-white p-3 rounded-2 border border-danger-subtle h-100">
                                    <div class="text-uppercase small fw-semibold text-danger mb-1">Recall Date</div>
                                    <div class="fw-bold fs-6 text-dark" id="recallDate"><?= e($scanResult['recall_date'] ?? '') ?></div>
                                </div>
                            </div>
                            <div class="col-sm-6 col-md-8">
                                <div class="bg-white p-3 rounded-2 border border-danger-subtle h-100">
                                    <div class="text-uppercase small fw-semibold text-danger mb-1">Recall Reason</div>
                                    <div class="fw-bold fs-6 text-dark" id="recallReason"><?= e($scanResult['recall_reason'] ?? '') ?></div>
                                </div>
                            </div>
                        </div>

                        <div class="p-3 bg-white rounded-2 border-start border-4 border-danger">
                            <div class="text-uppercase small fw-semibold text-secondary mb-1">Customer Action</div>
                            <p class="mb-0 fw-bold text-danger fs-6" id="recallInstruction">
                                <?= e($scanResult['recall_instruction'] ?? 'Stop using the medicine and return it to the pharmacy.') ?>
                            </p>
                        </div>
                    </div>
                <?php endif; ?>

                <!-- Known Code Detailed Information -->
                <?php if ($scanResult['is_known']): ?>

                    <div class="mb-4">
                        <h3 class="h4 fw-bold text-dark mb-1"><?= e($scanResult['medicine_name']) ?></h3>
                        <p class="text-secondary mb-0">
                            <strong><?= e($scanResult['strength']) ?></strong>
                            <?php if (!empty($scanResult['ingredient'])): ?>
                                &bull; Active Ingredient: <span><?= e($scanResult['ingredient']) ?></span>
                            <?php endif; ?>
                        </p>
                    </div>

                    <!-- Key Metadata Grid -->
                    <div class="row g-3 mb-4">
                        <div class="col-sm-6 col-md-4">
                            <div class="info-block">
                                <div class="info-label">Manufacturer</div>
                                <div class="info-value"><?= e($scanResult['manufacturer']) ?></div>
                            </div>
                        </div>
                        <div class="col-sm-6 col-md-4">
                            <div class="info-block">
                                <div class="info-label">Batch Number</div>
                                <div class="info-value"><code><?= e($scanResult['batch_number']) ?></code></div>
                            </div>
                        </div>
                        <div class="col-sm-6 col-md-4">
                            <div class="info-block">
                                <div class="info-label">Manufacture Date</div>
                                <div class="info-value"><?= e($scanResult['mfg_date']) ?></div>
                            </div>
                        </div>
                        <div class="col-sm-6 col-md-6">
                            <div class="info-block">
                                <div class="info-label">Expiry Date</div>
                                <div class="info-value"><?= e($scanResult['exp_date']) ?></div>
                            </div>
                        </div>
                        <div class="col-sm-12 col-md-6">
                            <div class="info-block">
                                <div class="info-label">Storage Conditions</div>
                                <div class="info-value small fw-normal"><?= e($scanResult['storage_note'] ?: 'Store as directed on packaging.') ?></div>
                            </div>
                        </div>
                    </div>

                    <hr class="my-4 text-secondary opacity-25">

                    <!-- Therapeutic Lists -->
                    <div class="mb-4">
                        <!-- Used for -->
                        <div class="mb-3">
                            <h4 class="h6 fw-bold text-dark mb-2">Used for</h4>
                            <?php if (!empty($scanResult['uses'])): ?>
                                <ul class="tag-list">
                                    <?php foreach ($scanResult['uses'] as $item): ?>
                                        <li class="tag-item"><?= e($item) ?></li>
                                    <?php endforeach; ?>
                                </ul>
                            <?php else: ?>
                                <p class="text-muted small mb-0">General indications listed on pack insert.</p>
                            <?php endif; ?>
                        </div>

                        <!-- Common side effects -->
                        <div class="mb-3">
                            <h4 class="h6 fw-bold text-dark mb-2">Common side effects</h4>
                            <?php if (!empty($scanResult['side_effects'])): ?>
                                <ul class="tag-list">
                                    <?php foreach ($scanResult['side_effects'] as $item): ?>
                                        <li class="tag-item"><?= e($item) ?></li>
                                    <?php endforeach; ?>
                                </ul>
                            <?php else: ?>
                                <p class="text-muted small mb-0">No specific adverse effects recorded.</p>
                            <?php endif; ?>
                        </div>

                        <!-- Avoid taking together with (Drug interactions) -->
                        <div class="mb-3">
                            <h4 class="h6 fw-bold text-danger mb-2">Avoid taking together with</h4>
                            <?php if (!empty($scanResult['avoid_with'])): ?>
                                <ul class="tag-list">
                                    <?php foreach ($scanResult['avoid_with'] as $item): ?>
                                        <li class="tag-item tag-warning"><?= e($item) ?></li>
                                    <?php endforeach; ?>
                                </ul>
                            <?php else: ?>
                                <p class="text-muted small mb-0">No known critical interactions in database.</p>
                            <?php endif; ?>
                        </div>
                    </div>

                <?php endif; ?>

                <!-- Required Public Advisory Note -->
                <div class="advisory-notice mt-4">
                    <div class="d-flex align-items-start gap-2">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="flex-shrink-0 mt-1" aria-hidden="true">
                            <circle cx="12" cy="12" r="10"></circle>
                            <line x1="12" y1="16" x2="12" y2="12"></line>
                            <line x1="12" y1="8" x2="12.01" y2="8"></line>
                        </svg>
                        <div>
                            <strong>Notice:</strong> <?= e($scanResult['advisory']) ?>
                        </div>
                    </div>
                </div>

            </div>
        <?php endif; ?>

    </main>

    <!-- Footer -->
    <footer class="site-footer py-3 text-center">
        <div class="container">
            <div>PharmaTrace 360 &copy; <?= date('Y') ?> &bull; Smart Pharmaceutical Traceability System</div>
        </div>
    </footer>

    <!-- JavaScript for Demo Code Filling -->
    <script>
        function fillDemoCode(code) {
            const input = document.getElementById('qrCodeInput');
            if (input) {
                input.value = code;
                input.focus();
                // Optional: automatically submit form when clicking demo chip for frictionless testing
                const form = document.getElementById('verificationForm');
                if (form) {
                    form.submit();
                }
            }
        }
    </script>
</body>
</html>
