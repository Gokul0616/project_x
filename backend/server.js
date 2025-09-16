const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const https = require('https');
const dotenv = require('dotenv'); const fs = require('fs');
const path = require('path');

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./routes/auth');
const tweetRoutes = require('./routes/tweets');
const userRoutes = require('./routes/users');
const { router: notificationRoutes } = require('./routes/notifications');
const listRoutes = require('./routes/lists');
const bookmarkRoutes = require('./routes/bookmarks');
const momentRoutes = require('./routes/moments');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ extended: true, limit: '100mb' }));

// Serve static files (uploaded media)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tweets', tweetRoutes);
app.use('/api/users', userRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/lists', listRoutes);
app.use('/api/bookmarks', bookmarkRoutes);
app.use('/api/moments', momentRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Twitter Clone Backend API is running',
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    message: 'Route not found'
  });
});

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// Start server
const PORT = process.env.PORT || 8001;
const options = {
  key: fs.readFileSync('certs/private-key.pem'),
  cert: fs.readFileSync('certs/certificate.pem')
};


const startServer = async () => {
  await connectDB();
  // Create HTTPS server
  // https.createServer(options, app).listen(PORT, () => {
  //   console.log('Server running on https://192.168.1.19:3000');
  // });
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/api/health`);
  });
};

startServer();

module.exports = app;