const express = require('express');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const DAPR_HTTP_PORT = process.env.DAPR_HTTP_PORT || 3500;
const PUBSUB_NAME = 'messagepubsub';
const TOPIC_NAME = 'orders';

app.use(express.json());

let messageCount = 0;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', service: 'product' });
});

// Endpoint to publish messages
app.post('/publish', async (req, res) => {
  try {
    const order = {
      orderId: `order-${Date.now()}-${++messageCount}`,
      customerId: `customer-${Math.floor(Math.random() * 1000)}`,
      product: ['laptop', 'phone', 'tablet', 'monitor'][Math.floor(Math.random() * 4)],
      quantity: Math.floor(Math.random() * 5) + 1,
      totalAmount: (Math.random() * 1000 + 100).toFixed(2),
      timestamp: new Date().toISOString()
    };

    // Publish to Dapr pubsub
    const daprUrl = `http://localhost:${DAPR_HTTP_PORT}/v1.0/publish/${PUBSUB_NAME}/${TOPIC_NAME}`;
    
    await axios.post(daprUrl, order, {
      headers: { 'Content-Type': 'application/json' }
    });

    console.log(`✅ Published order: ${order.orderId}`, order);
    res.status(200).json({ 
      success: true, 
      message: 'Order published successfully',
      order 
    });
  } catch (error) {
    console.error('❌ Error publishing message:', error.message);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Auto-publish messages every 5 seconds
setInterval(async () => {
  try {
    await axios.post(`http://localhost:${PORT}/publish`);
  } catch (error) {
    console.error('❌ Auto-publish error:', error.message);
  }
}, 5000);

app.listen(PORT, () => {
  console.log(`🚀 Publisher service listening on port ${PORT}`);
  console.log(`📡 Dapr sidecar expected on port ${DAPR_HTTP_PORT}`);
  console.log(`📢 Publishing to topic: ${TOPIC_NAME}`);
});
