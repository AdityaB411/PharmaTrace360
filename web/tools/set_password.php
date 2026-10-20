<?php
/**
 * PharmaTrace 360 - Set User Password CLI Utility
 *
 * Command-line only utility to hash and set user passwords via sp_set_password(?).
 * Usage: php web/tools/set_password.php
 *
 * Rules:
 * - CLI only (exits immediately if accessed via web).
 * - Requires password length >= 10 characters.
 * - Uses password_hash(PASSWORD_DEFAULT).
 * - Calls stored procedure sp_set_password via the 'app' connection.
 * - Never prints or stores plaintext passwords.
 */

declare(strict_types=1);

// Guard: Exit if not running in CLI mode
if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    echo "This tool must be run from the command line only.\n";
    exit(1);
}

require_once __DIR__ . '/../includes/db.php';

echo "========================================\n";
echo " PharmaTrace 360 - Password Setup Tool \n";
echo "========================================\n\n";

// 1. Prompt for email
echo "Enter user email: ";
$email = trim((string)fgets(STDIN));

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "Error: A valid email address is required.\n");
    exit(1);
}

// 2. Prompt for password with Windows visibility warning
echo "\nNote: On Windows console, password input is visible while typing.\n";
echo "Enter new password (minimum 10 characters): ";

$password = trim((string)fgets(STDIN));

// 3. Validation
if (strlen($password) < 10) {
    fwrite(STDERR, "\nError: Password must be at least 10 characters long.\n");
    exit(1);
}

// 4. Hash using bcrypt / Argon2 (PASSWORD_DEFAULT)
$hash = password_hash($password, PASSWORD_DEFAULT);

// Clean up plaintext password from memory immediately
unset($password);

// 5. Update password in database via sp_set_password through pt_app connection
try {
    $pdo = dbApp();
    $stmt = $pdo->prepare('CALL sp_set_password(?, ?)');
    $stmt->execute([$email, $hash]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $stmt->closeCursor();

    echo "\nSuccess: " . ($row['result'] ?? "Password updated successfully for {$email}.") . "\n";
} catch (Throwable $e) {
    fwrite(STDERR, "\nError updating password: " . $e->getMessage() . "\n");
    exit(1);
}
