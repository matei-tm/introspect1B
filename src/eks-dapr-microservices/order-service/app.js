const express = require('express');

const app = express();
const PORT = process.env.PORT || 3001;
const PUBSUB_NAME = 'messagepubsub';
const TOPIC_NAME = 'orders';

// Configure body parsers with increased limits
app.use(express.json({ limit: '10mb' }));
app.use(express.text({ type: 'text/plain', limit: '10mb' }));
app.use(express.raw({ type: 'application/octet-stream', limit: '10mb' }));
// Add CloudEvents JSON parser
app.use(express.json({ type: 'application/cloudevents+json', limit: '10mb' }));

let receivedMessages = [];
let messageCount = 0;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    service: 'order',
    messagesReceived: messageCount
  });
});

// Dapr subscription endpoint - tells Dapr what topics to subscribe to
app.get('/dapr/subscribe', (req, res) => {
  const subscriptions = [{
    pubsubname: PUBSUB_NAME,
    topic: TOPIC_NAME,
    route: '/orders'
  }];
  console.log('📋 Subscription configuration requested');
  res.status(200).json(subscriptions);
});

// Handler for incoming messages from Dapr
app.post('/orders', (req, res) => {
  try {
    // Extract data from CloudEvents format (req.body.data) or use body directly
    const order = req.body.data || req.body;
    messageCount++;
    
    console.log(`\n📦 [${messageCount}] Received order:`, {
      orderId: order.orderId,
      product: order.product,
      quantity: order.quantity,
      amount: order.totalAmount,
      timestamp: order.timestamp
    });

    // Store last 10 messages
    receivedMessages.unshift({
      ...order,
      receivedAt: new Date().toISOString(),
      messageNumber: messageCount
    });
    if (receivedMessages.length > 10) {
      receivedMessages.pop();
    }

    // Simulate processing
    setTimeout(() => {
      console.log(`✅ Order ${order.orderId} processed successfully`);
    }, 500);

    // Return success to Dapr
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('❌ Error processing message:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Endpoint to view recent messages
app.get('/messages', (req, res) => {
  res.status(200).json({
    totalReceived: messageCount,
    recentMessages: receivedMessages
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Order service listening on port ${PORT}`);
  console.log(`👂 Subscribed to topic: ${TOPIC_NAME}`);
  console.log(`📡 Dapr will send messages to /orders endpoint`);
});
