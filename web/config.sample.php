<?php
/**
 * PharmaTrace 360 - Database & Application Configuration Sample
 *
 * Copy this file to web/config.local.php and enter your local MySQL credentials.
 * DO NOT commit web/config.local.php to version control.
 *
 * Two database connections are used:
 *   - 'public': pt_public user — can only call sp_verify_scan and read v_demo_codes.
 *   - 'app':    pt_app user    — can call business procedures and read views.
 */

return [
    'db' => [
        'host'    => '127.0.0.1',
        'port'    => 3306,
        'dbname'  => 'pharmatrace360',
        'charset' => 'utf8mb4',

        // pt_public: anonymous scan page (least privilege)
        'public' => [
            'user'     => 'pt_public',
            'password' => '', // Set your pt_public password here
        ],

        // pt_app: authenticated pages (procedures + views only)
        'app' => [
            'user'     => 'pt_app',
            'password' => '', // Set your pt_app password here
        ],
    ],
    // When true, displays sample QR codes on the scan page for demonstration
    'DEMO_MODE' => true,

    // Public base URL used for QR code verification links and printable sheets.
    // Set this to your PC's local network address (e.g. http://192.168.1.50:8000) for phone scanning on the same Wi-Fi.
    'PUBLIC_BASE_URL' => 'http://localhost:8000',
];
