const express = require('express');
const Bookmark = require('../models/Bookmark');
const Tweet = require('../models/Tweet');
const auth = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/bookmarks
// @desc    Get user's bookmarked tweets
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const sortBy = req.query.sortBy || 'date'; // date, author, engagement

    let sortOptions = {};
    switch (sortBy) {
      case 'author':
        sortOptions = { 'tweet.author.displayName': 1 };
        break;
      case 'engagement':
        sortOptions = { engagementScore: -1, createdAt: -1 };
        break;
      default: // date
        sortOptions = { createdAt: -1 };
    }

    let bookmarks;

    if (sortBy === 'engagement') {
      // Use aggregation for engagement sorting
      bookmarks = await Bookmark.aggregate([
        { $match: { user: req.user._id } },
        {
          $lookup: {
            from: 'tweets',
            localField: 'tweet',
            foreignField: '_id',
            as: 'tweet',
            pipeline: [
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
            ]
          }
        },
        { $unwind: '$tweet' },
        {
          $addFields: {
            engagementScore: {
              $add: [
                { $size: { $ifNull: ['$tweet.likes', []] } },
                { $size: { $ifNull: ['$tweet.retweets', []] } },
                { $size: { $ifNull: ['$tweet.replies', []] } }
              ]
            }
          }
        },
        { $sort: sortOptions },
        { $skip: skip },
        { $limit: limit }
      ]);
    } else {
      // Use regular find with populate for other sorts
      bookmarks = await Bookmark.find({ user: req.user._id })
        .populate({
          path: 'tweet',
          populate: {
            path: 'author',
            select: 'username displayName profileImage'
          }
        })
        .sort(sortOptions)
        .skip(skip)
        .limit(limit);
    }

    // Extract tweets and add user-specific data
    const tweetsWithUserData = bookmarks.map(bookmark => {
      const tweet = bookmark.tweet;
      if (!tweet) return null; // Handle deleted tweets
      
      const tweetObj = typeof tweet.toJSON === 'function' ? tweet.toJSON() : tweet;
      tweetObj.isLiked = tweet.likes ? tweet.likes.includes(req.user._id) : false;
      tweetObj.isRetweeted = tweet.retweets ? tweet.retweets.includes(req.user._id) : false;
      tweetObj.likesCount = tweet.likes ? tweet.likes.length : 0;
      tweetObj.retweetsCount = tweet.retweets ? tweet.retweets.length : 0;
      tweetObj.repliesCount = tweet.replies ? tweet.replies.length : 0;
      tweetObj.bookmarkedAt = bookmark.createdAt;
      
      return tweetObj;
    }).filter(tweet => tweet !== null); // Remove null entries

    res.json(tweetsWithUserData);

  } catch (error) {
    console.error('Get bookmarks error:', error);
    res.status(500).json({
      message: 'Server error while fetching bookmarks'
    });
  }
});

// @route   POST /api/bookmarks/:tweetId
// @desc    Bookmark a tweet
// @access  Private
router.post('/:tweetId', auth, async (req, res) => {
  try {
    const tweet = await Tweet.findById(req.params.tweetId);

    if (!tweet) {
      return res.status(404).json({
        message: 'Tweet not found'
      });
    }

    // Check if already bookmarked
    const existingBookmark = await Bookmark.findOne({
      user: req.user._id,
      tweet: req.params.tweetId
    });

    if (existingBookmark) {
      return res.status(400).json({
        message: 'Tweet already bookmarked'
      });
    }

    const bookmark = new Bookmark({
      user: req.user._id,
      tweet: req.params.tweetId
    });

    await bookmark.save();

    res.status(201).json({
      message: 'Tweet bookmarked successfully',
      bookmarkId: bookmark._id
    });

  } catch (error) {
    console.error('Bookmark tweet error:', error);
    res.status(500).json({
      message: 'Server error while bookmarking tweet'
    });
  }
});

// @route   DELETE /api/bookmarks/:tweetId
// @desc    Remove bookmark from a tweet
// @access  Private
router.delete('/:tweetId', auth, async (req, res) => {
  try {
    const bookmark = await Bookmark.findOneAndDelete({
      user: req.user._id,
      tweet: req.params.tweetId
    });

    if (!bookmark) {
      return res.status(404).json({
        message: 'Bookmark not found'
      });
    }

    res.json({
      message: 'Bookmark removed successfully'
    });

  } catch (error) {
    console.error('Remove bookmark error:', error);
    res.status(500).json({
      message: 'Server error while removing bookmark'
    });
  }
});

// @route   GET /api/bookmarks/check/:tweetId
// @desc    Check if a tweet is bookmarked by user
// @access  Private
router.get('/check/:tweetId', auth, async (req, res) => {
  try {
    const bookmark = await Bookmark.findOne({
      user: req.user._id,
      tweet: req.params.tweetId
    });

    res.json({
      isBookmarked: !!bookmark
    });

  } catch (error) {
    console.error('Check bookmark error:', error);
    res.status(500).json({
      message: 'Server error while checking bookmark'
    });
  }
});

module.exports = router;