/**
 * Script to fix MongoDB indexing issues
 * This script removes problematic compound indexes on parallel arrays
 * and creates appropriate alternative indexes
 */

const mongoose = require('mongoose');
require('dotenv').config();

const fixIndexes = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('tweets');

    // Get current indexes
    const currentIndexes = await collection.indexes();
    console.log('Current indexes:', currentIndexes.map(idx => idx.name));

    // Drop problematic compound index if it exists
    try {
      await collection.dropIndex({ 'likes.length': 1, 'retweets.length': 1 });
      console.log('✅ Dropped problematic compound index on parallel arrays');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ️  Compound index on parallel arrays does not exist (already removed)');
      } else {
        console.log('⚠️  Could not drop compound index:', error.message);
      }
    }

    // Create individual indexes for better performance
    const indexesToCreate = [
      { likes: 1 },
      { retweets: 1 },
      { createdAt: -1 },
      { author: 1 },
      { hashtags: 1 },
      { mentions: 1 },
      { imageUrl: 1 }
    ];

    for (const indexDef of indexesToCreate) {
      try {
        await collection.createIndex(indexDef);
        console.log('✅ Created index:', Object.keys(indexDef).join(', '));
      } catch (error) {
        if (error.code === 85) {
          console.log('ℹ️  Index already exists:', Object.keys(indexDef).join(', '));
        } else {
          console.log('⚠️  Could not create index:', Object.keys(indexDef).join(', '), error.message);
        }
      }
    }

    // Create text index for search
    try {
      await collection.createIndex({ content: 'text' });
      console.log('✅ Created text index for search');
    } catch (error) {
      if (error.code === 85) {
        console.log('ℹ️  Text index already exists');
      } else {
        console.log('⚠️  Could not create text index:', error.message);
      }
    }

    // Display final indexes
    const finalIndexes = await collection.indexes();
    console.log('\n📋 Final indexes:');
    finalIndexes.forEach(index => {
      console.log(`  - ${index.name}: ${JSON.stringify(index.key)}`);
    });

    console.log('\n✅ Index fixing completed successfully!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error fixing indexes:', error);
    process.exit(1);
  }
};

// Run the fix
fixIndexes();