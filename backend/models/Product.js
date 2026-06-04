const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  barcode: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  category: { type: String, default: 'General' },
  brand: { type: String },
  quantity: { type: String },
  latestPrice: { type: Number, required: true },
  priceHistory: [
    {
      price: { type: Number },
      date: { type: Date, default: Date.now }
    }
  ],
  isPromo: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Product', productSchema);