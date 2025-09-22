const Tweet = require('../models/Tweet');
const User = require('../models/User');
const UserInteraction = require('../models/UserInteraction');
const UserPreference = require('../models/UserPreference');

class RecommendationEngine {
  
  // PHASE 1: COLLABORATIVE FILTERING (35%)
  async getCollaborativeRecommendations(userId, limit = 10) {
    try {
      // Get user preferences
      let userPrefs = await UserPreference.findOne({ userId });
      
      if (!userPrefs) {
        // Create initial preferences if none exist
        userPrefs = await this.calculateUserPreferences(userId);
      }

      // Get similar users
      const similarUsers = userPrefs.similarUsers.slice(0, 20).map(u => u.userId);
      
      if (similarUsers.length === 0) {
        return [];
      }

      // Get tweets liked/retweeted by similar users
      const collaborativeRecommendations = await Tweet.aggregate([
        {
          $match: {
            $or: [
              { likes: { $in: similarUsers } },
              { retweets: { $in: similarUsers } }
            ],
            author: { $ne: userId }, // Don't recommend own tweets
            likes: { $ne: userId }, // Don't recommend already liked tweets
            retweets: { $ne: userId } // Don't recommend already retweeted tweets
          }
        },
        {
          $addFields: {
            collaborativeScore: {
              $add: [
                { $multiply: [{ $size: { $setIntersection: ['$likes', similarUsers] } }, 2] },
                { $multiply: [{ $size: { $setIntersection: ['$retweets', similarUsers] } }, 3] }
              ]
            }
          }
        },
        { $sort: { collaborativeScore: -1, createdAt: -1 } },
        { $limit: limit },
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

      return collaborativeRecommendations;
    } catch (error) {
      console.error('Collaborative filtering error:', error);
      return [];
    }
  }

  // PHASE 2: CONTENT-BASED FILTERING (30%)
  async getContentBasedRecommendations(userId, limit = 10) {
    try {
      // Get user preferences
      const userPrefs = await UserPreference.findOne({ userId });
      
      if (!userPrefs || !userPrefs.preferredHashtags.length) {
        return [];
      }

      // Get top hashtags user likes
      const topHashtags = userPrefs.preferredHashtags
        .slice(0, 10)
        .map(h => h.hashtag);

      // Find tweets with similar hashtags
      const contentRecommendations = await Tweet.aggregate([
        {
          $match: {
            hashtags: { $in: topHashtags },
            author: { $ne: userId },
            likes: { $ne: userId },
            retweets: { $ne: userId }
          }
        },
        {
          $addFields: {
            contentScore: {
              $add: [
                { $multiply: [{ $size: { $setIntersection: ['$hashtags', topHashtags] } }, 3] },
                { $multiply: [{ $size: { $ifNull: ['$likes', []] } }, 0.5] },
                { $multiply: [{ $size: { $ifNull: ['$retweets', []] } }, 1] }
              ]
            }
          }
        },
        { $sort: { contentScore: -1, createdAt: -1 } },
        { $limit: limit },
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

      return contentRecommendations;
    } catch (error) {
      console.error('Content-based filtering error:', error);
      return [];
    }
  }

  // PHASE 3: SOCIAL GRAPH ENHANCEMENT (20%)
  async getSocialGraphRecommendations(userId, limit = 10) {
    try {
      const currentUser = await User.findById(userId);
      const followingIds = currentUser.following || [];

      if (followingIds.length === 0) {
        return [];
      }

      // Find friends-of-friends and mutual connections
      const friendsOfFriends = await User.aggregate([
        { $match: { _id: { $in: followingIds } } },
        { $unwind: '$following' },
        {
          $match: {
            following: { $ne: userId, $nin: followingIds }
          }
        },
        {
          $group: {
            _id: '$following',
            mutualCount: { $sum: 1 }
          }
        },
        { $sort: { mutualCount: -1 } },
        { $limit: 20 }
      ]);

      const friendsOfFriendsIds = friendsOfFriends.map(f => f._id);

      // Get tweets from friends-of-friends
      const socialRecommendations = await Tweet.aggregate([
        {
          $match: {
            author: { $in: friendsOfFriendsIds },
            likes: { $ne: userId },
            retweets: { $ne: userId }
          }
        },
        {
          $addFields: {
            socialScore: {
              $add: [
                { $multiply: [{ $size: { $ifNull: ['$likes', []] } }, 1] },
                { $multiply: [{ $size: { $ifNull: ['$retweets', []] } }, 2] }
              ]
            }
          }
        },
        { $sort: { socialScore: -1, createdAt: -1 } },
        { $limit: limit },
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

      return socialRecommendations;
    } catch (error) {
      console.error('Social graph recommendations error:', error);
      return [];
    }
  }

  // PHASE 4: TRENDING & TEMPORAL (15%)
  async getTrendingRecommendations(userId, limit = 10) {
    try {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

      // Get trending tweets from last hour with high engagement velocity
      const trendingRecommendations = await Tweet.aggregate([
        {
          $match: {
            createdAt: { $gte: oneDayAgo },
            author: { $ne: userId },
            likes: { $ne: userId },
            retweets: { $ne: userId }
          }
        },
        {
          $addFields: {
            engagementVelocity: {
              $divide: [
                {
                  $add: [
                    { $size: { $ifNull: ['$likes', []] } },
                    { $multiply: [{ $size: { $ifNull: ['$retweets', []] } }, 2] },
                    { $multiply: [{ $size: { $ifNull: ['$replies', []] } }, 1.5] }
                  ]
                },
                {
                  $divide: [
                    { $subtract: [new Date(), '$createdAt'] },
                    1000 * 60 * 60 // Convert to hours
                  ]
                }
              ]
            },
            recencyBoost: {
              $cond: {
                if: { $gte: ['$createdAt', oneHourAgo] },
                then: 2,
                else: 1
              }
            }
          }
        },
        {
          $addFields: {
            trendingScore: {
              $multiply: ['$engagementVelocity', '$recencyBoost']
            }
          }
        },
        { $sort: { trendingScore: -1, createdAt: -1 } },
        { $limit: limit },
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

      return trendingRecommendations;
    } catch (error) {
      console.error('Trending recommendations error:', error);
      return [];
    }
  }

  // MAIN RECOMMENDATION METHOD - HYBRID APPROACH
  async getHybridRecommendations(userId, page = 1, limit = 20) {
    try {
      const skip = (page - 1) * limit;
      
      // Calculate distribution based on percentages
      const collaborativeLimit = Math.ceil(limit * 0.35);
      const contentBasedLimit = Math.ceil(limit * 0.30);
      const socialGraphLimit = Math.ceil(limit * 0.20);
      const trendingLimit = Math.ceil(limit * 0.15);

      // Get recommendations from all phases in parallel
      const [
        collaborativeRecs,
        contentRecs,
        socialRecs,
        trendingRecs
      ] = await Promise.all([
        this.getCollaborativeRecommendations(userId, collaborativeLimit),
        this.getContentBasedRecommendations(userId, contentBasedLimit),
        this.getSocialGraphRecommendations(userId, socialGraphLimit),
        this.getTrendingRecommendations(userId, trendingLimit)
      ]);

      // Combine all recommendations
      let allRecommendations = [
        ...collaborativeRecs.map(tweet => ({ ...tweet, source: 'collaborative' })),
        ...contentRecs.map(tweet => ({ ...tweet, source: 'content' })),
        ...socialRecs.map(tweet => ({ ...tweet, source: 'social' })),
        ...trendingRecs.map(tweet => ({ ...tweet, source: 'trending' }))
      ];

      // Remove duplicates
      const seenIds = new Set();
      allRecommendations = allRecommendations.filter(tweet => {
        if (seenIds.has(tweet._id)) {
          return false;
        }
        seenIds.add(tweet._id);
        return true;
      });

      // Shuffle for variety while maintaining some order
      allRecommendations = this.shuffleWithBias(allRecommendations);

      // Apply pagination
      const paginatedRecommendations = allRecommendations.slice(skip, skip + limit);

      return paginatedRecommendations;
    } catch (error) {
      console.error('Hybrid recommendations error:', error);
      return [];
    }
  }

  // Helper method to shuffle with bias towards higher quality content
  shuffleWithBias(recommendations) {
    // Separate high-engagement and regular tweets
    const highEngagement = recommendations.filter(tweet => 
      (tweet.likes?.length || 0) + (tweet.retweets?.length || 0) > 5
    );
    const regularTweets = recommendations.filter(tweet => 
      (tweet.likes?.length || 0) + (tweet.retweets?.length || 0) <= 5
    );

    // Shuffle each group
    this.shuffleArray(highEngagement);
    this.shuffleArray(regularTweets);

    // Interleave high-engagement tweets with regular tweets
    const result = [];
    const maxLength = Math.max(highEngagement.length, regularTweets.length);
    
    for (let i = 0; i < maxLength; i++) {
      if (highEngagement[i]) result.push(highEngagement[i]);
      if (regularTweets[i]) result.push(regularTweets[i]);
    }

    return result;
  }

  shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  }

  // Calculate user preferences based on interactions
  async calculateUserPreferences(userId) {
    try {
      // Get user's recent interactions
      const interactions = await UserInteraction.find({ userId })
        .sort({ timestamp: -1 })
        .limit(1000);

      // Get user's liked/retweeted tweets
      const likedTweets = await Tweet.find({ likes: userId });
      const retweetedTweets = await Tweet.find({ retweets: userId });

      // Calculate hashtag preferences
      const hashtagCounts = {};
      [...likedTweets, ...retweetedTweets].forEach(tweet => {
        tweet.hashtags.forEach(hashtag => {
          hashtagCounts[hashtag] = (hashtagCounts[hashtag] || 0) + 1;
        });
      });

      const preferredHashtags = Object.entries(hashtagCounts)
        .map(([hashtag, count]) => ({
          hashtag,
          score: count,
          lastUpdated: new Date()
        }))
        .sort((a, b) => b.score - a.score)
        .slice(0, 20);

      // Calculate user similarity (simplified collaborative filtering)
      const similarUsers = await this.calculateUserSimilarity(userId);

      // Create or update user preferences
      const userPrefs = await UserPreference.findOneAndUpdate(
        { userId },
        {
          preferredHashtags,
          similarUsers,
          lastUpdated: new Date()
        },
        { upsert: true, new: true }
      );

      return userPrefs;
    } catch (error) {
      console.error('Calculate user preferences error:', error);
      return null;
    }
  }

  // Calculate user similarity for collaborative filtering
  async calculateUserSimilarity(userId) {
    try {
      // Get user's liked tweets
      const userLikes = await Tweet.find({ likes: userId }).select('_id');
      const userLikeIds = userLikes.map(tweet => tweet._id);

      if (userLikeIds.length === 0) {
        return [];
      }

      // Find users with similar likes
      const similarUsers = await Tweet.aggregate([
        { $match: { _id: { $in: userLikeIds } } },
        { $unwind: '$likes' },
        { $match: { likes: { $ne: userId } } },
        {
          $group: {
            _id: '$likes',
            commonLikes: { $sum: 1 }
          }
        },
        {
          $match: {
            commonLikes: { $gte: 2 } // At least 2 common likes
          }
        },
        {
          $lookup: {
            from: 'tweets',
            let: { otherUserId: '$_id' },
            pipeline: [
              { $match: { $expr: { $in: ['$$otherUserId', '$likes'] } } },
              { $count: 'totalLikes' }
            ],
            as: 'userStats'
          }
        },
        { $unwind: '$userStats' },
        {
          $addFields: {
            similarityScore: {
              $divide: [
                '$commonLikes',
                { $add: ['$userStats.totalLikes', userLikeIds.length] }
              ]
            }
          }
        },
        { $sort: { similarityScore: -1 } },
        { $limit: 50 },
        {
          $project: {
            userId: '$_id',
            similarityScore: 1,
            lastCalculated: new Date(),
            _id: 0
          }
        }
      ]);

      return similarUsers;
    } catch (error) {
      console.error('Calculate user similarity error:', error);
      return [];
    }
  }

  // Track user interactions for learning
  async trackInteraction(userId, tweetId, interactionType, sessionId = null) {
    try {
      const weights = {
        view: 0.1,
        click: 0.5,
        like: 1,
        retweet: 2,
        reply: 3,
        share: 1.5
      };

      const interaction = new UserInteraction({
        userId,
        tweetId,
        interactionType,
        weight: weights[interactionType] || 1,
        sessionId
      });

      await interaction.save();
      
      // Update user preferences periodically (every 10 interactions)
      const interactionCount = await UserInteraction.countDocuments({ userId });
      if (interactionCount % 10 === 0) {
        await this.calculateUserPreferences(userId);
      }
    } catch (error) {
      console.error('Track interaction error:', error);
    }
  }
}

module.exports = new RecommendationEngine();