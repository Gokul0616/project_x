const express = require('express');
const { body, validationResult } = require('express-validator');
const List = require('../models/List');
const User = require('../models/User');
const Tweet = require('../models/Tweet');
const auth = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/lists
// @desc    Get user's lists and pinned lists
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const type = req.query.type || 'user'; // 'user' or 'pinned'

    let query = {};
    
    if (type === 'user') {
      query = { owner: req.user._id };
    } else if (type === 'pinned') {
      query = { pinnedBy: req.user._id };
    }

    const lists = await List.find(query)
      .populate('owner', 'username displayName profileImage')
      .populate('members', 'username displayName profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.json(lists);

  } catch (error) {
    console.error('Get lists error:', error);
    res.status(500).json({
      message: 'Server error while fetching lists'
    });
  }
});

// @route   GET /api/lists/:id
// @desc    Get single list with details
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const list = await List.findById(req.params.id)
      .populate('owner', 'username displayName profileImage')
      .populate('members', 'username displayName profileImage')
      .populate({
        path: 'tweets',
        populate: {
          path: 'author',
          select: 'username displayName profileImage'
        }
      });

    if (!list) {
      return res.status(404).json({
        message: 'List not found'
      });
    }

    // Check if user has access to private list
    if (list.isPrivate && 
        list.owner._id !== req.user._id && 
        !list.subscribers.includes(req.user._id)) {
      return res.status(403).json({
        message: 'Access denied to private list'
      });
    }

    res.json(list);

  } catch (error) {
    console.error('Get list error:', error);
    res.status(500).json({
      message: 'Server error while fetching list'
    });
  }
});

// @route   POST /api/lists
// @desc    Create a new list
// @access  Private
router.post('/', [
  auth,
  body('name')
    .trim()
    .notEmpty()
    .withMessage('List name is required')
    .isLength({ max: 25 })
    .withMessage('List name cannot exceed 25 characters'),
  body('description')
    .optional()
    .isLength({ max: 100 })
    .withMessage('Description cannot exceed 100 characters')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, description, isPrivate } = req.body;

    const newList = new List({
      name,
      description: description || '',
      owner: req.user._id,
      isPrivate: isPrivate || false
    });

    await newList.save();
    await newList.populate('owner', 'username displayName profileImage');

    res.status(201).json(newList);

  } catch (error) {
    console.error('Create list error:', error);
    res.status(500).json({
      message: 'Server error while creating list'
    });
  }
});

// @route   PUT /api/lists/:id
// @desc    Update a list
// @access  Private
router.put('/:id', [
  auth,
  body('name')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('List name cannot be empty')
    .isLength({ max: 25 })
    .withMessage('List name cannot exceed 25 characters'),
  body('description')
    .optional()
    .isLength({ max: 100 })
    .withMessage('Description cannot exceed 100 characters')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const list = await List.findById(req.params.id);

    if (!list) {
      return res.status(404).json({
        message: 'List not found'
      });
    }

    // Check if user owns the list
    if (list.owner.toString() !== req.user._id) {
      return res.status(403).json({
        message: 'Not authorized to update this list'
      });
    }

    const { name, description, isPrivate } = req.body;

    if (name !== undefined) list.name = name;
    if (description !== undefined) list.description = description;
    if (isPrivate !== undefined) list.isPrivate = isPrivate;

    await list.save();
    await list.populate('owner', 'username displayName profileImage');

    res.json(list);

  } catch (error) {
    console.error('Update list error:', error);
    res.status(500).json({
      message: 'Server error while updating list'
    });
  }
});

// @route   DELETE /api/lists/:id
// @desc    Delete a list
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const list = await List.findById(req.params.id);

    if (!list) {
      return res.status(404).json({
        message: 'List not found'
      });
    }

    // Check if user owns the list
    if (list.owner.toString() !== req.user._id) {
      return res.status(403).json({
        message: 'Not authorized to delete this list'
      });
    }

    await List.findByIdAndDelete(req.params.id);

    res.json({
      message: 'List deleted successfully'
    });

  } catch (error) {
    console.error('Delete list error:', error);
    res.status(500).json({
      message: 'Server error while deleting list'
    });
  }
});

// @route   POST /api/lists/:id/pin
// @desc    Pin/unpin a list
// @access  Private
router.post('/:id/pin', auth, async (req, res) => {
  try {
    const list = await List.findById(req.params.id);

    if (!list) {
      return res.status(404).json({
        message: 'List not found'
      });
    }

    const userId = req.user._id;
    const isPinned = list.pinnedBy.includes(userId);

    if (isPinned) {
      list.pinnedBy = list.pinnedBy.filter(id => id.toString() !== userId.toString());
    } else {
      list.pinnedBy.push(userId);
    }

    await list.save();

    res.json({
      message: isPinned ? 'List unpinned' : 'List pinned',
      isPinned: !isPinned
    });

  } catch (error) {
    console.error('Pin list error:', error);
    res.status(500).json({
      message: 'Server error while pinning list'
    });
  }
});

// @route   POST /api/lists/:id/members/:userId
// @desc    Add user to list
// @access  Private
router.post('/:id/members/:userId', auth, async (req, res) => {
  try {
    const list = await List.findById(req.params.id);

    if (!list) {
      return res.status(404).json({
        message: 'List not found'
      });
    }

    // Check if user owns the list
    if (list.owner.toString() !== req.user._id) {
      return res.status(403).json({
        message: 'Not authorized to modify this list'
      });
    }

    const userToAdd = await User.findById(req.params.userId);
    if (!userToAdd) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    if (!list.members.includes(req.params.userId)) {
      list.members.push(req.params.userId);
      await list.save();
    }

    res.json({
      message: 'User added to list successfully'
    });

  } catch (error) {
    console.error('Add member error:', error);
    res.status(500).json({
      message: 'Server error while adding member'
    });
  }
});

// @route   DELETE /api/lists/:id/members/:userId
// @desc    Remove user from list
// @access  Private
router.delete('/:id/members/:userId', auth, async (req, res) => {
  try {
    const list = await List.findById(req.params.id);

    if (!list) {
      return res.status(404).json({
        message: 'List not found'
      });
    }

    // Check if user owns the list
    if (list.owner.toString() !== req.user._id) {
      return res.status(403).json({
        message: 'Not authorized to modify this list'
      });
    }

    list.members = list.members.filter(id => id.toString() !== req.params.userId);
    await list.save();

    res.json({
      message: 'User removed from list successfully'
    });

  } catch (error) {
    console.error('Remove member error:', error);
    res.status(500).json({
      message: 'Server error while removing member'
    });
  }
});

module.exports = router;