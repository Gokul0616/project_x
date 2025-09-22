/**
 * Force fix MongoDB indexes - drops and recreates the Tweet collection if needed
 */

const mongoose = require('mongoose');
require('dotenv').config();

const forceFix = async () => {
  try {
    console.log('🔧 FORCE FIXING MongoDB indexes...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('tweets');

    // Get current indexes
    try {
      const indexes = await collection.indexes();
      console.log('\n📋 Current indexes:');
      indexes.forEach(index => {
        console.log(`  - ${index.name}: ${JSON.stringify(index.key)}`);
      });
    } catch (error) {
      console.log('⚠️  Could not get indexes:', error.message);
    }

    // Drop all indexes except _id
    try {
      console.log('\n🗑️  Dropping all custom indexes...');
      await collection.dropIndexes();
      console.log('✅ All custom indexes dropped');
    } catch (error) {
      console.log('⚠️  Could not drop indexes:', error.message);
    }

    // Recreate safe indexes
    console.log('\n🔨 Creating new safe indexes...');
    
    const indexesToCreate = [
      { key: { createdAt: -1 }, name: 'createdAt_-1' },
      { key: { author: 1 }, name: 'author_1' },
      { key: { content: 'text' }, name: 'content_text' },
      { key: { hashtags: 1 }, name: 'hashtags_1' },
      { key: { mentions: 1 }, name: 'mentions_1' },
      { key: { imageUrl: 1 }, name: 'imageUrl_1' },
      { key: { likes: 1 }, name: 'likes_1' },
      { key: { retweets: 1 }, name: 'retweets_1' }
    ];

    for (const indexDef of indexesToCreate) {
      try {
        await collection.createIndex(indexDef.key, { name: indexDef.name });
        console.log(`✅ Created index: ${indexDef.name}`);
      } catch (error) {
        console.log(`⚠️  Could not create index ${indexDef.name}:`, error.message);
      }
    }

    // Verify final indexes
    try {
      const finalIndexes = await collection.indexes();
      console.log('\n🎉 FINAL INDEXES:');
      finalIndexes.forEach(index => {
        console.log(`  ✅ ${index.name}: ${JSON.stringify(index.key)}`);
      });
    } catch (error) {
      console.log('⚠️  Could not verify final indexes:', error.message);
    }

    console.log('\n✅ FORCE FIX COMPLETED! Try creating a tweet now.');
    process.exit(0);

  } catch (error) {
    console.error('❌ Force fix failed:', error);
    process.exit(1);
  }
};

forceFix();