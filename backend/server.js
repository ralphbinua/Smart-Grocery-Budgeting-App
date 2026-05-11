const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

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

// Root endpoint
app.get('/', (req, res) => {
  res.send('Smart Grocery IoT Backend is running...');
});

// Endpoint for the IoT device (ESP32) to send scan results via HTTP POST
// Alternatively, the ESP32 can use Socket.io directly.
app.post('/scan', (req, res) => {
  const { barcode } = req.body;
  
  if (!barcode) {
    return res.status(400).json({ error: 'Barcode is required' });
  }

  console.log(`[IoT] Scanned barcode received: ${barcode}`);

  // Broadcast the scan to all connected Flutter apps
  io.emit('new_item_scanned', { barcode });

  res.status(200).json({ success: true, message: 'Scan broadcasted' });
});

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log(`[Socket] A client connected: ${socket.id}`);

  socket.on('disconnect', () => {
    console.log(`[Socket] Client disconnected: ${socket.id}`);
  });

  // Example: Listening for events from the Flutter app
  socket.on('app_status', (data) => {
    console.log(`[App] Status received:`, data);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n==========================================`);
  console.log(`  Smart Grocery Backend Server`);
  console.log(`  Running on: http://localhost:${PORT}`);
  console.log(`  Listening for IoT scans...`);
  console.log(`==========================================\n`);
});
