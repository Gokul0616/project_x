const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');
const User = require('../models/User');
const Tweet = require('../models/Tweet');

dotenv.config();

const sampleTweets = [
  {
    content: "Just launched my new Twitter clone! 🚀 Excited to see how it grows. #TwitterClone #WebDev",
    author: null // Will be set to user ID
  },
  {
    content: "Beautiful sunrise today! Nothing beats starting the day with nature's artwork. 🌅 #MorningVibes #Nature",
    author: null
  },
  {
    content: "Working on some exciting new features. Can't wait to share them with the community! 💻 #Development #Tech",
    author: null
  },
  {
    content: "Coffee + Code = Perfect Monday morning ☕️ What's your favorite way to start the week? #MondayMotivation #Coffee",
    author: null
  },
  {
    content: "Reading an amazing book about machine learning. The future is so exciting! 📚 🤖 #AI #MachineLearning #Books",
    author: null
  },
  {
    content: "Just finished a great workout session! 💪 Feeling energized and ready to tackle the day. #Fitness #HealthyLifestyle",
    author: null
  },
  {
    content: "Exploring new JavaScript frameworks today. The ecosystem is evolving so fast! 🌟 #JavaScript #Frontend #Learning",
    author: null
  },
  {
    content: "Amazing how quickly technology changes. What seemed impossible yesterday is reality today! 🚀 #Technology #Innovation",
    author: null
  },
  {
    content: "Grateful for all the support from the developer community. You all are amazing! 🙏 #Community #Gratitude #DevLife",
    author: null
  },
  {
    content: "Weekend project: Building a mobile app with Flutter! The cross-platform capabilities are incredible. 📱 #Flutter #MobileApp #WeekendProject",
    author: null
  }
];

const seedDatabase = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Check if user already exists
    let user = await User.findOne({ email: 'gokul@gmail.com' });
    
    if (!user) {
      // Create the user with provided credentials
      const hashedPassword = await bcrypt.hash('Gokul001@', 10);
      
      user = new User({
        username: 'gokul_dev',
        email: 'gokul@gmail.com',
        password: hashedPassword,
        displayName: 'Gokul',
        bio: 'Full-stack developer passionate about creating amazing user experiences. Love coding, coffee, and continuous learning! 🚀',
        followersCount: 0,
        followingCount: 0
      });

      await user.save();
      console.log('User created successfully');
    } else {
      console.log('User already exists');
    }

    // Delete all existing tweets for clean slate
    await Tweet.deleteMany({});
    console.log('Cleared existing tweets');

    // Create sample tweets
    const tweetsToCreate = sampleTweets.map(tweet => ({
      ...tweet,
      author: user._id
    }));

    // Insert tweets with different timestamps to simulate realistic posting
    for (let i = 0; i < tweetsToCreate.length; i++) {
      const tweet = new Tweet(tweetsToCreate[i]);
      
      // Set different creation times (spread over last 7 days)
      const daysAgo = Math.floor(Math.random() * 7);
      const hoursAgo = Math.floor(Math.random() * 24);
      const minutesAgo = Math.floor(Math.random() * 60);
      
      tweet.createdAt = new Date(Date.now() - (daysAgo * 24 * 60 * 60 * 1000) - (hoursAgo * 60 * 60 * 1000) - (minutesAgo * 60 * 1000));
      
      await tweet.save();
    }

    console.log('Sample tweets created successfully');
    console.log(`Total tweets: ${tweetsToCreate.length}`);

    // Create sample replies to make testing easier
    const allTweets = await Tweet.find({ author: user._id });
    
    if (allTweets.length > 0) {
      // Add replies to the first few tweets
      const sampleReplies = [
        {
          content: "This is amazing! Can't wait to try it out myself 🔥",
          parentTweet: allTweets[0]._id
        },
        {
          content: "Great work! The UI looks really clean and modern.",
          parentTweet: allTweets[0]._id
        },
        {
          content: "Wow, the sunrise looks absolutely breathtaking! 🌅",
          parentTweet: allTweets[1]._id
        },
        {
          content: "I'm curious about what features you're working on! Any sneak peeks? 👀",
          parentTweet: allTweets[2]._id
        },
        {
          content: "Coffee is definitely the fuel of developers! ☕️ What's your favorite blend?",
          parentTweet: allTweets[3]._id
        }
      ];

      for (const replyData of sampleReplies) {
        const reply = new Tweet({
          content: replyData.content,
          author: user._id,
          parentTweet: replyData.parentTweet
        });

        // Set creation time slightly after parent tweet
        const parentTweet = allTweets.find(t => t._id === replyData.parentTweet);
        reply.createdAt = new Date(parentTweet.createdAt.getTime() + Math.random() * 2 * 60 * 60 * 1000); // 0-2 hours after parent
        
        await reply.save();

        // Add reply to parent tweet's replies array
        await Tweet.findByIdAndUpdate(
          replyData.parentTweet,
          { $push: { replies: reply._id } }
        );
      }

      console.log('Sample replies created successfully');
      console.log(`Total replies: ${sampleReplies.length}`);
    }

    console.log('Login credentials: gokul@gmail.com / Gokul001@');

  } catch (error) {
    console.error('Error seeding database:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
};

// Run the seed function
seedDatabase();