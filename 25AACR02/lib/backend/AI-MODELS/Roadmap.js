// lib/backend/AI-MODELS/Roadmap.js
const { Cerebras } = require('@cerebras/cerebras_cloud_sdk');

class RoadmapModel {
  constructor() {
    this.client = new Cerebras({
      apiKey: process.env.CEREBRAS_API_KEY,
    });
    this.modelName = 'llama3.1-8b';
    this.maxTokens = 2048;
    this.temperature = 0.7;
  }

  async generateRoadmap(userQuery, userContext = {}) {
    try {
      const systemPrompt = this.buildRoadmapPrompt(userQuery, userContext);
      
      const response = await this.client.chat.completions.create({
        messages: [
          { 
            role: 'system', 
            content: 'You are an expert learning roadmap creator. Provide detailed, structured learning paths with timelines, resources, and milestones.' 
          },
          { 
            role: 'user', 
            content: systemPrompt 
          }
        ],
        model: this.modelName,
        max_tokens: this.maxTokens,
        temperature: this.temperature,
        stream: false
      });

      return {
        success: true,
        roadmap: response.choices[0].message.content,
        model: this.modelName,
        tokens_used: response.usage?.total_tokens || 0,
        metadata: {
          query: userQuery,
          timestamp: new Date().toISOString(),
          user_context: userContext
        }
      };

    } catch (error) {
      console.error('Roadmap model error:', error);
      throw new Error(`Roadmap generation failed: ${error.message}`);
    }
  }

  buildRoadmapPrompt(query, context) {
    return `
Create a comprehensive learning roadmap for: ${query}

User Context:
- Experience Level: ${context.experience_level || 'beginner'}
- Available Time: ${context.time_commitment || 'flexible'}
- Learning Style: ${context.learning_style || 'mixed'}
- Goals: ${context.goals || 'general skill development'}

Please provide:
1. **Skill Assessment & Prerequisites**
   - Current knowledge requirements
   - Skills gap analysis
   - Recommended background

2. **Learning Phases** (with timeframes)
   - Phase 1: Foundations (Week 1-2)
   - Phase 2: Core Concepts (Week 3-6)
   - Phase 3: Advanced Topics (Week 7-10)
   - Phase 4: Practical Applications (Week 11-12)

3. **Hands-on Projects**
   - Beginner project ideas
   - Intermediate challenges
   - Advanced capstone project

4. **Resources & Tools**
   - Recommended courses/tutorials
   - Books and documentation
   - Tools and software needed
   - Community resources

5. **Milestones & Assessment**
   - Weekly checkpoints
   - Skills validation methods
   - Portfolio development
   - Next steps recommendations

Format the response as a clear, actionable roadmap with specific timelines and measurable goals.
    `;
  }

  async validateQuery(query) {
    const roadmapKeywords = ['roadmap', 'learning path', 'curriculum', 'study plan', 'career path', 'guide', 'how to learn'];
    const queryLower = query.toLowerCase();
    
    return roadmapKeywords.some(keyword => queryLower.includes(keyword));
  }
}

module.exports = RoadmapModel;