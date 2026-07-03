<?php
// ---------------------------------------------------------------------------
// CloudFlow Guestbook — a tiny app you own.
// One file: serves the UI (HTML) AND a JSON API. Talks to MySQL directly.
// Edit anything here, refresh the browser, see it change.
// ---------------------------------------------------------------------------

// --- Database connection (reads settings from environment variables) ---
$host = getenv('DB_HOST') ?: 'db';
$name = getenv('DB_DATABASE') ?: 'guestbook';
$user = getenv('DB_USERNAME') ?: 'guestbook';
$pass = getenv('DB_PASSWORD') ?: 'secret';

function db() {
    global $host, $name, $user, $pass;
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            "mysql:host=$host;dbname=$name;charset=utf8mb4",
            $user,
            $pass,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
    }
    return $pdo;
}

// --- Auto-create the table on first run (so setup is zero-effort) ---
function ensure_table() {
    db()->exec("
        CREATE TABLE IF NOT EXISTS messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            message TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ");
}

// --- Simple router: is this an API call or a page view? ---
$path   = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// =========================================================================
// API ROUTES  (return JSON)
// =========================================================================
if (strpos($path, '/api/') === 0) {
    header('Content-Type: application/json');
    try {
        ensure_table();

        // GET /api/messages  -> list all messages
        if ($path === '/api/messages' && $method === 'GET') {
            $rows = db()->query("SELECT * FROM messages ORDER BY id DESC")->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode($rows);
            exit;
        }

        // POST /api/messages -> add a message
        if ($path === '/api/messages' && $method === 'POST') {
            $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
            $nameIn = trim($input['name'] ?? '');
            $msgIn  = trim($input['message'] ?? '');
            if ($nameIn === '' || $msgIn === '') {
                http_response_code(422);
                echo json_encode(['error' => 'name and message are required']);
                exit;
            }
            $stmt = db()->prepare("INSERT INTO messages (name, message) VALUES (?, ?)");
            $stmt->execute([$nameIn, $msgIn]);
            http_response_code(201);
            echo json_encode(['id' => db()->lastInsertId(), 'name' => $nameIn, 'message' => $msgIn]);
            exit;
        }

        // health check -> used later by monitoring / load balancers
        if ($path === '/api/health') {
            db()->query("SELECT 1");
            echo json_encode(['status' => 'ok']);
            exit;
        }

        http_response_code(404);
        echo json_encode(['error' => 'not found']);
    } catch (Throwable $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit;
}

// =========================================================================
// UI ROUTE  (return HTML)  — the page people see
// =========================================================================
try {
    ensure_table();
    $messages = db()->query("SELECT * FROM messages ORDER BY id DESC")->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $messages = [];
    $dbError = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CloudFlow Guestbook</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 640px; margin: 40px auto; padding: 0 16px; background: #0f1117; color: #e6e6e6; }
        h1 { color: #6ea8fe; }
        form { display: flex; flex-direction: column; gap: 8px; margin-bottom: 32px; }
        input, textarea { padding: 10px; border-radius: 8px; border: 1px solid #333; background: #1a1d27; color: #e6e6e6; font-size: 15px; }
        button { padding: 10px; border: none; border-radius: 8px; background: #6ea8fe; color: #0f1117; font-weight: 600; font-size: 15px; cursor: pointer; }
        .msg { background: #1a1d27; border: 1px solid #262a36; border-radius: 8px; padding: 12px 16px; margin-bottom: 12px; }
        .msg .who { color: #6ea8fe; font-weight: 600; }
        .msg .when { color: #777; font-size: 12px; }
        .err { background: #3a1a1a; border: 1px solid #663; padding: 12px; border-radius: 8px; }
    </style>
</head>
<body>
   <h1>&#128075; John's Guestbook</h1>
    <p>Leave a message below. This is a tiny app you own end to end.</p>

    <?php if (!empty($dbError)): ?>
        <div class="err">Database error: <?= htmlspecialchars($dbError) ?></div>
    <?php endif; ?>

    <form method="POST" action="/api/messages" onsubmit="return submitForm(event)">
        <input type="text" name="name" placeholder="Your name" required>
        <textarea name="message" placeholder="Your message" rows="3" required></textarea>
        <button type="submit">Sign the guestbook</button>
    </form>

    <div id="messages">
        <?php foreach ($messages as $m): ?>
            <div class="msg">
                <div class="who"><?= htmlspecialchars($m['name']) ?></div>
                <div><?= htmlspecialchars($m['message']) ?></div>
                <div class="when"><?= htmlspecialchars($m['created_at']) ?></div>
            </div>
        <?php endforeach; ?>
    </div>

    <script>
        // Submit via the API (JSON), then refresh the list — no page reload.
        async function submitForm(e) {
            e.preventDefault();
            const form = e.target;
            const data = { name: form.name.value, message: form.message.value };
            const res = await fetch('/api/messages', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            if (res.ok) { form.reset(); location.reload(); }
            else { alert('Error saving message'); }
            return false;
        }
    </script>
</body>
</html>
