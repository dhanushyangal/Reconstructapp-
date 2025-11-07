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
        
        .success {
            color: #155724;
            background-color: #d4edda;
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
            const urlParams = new URLSearchParams(window.location.search);
            const code = urlParams.get('code');
            const statusDiv = document.getElementById('status');
            
            console.log('URL parameters:', window.location.search);
            console.log('Code parameter:', code);
            
            // Check if this is a Supabase email verification with code parameter
            if (code) {
                console.log('Email verification code detected, processing...');
                statusDiv.textContent = 'Email verification code detected, processing...';
                
                // Call Supabase API to verify the email
                verifyEmailWithSupabase(code);
            } else {
                showError('No verification code found in URL');
            }
        });
        
        async function verifyEmailWithSupabase(code) {
            const statusDiv = document.getElementById('status');
            
            try {
                statusDiv.textContent = 'Verifying email with Supabase...';
                
                // Call your backend API to verify the email
                const response = await fetch('https://reconstrect-api.onrender.com/api/verify-email', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        code: code,
                        type: 'signup'
                    })
                });
                
                const result = await response.json();
                
                if (result.success) {
                    showSuccess('Email verified successfully! You can now log in to the Reconstruct app.');
                } else {
                    showError('Verification failed: ' + (result.message || 'Unknown error'));
                }
                
            } catch (error) {
                console.error('Verification error:', error);
                showError('Verification failed: Network error. Please try again.');
            }
        }
        
        function showError(message) {
            const statusDiv = document.getElementById('status');
            statusDiv.innerHTML = '<div class="error">' + message + '</div>';
            document.querySelector('.spinner').style.display = 'none';
        }
        
        function showSuccess(message) {
            const statusDiv = document.getElementById('status');
            statusDiv.innerHTML = '<div class="success">' + message + '</div>';
            document.querySelector('.spinner').style.display = 'none';
        }
    </script>
</body>
</html>



























