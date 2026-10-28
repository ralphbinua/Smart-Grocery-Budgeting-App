const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  barcode: { type: String, trim: true, sparse: true, unique: true },
  name: { type: String, required: true, trim: true },
  category: { type: String, default: 'General' },
  brand: { type: String },
  quantity: { type: String },
  latestPrice: { type: Number, min: 0 },
  priceHistory: [
    {
      price: { type: Number },
      date: { type: Date, default: Date.now }
    }
  ]
}, { timestamps: true });

module.exports = mongoose.model('Product', productSchema);