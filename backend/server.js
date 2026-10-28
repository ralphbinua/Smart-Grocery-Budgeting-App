require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

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
  res.send('Smart Grocery Backend is running with MongoDB...');
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
    const { barcode, latestPrice, name, brand, quantity, category } = req.body;
    const cleanName = typeof name === 'string' ? name.trim() : '';
    const cleanBarcode = typeof barcode === 'string' ? barcode.trim() : '';
    const cleanBrand = typeof brand === 'string' ? brand.trim() : '';
    const cleanQuantity = typeof quantity === 'string' ? quantity.trim() : '';

    if (!cleanName) {
      return res.status(400).json({ error: 'Product name is required' });
    }
    if (latestPrice != null && (!Number.isFinite(Number(latestPrice)) || Number(latestPrice) < 0)) {
      return res.status(400).json({ error: 'latestPrice must be a non-negative number' });
    }

    let product = cleanBarcode
      ? await Product.findOne({ barcode: cleanBarcode })
      : null;

    // A barcode miss can still refer to a catalog product recognized by name,
    // brand, and package size. Reuse it instead of creating a duplicate.
    if (!product) {
      const candidates = await Product.find({
        name: { $regex: `^${escapeRegex(cleanName)}$`, $options: 'i' },
      });
      const normalizedBrand = cleanBrand.toLowerCase();
      const normalizedQuantity = cleanQuantity.toLowerCase();
      const matches = candidates.filter((candidate) =>
        (!normalizedBrand || (candidate.brand || '').trim().toLowerCase() === normalizedBrand) &&
        (!normalizedQuantity || (candidate.quantity || '').trim().toLowerCase() === normalizedQuantity)
      );
      if (matches.length === 1) product = matches[0];
    }

    if (product) {
      if (cleanBarcode && !product.barcode) {
        product.barcode = cleanBarcode;
      }
      if (latestPrice != null && Number(product.latestPrice) !== Number(latestPrice)) {
        if (product.latestPrice != null) {
          product.priceHistory.push({ price: product.latestPrice });
        }
        product.latestPrice = Number(latestPrice);
      }
      if (cleanName) product.name = cleanName;
      if (cleanBrand) product.brand = cleanBrand;
      if (cleanQuantity) product.quantity = cleanQuantity;
      if (typeof category === 'string' && category.trim()) {
        product.category = category.trim();
      }
    } else {
      product = new Product({
        ...(cleanBarcode ? { barcode: cleanBarcode } : {}),
        name: cleanName,
        ...(cleanBrand ? { brand: cleanBrand } : {}),
        ...(cleanQuantity ? { quantity: cleanQuantity } : {}),
        ...(typeof category === 'string' && category.trim()
          ? { category: category.trim() }
          : {}),
        ...(latestPrice != null ? { latestPrice: Number(latestPrice) } : {}),
      });
    }

    await product.save();
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

app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n==========================================`);
  console.log(`  Smart Grocery Backend Server`);
  console.log(`  Running on: http://localhost:${PORT}`);
  console.log(`==========================================\n`);
});