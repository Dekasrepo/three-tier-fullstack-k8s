// server.js - Backend API
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection from environment variables
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/userdb';
const DB_PASSWORD = process.env.DB_PASSWORD || 'defaultpassword';
const API_KEY = process.env.API_KEY || 'default-api-key';

// Configuration from ConfigMap
const APP_NAME = process.env.APP_NAME || 'User Management System';
const MAX_USERS = parseInt(process.env.MAX_USERS) || 100;
const DEFAULT_ROLE = process.env.DEFAULT_ROLE || 'user';

console.log(`Starting ${APP_NAME}...`);
console.log(`MongoDB URI: ${MONGO_URI}`);
console.log(`Max Users: ${MAX_USERS}`);

// Connect to MongoDB
mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB'))
.catch(err => console.error('❌ MongoDB connection error:', err));

// User Schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  role: { type: String, enum: ['admin', 'user', 'guest'], default: DEFAULT_ROLE },
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

// API Key validation middleware
const validateApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  if (apiKey && apiKey === API_KEY) {
    next();
  } else {
    res.status(401).json({ error: 'Unauthorized: Invalid API Key' });
  }
};

// ==================== ROUTES ====================

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// Get configuration
app.get('/api/config', (req, res) => {
  res.json({
    appName: APP_NAME,
    maxUsers: MAX_USERS,
    defaultRole: DEFAULT_ROLE,
    environment: process.env.ENVIRONMENT || 'development',
    version: process.env.APP_VERSION || '1.0.0'
  });
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user by ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new user (with API key validation)
app.post('/api/users', validateApiKey, async (req, res) => {
  try {
    const userCount = await User.countDocuments();
    if (userCount >= MAX_USERS) {
      return res.status(400).json({ error: `Maximum users limit (${MAX_USERS}) reached` });
    }

    const { name, email, role } = req.body;
    
    // Check if email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    const user = new User({ name, email, role: role || DEFAULT_ROLE });
    await user.save();
    
    res.status(201).json(user);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update user
app.put('/api/users/:id', validateApiKey, async (req, res) => {
  try {
    const { name, email, role } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { name, email, role },
      { new: true, runValidators: true }
    );
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete user
app.delete('/api/users/:id', validateApiKey, async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ message: 'User deleted successfully', user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get statistics
app.get('/api/stats', async (req, res) => {
  try {
    const total = await User.countDocuments();
    const admins = await User.countDocuments({ role: 'admin' });
    const activeUsers = await User.countDocuments({ role: { $ne: 'guest' } });
    
    res.json({
      totalUsers: total,
      adminCount: admins,
      activeUsers: activeUsers
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.ENVIRONMENT || 'development'}`);
});