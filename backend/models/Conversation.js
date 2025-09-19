const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const conversationSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  participants: [{
    type: String,
    ref: 'User',
    required: true
  }],
  isGroup: {
    type: Boolean,
    default: false
  },
  groupName: {
    type: String,
    maxLength: 100
  },
  groupImage: {
    type: String
  },
  lastMessage: {
    type: String,
    ref: 'Message'
  },
  lastActivity: {
    type: Date,
    default: Date.now,
    index: true
  },
  unreadCounts: [{
    user: {
      type: String,
      ref: 'User'
    },
    count: {
      type: Number,
      default: 0
    }
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: String,
    ref: 'User',
    required: true
  },
  // Settings for each participant
  participantSettings: [{
    user: {
      type: String,
      ref: 'User'
    },
    isMuted: {
      type: Boolean,
      default: false
    },
    muteUntil: {
      type: Date
    },
    customName: {
      type: String,
      maxLength: 50
    },
    joinedAt: {
      type: Date,
      default: Date.now
    },
    leftAt: {
      type: Date
    }
  }]
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.participantCount = ret.participants ? ret.participants.length : 0;
      ret.totalUnreadMessages = ret.unreadCounts ? 
        ret.unreadCounts.reduce((total, uc) => total + uc.count, 0) : 0;
      delete ret.__v;
      return ret;
    }
  }
});

// Indexes for optimal query performance
conversationSchema.index({ participants: 1, lastActivity: -1 });
conversationSchema.index({ lastActivity: -1 });
conversationSchema.index({ isActive: 1, lastActivity: -1 });

// Compound index for user's conversations
conversationSchema.index({ participants: 1, isActive: 1, lastActivity: -1 });

// Helper methods
conversationSchema.methods.getUnreadCountForUser = function(userId) {
  const userUnread = this.unreadCounts.find(uc => uc.user.toString() === userId);
  return userUnread ? userUnread.count : 0;
};

conversationSchema.methods.incrementUnreadForUser = function(userId) {
  const userUnread = this.unreadCounts.find(uc => uc.user.toString() === userId);
  if (userUnread) {
    userUnread.count += 1;
  } else {
    this.unreadCounts.push({ user: userId, count: 1 });
  }
};

conversationSchema.methods.resetUnreadForUser = function(userId) {
  const userUnread = this.unreadCounts.find(uc => uc.user.toString() === userId);
  if (userUnread) {
    userUnread.count = 0;
  }
};

conversationSchema.methods.getOtherParticipant = function(currentUserId) {
  if (this.isGroup) {
    return null; // Group conversations don't have a single "other" participant
  }
  return this.participants.find(p => p.toString() !== currentUserId);
};

module.exports = mongoose.model('Conversation', conversationSchema);