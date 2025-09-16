const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const BookmarkSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  user: {
    type: String,
    ref: 'User',
    required: true
  },
  tweet: {
    type: String,
    ref: 'Tweet',
    required: true
  }
}, {
  timestamps: true
});

// Compound index to ensure user can only bookmark a tweet once
BookmarkSchema.index({ user: 1, tweet: 1 }, { unique: true });

module.exports = mongoose.model('Bookmark', BookmarkSchema);