const mongoose = require('mongoose');
const User = require('../models/User');
const Tweet = require('../models/Tweet');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const sampleUsers = [
  {
    username: 'alice_developer',
    email: 'alice@example.com',
    password: 'password123',
    displayName: 'Alice Johnson',
    bio: 'Full-stack developer passionate about React and Node.js 🚀',
    profileImage: 'https://images.unsplash.com/photo-1494790108755-2616b612394e?w=150'
  },
  {
    username: 'bob_designer',
    email: 'bob@example.com',
    password: 'password123',
    displayName: 'Bob Wilson',
    bio: 'UI/UX Designer creating beautiful digital experiences ✨',
    profileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'
  },
  {
    username: 'carol_tech',
    email: 'carol@example.com',
    password: 'password123',
    displayName: 'Carol Smith',
    bio: 'Tech enthusiast | AI researcher | Coffee lover ☕',
    profileImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150'
  },
  {
    username: 'david_mobile',
    email: 'david@example.com',
    password: 'password123',
    displayName: 'David Brown',
    bio: 'Mobile app developer specializing in Flutter & React Native 📱',
    profileImage: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150'
  },
  {
    username: 'emma_data',
    email: 'emma@example.com',
    password: 'password123',
    displayName: 'Emma Davis',
    bio: 'Data scientist turning data into insights 📊',
    profileImage: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150'
  },
  {
    username: 'frank_devops',
    email: 'frank@example.com',
    password: 'password123',
    displayName: 'Frank Miller',
    bio: 'DevOps engineer automating the world 🤖',
    profileImage: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'
  },
  {
    username: 'grace_product',
    email: 'grace@example.com',
    password: 'password123',
    displayName: 'Grace Lee',
    bio: 'Product manager building products people love 💝',
    profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'
  },
  {
    username: 'henry_startup',
    email: 'henry@example.com',
    password: 'password123',
    displayName: 'Henry Taylor',
    bio: 'Startup founder | Tech entrepreneur | Building the future 🚀',
    profileImage: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150'
  }
];

const sampleTweets = [
  {
    content: 'Just deployed my new #React app! The component architecture is so clean. Shoutout to @alice_developer for the amazing tutorial! 🚀 #webdev #javascript',
    hashtags: ['react', 'webdev', 'javascript'],
    author: 'bob_designer'
  },
  {
    content: 'Working on some exciting #AI research today. Machine learning models are getting incredibly sophisticated! #machinelearning #datascience',
    hashtags: ['ai', 'machinelearning', 'datascience'],
    author: 'carol_tech'
  },
  {
    content: 'Flutter is amazing for cross-platform development! @david_mobile your latest app looks fantastic 📱 #flutter #mobiledev',
    hashtags: ['flutter', 'mobiledev'],
    author: 'alice_developer'
  },
  {
    content: 'Data visualization can tell such powerful stories. Just finished an incredible dashboard for our client 📊 #datavisualization #analytics',
    hashtags: ['datavisualization', 'analytics'],
    author: 'emma_data'
  },
  {
    content: 'Automated our entire deployment pipeline today! CI/CD is a game changer 🤖 @frank_devops knows what I am talking about #devops #automation',
    hashtags: ['devops', 'automation'],
    author: 'henry_startup'
  },
  {
    content: 'User feedback is gold! Our latest feature update got amazing reviews 💝 Thanks to the dev team @alice_developer @bob_designer #productmanagement',
    hashtags: ['productmanagement'],
    author: 'grace_product'
  },
  {
    content: 'Building a startup is like riding a roller coaster 🎢 But the journey is so worth it! #startup #entrepreneur #buildinpublic',
    hashtags: ['startup', 'entrepreneur', 'buildinpublic'],
    author: 'henry_startup'
  },
  {
    content: 'CSS Grid and Flexbox together = perfect layouts! 💯 #css #webdesign #frontend',
    hashtags: ['css', 'webdesign', 'frontend'],
    author: 'bob_designer'
  }
];

const createSampleData = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing sample data
    console.log('Clearing existing sample users and tweets...');
    await User.deleteMany({ 
      username: { $in: sampleUsers.map(u => u.username) } 
    });
    
    // Create sample users
    console.log('Creating sample users...');
    const createdUsers = {};
    
    for (const userData of sampleUsers) {
      const user = new User(userData);
      await user.save();
      createdUsers[userData.username] = user._id;
      console.log(`Created user: ${userData.username}`);
    }

    // Create sample tweets with hashtags and mentions
    console.log('Creating sample tweets...');
    for (const tweetData of sampleTweets) {
      const authorId = createdUsers[tweetData.author];
      if (!authorId) {
        console.log(`Author ${tweetData.author} not found, skipping tweet`);
        continue;
      }

      // Extract mentions from content and convert to user IDs
      const mentionRegex = /@(\w+)/g;
      const mentions = [];
      let mentionMatch;
      while ((mentionMatch = mentionRegex.exec(tweetData.content)) !== null) {
        const mentionedUsername = mentionMatch[1];
        const mentionedUserId = createdUsers[mentionedUsername];
        if (mentionedUserId) {
          mentions.push(mentionedUserId);
        }
      }

      const tweet = new Tweet({
        content: tweetData.content,
        author: authorId,
        hashtags: tweetData.hashtags,
        mentions: mentions
      });
      
      await tweet.save();
      console.log(`Created tweet by ${tweetData.author}`);
    }

    console.log('Sample data created successfully!');
    console.log(`Created ${sampleUsers.length} users and ${sampleTweets.length} tweets`);
    
  } catch (error) {
    console.error('Error creating sample data:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
};

createSampleData();