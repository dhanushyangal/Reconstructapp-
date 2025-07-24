<?php
/**
 * Supabase Email Verification Integration
 * 
 * This script can be integrated into your existing verify-email.php page
 * to confirm the email in Supabase and create the user record.
 * 
 * Usage:
 * 1. Include this file in your verify-email.php
 * 2. Call confirmEmailInSupabase($email) after successful verification
 */

// Supabase configuration
$SUPABASE_URL = 'https://your-project-ref.supabase.co'; // Replace with your Supabase URL
$SUPABASE_ANON_KEY = 'your-anon-key'; // Replace with your Supabase anon key

/**
 * Confirm email in Supabase and create user record
 * 
 * @param string $email The email address to confirm
 * @return array Response with success status and message
 */
function confirmEmailInSupabase($email) {
    global $SUPABASE_URL, $SUPABASE_ANON_KEY;
    
    // Validate email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        return [
            'success' => false,
            'message' => 'Invalid email address'
        ];
    }
    
    // Prepare the request to Supabase RPC function
    $url = $SUPABASE_URL . '/rest/v1/rpc/confirm_email_and_create_user';
    
    $headers = [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $SUPABASE_ANON_KEY,
        'apikey: ' . $SUPABASE_ANON_KEY
    ];
    
    $data = [
        'user_email' => $email
    ];
    
    // Make the request
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    // Handle curl errors
    if ($error) {
        error_log("Supabase API Error: " . $error);
        return [
            'success' => false,
            'message' => 'Connection error: ' . $error
        ];
    }
    
    // Handle HTTP errors
    if ($httpCode !== 200) {
        error_log("Supabase API HTTP Error: " . $httpCode . " - " . $response);
        return [
            'success' => false,
            'message' => 'API error: HTTP ' . $httpCode
        ];
    }
    
    // Parse response
    $result = json_decode($response, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        error_log("Supabase API JSON Error: " . json_last_error_msg() . " - " . $response);
        return [
            'success' => false,
            'message' => 'Invalid response format'
        ];
    }
    
    // Log the result for debugging
    error_log("Supabase confirmation result for $email: " . json_encode($result));
    
    return $result;
}

/**
 * Example integration with existing verification page
 * 
 * Add this to your verify-email.php after successful verification:
 */
function integrateWithExistingVerification($email) {
    // Your existing verification logic here
    // ...
    
    // After successful verification, call Supabase
    $supabaseResult = confirmEmailInSupabase($email);
    
    if ($supabaseResult['success']) {
        // Success - user confirmed in Supabase
        echo "<div class='success'>Email verified successfully! You can now log in to the app.</div>";
        
        // Optional: Redirect to app or show login instructions
        echo "<p><a href='https://your-app-download-link.com'>Download the App</a></p>";
    } else {
        // Handle error
        echo "<div class='error'>Email verified on website, but there was an issue with the app integration: " . 
             htmlspecialchars($supabaseResult['message']) . "</div>";
        
        // You might want to show instructions to contact support
        echo "<p>Please contact support if you have trouble logging into the app.</p>";
    }
}

/**
 * Configuration instructions:
 * 
 * 1. Replace the Supabase configuration at the top of this file:
 *    - $SUPABASE_URL: Your Supabase project URL
 *    - $SUPABASE_ANON_KEY: Your Supabase anon/public key
 * 
 * 2. In your verify-email.php, add this code after successful verification:
 * 
 *    // Include this file
 *    require_once 'verify_email_supabase_integration.php';
 *    
 *    // After your existing verification logic succeeds
 *    $email = $_GET['email'] ?? ''; // Get email from URL parameter
 *    if ($email) {
 *        integrateWithExistingVerification($email);
 *    }
 * 
 * 3. Make sure your verification page extracts the email from the verification link
 *    (usually from a token or email parameter in the URL)
 */

// Example usage (uncomment and modify for testing):
/*
if (isset($_GET['test_email'])) {
    $testEmail = $_GET['test_email'];
    $result = confirmEmailInSupabase($testEmail);
    echo "<pre>" . json_encode($result, JSON_PRETTY_PRINT) . "</pre>";
}
*/
?> 