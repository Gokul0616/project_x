const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const List = require('../models/List');
const Bookmark = require('../models/Bookmark');
const Moment = require('../models/Moment');
const User = require('../models/User');
const Tweet = require('../models/Tweet');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

const seedDrawerData = async () => {
  try {
    console.log('Starting to seed drawer data...');

    // Get existing users and tweets
    const users = await User.find().limit(5);
    const tweets = await Tweet.find().limit(20);

    if (users.length === 0 || tweets.length === 0) {
      console.log('No users or tweets found. Please seed basic data first.');
      return;
    }

    console.log(`Found ${users.length} users and ${tweets.length} tweets`);

    // Create sample lists
    const sampleLists = [
      {
        _id: uuidv4(),
        name: 'Tech News',
        description: 'Latest updates in technology and software development',
        owner: users[0]._id,
        members: [users[1]._id, users[2]._id],
        subscribers: [users[0]._id, users[1]._id, users[2]._id, users[3]._id],
        isPrivate: false,
        tweets: tweets.slice(0, 5).map(t => t._id),
        pinnedBy: [users[0]._id]
      },
      {
        _id: uuidv4(),
        name: 'Flutter Developers',
        description: 'Amazing Flutter developers and community members',
        owner: users[1]._id,
        members: [users[0]._id, users[2]._id, users[3]._id],
        subscribers: [users[0]._id, users[1]._id, users[4]._id],
        isPrivate: false,
        tweets: tweets.slice(5, 10).map(t => t._id),
        pinnedBy: [users[0]._id, users[1]._id]
      },
      {
        _id: uuidv4(),
        name: 'Design Inspiration',
        description: 'UI/UX designers and inspiration accounts',
        owner: users[2]._id,
        members: [users[0]._id, users[1]._id],
        subscribers: [users[0]._id, users[3]._id],
        isPrivate: true,
        tweets: tweets.slice(10, 15).map(t => t._id),
        pinnedBy: []
      },
      {
        _id: uuidv4(),
        name: 'AI & Machine Learning',
        description: 'Latest in artificial intelligence and ML research',
        owner: users[3]._id,
        members: [users[0]._id, users[1]._id, users[2]._id, users[4]._id],
        subscribers: [users[0]._id, users[1]._id, users[2]._id],
        isPrivate: false,
        tweets: tweets.slice(15, 20).map(t => t._id),
        pinnedBy: [users[1]._id]
      }
    ];

    // Clear existing lists
    await List.deleteMany({});
    console.log('Cleared existing lists');

    // Insert sample lists
    await List.insertMany(sampleLists);
    console.log(`Created ${sampleLists.length} sample lists`);

    // Create sample bookmarks for each user
    const bookmarks = [];
    users.forEach((user, userIndex) => {
      // Each user bookmarks 3-5 random tweets
      const userTweets = tweets.slice(userIndex * 3, userIndex * 3 + 4);
      userTweets.forEach(tweet => {
        bookmarks.push({
          _id: uuidv4(),
          user: user._id,
          tweet: tweet._id
        });
      });
    });

    // Clear existing bookmarks
    await Bookmark.deleteMany({});
    console.log('Cleared existing bookmarks');

    // Insert sample bookmarks
    await Bookmark.insertMany(bookmarks);
    console.log(`Created ${bookmarks.length} sample bookmarks`);

    // Create sample moments
    const sampleMoments = [
      {
        _id: uuidv4(),
        title: 'Flutter 3.16 Release',
        description: 'The latest Flutter release brings amazing new features and improvements including better performance, new widgets, and enhanced developer experience.',
        category: 'Technology',
        tweets: tweets.slice(0, 8).map(t => t._id),
        participants: users.slice(0, 4).map(u => u._id),
        hashtags: ['flutter', 'mobile', 'development'],
        isLive: true,
        isFeatured: true,
        startDate: new Date(Date.now() - 4 * 60 * 60 * 1000) // 4 hours ago
      },
      {
        _id: uuidv4(),
        title: 'Tech Conference 2024',
        description: 'Highlights and key takeaways from the biggest tech conference of the year. Join the conversation about the future of technology.',
        category: 'Technology',
        tweets: tweets.slice(8, 15).map(t => t._id),
        participants: users.map(u => u._id),
        hashtags: ['techconf2024', 'innovation', 'future'],
        isLive: false,
        isFeatured: true,
        startDate: new Date(Date.now() - 24 * 60 * 60 * 1000), // 1 day ago
        endDate: new Date(Date.now() - 12 * 60 * 60 * 1000) // 12 hours ago
      },
      {
        _id: uuidv4(),
        title: 'Mobile Development Trends',
        description: 'Latest trends and best practices in mobile app development. Discover what developers are building in 2024.',
        category: 'Technology',
        tweets: tweets.slice(5, 12).map(t => t._id),
        participants: users.slice(0, 3).map(u => u._id),
        hashtags: ['mobiledev', 'trends2024', 'apps'],
        isLive: false,
        isFeatured: false,
        startDate: new Date(Date.now() - 48 * 60 * 60 * 1000) // 2 days ago
      },
      {
        _id: uuidv4(),
        title: 'AI Revolution in 2024',
        description: 'How artificial intelligence is transforming industries and changing the way we work and live.',
        category: 'Technology',
        tweets: tweets.slice(10, 18).map(t => t._id),
        participants: users.slice(1, 5).map(u => u._id),
        hashtags: ['ai', 'artificialintelligence', 'future', 'technology'],
        isLive: false,
        isFeatured: true,
        startDate: new Date(Date.now() - 72 * 60 * 60 * 1000) // 3 days ago
      },
      {
        _id: uuidv4(),
        title: 'Open Source Celebration',
        description: 'Celebrating the amazing contributions of open source developers worldwide. Share your favorite projects!',
        category: 'Technology',
        tweets: tweets.slice(0, 6).map(t => t._id),
        participants: users.slice(0, 2).map(u => u._id),
        hashtags: ['opensource', 'github', 'developers'],
        isLive: false,
        isFeatured: false,
        startDate: new Date(Date.now() - 96 * 60 * 60 * 1000) // 4 days ago
      }
    ];

    // Clear existing moments
    await Moment.deleteMany({});
    console.log('Cleared existing moments');

    // Insert sample moments
    await Moment.insertMany(sampleMoments);
    console.log(`Created ${sampleMoments.length} sample moments`);

    console.log('✅ Successfully seeded drawer data!');
    console.log('Summary:');
    console.log(`- Lists: ${sampleLists.length}`);
    console.log(`- Bookmarks: ${bookmarks.length}`);
    console.log(`- Moments: ${sampleMoments.length}`);

  } catch (error) {
    console.error('Error seeding drawer data:', error);
  }
};

const main = async () => {
  await connectDB();
  await seedDrawerData();
  await mongoose.connection.close();
  console.log('Database connection closed');
};

main();