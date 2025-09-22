const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

// Model to store computed user preferences for faster recommendations
const userPreferenceSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  userId: {
    type: String,
    ref: 'User',
    required: true,
    unique: true
  },
  preferredHashtags: [{
    hashtag: String,
    score: Number,
    lastUpdated: Date
  }],
  preferredTopics: [{
    topic: String,
    score: Number,
    confidence: Number
  }],
  similarUsers: [{
    userId: {
      type: String,
      ref: 'User'
    },
    similarityScore: Number,
    lastCalculated: Date
  }],
  interactionPatterns: {
    peakHours: [Number], // Hours when user is most active
    preferredContentTypes: [{
      type: String, // 'text', 'image', 'video'
      preference: Number
    }],
    avgSessionDuration: Number,
    retweetToLikeRatio: Number
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes
userPreferenceSchema.index({ userId: 1 });
userPreferenceSchema.index({ 'similarUsers.userId': 1 });
userPreferenceSchema.index({ lastUpdated: -1 });

module.exports = mongoose.model('UserPreference', userPreferenceSchema);