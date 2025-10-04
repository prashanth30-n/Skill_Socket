require('dotenv').config();
const { connectToDatabase, getAllUsers, findComplementaryUsers } = require('./tools/dbTool');

async function testSkillMatch() {
  try {
    console.log('Testing database connection...');
    await connectToDatabase();
    console.log('✅ Database connected successfully');
    
    console.log('\nTesting getAllUsers...');
    const allUsers = await getAllUsers();
    console.log(`✅ Found ${allUsers.length} users in database`);
    
    if (allUsers.length > 0) {
      console.log('\nSample users:');
      allUsers.slice(0, 3).forEach((user, index) => {
        console.log(`${index + 1}. ${user.name || user.firstName || 'Unknown'} (${user.email})`);
        console.log(`   - Offers: ${(user.skillsOffered || []).join(', ') || 'None'}`);
        console.log(`   - Needs: ${(user.skillsRequired || []).join(', ') || 'None'}`);
      });
    }
    
    console.log('\nTesting skill matching...');
    const testSkillsRequired = ['Flutter', 'React'];
    const testSkillsOffered = ['Java', 'Python'];
    
    const matches = await findComplementaryUsers(testSkillsRequired, testSkillsOffered);
    console.log(`✅ Found ${matches.length} matching users for test query`);
    
    if (matches.length > 0) {
      console.log('\nMatching users:');
      matches.forEach((user, index) => {
        console.log(`${index + 1}. ${user.name || user.firstName || 'Unknown'} (Score: ${user.matchScore})`);
        console.log(`   - Offers: ${(user.skillsOffered || []).join(', ') || 'None'}`);
        console.log(`   - Needs: ${(user.skillsRequired || []).join(', ') || 'None'}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
  
  process.exit(0);
}

testSkillMatch();