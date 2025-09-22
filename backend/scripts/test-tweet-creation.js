/**
 * Test script to verify tweet creation works after fixing the MongoDB indexing issue
 */

const mongoose = require('mongoose');
const Tweet = require('../models/Tweet');
const User = require('../models/User');
require('dotenv').config();

const testTweetCreation = async () => {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Create a test user if not exists
    let testUser = await User.findOne({ username: 'testuser' });
    if (!testUser) {
      testUser = new User({
        _id: 'test-user-id',
        username: 'testuser',
        email: 'test@example.com',
        password: 'hashedpassword', // In real app this would be hashed
        displayName: 'Test User'
      });
      await testUser.save();
      console.log('✅ Created test user');
    } else {
      console.log('ℹ️  Test user already exists');
    }

    // Test tweet creation
    console.log('🐦 Creating test tweet...');
    const testTweet = new Tweet({
      content: 'This is a test tweet to verify the MongoDB indexing fix works! 🎉',
      author: testUser._id,
      likes: [], // Empty array initially
      retweets: [], // Empty array initially
      hashtags: ['test', 'mongodb', 'fix'],
      mentions: []
    });

    const savedTweet = await testTweet.save();
    console.log('✅ Tweet created successfully!');
    console.log('📄 Tweet details:', {
      id: savedTweet._id,
      content: savedTweet.content,
      author: savedTweet.author,
      likesCount: savedTweet.likes.length,
      retweetsCount: savedTweet.retweets.length,
      createdAt: savedTweet.createdAt
    });

    // Test adding likes and retweets
    console.log('👍 Testing likes and retweets...');
    savedTweet.likes.push('user1', 'user2', 'user3');
    savedTweet.retweets.push('user4', 'user5');
    
    await savedTweet.save();
    console.log('✅ Updated tweet with likes and retweets');
    console.log('📊 Updated counts:', {
      likesCount: savedTweet.likes.length,
      retweetsCount: savedTweet.retweets.length
    });

    // Test querying tweets (this should work with our new indexes)
    console.log('🔍 Testing tweet queries...');
    const tweets = await Tweet.find({ author: testUser._id }).sort({ createdAt: -1 });
    console.log(`✅ Found ${tweets.length} tweets for user`);

    // Test engagement-based aggregation
    console.log('📈 Testing engagement aggregation...');
    const engagementResults = await Tweet.aggregate([
      { $match: { author: testUser._id } },
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
      { $sort: { engagementScore: -1, createdAt: -1 } }
    ]);
    
    console.log('✅ Engagement aggregation successful');
    console.log('🏆 Top tweet engagement score:', engagementResults[0]?.engagementScore || 0);

    console.log('\n🎉 ALL TESTS PASSED! The MongoDB indexing fix is working correctly.');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    
    if (error.message.includes('parallel arrays')) {
      console.log('\n🔧 DIAGNOSIS: The parallel arrays indexing issue still exists.');
      console.log('Please ensure you have:');
      console.log('1. Updated the Tweet model indexes');
      console.log('2. Run the fix-indexes.js script to update the database');
      console.log('3. Restarted the backend server');
    }
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
};

// Run the test
testTweetCreation();