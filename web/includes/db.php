<?php
/**
 * PharmaTrace 360 - Database Connection & Logging Helpers
 *
 * Provides two PDO connections (public and app), error logging,
 * demo-code lookup, and session/auth helpers.
 * Never exposes raw database errors or credentials to visitors.
 */

declare(strict_types=1);

// ─── Configuration ──────────────────────────────────────────

/**
 * Load application configuration from web/config.local.php.
 */
function getAppConfig(): array
{
    static $config = null;
    if ($config !== null) {
        return $config;
    }

    $configPath = dirname(__DIR__) . '/config.local.php';
    if (!file_exists($configPath)) {
        throw new RuntimeException(
            'Configuration file web/config.local.php not found. ' .
            'Please copy web/config.sample.php to web/config.local.php and configure your database credentials.'
        );
    }

    $loaded = require $configPath;
    if (!is_array($loaded)) {
        throw new RuntimeException('Invalid configuration format in web/config.local.php.');
    }

    $config = $loaded;
    return $config;
}

// ─── PDO Connections ────────────────────────────────────────

/**
 * Build a PDO DSN + options array from the common config block.
 */
function buildDsn(array $db): string
{
    $host    = $db['host'] ?? '127.0.0.1';
    $port    = (int)($db['port'] ?? 3306);
    $dbname  = $db['dbname'] ?? 'pharmatrace360';
    $charset = $db['charset'] ?? 'utf8mb4';
    return "mysql:host={$host};port={$port};dbname={$dbname};charset={$charset}";
}

function pdoOptions(): array
{
    return [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];
}

/**
 * Public connection (pt_public) — for the anonymous scan page.
 */
function dbPublic(): PDO
{
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }

    $config = getAppConfig();
    $db     = $config['db'] ?? [];
    $pub    = $db['public'] ?? [];

    $pdo = new PDO(
        buildDsn($db),
        $pub['user'] ?? 'pt_public',
        (string)($pub['password'] ?? ''),
        pdoOptions()
    );
    return $pdo;
}

/**
 * App connection (pt_app) — for authenticated pages.
 */
function dbApp(): PDO
{
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }

    $config = getAppConfig();
    $db     = $config['db'] ?? [];
    $app    = $db['app'] ?? [];

    $pdo = new PDO(
        buildDsn($db),
        $app['user'] ?? 'pt_app',
        (string)($app['password'] ?? ''),
        pdoOptions()
    );
    return $pdo;
}

/**
 * Legacy wrapper — returns the public connection.
 * Kept for backward compatibility with the existing scan page.
 */
function getDbConnection(): PDO
{
    return dbPublic();
}

// ─── Logging ────────────────────────────────────────────────

/**
 * Log error to web/logs/error.log. Never reveals credentials or leaks to browser.
 */
function logAppError(Throwable $e): void
{
    $logDir = dirname(__DIR__) . '/logs';
    if (!is_dir($logDir)) {
        @mkdir($logDir, 0755, true);
    }

    $logFile = $logDir . '/error.log';
    $timestamp = date('Y-m-d H:i:s');
    $message = sprintf(
        "[%s] %s in %s:%d\nStack trace:\n%s\n---\n",
        $timestamp,
        $e->getMessage(),
        $e->getFile(),
        $e->getLine(),
        $e->getTraceAsString()
    );

    @file_put_contents($logFile, $message, FILE_APPEND | LOCK_EX);
}

// ─── Demo Codes ─────────────────────────────────────────────

/**
 * Retrieve demo codes from the v_demo_codes view.
 */
function getDemoCodes(PDO $pdo): array
{
    $stmt = $pdo->prepare('SELECT demo_type, code, batch_number FROM v_demo_codes');
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();

    $demoCodes = [];
    foreach ($rows as $row) {
        $demoCodes[$row['demo_type']] = [
            'code'         => $row['code'],
            'batch_number' => $row['batch_number'],
        ];
    }
    return $demoCodes;
}

// ─── Session & Auth Helpers ─────────────────────────────────

/**
 * Start or resume a session with secure cookie settings.
 */
function startSecureSession(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }

    session_set_cookie_params([
        'lifetime' => 0,
        'path'     => '/',
        'httponly'  => true,
        'samesite' => 'Lax',
    ]);

    session_start();

    // 30-minute idle timeout
    if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity']) > 1800) {
        session_unset();
        session_destroy();
        session_start();
    }
    $_SESSION['last_activity'] = time();
}

/**
 * Generate or retrieve a CSRF token for the current session.
 */
function csrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Verify the CSRF token from a POST request.
 */
function verifyCsrf(): bool
{
    return isset($_POST['csrf_token']) && hash_equals(csrfToken(), $_POST['csrf_token']);
}

/**
 * Require a specific role(s) or redirect to login.
 * @param string|string[] $roles
 */
function requireRole($roles): void
{
    startSecureSession();

    if (empty($_SESSION['user_id'])) {
        header('Location: /login.php');
        exit;
    }

    $allowed = is_array($roles) ? $roles : [$roles];
    if (!in_array($_SESSION['role_name'], $allowed, true)) {
        http_response_code(403);
        echo '<!DOCTYPE html><html><head><title>Forbidden</title></head><body><h1>403 Forbidden</h1><p>You do not have permission to access this page.</p></body></html>';
        exit;
    }
}

/**
 * HTML-escape helper.
 */
function e(?string $val): string
{
    return htmlspecialchars((string)$val, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
