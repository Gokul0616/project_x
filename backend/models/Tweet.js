const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const tweetSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  content: {
    type: String,
    required: true,
    trim: true
  },
  author: {
    type: String,
    ref: 'User',
    required: true
  },
  imageUrl: {
    type: String,
    default: null
  },
  mediaFiles: [{
    url: {
      type: String,
      required: true
    },
    type: {
      type: String,
      enum: ['image', 'video'],
      required: true
    },
    filename: {
      type: String,
      required: true
    },
    size: {
      type: Number,
      required: true
    },
    thumbnailUrl: {
      type: String // For video thumbnails
    }
  }],
  hashtags: [{
    type: String,
    lowercase: true
  }],
  mentions: [{
    type: String,
    ref: 'User'
  }],
  likes: [{
    type: String,
    ref: 'User'
  }],
  retweets: [{
    type: String,
    ref: 'User'
  }],
  replies: [{
    type: String,
    ref: 'Tweet'
  }],
  parentTweet: {
    type: String,
    ref: 'Tweet',
    default: null
  },
  isRetweet: {
    type: Boolean,
    default: false
  },
  originalTweet: {
    type: String,
    ref: 'Tweet',
    default: null
  },
  quotedTweet: {
    type: String,
    ref: 'Tweet',
    default: null
  },
  isQuoteTweet: {
    type: Boolean,
    default: false
  },
  threadId: {
    type: String,
    ref: 'Tweet',
    default: null
  },
  threadOrder: {
    type: Number,
    default: 1
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function (doc, ret) {
      ret.likesCount = ret.likes ? ret.likes.length : 0;
      ret.retweetsCount = ret.retweets ? ret.retweets.length : 0;
      ret.repliesCount = ret.replies ? ret.replies.length : 0;
      delete ret.__v;
      return ret;
    }
  }
});

// Index for better query performance
tweetSchema.index({ createdAt: -1 });
tweetSchema.index({ author: 1 });
tweetSchema.index({ content: 'text' }); // Text index for search
tweetSchema.index({ hashtags: 1 });
tweetSchema.index({ mentions: 1 });
tweetSchema.index({ imageUrl: 1 }); // For media filtering
// Separate indexes for array fields to avoid "parallel arrays" error
tweetSchema.index({ likes: 1 }); // For likes-based queries
tweetSchema.index({ retweets: 1 }); // For retweets-based queries

module.exports = mongoose.model('Tweet', tweetSchema);
