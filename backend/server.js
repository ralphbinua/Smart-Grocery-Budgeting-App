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

// Helper to escape regex special characters
function escapeRegex(text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

// Batch search products by names
app.post('/api/products/search-batch', async (req, res) => {
  try {
    const { names } = req.body;
    if (!names || !Array.isArray(names)) {
      return res.status(400).json({ error: 'Names array is required' });
    }

    const results = {};
    for (const rawName of names) {
      if (!rawName || typeof rawName !== 'string') continue;
      const queryName = rawName.trim();
      if (queryName.length === 0) continue;

      // 1. Try exact/substring match
      let product = await Product.findOne({ name: { $regex: escapeRegex(queryName), $options: 'i' } });

      // 2. Fallback: split into words and match documents containing ALL words
      if (!product) {
        const words = queryName.split(/\s+/).filter(w => w.length > 1 && !/^\d+g$|^\d+ml$|^\d+l$|^\d+kg$/i.test(w));
        if (words.length > 0) {
          const andQueries = words.map(w => ({ name: { $regex: escapeRegex(w), $options: 'i' } }));
          product = await Product.findOne({ $and: andQueries });

          // 3. Fallback: match first 2 words if query is multi-word
          if (!product && words.length > 1) {
            const partialQueries = words.slice(0, 2).map(w => ({ name: { $regex: escapeRegex(w), $options: 'i' } }));
            product = await Product.findOne({ $and: partialQueries });
          }
        }
      }

      if (product) {
        results[rawName] = {
          name: product.name,
          price: product.latestPrice,
          category: product.category,
          isPromo: product.isPromo
        };
      } else {
        results[rawName] = null;
      }
    }

    res.status(200).json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Bulk update promo fields (for admin seeding)
// Body: { promos: [ { barcode, isPromo, promoLabel, promoDiscount, promoStore, promoExpiresAt }, ... ] }
app.patch('/api/products/bulk-promo', async (req, res) => {
  try {
    const { promos } = req.body;
    if (!promos || !Array.isArray(promos)) {
      return res.status(400).json({ error: 'promos array is required' });
    }
    const results = [];
    for (const promo of promos) {
      const { barcode, ...fields } = promo;
      if (!barcode) continue;
      const updated = await Product.findOneAndUpdate(
        { barcode },
        { $set: fields },
        { new: true }
      );
      results.push(updated ? { barcode, status: 'updated', name: updated.name } : { barcode, status: 'not_found' });
    }
    res.status(200).json({ results });
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

// Get All Products
app.get('/api/products', async (req, res) => {
  try {
    const products = await Product.find().sort({ name: 1 });
    res.status(200).json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Product
app.put('/api/products/:barcode', async (req, res) => {
  try {
    const updatedProduct = await Product.findOneAndUpdate(
      { barcode: req.params.barcode },
      req.body,
      { new: true }
    );
    if (!updatedProduct) return res.status(404).json({ message: 'Product not found' });
    res.status(200).json(updatedProduct);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete Product
app.delete('/api/products/:barcode', async (req, res) => {
  try {
    const deletedProduct = await Product.findOneAndDelete({ barcode: req.params.barcode });
    if (!deletedProduct) return res.status(404).json({ message: 'Product not found' });
    res.status(200).json({ message: 'Product deleted' });
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
