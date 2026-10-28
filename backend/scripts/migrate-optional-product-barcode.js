require('dotenv').config();
const mongoose = require('mongoose');

async function migrate() {
  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/smart-grocery';
  await mongoose.connect(mongoUri);

  const products = mongoose.connection.collection('products');
  const indexes = await products.indexes();
  const barcodeIndex = indexes.find(
    (index) => index.key?.barcode === 1 && index.unique,
  );

  if (barcodeIndex && !barcodeIndex.sparse) {
    await products.dropIndex(barcodeIndex.name);
  }

  await products.createIndex({ barcode: 1 }, { unique: true, sparse: true });
  console.log('Product barcode index now allows records without a barcode.');
}

migrate()
  .catch((error) => {
    console.error('Could not migrate the product barcode index:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
