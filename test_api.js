const axios = require('axios');

const baseUrl = 'http://localhost:3000/api';

async function testAPI() {
  try {
    console.log('Testing API endpoints...\n');

    // Test health check
    console.log('1. Testing health check...');
    const healthResponse = await axios.get(`${baseUrl}/health`);
    console.log('✅ Health check successful\n');

    // Test login
    console.log('2. Testing login...');
    const loginResponse = await axios.post(`${baseUrl}/auth/login`, {
      email: 'gokul@gmail.com',
      password: 'Gokul001@'
    });
    const token = loginResponse.data.token;
    console.log('✅ Login successful\n');

    // Test get tweets
    console.log('3. Testing get tweets...');
    const tweetsResponse = await axios.get(`${baseUrl}/tweets`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log(`✅ Found ${tweetsResponse.data.length} tweets\n`);

    // Find a tweet with replies
    const tweetWithReplies = tweetsResponse.data.find(tweet => tweet.repliesCount > 0);
    
    if (tweetWithReplies) {
      console.log(`4. Testing get replies for tweet "${tweetWithReplies.content.substring(0, 50)}..."`);
      console.log(`   Tweet ID: ${tweetWithReplies._id}`);
      console.log(`   Replies Count: ${tweetWithReplies.repliesCount}`);
      
      const repliesResponse = await axios.get(`${baseUrl}/tweets/${tweetWithReplies._id}/replies`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      console.log(`✅ Found ${repliesResponse.data.length} replies:`);
      repliesResponse.data.forEach((reply, index) => {
        console.log(`   ${index + 1}. "${reply.content}" by ${reply.author.displayName}`);
      });
    } else {
      console.log('❌ No tweets with replies found');
    }

  } catch (error) {
    console.error('❌ API test failed:', error.response?.data || error.message);
  }
}

testAPI();