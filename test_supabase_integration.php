<?php
/**
 * Test Script for Supabase Email Verification Integration
 * 
 * This script can be used to test the Supabase integration without
 * modifying your existing verification page.
 * 
 * Usage:
 * 1. Update the Supabase configuration below
 * 2. Upload this file to your server
 * 3. Access: https://your-domain.com/test_supabase_integration.php?email=test@example.com
 */

// Supabase configuration - UPDATE THESE VALUES
$SUPABASE_URL = 'https://your-project-ref.supabase.co'; // Replace with your Supabase URL
$SUPABASE_ANON_KEY = 'your-anon-key'; // Replace with your Supabase anon key

// Get email from URL parameter
$testEmail = $_GET['email'] ?? '';

if (empty($testEmail)) {
    echo "<h2>Supabase Integration Test</h2>";
    echo "<p>Add an email parameter to test: ?email=test@example.com</p>";
    echo "<p>Example: <a href='?email=test@example.com'>Test with test@example.com</a></p>";
    exit;
}

// Validate email
if (!filter_var($testEmail, FILTER_VALIDATE_EMAIL)) {
    echo "<h2>Error</h2>";
    echo "<p>Invalid email address: " . htmlspecialchars($testEmail) . "</p>";
    exit;
}

echo "<h2>Testing Supabase Integration</h2>";
echo "<p>Testing email: " . htmlspecialchars($testEmail) . "</p>";

// Test the Supabase API call
function testSupabaseIntegration($email) {
    global $SUPABASE_URL, $SUPABASE_ANON_KEY;
    
    // Check if configuration is set
    if ($SUPABASE_URL === 'https://your-project-ref.supabase.co' || $SUPABASE_ANON_KEY === 'your-anon-key') {
        return [
            'success' => false,
            'message' => 'Please update the Supabase configuration in this file first.'
        ];
    }
    
    // Prepare the request
    $url = $SUPABASE_URL . '/rest/v1/rpc/confirm_email_and_create_user';
    
    $headers = [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $SUPABASE_ANON_KEY,
        'apikey: ' . $SUPABASE_ANON_KEY
    ];
    
    $data = [
        'user_email' => $email
    ];
    
    echo "<h3>Making API Request</h3>";
    echo "<p><strong>URL:</strong> " . htmlspecialchars($url) . "</p>";
    echo "<p><strong>Data:</strong> " . htmlspecialchars(json_encode($data)) . "</p>";
    
    // Make the request
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_VERBOSE, true);
    
    // Capture verbose output
    $verbose = fopen('php://temp', 'w+');
    curl_setopt($ch, CURLOPT_STDERR, $verbose);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    // Show verbose output
    rewind($verbose);
    $verboseLog = stream_get_contents($verbose);
    fclose($verbose);
    
    echo "<h3>Request Details</h3>";
    echo "<pre>" . htmlspecialchars($verboseLog) . "</pre>";
    
    echo "<h3>Response</h3>";
    echo "<p><strong>HTTP Code:</strong> " . $httpCode . "</p>";
    echo "<p><strong>Response Body:</strong></p>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    
    // Handle curl errors
    if ($error) {
        return [
            'success' => false,
            'message' => 'Connection error: ' . $error
        ];
    }
    
    // Handle HTTP errors
    if ($httpCode !== 200) {
        return [
            'success' => false,
            'message' => 'API error: HTTP ' . $httpCode . ' - ' . $response
        ];
    }
    
    // Parse response
    $result = json_decode($response, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        return [
            'success' => false,
            'message' => 'Invalid response format: ' . json_last_error_msg()
        ];
    }
    
    return $result;
}

// Run the test
$result = testSupabaseIntegration($testEmail);

echo "<h3>Test Result</h3>";
if ($result['success']) {
    echo "<div style='color: green; background: #e8f5e8; padding: 10px; border: 1px solid green;'>";
    echo "<strong>✅ SUCCESS:</strong> " . htmlspecialchars($result['message']);
    if (isset($result['user_id'])) {
        echo "<br>User ID: " . htmlspecialchars($result['user_id']);
    }
    echo "</div>";
} else {
    echo "<div style='color: red; background: #ffe8e8; padding: 10px; border: 1px solid red;'>";
    echo "<strong>❌ ERROR:</strong> " . htmlspecialchars($result['message']);
    echo "</div>";
}

echo "<h3>Next Steps</h3>";
if ($result['success']) {
    echo "<p>✅ The integration is working! You can now:</p>";
    echo "<ol>";
    echo "<li>Integrate this into your existing verification page</li>";
    echo "<li>Test the complete registration flow</li>";
    echo "<li>Check Supabase Auth to see the user status</li>";
    echo "</ol>";
} else {
    echo "<p>❌ Please fix the issues above before proceeding:</p>";
    echo "<ol>";
    echo "<li>Update the Supabase configuration</li>";
    echo "<li>Verify the RPC function exists in Supabase</li>";
    echo "<li>Check your network connectivity</li>";
    echo "</ol>";
}

echo "<hr>";
echo "<p><a href='?email=" . urlencode($testEmail) . "'>Test Again</a> | <a href='?'>Test Different Email</a></p>";
?> 