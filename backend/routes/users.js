const express = require('express');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const Tweet = require('../models/Tweet');
const auth = require('../middleware/auth');

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, '../uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

// Multer configuration for avatar uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'avatar-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  }
});

const router = express.Router();

// @route   GET /api/users/search/:query
// @desc    Search users by username or display name (for mentions)
// @access  Private
router.get('/search/:query', auth, async (req, res) => {
  try {
    const query = req.params.query.trim();

    if (!query || query.length < 1) {
      return res.json([]);
    }

    const users = await User.find({
      $or: [
        { username: { $regex: query, $options: 'i' } },
        { displayName: { $regex: query, $options: 'i' } }
      ]
    })
      .select('_id username displayName profileImage')
      .limit(10);

    res.json(users);

  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      message: 'Server error while searching users'
    });
  }
});

// @route   GET /api/users/:username
// @desc    Get user profile by username
// @access  Private
router.get('/:username', auth, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username })
      .select('-password');

    if (!user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    res.json({
      user: user.toJSON()
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      message: 'Server error while fetching user'
    });
  }
});

// @route   GET /api/users/:username/tweets
// @desc    Get user's tweets
// @access  Private
router.get('/:username/tweets', auth, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username });

    if (!user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const tweets = await Tweet.find({ author: user._id })
      .populate('author', 'username displayName profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Add user-specific data (isLiked, isRetweeted)
    const tweetsWithUserData = tweets.map(tweet => {
      const tweetObj = tweet.toJSON();
      tweetObj.isLiked = tweet.likes.includes(req.user._id);
      tweetObj.isRetweeted = tweet.retweets.includes(req.user._id);
      return tweetObj;
    });

    res.json(tweetsWithUserData);

  } catch (error) {
    console.error('Get user tweets error:', error);
    res.status(500).json({
      message: 'Server error while fetching user tweets'
    });
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', [
  auth,
  body('displayName')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Display name cannot be empty')
    .isLength({ max: 50 })
    .withMessage('Display name cannot exceed 50 characters'),
  body('bio')
    .optional()
    .isLength({ max: 160 })
    .withMessage('Bio cannot exceed 160 characters')
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

    const { displayName, bio, profileImage } = req.body;
    const updateData = {};

    if (displayName !== undefined) updateData.displayName = displayName;
    if (bio !== undefined) updateData.bio = bio;
    if (profileImage !== undefined) updateData.profileImage = profileImage;

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      updateData,
      { new: true, runValidators: true }
    ).select('-password');

    res.json({
      message: 'Profile updated successfully',
      user: updatedUser.toJSON()
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      message: 'Server error while updating profile'
    });
  }
});

// @route   GET /api/users/:username/replies
// @desc    Get user's replies (tweets that are replies to other tweets)
// @access  Private
router.get('/:username/replies', auth, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username });

    if (!user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Find tweets by this user that have a parentTweet (are replies)
    const replies = await Tweet.find({
      author: user._id,
      parentTweet: { $ne: null }
    })
      .populate('author', 'username displayName profileImage')
      .populate('parentTweet', 'content author')
      .populate({
        path: 'parentTweet',
        populate: {
          path: 'author',
          select: 'username displayName profileImage'
        }
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Add user-specific data (isLiked, isRetweeted)
    const repliesWithUserData = replies.map(reply => {
      const replyObj = reply.toJSON();
      replyObj.isLiked = reply.likes.includes(req.user._id);
      replyObj.isRetweeted = reply.retweets.includes(req.user._id);
      return replyObj;
    });

    res.json(repliesWithUserData);

  } catch (error) {
    console.error('Get user replies error:', error);
    res.status(500).json({
      message: 'Server error while fetching user replies'
    });
  }
});

// @route   GET /api/users/:username/likes
// @desc    Get tweets liked by user
// @access  Private
router.get('/:username/likes', auth, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.params.username });

    if (!user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Find tweets that include this user's ID in their likes array
    const likedTweets = await Tweet.find({
      likes: { $in: [user._id] }
    })
      .populate('author', 'username displayName profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Add user-specific data (all will be liked since we filtered by likes)
    const tweetsWithUserData = likedTweets.map(tweet => {
      const tweetObj = tweet.toJSON();
      tweetObj.isLiked = true; // All tweets in this list are liked by the user
      tweetObj.isRetweeted = tweet.retweets.includes(req.user._id);
      return tweetObj;
    });

    res.json(tweetsWithUserData);

  } catch (error) {
    console.error('Get user liked tweets error:', error);
    res.status(500).json({
      message: 'Server error while fetching user liked tweets'
    });
  }
});

// @route   GET /api/users/:username/follow-status
// @desc    Get follow status between current user and target user
// @access  Private
router.get('/:username/follow-status', auth, async (req, res) => {
  try {
    const targetUser = await User.findOne({ username: req.params.username });

    if (!targetUser) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    const currentUser = await User.findById(req.user._id);
    const isFollowing = currentUser.following.includes(targetUser._id);
    const isFollowedBy = targetUser.followers.includes(currentUser._id);

    res.json({
      isFollowing,
      isFollowedBy,
      followersCount: targetUser.followers.length,
      followingCount: targetUser.following.length
    });

  } catch (error) {
    console.error('Get follow status error:', error);
    res.status(500).json({
      message: 'Server error while getting follow status'
    });
  }
});

// @route   POST /api/users/:username/follow
// @desc    Follow/unfollow a user
// @access  Private
router.post('/:username/follow', auth, async (req, res) => {
  try {
    const userToFollow = await User.findOne({ username: req.params.username });

    if (!userToFollow) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    if (userToFollow._id === req.user._id) {
      return res.status(400).json({
        message: 'You cannot follow yourself'
      });
    }

    const currentUser = await User.findById(req.user._id);
    const isFollowing = currentUser.following.includes(userToFollow._id);

    if (isFollowing) {
      // Unfollow
      currentUser.following = currentUser.following.filter(id => id !== userToFollow._id);
      userToFollow.followers = userToFollow.followers.filter(id => id !== currentUser._id);
    } else {
      // Follow
      currentUser.following.push(userToFollow._id);
      userToFollow.followers.push(currentUser._id);
    }

    await currentUser.save();
    await userToFollow.save();

    res.json({
      message: isFollowing ? 'User unfollowed' : 'User followed',
      isFollowing: !isFollowing,
      followersCount: userToFollow.followers.length
    });

  } catch (error) {
    console.error('Follow user error:', error);
    res.status(500).json({
      message: 'Server error while following user'
    });
  }
});

// @route   POST /api/users/profile/avatar
// @desc    Upload profile avatar
// @access  Private
router.post('/profile/avatar', auth, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        message: 'No avatar file uploaded'
      });
    }

    // Validate file type
    if (!req.file.mimetype.startsWith('image/')) {
      return res.status(400).json({
        message: 'Only image files are allowed'
      });
    }

    // Validate file size (max 5MB)
    if (req.file.size > 5 * 1024 * 1024) {
      return res.status(400).json({
        message: 'File size too large. Maximum size is 5MB'
      });
    }

    const avatarUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { profileImage: avatarUrl },
      { new: true, runValidators: true }
    ).select('-password');

    res.json({
      message: 'Avatar updated successfully',
      user: updatedUser.toJSON()
    });

  } catch (error) {
    console.error('Avatar upload error:', error);
    res.status(500).json({
      message: 'Server error while uploading avatar'
    });
  }
});

module.exports = router;
