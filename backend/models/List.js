const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const ListSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  name: {
    type: String,
    required: true,
    maxlength: 25
  },
  description: {
    type: String,
    maxlength: 100,
    default: ''
  },
  owner: {
    type: String,
    ref: 'User',
    required: true
  },
  members: [{
    type: String,
    ref: 'User'
  }],
  subscribers: [{
    type: String,
    ref: 'User'
  }],
  isPrivate: {
    type: Boolean,
    default: false
  },
  tweets: [{
    type: String,
    ref: 'Tweet'
  }],
  pinnedBy: [{
    type: String,
    ref: 'User'
  }]
}, {
  timestamps: true
});

// Virtual for member count
ListSchema.virtual('memberCount').get(function() {
  return this.members.length;
});

// Virtual for subscriber count
ListSchema.virtual('subscriberCount').get(function() {
  return this.subscribers.length;
});

// Include virtuals when converting to JSON
ListSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('List', ListSchema);