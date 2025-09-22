const express = require('express');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const ffmpeg = require('fluent-ffmpeg');
const ffmpegStatic = require('ffmpeg-static');
const Tweet = require('../models/Tweet');
const User = require('../models/User');
const auth = require('../middleware/auth');
const { createNotification } = require('./notifications');
const RecommendationEngine = require('../services/RecommendationEngine');

// Set ffmpeg path
ffmpeg.setFfmpegPath(ffmpegStatic);

const router = express.Router();
const allowedExtensions = ['.mp4', '.mov', '.avi', '.webm', '.mkv', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, '../uploads');
fs.mkdir(uploadsDir, { recursive: true }).catch(console.error);

// Multer configuration for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (
    (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/'))
    // ||
    // (file.mimetype === 'application/octet-stream' && allowedExtensions.includes(ext))
  ) {
    cb(null, true);
  } else {
    cb(new Error('Only image and video files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  }
});

// @route   POST /api/tweets/upload-media
// @desc    Upload media files (images/videos)
// @access  Private
router.post('/upload-media', auth, upload.array('media', 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'No files uploaded' });
    }

    const mediaFiles = [];

    for (const file of req.files) {
      const mediaFile = {
        url: `${req.protocol}://${req.get('host')}/uploads/${file.filename}`,
        type: file.mimetype.startsWith('image/') ? 'image' : 'video',
        filename: file.filename,
        originalName: file.originalname,
        size: file.size,
        path: file.path
      };

      // Generate thumbnail for videos
      if (mediaFile.type === 'video') {
        try {
          const thumbnailFilename = `thumb_${file.filename.replace(/\.[^/.]+$/, '.jpg')}`;
          const thumbnailPath = path.join(uploadsDir, thumbnailFilename);

          await generateVideoThumbnail(file.path, thumbnailPath);
          mediaFile.thumbnailUrl = `${req.protocol}://${req.get('host')}/uploads/${thumbnailFilename}`;
        } catch (error) {
          console.error('Failed to generate thumbnail:', error);
          // Continue without thumbnail if generation fails
        }
      }

      mediaFiles.push(mediaFile);
    }

    res.json({
      success: true,
      mediaFiles: mediaFiles
    });
  } catch (error) {
    console.error('Media upload error:', error);
    res.status(500).json({ message: 'Error uploading media files' });
  }
});

// Helper function to generate video thumbnail
const generateVideoThumbnail = (videoPath, outputPath) => {
  return new Promise((resolve, reject) => {
    ffmpeg(videoPath)
      .screenshots({
        timestamps: ['00:00:01'],
        filename: path.basename(outputPath),
        folder: path.dirname(outputPath),
        size: '320x240'
      })
      .on('end', () => {
        resolve(outputPath);
      })
      .on('error', (err) => {
        console.error('Error generating thumbnail:', err);
        reject(err);
      });
  });
};

// Helper function to extract hashtags and mentions from content
const extractHashtagsAndMentions = (content) => {
  const hashtags = [];
  const mentions = [];

  // Extract hashtags (e.g., #flutter, #coding)
  const hashtagRegex = /#(\w+)/g;
  let hashtagMatch;
  while ((hashtagMatch = hashtagRegex.exec(content)) !== null) {
    hashtags.push(hashtagMatch[1].toLowerCase());
  }

  // Extract mentions (e.g., @username)
  const mentionRegex = /@(\w+)/g;
  let mentionMatch;
  while ((mentionMatch = mentionRegex.exec(content)) !== null) {
    mentions.push(mentionMatch[1].toLowerCase());
  }

  return { hashtags, mentions };
};

// @route   GET /api/tweets/search/:query
// @desc    Search tweets by content, hashtags, or mentions with advanced filtering
// @access  Private
router.get('/search/:query', auth, async (req, res) => {
  try {
    const query = req.params.query.trim();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Enhanced parameters for advanced search
    const sortBy = req.query.sortBy || 'relevance'; // relevance, date, engagement
    const mediaType = req.query.mediaType; // photo, video, any
    const hasMedia = req.query.hasMedia === 'true'; // true, false

    if (!query || query.length < 1) {
      return res.json([]);
    }

    let searchConditions = [];

    // If query starts with #, search hashtags
    if (query.startsWith('#')) {
      const hashtag = query.substring(1).toLowerCase();
      searchConditions.push({ hashtags: hashtag });
    }
    // If query starts with @, search mentions
    else if (query.startsWith('@')) {
      const mention = query.substring(1).toLowerCase();
      searchConditions.push({ mentions: mention });
    }
    // Otherwise, search content, hashtags, and mentions
    else {
      searchConditions = [
        { content: { $regex: query, $options: 'i' } },
        { hashtags: { $regex: query, $options: 'i' } },
        { mentions: { $regex: query, $options: 'i' } }
      ];
    }

    // Build the main query
    let mainQuery = {
      $or: searchConditions
    };

    // Add media filtering
    if (hasMedia) {
      mainQuery.imageUrl = { $ne: null, $exists: true };
    }

    if (mediaType === 'photo') {
      mainQuery.imageUrl = {
        $ne: null,
        $exists: true,
        $not: { $regex: /\.(mp4|avi|mov|wmv|flv|webm|mkv)$/i }
      };
    } else if (mediaType === 'video') {
      mainQuery.imageUrl = {
        $ne: null,
        $exists: true,
        $regex: /\.(mp4|avi|mov|wmv|flv|webm|mkv)$/i
      };
    }

    // Apply sorting based on sortBy parameter
    let sortOptions = {};
    if (sortBy === 'date') {
      sortOptions = { createdAt: -1 };
    } else if (sortBy === 'engagement') {
      // Sort by engagement score (combination of likes and retweets)
      const tweets = await Tweet.aggregate([
        { $match: mainQuery },
        {
          $addFields: {
            engagementScore: {
              $add: [
                { $size: { $ifNull: ['$likes', []] } },
                { $multiply: [{ $size: { $ifNull: ['$retweets', []] } }, 2] } // Weight retweets more
              ]
            }
          }
        },
        { $sort: { engagementScore: -1, createdAt: -1 } },
        { $skip: skip },
        { $limit: limit },
        {
          $lookup: {
            from: 'users',
            localField: 'author',
            foreignField: '_id',
            as: 'author',
            pipeline: [{ $project: { username: 1, displayName: 1, profileImage: 1 } }]
          }
        },
        {
          $lookup: {
            from: 'users',
            localField: 'mentions',
            foreignField: '_id',
            as: 'mentions',
            pipeline: [{ $project: { username: 1, displayName: 1 } }]
          }
        },
        {
          $addFields: {
            author: { $arrayElemAt: ['$author', 0] }
          }
        }
      ]);

      // Add user-specific data for aggregated results
      const tweetsWithUserData = tweets.map(tweet => {
        const tweetObj = { ...tweet };
        tweetObj.isLiked = tweet.likes ? tweet.likes.includes(req.user._id) : false;
        tweetObj.isRetweeted = tweet.retweets ? tweet.retweets.includes(req.user._id) : false;
        tweetObj.likesCount = tweet.likes ? tweet.likes.length : 0;
        tweetObj.retweetsCount = tweet.retweets ? tweet.retweets.length : 0;
        tweetObj.repliesCount = tweet.replies ? tweet.replies.length : 0;
        return tweetObj;
      });

      return res.json(tweetsWithUserData);
    } else {
      // Default relevance-based sorting (by creation date for now, can be enhanced)
      sortOptions = { createdAt: -1 };
    }

    // Apply sorting and pagination for non-aggregated queries
    const tweets = await Tweet.find(mainQuery)
      .populate('author', 'username displayName profileImage')
      .populate('mentions', 'username displayName')
      .sort(sortOptions)
      .skip(skip)
      .limit(limit);

    // Add user-specific data (isLiked, isRetweeted)
    const tweetsWithUserData = tweets.map(tweet => {
      const tweetObj = typeof tweet.toJSON === 'function' ? tweet.toJSON() : tweet;
      tweetObj.isLiked = tweet.likes.includes(req.user._id);
      tweetObj.isRetweeted = tweet.retweets.includes(req.user._id);
      return tweetObj;
    });

    res.json(tweetsWithUserData);

  } catch (error) {
    console.error('Search tweets error:', error);
    res.status(500).json({
      message: 'Server error while searching tweets'
    });
  }
});

// @route   GET /api/tweets/trending
// @desc    Get trending hashtags
// @access  Private
router.get('/trending', auth, async (req, res) => {
  try {
    // Get hashtags from recent tweets (last 24 hours)
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const trendingHashtags = await Tweet.aggregate([
      {
        $match: {
          createdAt: { $gte: oneDayAgo },
          hashtags: { $exists: true, $not: { $size: 0 } }
        }
      },
      { $unwind: '$hashtags' },
      {
        $group: {
          _id: '$hashtags',
          count: { $sum: 1 },
          recentTweets: { $push: '$_id' }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 20 },
      {
        $project: {
          hashtag: '$_id',
          count: 1,
          _id: 0
        }
      }
    ]);

    res.json(trendingHashtags);

  } catch (error) {
    console.error('Get trending hashtags error:', error);
    res.status(500).json({
      message: 'Server error while fetching trending hashtags'
    });
  }
});

// @route   GET /api/tweets/recommended
// @desc    Get enhanced hybrid recommendations for user
// @access  Private
router.get('/recommended', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const refresh = req.query.refresh === 'true'; // For "See new posts" functionality
    // Track view interaction for learning
    if (req.user._id) {
      RecommendationEngine.trackInteraction(
        req.user._id,
        'feed_view',
        'view',
        req.headers['x-session-id']
      );
    }

    // Use enhanced hybrid recommendation system
    let recommendedTweets = await RecommendationEngine.getHybridRecommendations(
      req.user._id,
      page,
      limit
    );
    // If no recommendations available, fall back to basic algorithm
    if (recommendedTweets.length === 0) {
      recommendedTweets = await getFallbackRecommendations(req.user._id, page, limit);
    }
    // Add user-specific data (isLiked, isRetweeted)
    const tweetsWithUserData = recommendedTweets.map(tweet => {
      const tweetObj = typeof tweet.toJSON === 'function' ? tweet.toJSON() : tweet;
      tweetObj.isLiked = tweet.likes && tweet.likes.includes(req.user._id);
      tweetObj.isRetweeted = tweet.retweets && tweet.retweets.includes(req.user._id);
      tweetObj.recommendationSource = tweet.source || 'hybrid'; // Track recommendation source
      return tweetObj;
    });
    // Add timestamp for refresh detection
    const response = {
      tweets: tweetsWithUserData,
      timestamp: new Date().toISOString(),
      page,
      hasMore: tweetsWithUserData.length === limit
    };
    res.json(response);

  } catch (error) {
    console.error('Get enhanced recommendations error:', error);
    res.status(500).json({
      message: 'Server error while fetching recommendations'
    });
  }
});

// Fallback recommendation function (original algorithm)
async function getFallbackRecommendations(userId, page, limit) {
  const skip = (page - 1) * limit;
  const currentUser = await User.findById(userId);
  const followingIds = currentUser.following || [];

  // Get tweets from followed users (50% of results)
  const followingTweets = await Tweet.find({
    author: { $in: followingIds }
  })
    .populate('author', 'username displayName profileImage')
    .sort({ createdAt: -1 })
    .limit(Math.floor(limit * 0.5));

  // Get popular tweets (30% of results) - tweets with high engagement
  const popularTweets = await Tweet.aggregate([
    { $match: { author: { $nin: [userId, ...followingIds] } } },
    {
      $addFields: {
        engagementScore: {
          $add: [
            { $size: { $ifNull: ['$likes', []] } },
            { $multiply: [{ $size: { $ifNull: ['$retweets', []] } }, 2] }
          ]
        }
      }
    },
    { $sort: { engagementScore: -1, createdAt: -1 } },
    { $limit: Math.floor(limit * 0.3) },
    {
      $lookup: {
        from: 'users',
        localField: 'author',
        foreignField: '_id',
        as: 'author'
      }
    },
    { $unwind: '$author' },
    {
      $project: {
        'author.password': 0,
        'author.email': 0
      }
    }
  ]);

  // Get recent tweets from non-followed users (20% of results)
  const recentTweets = await Tweet.find({
    author: { $nin: [userId, ...followingIds] }
  })
    .populate('author', 'username displayName profileImage')
    .sort({ createdAt: -1 })
    .limit(Math.floor(limit * 0.2));

  // Combine and shuffle the tweets
  let allTweets = [...followingTweets, ...popularTweets, ...recentTweets];

  // Remove duplicates
  const seenIds = new Set();
  allTweets = allTweets.filter(tweet => {
    if (seenIds.has(tweet._id.toString())) {
      return false;
    }
    seenIds.add(tweet._id.toString());
    return true;
  });

  // Shuffle the array for variety
  for (let i = allTweets.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [allTweets[i], allTweets[j]] = [allTweets[j], allTweets[i]];
  }

  // Apply pagination
  return allTweets.slice(skip, skip + limit);
}

// @route   GET /api/tweets
// @desc    Get all tweets (feed) with enhanced refresh detection
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const lastTweetId = req.query.lastTweetId; // For "See new posts" detection
    const refresh = req.query.refresh === 'true';

    let query = {};
    // If checking for new posts, get tweets newer than lastTweetId
    if (lastTweetId && !refresh) {
      const lastTweet = await Tweet.findById(lastTweetId);
      if (lastTweet) {
        query.createdAt = { $gt: lastTweet.createdAt };
      }
    }

    const tweets = await Tweet.find(query)
      .populate('author', 'username displayName profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Add user-specific data (isLiked, isRetweeted)
    const tweetsWithUserData = tweets.map(tweet => {
      const tweetObj = typeof tweet.toJSON === 'function' ? tweet.toJSON() : tweet;
      tweetObj.isLiked = tweet.likes.includes(req.user._id);
      tweetObj.isRetweeted = tweet.retweets.includes(req.user._id);
      return tweetObj;
    });

    // Add metadata for refresh functionality
    const response = {
      tweets: tweetsWithUserData,
      timestamp: new Date().toISOString(),
      page,
      hasMore: tweetsWithUserData.length === limit,
      isNewContent: !refresh && lastTweetId && tweetsWithUserData.length > 0
    };

    res.json(response);

  } catch (error) {
    console.error('Get tweets error:', error);
    res.status(500).json({
      message: 'Server error while fetching tweets'
    });
  }
});

// @route   GET /api/tweets/:id
// @desc    Get single tweet
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const tweet = await Tweet.findById(req.params.id)
      .populate('author', 'username displayName profileImage');

    if (!tweet) {
      return res.status(404).json({
        message: 'Tweet not found'
      });
    }

    const tweetObj = typeof tweet.toJSON === 'function' ? tweet.toJSON() : tweet;
    tweetObj.isLiked = tweet.likes.includes(req.user._id);
    tweetObj.isRetweeted = tweet.retweets.includes(req.user._id);

    res.json(tweetObj);

  } catch (error) {
    console.error('Get tweet error:', error);
    res.status(500).json({
      message: 'Server error while fetching tweet'
    });
  }
});

// @route   POST /api/tweets
// @desc    Create a new tweet with media support
// @access  Private
router.post('/', [
  auth,
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Tweet content is required')
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

    const { content, imageUrl, mediaFiles } = req.body;

    // Extract hashtags and mentions from content
    const { hashtags, mentions } = extractHashtagsAndMentions(content);

    // Convert mention usernames to user IDs
    let mentionUserIds = [];
    if (mentions.length > 0) {
      const mentionedUsers = await User.find({
        username: { $in: mentions }
      }).select('_id username');

      mentionUserIds = mentionedUsers.map(user => user._id);
    }

    // Create new tweet
    const tweet = new Tweet({
      content,
      author: req.user._id,
      imageUrl: imageUrl || null, // Keep for backward compatibility
      mediaFiles: mediaFiles || [], // New multiple media support
      hashtags,
      mentions: mentionUserIds
    });

    await tweet.save();

    // Create notifications for mentioned users
    for (const mentionedUserId of mentionUserIds) {
      if (mentionedUserId !== req.user._id) { // Don't notify self
        await createNotification(
          mentionedUserId,
          req.user._id,
          'mention',
          'New mention',
          `${req.user.displayName} mentioned you in a tweet`,
          tweet._id
        );
      }
    }

    // Populate author data
    await tweet.populate('author', 'username displayName profileImage');
    await tweet.populate('mentions', 'username displayName');

    // Add user-specific data
    const tweetObj = typeof tweet.toJSON === 'function' ? tweet.toJSON() : tweet;
    tweetObj.isLiked = false;
    tweetObj.isRetweeted = false;

    res.status(201).json(tweetObj);

  } catch (error) {
    console.error('Create tweet error:', error);
    res.status(500).json({
      message: 'Server error while creating tweet'
    });
  }
});

// @route   POST /api/tweets/:id/like
// @desc    Like/unlike a tweet with interaction tracking
// @access  Private
router.post('/:id/like', auth, async (req, res) => {
  try {
    const tweet = await Tweet.findById(req.params.id);

    if (!tweet) {
      return res.status(404).json({
        message: 'Tweet not found'
      });
    }

    const userId = req.user._id;
    const isLiked = tweet.likes.includes(userId);

    if (isLiked) {
      // Unlike the tweet
      tweet.likes = tweet.likes.filter(id => id.toString() !== userId.toString());
    } else {
      // Like the tweet
      tweet.likes.push(userId);

      // Track interaction for recommendation learning
      await RecommendationEngine.trackInteraction(
        userId,
        req.params.id,
        'like',
        req.headers['x-session-id']
      );

      // Create notification for tweet author (if not liking own tweet)
      if (tweet.author.toString() !== userId.toString()) {
        await createNotification(
          tweet.author,
          userId,
          'like',
          'New like',
          `${req.user.displayName} liked your tweet`,
          tweet._id
        );
      }
    }

    await tweet.save();

    res.json({
      message: isLiked ? 'Tweet unliked' : 'Tweet liked',
      isLiked: !isLiked,
      likesCount: tweet.likes.length
    });

  } catch (error) {
    console.error('Like tweet error:', error);
    res.status(500).json({
      message: 'Server error while liking tweet'
    });
  }
});

// @route   POST /api/tweets/:id/retweet
// @desc    Retweet/unretweet a tweet with interaction tracking
// @access  Private
router.post('/:id/retweet', auth, async (req, res) => {
  try {
    const tweet = await Tweet.findById(req.params.id);

    if (!tweet) {
      return res.status(404).json({
        message: 'Tweet not found'
      });
    }

    const userId = req.user._id;
    const isRetweeted = tweet.retweets.includes(userId);

    if (isRetweeted) {
      // Unretweet
      tweet.retweets = tweet.retweets.filter(id => id.toString() !== userId.toString());
    } else {
      // Retweet
      tweet.retweets.push(userId);

      // Track interaction for recommendation learning
      await RecommendationEngine.trackInteraction(
        userId,
        req.params.id,
        'retweet',
        req.headers['x-session-id']
      );

      // Create notification for tweet author (if not retweeting own tweet)
      if (tweet.author.toString() !== userId.toString()) {
        await createNotification(
          tweet.author,
          userId,
          'retweet',
          'New retweet',
          `${req.user.displayName} retweeted your tweet`,
          tweet._id
        );
      }
    }

    await tweet.save();

    res.json({
      message: isRetweeted ? 'Tweet unretweeted' : 'Tweet retweeted',
      isRetweeted: !isRetweeted,
      retweetsCount: tweet.retweets.length
    });

  } catch (error) {
    console.error('Retweet error:', error);
    res.status(500).json({
      message: 'Server error while retweeting'
    });
  }
});

// @route   DELETE /api/tweets/:id
// @desc    Delete a tweet
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const tweet = await Tweet.findById(req.params.id);

    if (!tweet) {
      return res.status(404).json({
        message: 'Tweet not found'
      });
    }

    // Check if user owns the tweet
    if (tweet.author.toString() !== req.user._id) {
      return res.status(403).json({
        message: 'Not authorized to delete this tweet'
      });
    }

    await Tweet.findByIdAndDelete(req.params.id);

    res.json({
      message: 'Tweet deleted successfully'
    });

  } catch (error) {
    console.error('Delete tweet error:', error);
    res.status(500).json({
      message: 'Server error while deleting tweet'
    });
  }
});

// @route   POST /api/tweets/:id/reply
// @desc    Reply to a tweet
// @access  Private
router.post('/:id/reply', [
  auth,
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Reply content is required')
    .isLength({ max: 280 })
    .withMessage('Reply cannot exceed 280 characters')
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

    const parentTweet = await Tweet.findById(req.params.id);

    if (!parentTweet) {
      return res.status(404).json({
        message: 'Tweet not found'
      });
    }

    const { content, imageUrl } = req.body;

    // Create new reply tweet
    const replyTweet = new Tweet({
      content,
      author: req.user._id,
      imageUrl: imageUrl || null,
      parentTweet: req.params.id
    });

    await replyTweet.save();

    // Add reply to parent tweet's replies array
    parentTweet.replies.push(replyTweet._id);
    await parentTweet.save();

    // Populate author data
    await replyTweet.populate('author', 'username displayName profileImage');

    // Add user-specific data
    const replyTweetObj = typeof replyTweet.toJSON === 'function' ? replyTweet.toJSON() : replyTweet;
    replyTweetObj.isLiked = false;
    replyTweetObj.isRetweeted = false;

    // Create notification for parent tweet author (if not replying to own tweet)
    if (parentTweet.author.toString() !== req.user._id.toString()) {
      await createNotification(
        parentTweet.author,
        req.user._id,
        'reply',
        'New reply',
        `${req.user.displayName} replied to your tweet`,
        parentTweet._id
      );
    }

    res.status(201).json(replyTweetObj);

  } catch (error) {
    console.error('Reply tweet error:', error);
    res.status(500).json({
      message: 'Server error while creating reply'
    });
  }
});

// @route   GET /api/tweets/:id/replies
// @desc    Get replies to a tweet
// @access  Private
router.get('/:id/replies', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const replies = await Tweet.find({ parentTweet: req.params.id })
      .populate('author', 'username displayName profileImage')
      .sort({ createdAt: 1 }) // Oldest first for replies
      .skip(skip)
      .limit(limit);

    // Add user-specific data (isLiked, isRetweeted)
    const repliesWithUserData = replies.map(reply => {
      const replyObj = typeof reply.toJSON === 'function' ? reply.toJSON() : reply;
      replyObj.isLiked = reply.likes.includes(req.user._id);
      replyObj.isRetweeted = reply.retweets.includes(req.user._id);
      return replyObj;
    });

    res.json(repliesWithUserData);

  } catch (error) {
    console.error('Get replies error:', error);
    res.status(500).json({
      message: 'Server error while fetching replies'
    });
  }
});

// @route   POST /api/tweets/track-interaction
// @desc    Track user interactions for recommendation learning
// @access  Private
router.post('/track-interaction', auth, async (req, res) => {
  try {
    const { tweetId, interactionType } = req.body;

    if (!tweetId || !interactionType) {
      return res.status(400).json({
        message: 'tweetId and interactionType are required'
      });
    }

    await RecommendationEngine.trackInteraction(
      req.user._id,
      tweetId,
      interactionType,
      req.headers['x-session-id']
    );

    res.json({
      message: 'Interaction tracked successfully'
    });

  } catch (error) {
    console.error('Track interaction error:', error);
    res.status(500).json({
      message: 'Server error while tracking interaction'
    });
  }
});

// @route   GET /api/tweets/check-new
// @desc    Check for new tweets since last timestamp (for "See new posts" functionality)
// @access  Private
router.get('/check-new', auth, async (req, res) => {
  try {
    const lastTimestamp = req.query.timestamp;

    if (!lastTimestamp) {
      return res.json({ hasNewTweets: false, count: 0 });
    }

    const count = await Tweet.countDocuments({
      createdAt: { $gt: new Date(lastTimestamp) }
    });

    res.json({
      hasNewTweets: count > 0,
      count: count,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Check new tweets error:', error);
    res.status(500).json({
      message: 'Server error while checking for new tweets'
    });
  }
});

module.exports = router;