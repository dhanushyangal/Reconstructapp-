// Backend API endpoint for email verification
// This should be added to your website's backend

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const router = express.Router();

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL || 'https://ruxsfzvrumqxsvanbbow.supabase.co',
  process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODk1MjI1NCwiZXhwIjoyMDY0NTI4MjU0fQ.nB_wLdAyCGS65u3dvb14V2dAOSGEPdV-FuR6vQ6TYtE'
);

// Email verification endpoint for Supabase code parameter
router.post('/api/verify-email', async (req, res) => {
  try {
    const { code, type } = req.body;

    console.log('Received verification request:', { code, type });

    if (!code) {
      return res.status(400).json({ 
        success: false, 
        message: 'Verification code is required' 
      });
    }

    // Verify the email using Supabase with the code parameter
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: code,
      type: type || 'signup'
    });

    console.log('Supabase verification response:', { data, error });

    if (error) {
      console.error('Verification error:', error);
      return res.status(400).json({ 
        success: false, 
        message: error.message 
      });
    }

    if (data.user) {
      console.log('User verified successfully:', data.user.email);
      
      // Update user record in custom table if needed
      try {
        const { error: updateError } = await supabase
          .from('user')
          .update({ 
            email_verified: true,
            email_verified_at: new Date().toISOString()
          })
          .eq('email', data.user.email);
          
        if (updateError) {
          console.error('Database update error:', updateError);
          // Don't fail the verification if database update fails
        } else {
          console.log('User record updated successfully');
        }
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
        message: 'Invalid verification code' 
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
router.get('/api/verify-email/:code', async (req, res) => {
  try {
    const { code } = req.params;

    console.log('Received GET verification request for code:', code);

    // Verify the email using Supabase
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: code,
      type: 'signup'
    });

    console.log('Supabase verification response:', { data, error });

    if (error) {
      console.error('Verification error:', error);
      return res.status(400).json({ 
        success: false, 
        message: error.message 
      });
    }

    if (data.user) {
      console.log('User verified successfully:', data.user.email);
      
      // Update user record in custom table
      try {
        const { error: updateError } = await supabase
          .from('user')
          .update({ 
            email_verified: true,
            email_verified_at: new Date().toISOString()
          })
          .eq('email', data.user.email);
          
        if (updateError) {
          console.error('Database update error:', updateError);
        } else {
          console.log('User record updated successfully');
        }
      } catch (dbError) {
        console.error('Database update error:', dbError);
      }

      return res.json({ 
        success: true, 
        message: 'Email verified successfully',
        user: data.user 
      });
    } else {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid verification code' 
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