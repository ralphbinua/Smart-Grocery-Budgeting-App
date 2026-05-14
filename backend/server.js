require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/smart-grocery').then(() => {
  console.log('[MongoDB] Connected successfully');
}).catch((err) => {
  console.log('[MongoDB] Connection error:', err.message);
});

// Import Models
const Product = require('./models/Product');
const Trip = require('./models/Trip');

// --- API ROUTES ---

// Root endpoint
app.get('/', (req, res) => {
  res.send('Smart Grocery IoT Backend is running with MongoDB...');
});

// Endpoint for the IoT device (ESP32) to send scan results via HTTP POST
app.post('/scan', (req, res) => {
  const { barcode } = req.body;
  if (!barcode) return res.status(400).json({ error: 'Barcode is required' });
  console.log(`[IoT] Scanned barcode received: ${barcode}`);
  io.emit('new_item_scanned', { barcode });
  res.status(200).json({ success: true, message: 'Scan broadcasted' });
});

// Save a trip (Checkout)
app.post('/api/trips', async (req, res) => {
  try {
    const newTrip = new Trip(req.body);
    const savedTrip = await newTrip.save();
    res.status(201).json(savedTrip);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all trips (For Analytics/History)
app.get('/api/trips', async (req, res) => {
  try {
    const trips = await Trip.find().sort({ date: -1 });
    res.status(200).json(trips);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Save or Update a Product (For price tracking)
app.post('/api/products', async (req, res) => {
  try {
    const { barcode, latestPrice } = req.body;
    let product = await Product.findOne({ barcode });

    if (product) {
      product.priceHistory.push({ price: product.latestPrice }); // Save old price
      product.latestPrice = latestPrice;
      Object.assign(product, req.body); // Update other fields
      await product.save();
    } else {
      product = new Product(req.body);
      await product.save();
    }
    res.status(200).json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Product by Barcode
app.get('/api/products/:barcode', async (req, res) => {
  try {
    const product = await Product.findOne({ barcode: req.params.barcode });
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.status(200).json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log(`[Socket] A client connected: ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`[Socket] Client disconnected: ${socket.id}`);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n==========================================`);
  console.log(`  Smart Grocery Backend Server`);
  console.log(`  Running on: http://localhost:${PORT}`);
  console.log(`==========================================\n`);
});
