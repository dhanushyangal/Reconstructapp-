// Backend API endpoint for email verification
// This should be added to your website's backend

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const router = express.Router();

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Email verification endpoint
router.post('/api/verify-email', async (req, res) => {
  try {
    const { token, type } = req.body;

    if (!token) {
      return res.status(400).json({ 
        success: false, 
        message: 'Verification token is required' 
      });
    }

    // Verify the email using Supabase
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: token,
      type: type || 'signup'
    });

    if (error) {
      console.error('Verification error:', error);
      return res.status(400).json({ 
        success: false, 
        message: error.message 
      });
    }

    if (data.user) {
      // Update user record in custom table if needed
      try {
        await supabase
          .from('user')
          .update({ 
            email_verified: true,
            email_verified_at: new Date().toISOString()
          })
          .eq('email', data.user.email);
      } catch (dbError) {
        console.error('Database update error:', dbError);
        // Don't fail the verification if database update fails
      }

      return res.json({ 
        success: true, 
        message: 'Email verified successfully',
        user: data.user 
      });
    } else {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid verification token' 
      });
    }

  } catch (error) {
    console.error('Server error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
});

// Alternative: Direct token verification endpoint
router.get('/api/verify-email/:token', async (req, res) => {
  try {
    const { token } = req.params;

    // Verify the email using Supabase
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: token,
      type: 'signup'
    });

    if (error) {
      console.error('Verification error:', error);
      return res.status(400).json({ 
        success: false, 
        message: error.message 
      });
    }

    if (data.user) {
      // Redirect to success page or return success response
      return res.json({ 
        success: true, 
        message: 'Email verified successfully',
        user: data.user 
      });
    } else {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid verification token' 
      });
    }

  } catch (error) {
    console.error('Server error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
});

module.exports = router; 