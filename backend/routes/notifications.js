const express = require('express');
const Notification = require('../models/Notification');
const auth = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/notifications
// @desc    Get user notifications
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user._id })
      .populate('fromUserId', 'username displayName profileImage')
      .populate('tweetId', 'content')
      .sort({ createdAt: -1 })
      .limit(50);

    res.json(notifications);
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      message: 'Server error fetching notifications'
    });
  }
});

// @route   PATCH /api/notifications/:id/read
// @desc    Mark notification as read
// @access  Private
router.patch('/:id/read', auth, async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        message: 'Notification not found'
      });
    }

    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({
      message: 'Server error marking notification as read'
    });
  }
});

// @route   PATCH /api/notifications/read-all
// @desc    Mark all notifications as read
// @access  Private
router.patch('/read-all', auth, async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { isRead: true }
    );

    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all notifications as read error:', error);
    res.status(500).json({
      message: 'Server error marking all notifications as read'
    });
  }
});

// @route   POST /api/notifications
// @desc    Create notification (internal use)
// @access  Private
router.post('/', auth, async (req, res) => {
  try {
    const { userId, type, title, message, tweetId, data } = req.body;

    // Don't create notification for yourself
    if (userId === req.user._id.toString()) {
      return res.status(400).json({
        message: 'Cannot create notification for yourself'
      });
    }

    const notification = new Notification({
      userId,
      fromUserId: req.user._id,
      type,
      title,
      message,
      tweetId,
      data
    });

    await notification.save();
    
    // Populate the notification before sending response
    await notification.populate('fromUserId', 'username displayName profileImage');
    if (tweetId) {
      await notification.populate('tweetId', 'content');
    }

    res.status(201).json(notification);
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({
      message: 'Server error creating notification'
    });
  }
});

// Helper function to create notifications
const createNotification = async (userId, fromUserId, type, title, message, tweetId = null, data = null) => {
  try {
    // Don't create notification for yourself
    if (userId === fromUserId) {
      return;
    }

    const notification = new Notification({
      userId,
      fromUserId,
      type,
      title,
      message,
      tweetId,
      data
    });

    await notification.save();
    return notification;
  } catch (error) {
    console.error('Create notification helper error:', error);
  }
};

module.exports = { router, createNotification };