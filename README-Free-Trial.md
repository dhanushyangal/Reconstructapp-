# Free Trial Implementation for Reconstrect App

This document explains how the free trial functionality is implemented in the Reconstrect app and the steps required to set it up.

## Database Changes

The free trial feature requires two additional columns in the `user` table to track the trial period:

1. `trial_start_date` - DATE - Stores the date when the free trial started
2. `trial_end_date` - DATE - Stores the date when the free trial will end/has ended

### Adding the Columns

Execute the following SQL statement on your MySQL database:

```sql
-- Add trial tracking columns to the user table
ALTER TABLE user
ADD COLUMN trial_start_date DATE NULL COMMENT 'Date when free trial started',
ADD COLUMN trial_end_date DATE NULL COMMENT 'Date when free trial ends/ended';

-- Optional index to improve query performance
CREATE INDEX idx_user_trial_dates ON user (email, trial_start_date, trial_end_date);
```

You can find this SQL in the file `reconstrect-api/sql/add_trial_columns.sql`.

## Server-Side Implementation

The server implements three main endpoints for trial management:

1. `/auth/start-trial` (POST) - Starts a free trial for a user
2. `/auth/trial-status` (GET) - Checks the current status of a user's trial
3. `/auth/end-trial` (POST) - Manually ends a trial (for testing or admin purposes)

### Starting a Trial

When a user clicks "Start Free Trial" in the app, it calls the server to record the trial start date and calculate the end date (default 7 days later). The server stores these dates in the database.

### Checking Trial Status

The app regularly checks with the server to see if the trial is still active or has ended. This ensures that users can't manipulate their local device clock to extend the trial.

### Ending a Trial

For testing or administrative purposes, there's an endpoint to manually end a user's trial.

## Client-Side Implementation

The app's `SubscriptionManager` class has been updated to work with these server endpoints. It now:

1. Starts trials by calling the server
2. Checks trial status with the server before falling back to local checks
3. Shows appropriate UI for active trial or trial ended states
4. Correctly locks premium features when a trial ends

## How Trial Status Affects Premium Access

A user is considered to have premium access if either:
1. They have purchased a subscription (is_premium = 1 in the database), OR
2. They have an active trial (current date is between trial_start_date and trial_end_date)

## Testing the Free Trial

1. Register a new user
2. Click "Start Free Trial" in the app
3. Verify the trial is active by checking the database and premium features in the app
4. To simulate a trial ending, you can:
   - Wait for the 7 days to pass, or
   - Use the `/auth/end-trial` endpoint to end the trial early, or
   - Manually update the `trial_end_date` in the database to a past date

## Troubleshooting

If the trial status isn't working correctly:

1. Check the database to ensure the trial dates are recorded properly
2. Verify the user has the correct premium access based on the dates
3. Check the logs for any errors in the API calls
4. Make sure the client's auth token is valid when making API calls 