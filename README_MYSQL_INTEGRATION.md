# MySQL Database Integration

This document provides instructions on how to set up and integrate a MySQL database with your Flutter application for authentication.

## Backend Setup

### 1. Set Up MySQL Database

1. Install MySQL on your server or use a cloud-based MySQL service.
2. Create a new database for your application:
   ```sql
   CREATE DATABASE reconstrect_app;
   ```
3. Create a users table:
   ```sql
   CREATE TABLE users (
     id INT AUTO_INCREMENT PRIMARY KEY,
     username VARCHAR(255) NOT NULL,
     email VARCHAR(255) NOT NULL UNIQUE,
     password VARCHAR(255) NOT NULL,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```

### 2. Create API Endpoints

You need to create a backend API that connects to your MySQL database. Here's a simple example using Node.js and Express:

1. Set up a new Node.js project:
   ```bash
   mkdir reconstrect-api
   cd reconstrect-api
   npm init -y
   npm install express mysql bcrypt jsonwebtoken cors
   ```

2. Create a server.js file:
   ```javascript
   const express = require('express');
   const mysql = require('mysql');
   const bcrypt = require('bcrypt');
   const jwt = require('jsonwebtoken');
   const cors = require('cors');

   const app = express();
   app.use(express.json());
   app.use(cors());

   // MySQL Connection
   const db = mysql.createConnection({
     host: 'your_mysql_host',
     user: 'your_mysql_user',
     password: 'your_mysql_password',
     database: 'reconstrect_app'
   });

   db.connect((err) => {
     if (err) {
       console.error('MySQL connection error:', err);
       return;
     }
     console.log('Connected to MySQL database');
   });

   // JWT Secret
   const JWT_SECRET = 'your_jwt_secret_key';

   // Register endpoint
   app.post('/auth/register', async (req, res) => {
     try {
       const { username, email, password } = req.body;
       
       // Check if email already exists
       db.query('SELECT * FROM users WHERE email = ?', [email], async (err, results) => {
         if (err) {
           console.error('Database error:', err);
           return res.status(500).json({ message: 'Server error' });
         }
         
         if (results.length > 0) {
           return res.status(400).json({ message: 'Email already in use' });
         }
         
         // Hash password
         const hashedPassword = await bcrypt.hash(password, 10);
         
         // Insert new user
         db.query(
           'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
           [username, email, hashedPassword],
           (err, result) => {
             if (err) {
               console.error('Database error:', err);
               return res.status(500).json({ message: 'Server error' });
             }
             
             // Generate JWT token
             const token = jwt.sign({ id: result.insertId, email }, JWT_SECRET, { expiresIn: '7d' });
             
             // Get user data without password
             db.query('SELECT id, username, email, created_at FROM users WHERE id = ?', [result.insertId], (err, userData) => {
               if (err) {
                 console.error('Database error:', err);
                 return res.status(500).json({ message: 'Server error' });
               }
               
               res.status(201).json({
                 message: 'Registration successful',
                 user: userData[0],
                 token
               });
             });
           }
         );
       });
     } catch (error) {
       console.error('Registration error:', error);
       res.status(500).json({ message: 'Server error' });
     }
   });

   // Login endpoint
   app.post('/auth/login', async (req, res) => {
     try {
       const { email, password } = req.body;
       
       // Find user by email
       db.query('SELECT * FROM users WHERE email = ?', [email], async (err, results) => {
         if (err) {
           console.error('Database error:', err);
           return res.status(500).json({ message: 'Server error' });
         }
         
         if (results.length === 0) {
           return res.status(401).json({ message: 'Invalid email or password' });
         }
         
         const user = results[0];
         
         // Compare passwords
         const isPasswordValid = await bcrypt.compare(password, user.password);
         if (!isPasswordValid) {
           return res.status(401).json({ message: 'Invalid email or password' });
         }
         
         // Generate JWT token
         const token = jwt.sign({ id: user.id, email }, JWT_SECRET, { expiresIn: '7d' });
         
         // Return user data without password
         const { password: _, ...userData } = user;
         
         res.status(200).json({
           message: 'Login successful',
           user: userData,
           token
         });
       });
     } catch (error) {
       console.error('Login error:', error);
       res.status(500).json({ message: 'Server error' });
     }
   });

   // Profile endpoint (protected)
   app.get('/auth/profile', (req, res) => {
     try {
       const authHeader = req.headers.authorization;
       if (!authHeader || !authHeader.startsWith('Bearer ')) {
         return res.status(401).json({ message: 'Unauthorized' });
       }
       
       const token = authHeader.split(' ')[1];
       
       // Verify token
       jwt.verify(token, JWT_SECRET, (err, decoded) => {
         if (err) {
           return res.status(401).json({ message: 'Invalid token' });
         }
         
         // Get user data
         db.query('SELECT id, username, email, created_at FROM users WHERE id = ?', [decoded.id], (err, results) => {
           if (err) {
             console.error('Database error:', err);
             return res.status(500).json({ message: 'Server error' });
           }
           
           if (results.length === 0) {
             return res.status(404).json({ message: 'User not found' });
           }
           
           res.status(200).json({
             user: results[0]
           });
         });
       });
     } catch (error) {
       console.error('Profile error:', error);
       res.status(500).json({ message: 'Server error' });
     }
   });

   // Start server
   const PORT = process.env.PORT || 3000;
   app.listen(PORT, () => {
     console.log(`Server running on port ${PORT}`);
   });
   ```

3. Start the server:
   ```bash
   node server.js
   ```

## Flutter App Integration

1. Update the `baseUrl` in the `AuthService` class to point to your API:
   ```dart
   final MySqlDatabaseService _mysqlService = MySqlDatabaseService(
     baseUrl: 'http://your-api-url:3000', // Replace with your actual API URL
   );
   ```

2. Make sure to add the HTTP package to your pubspec.yaml:
   ```yaml
   dependencies:
     http: ^1.1.0
   ```

3. Run `flutter pub get` to install the dependencies.

## Testing

1. Start your API server.
2. Run your Flutter app.
3. Try registering a new user and logging in.

## Security Considerations

1. Always use HTTPS for your API in production.
2. Store sensitive information like API URLs and JWT secrets in environment variables.
3. Implement rate limiting to prevent brute force attacks.
4. Consider adding additional security measures like email verification and two-factor authentication.

## Troubleshooting

- If you encounter CORS issues, make sure your API server has CORS properly configured.
- Check the network tab in your browser's developer tools to see the API requests and responses.
- Use `debugPrint` statements in your Flutter app to log the API responses for debugging.