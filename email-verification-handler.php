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
        
        .loading {
            color: #666;
            margin-bottom: 20px;
        }
        
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #23c4f7;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .error {
            color: #dc3545;
            background-color: #f8d7da;
            padding: 15px;
            border-radius: 4px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="verification-container">
        <div class="spinner"></div>
        <div class="loading" id="status">Processing email verification...</div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const hash = window.location.hash;
            const statusDiv = document.getElementById('status');
            
            // Check if this is a Supabase email verification callback
            if (hash && hash.includes('access_token') && hash.includes('type=signup')) {
                console.log('Email verification detected, processing...');
                statusDiv.textContent = 'Email verification detected, processing...';
                
                // Extract parameters from hash fragment
                const params = new URLSearchParams(hash.substring(1));
                const access_token = params.get('access_token');
                const refresh_token = params.get('refresh_token');
                const type = params.get('type');
                
                if (access_token && type === 'signup') {
                    statusDiv.textContent = 'Redirecting to complete verification...';
                    
                    // Redirect to auth-callback.php with query parameters
                    const callbackUrl = 'auth-callback.php?' + 
                        'access_token=' + encodeURIComponent(access_token) + 
                        '&refresh_token=' + encodeURIComponent(refresh_token || '') + 
                        '&type=' + encodeURIComponent(type);
                    
                    console.log('Redirecting to:', callbackUrl);
                    
                    // Small delay to show the processing message
                    setTimeout(function() {
                        window.location.href = callbackUrl;
                    }, 1000);
                } else {
                    showError('Invalid verification parameters');
                }
            } else {
                showError('No verification parameters found');
            }
        });
        
        function showError(message) {
            const statusDiv = document.getElementById('status');
            statusDiv.innerHTML = '<div class="error">' + message + '</div>';
            document.querySelector('.spinner').style.display = 'none';
        }
    </script>
</body>
</html> 