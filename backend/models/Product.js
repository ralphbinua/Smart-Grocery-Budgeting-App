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
  isPromo: { type: Boolean, default: false },
  promoLabel: { type: String, default: '' },       // e.g. "Buy 2 Get 1", "10% Off"
  promoDiscount: { type: Number, default: 0 },     // percentage discount (0-100)
  promoStore: { type: String, default: '' },        // e.g. "SM Supermarket", "Puregold"
  promoExpiresAt: { type: Date, default: null }     // promo validity date
}, { timestamps: true });

module.exports = mongoose.model('Product', productSchema);
