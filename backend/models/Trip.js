const mongoose = require('mongoose');

const tripSchema = new mongoose.Schema({
  date: { type: Date, default: Date.now },
  totalSpent: { type: Number, required: true },
  totalSaved: { type: Number, default: 0 },
  items: [
    {
      barcode: String,
      name: String,
      price: Number,
      quantity: Number,
      isAiSwapped: { type: Boolean, default: false }
    }
  ]
}, { timestamps: true });

module.exports = mongoose.model('Trip', tripSchema);
