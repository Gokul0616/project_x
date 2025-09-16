const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

// New model to track user interactions for collaborative filtering
const userInteractionSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  userId: {
    type: String,
    ref: 'User',
    required: true
  },
  tweetId: {
    type: String,
    ref: 'Tweet',
    required: true
  },
  interactionType: {
    type: String,
    enum: ['like', 'retweet', 'reply', 'view', 'click', 'share'],
    required: true
  },
  weight: {
    type: Number,
    default: 1 // Like=1, Retweet=2, Reply=3, View=0.1, Click=0.5
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  sessionId: {
    type: String // Track user sessions for temporal patterns
  }
}, {
  timestamps: true
});

// Indexes for efficient querying (fixed duplicate index warning)
userInteractionSchema.index({ userId: 1, timestamp: -1 });
userInteractionSchema.index({ tweetId: 1, interactionType: 1 });
userInteractionSchema.index({ interactionType: 1 });
userInteractionSchema.index({ timestamp: -1 });

module.exports = mongoose.model('UserInteraction', userInteractionSchema);