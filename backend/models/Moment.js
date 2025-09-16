const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const MomentSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  title: {
    type: String,
    required: true,
    maxlength: 100
  },
  description: {
    type: String,
    required: true,
    maxlength: 500
  },
  category: {
    type: String,
    required: true,
    enum: ['Technology', 'Sports', 'Entertainment', 'News', 'Politics', 'Business', 'Health', 'Science', 'Other'],
    default: 'Other'
  },
  tweets: [{
    type: String,
    ref: 'Tweet'
  }],
  participants: [{
    type: String,
    ref: 'User'
  }],
  hashtags: [String],
  isLive: {
    type: Boolean,
    default: false
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  coverImage: {
    type: String,
    default: null
  },
  startDate: {
    type: Date,
    default: Date.now
  },
  endDate: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Virtual for tweet count
MomentSchema.virtual('tweetCount').get(function() {
  return this.tweets.length;
});

// Virtual for participant count
MomentSchema.virtual('participantCount').get(function() {
  return this.participants.length;
});

// Include virtuals when converting to JSON
MomentSchema.set('toJSON', { virtuals: true });

// Index for efficient querying
MomentSchema.index({ category: 1, createdAt: -1 });
MomentSchema.index({ isFeatured: 1, createdAt: -1 });
MomentSchema.index({ isLive: 1, createdAt: -1 });

module.exports = mongoose.model('Moment', MomentSchema);