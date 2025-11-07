<?php
/**
 * Simple Email Verification Handler for Supabase
 * This handles the code parameter format that Supabase sends
 */

// Supabase configuration
$SUPABASE_URL = 'https://ruxsfzvrumqxsvanbbow.supabase.co';
$SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg';

// Get the verification code from URL
$code = $_GET['code'] ?? '';

if (empty($code)) {
    $error = 'No verification code found in URL';
} else {
    // Call Supabase API to verify the email
    $result = verifyEmailWithSupabase($code);
    
    if ($result['success']) {
        $success = 'Email verified successfully! You can now log in to the Reconstruct app.';
    } else {
        $error = 'Verification failed: ' . $result['message'];
    }
}

function verifyEmailWithSupabase($code) {
    global $SUPABASE_URL, $SUPABASE_ANON_KEY;
    
    // Prepare the request to Supabase
    $url = $SUPABASE_URL . '/auth/v1/verify';
    
    $headers = [
        'Content-Type: application/json',
        'apikey: ' . $SUPABASE_ANON_KEY
    ];
    
    $data = [
        'token_hash' => $code,
        'type' => 'signup'
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
        return [
            'success' => false,
            'message' => 'Network error: ' . $error
        ];
    }
    
    // Parse response
    $responseData = json_decode($response, true);
    
    if ($httpCode === 200 && isset($responseData['user'])) {
        // Success - update user record in database
        updateUserVerification($responseData['user']['email']);
        
        return [
            'success' => true,
            'message' => 'Email verified successfully',
            'user' => $responseData['user']
        ];
    } else {
        // Error
        $errorMessage = 'Verification failed';
        if (isset($responseData['error_description'])) {
            $errorMessage = $responseData['error_description'];
        } elseif (isset($responseData['msg'])) {
            $errorMessage = $responseData['msg'];
        }
        
        return [
            'success' => false,
            'message' => $errorMessage
        ];
    }
}

function updateUserVerification($email) {
    global $SUPABASE_URL, $SUPABASE_ANON_KEY;
    
    // Update user record in database
    $url = $SUPABASE_URL . '/rest/v1/user';
    
    $headers = [
        'Content-Type: application/json',
        'apikey: ' . $SUPABASE_ANON_KEY,
        'Authorization: Bearer ' . $SUPABASE_ANON_KEY
    ];
    
    $data = [
        'email_verified' => true,
        'email_verified_at' => date('c')
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url . '?email=eq.' . urlencode($email));
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    
    curl_exec($ch);
    curl_close($ch);
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification | Reconstruct</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }
        
        .verification-container {
            background-color: #fff;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            text-align: center;
            max-width: 400px;
        }
        
        .error {
            color: #dc3545;
            background-color: #f8d7da;
            padding: 15px;
            border-radius: 4px;
            margin-top: 20px;
        }
        
        .success {
            color: #155724;
            background-color: #d4edda;
            padding: 15px;
            border-radius: 4px;
            margin-top: 20px;
        }
        
        .app-link {
            margin-top: 20px;
            padding: 15px;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            display: inline-block;
        }
        
        .app-link:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
    <div class="verification-container">
        <?php if (isset($error)): ?>
            <div class="error">
                <?php echo htmlspecialchars($error); ?>
            </div>
            <p>Please try again or contact support if the problem persists.</p>
        <?php elseif (isset($success)): ?>
            <div class="success">
                <?php echo htmlspecialchars($success); ?>
            </div>
            <a href="https://play.google.com/store/apps/details?id=com.reconstrect.visionboard" class="app-link">
                Download Reconstruct App
            </a>
        <?php else: ?>
            <div class="error">
                No verification code found. Please check your email for the correct verification link.
            </div>
        <?php endif; ?>
    </div>
</body>
</html>



























