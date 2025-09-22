const express = require('express');
const { body, validationResult } = require('express-validator');
const Moment = require('../models/Moment');
const Tweet = require('../models/Tweet');
const auth = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/moments
// @desc    Get moments (featured or all)
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const type = req.query.type || 'all'; // 'featured' or 'all'
    const category = req.query.category; // optional category filter

    let query = {};
    
    if (type === 'featured') {
      query.isFeatured = true;
    }

    if (category) {
      query.category = category;
    }

    const moments = await Moment.find(query)
      .populate('tweets', 'content author createdAt')
      .populate('participants', 'username displayName profileImage')
      .sort({ isLive: -1, createdAt: -1 }) // Live moments first, then by date
      .skip(skip)
      .limit(limit);

    res.json(moments);

  } catch (error) {
    console.error('Get moments error:', error);
    res.status(500).json({
      message: 'Server error while fetching moments'
    });
  }
});

// @route   GET /api/moments/:id
// @desc    Get single moment with all tweets
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const moment = await Moment.findById(req.params.id)
      .populate({
        path: 'tweets',
        populate: {
          path: 'author',
          select: 'username displayName profileImage'
        }
      })
      .populate('participants', 'username displayName profileImage');

    if (!moment) {
      return res.status(404).json({
        message: 'Moment not found'
      });
    }

    // Add user-specific data to tweets
    const tweetsWithUserData = moment.tweets.map(tweet => {
      const tweetObj = typeof tweet.toJSON === 'function' ? tweet.toJSON() : tweet;
      tweetObj.isLiked = tweet.likes ? tweet.likes.includes(req.user._id) : false;
      tweetObj.isRetweeted = tweet.retweets ? tweet.retweets.includes(req.user._id) : false;
      tweetObj.likesCount = tweet.likes ? tweet.likes.length : 0;
      tweetObj.retweetsCount = tweet.retweets ? tweet.retweets.length : 0;
      tweetObj.repliesCount = tweet.replies ? tweet.replies.length : 0;
      return tweetObj;
    });

    const momentObj = moment.toJSON();
    momentObj.tweets = tweetsWithUserData;

    res.json(momentObj);

  } catch (error) {
    console.error('Get moment error:', error);
    res.status(500).json({
      message: 'Server error while fetching moment'
    });
  }
});

// @route   POST /api/moments
// @desc    Create a new moment (admin functionality)
// @access  Private
router.post('/', [
  auth,
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 100 })
    .withMessage('Title cannot exceed 100 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),
  body('category')
    .optional()
    .isIn(['Technology', 'Sports', 'Entertainment', 'News', 'Politics', 'Business', 'Health', 'Science', 'Other'])
    .withMessage('Invalid category')
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

    const { title, description, category, hashtags, isLive, isFeatured, coverImage } = req.body;

    const newMoment = new Moment({
      title,
      description,
      category: category || 'Other',
      hashtags: hashtags || [],
      isLive: isLive || false,
      isFeatured: isFeatured || false,
      coverImage: coverImage || null
    });

    await newMoment.save();

    res.status(201).json(newMoment);

  } catch (error) {
    console.error('Create moment error:', error);
    res.status(500).json({
      message: 'Server error while creating moment'
    });
  }
});

// @route   PUT /api/moments/:id
// @desc    Update a moment (admin functionality)
// @access  Private
router.put('/:id', [
  auth,
  body('title')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Title cannot be empty')
    .isLength({ max: 100 })
    .withMessage('Title cannot exceed 100 characters'),
  body('description')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Description cannot be empty')
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters')
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

    const moment = await Moment.findById(req.params.id);

    if (!moment) {
      return res.status(404).json({
        message: 'Moment not found'
      });
    }

    const { title, description, category, hashtags, isLive, isFeatured, coverImage, endDate } = req.body;

    if (title !== undefined) moment.title = title;
    if (description !== undefined) moment.description = description;
    if (category !== undefined) moment.category = category;
    if (hashtags !== undefined) moment.hashtags = hashtags;
    if (isLive !== undefined) moment.isLive = isLive;
    if (isFeatured !== undefined) moment.isFeatured = isFeatured;
    if (coverImage !== undefined) moment.coverImage = coverImage;
    if (endDate !== undefined) moment.endDate = endDate;

    await moment.save();

    res.json(moment);

  } catch (error) {
    console.error('Update moment error:', error);
    res.status(500).json({
      message: 'Server error while updating moment'
    });
  }
});

// @route   DELETE /api/moments/:id
// @desc    Delete a moment (admin functionality)
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const moment = await Moment.findById(req.params.id);

    if (!moment) {
      return res.status(404).json({
        message: 'Moment not found'
      });
    }

    await Moment.findByIdAndDelete(req.params.id);

    res.json({
      message: 'Moment deleted successfully'
    });

  } catch (error) {
    console.error('Delete moment error:', error);
    res.status(500).json({
      message: 'Server error while deleting moment'
    });
  }
});

// @route   POST /api/moments/:id/tweets/:tweetId
// @desc    Add tweet to moment
// @access  Private
router.post('/:id/tweets/:tweetId', auth, async (req, res) => {
  try {
    const moment = await Moment.findById(req.params.id);
    const tweet = await Tweet.findById(req.params.tweetId);

    if (!moment) {
      return res.status(404).json({
        message: 'Moment not found'
      });
    }

    if (!tweet) {
      return res.status(404).json({
        message: 'Tweet not found'
      });
    }

    if (!moment.tweets.includes(req.params.tweetId)) {
      moment.tweets.push(req.params.tweetId);
      
      if (!moment.participants.includes(tweet.author)) {
        moment.participants.push(tweet.author);
      }
      
      await moment.save();
    }

    res.json({
      message: 'Tweet added to moment successfully'
    });

  } catch (error) {
    console.error('Add tweet to moment error:', error);
    res.status(500).json({
      message: 'Server error while adding tweet to moment'
    });
  }
});

// @route   DELETE /api/moments/:id/tweets/:tweetId
// @desc    Remove tweet from moment
// @access  Private
router.delete('/:id/tweets/:tweetId', auth, async (req, res) => {
  try {
    const moment = await Moment.findById(req.params.id);

    if (!moment) {
      return res.status(404).json({
        message: 'Moment not found'
      });
    }

    moment.tweets = moment.tweets.filter(tweetId => tweetId.toString() !== req.params.tweetId);
    await moment.save();

    res.json({
      message: 'Tweet removed from moment successfully'
    });

  } catch (error) {
    console.error('Remove tweet from moment error:', error);
    res.status(500).json({
      message: 'Server error while removing tweet from moment'
    });
  }
});

// @route   GET /api/moments/categories
// @desc    Get available moment categories
// @access  Private
router.get('/categories', auth, async (req, res) => {
  try {
    const categories = ['Technology', 'Sports', 'Entertainment', 'News', 'Politics', 'Business', 'Health', 'Science', 'Other'];
    res.json(categories);
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      message: 'Server error while fetching categories'
    });
  }
});

module.exports = router;