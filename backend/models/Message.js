const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const messageSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  conversationId: {
    type: String,
    ref: 'Conversation',
    required: true,
    index: true
  },
  sender: {
    type: String,
    ref: 'User',
    required: true,
    index: true
  },
  recipient: {
    type: String,
    ref: 'User',
    required: true,
    index: true
  },
  content: {
    type: String,
    required: true,
    trim: true,
    maxLength: 10000 // Longer than tweets for DMs
  },
  messageType: {
    type: String,
    enum: ['text', 'media', 'system'],
    default: 'text'
  },
  mediaFiles: [{
    url: {
      type: String,
      required: true
    },
    type: {
      type: String,
      enum: ['image', 'video', 'gif'],
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
  readBy: [{
    user: {
      type: String,
      ref: 'User'
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],
  isRead: {
    type: Boolean,
    default: false,
    index: true
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedBy: [{
    type: String,
    ref: 'User'
  }],
  replyTo: {
    type: String,
    ref: 'Message',
    default: null
  },
  reactions: [{
    user: {
      type: String,
      ref: 'User'
    },
    emoji: {
      type: String,
      required: true
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }]
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.reactionsCount = ret.reactions ? ret.reactions.length : 0;
      ret.isReadByRecipient = ret.readBy ? ret.readBy.some(read => read.user !== ret.sender) : false;
      delete ret.__v;
      return ret;
    }
  }
});

// Indexes for optimal query performance
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ sender: 1, createdAt: -1 });
messageSchema.index({ recipient: 1, isRead: 1 });
messageSchema.index({ createdAt: -1 });

// Compound index for conversation pagination
messageSchema.index({ conversationId: 1, createdAt: -1, _id: 1 });

module.exports = mongoose.model('Message', messageSchema);