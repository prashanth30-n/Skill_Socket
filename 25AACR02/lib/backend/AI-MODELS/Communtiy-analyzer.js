// lib/backend/AI-MODELS/Community-analyzer.js
const { Cerebras } = require('@cerebras/cerebras_cloud_sdk');
const mongoose = require('mongoose');

class CommunityModel {
    constructor() {
        this.client = new Cerebras({
            apiKey: process.env.CEREBRAS_API_KEY,
        });
        this.modelName = 'llama3.1-70b';
        this.maxTokens = 3000;
        this.temperature = 0.6;
        
        // RAG Configuration
        this.retrievalConfig = {
            maxPosts: 15,
            maxComments: 10,
            maxUsers: 10,
            timeWindow: 30, // days
            relevanceThreshold: 0.7
        };
    }

    async analyzeCommunity(userQuery, userContext = {}) {
        try {
            console.log(`🔍 RAG: Starting community analysis for query: "${userQuery}"`);
            
            // Step 1: Retrieve relevant data from database
            const retrievedData = await this.retrieveRelevantData(userQuery, userContext);
            
            // Step 2: Enhance query with retrieved context
            const enhancedPrompt = this.buildRAGPrompt(userQuery, retrievedData, userContext);
            
            // Step 3: Generate response using Cerebras with RAG context
            const response = await this.generateWithRAG(enhancedPrompt);
            
            return {
                success: true,
                analysis: response.content,
                model: this.modelName,
                rag_context: {
                    posts_retrieved: retrievedData.posts.length,
                    users_analyzed: retrievedData.users.length,
                    comments_processed: retrievedData.comments.length,
                    trends_identified: retrievedData.trends.length
                },
                tokens_used: response.usage?.total_tokens || 0,
                metadata: {
                    query: userQuery,
                    timestamp: new Date().toISOString(),
                    retrieval_time: retrievedData.retrievalTime,
                    user_context: userContext
                }
            };

        } catch (error) {
            console.error('🚨 Community RAG analysis error:', error);
            throw new Error(`Community analysis failed: ${error.message}`);
        }
    }

    async retrieveRelevantData(query, userContext) {
        const startTime = Date.now();
        console.log('📊 RAG: Retrieving relevant community data...');
        
        try {
            // Import models (avoid circular dependencies)
            const Post = require('../models/Post');
            const User = require('../models/User');
            const Comment = require('../models/Comment');
            
            // Calculate time window
            const timeThreshold = new Date();
            timeThreshold.setDate(timeThreshold.getDate() - this.retrievalConfig.timeWindow);
            
            // Step 1: Retrieve recent posts with relevance scoring
            const posts = await this.retrieveRelevantPosts(query, timeThreshold, Post);
            
            // Step 2: Retrieve active users and their activities
            const users = await this.retrieveActiveUsers(query, timeThreshold, User);
            
            // Step 3: Retrieve trending comments and discussions
            const comments = await this.retrieveTrendingComments(timeThreshold, Comment);
            
            // Step 4: Analyze trends and patterns
            const trends = await this.identifyTrends(posts, users, comments);
            
            // Step 5: Get user engagement metrics
            const engagement = await this.calculateEngagementMetrics(posts, comments);
            
            const retrievalTime = Date.now() - startTime;
            console.log(`✅ RAG: Data retrieved in ${retrievalTime}ms`);
            
            return {
                posts,
                users,
                comments,
                trends,
                engagement,
                retrievalTime,
                timestamp: new Date().toISOString()
            };

        } catch (error) {
            console.error('🚨 RAG retrieval error:', error);
            return {
                posts: [],
                users: [],
                comments: [],
                trends: [],
                engagement: {},
                retrievalTime: Date.now() - startTime,
                error: error.message
            };
        }
    }

    async retrieveRelevantPosts(query, timeThreshold, Post) {
        try {
            // Create search terms from query
            const searchTerms = this.extractSearchTerms(query);
            
            // Build MongoDB aggregation pipeline for relevance scoring
            const pipeline = [
                // Match recent posts
                {
                    $match: {
                        createdAt: { $gte: timeThreshold },
                        $or: [
                            { title: { $regex: searchTerms.join('|'), $options: 'i' } },
                            { content: { $regex: searchTerms.join('|'), $options: 'i' } },
                            { tags: { $in: searchTerms } }
                        ]
                    }
                },
                // Populate author information
                {
                    $lookup: {
                        from: 'users',
                        localField: 'author',
                        foreignField: '_id',
                        as: 'authorInfo'
                    }
                },
                // Calculate relevance score
                {
                    $addFields: {
                        relevanceScore: {
                            $add: [
                                { $multiply: [{ $size: { $ifNull: ['$likes', []] } }, 0.3] },
                                { $multiply: [{ $size: { $ifNull: ['$comments', []] } }, 0.4] },
                                { $multiply: [{ $size: { $ifNull: ['$shares', []] } }, 0.2] },
                                { $cond: [{ $in: [{ $toLower: '$title' }, searchTerms.map(t => t.toLowerCase())] }, 0.1, 0] }
                            ]
                        }
                    }
                },
                // Sort by relevance and recency
                {
                    $sort: {
                        relevanceScore: -1,
                        createdAt: -1
                    }
                },
                // Limit results
                { $limit: this.retrievalConfig.maxPosts },
                // Project required fields
                {
                    $project: {
                        title: 1,
                        content: 1,
                        tags: 1,
                        createdAt: 1,
                        likes: { $size: { $ifNull: ['$likes', []] } },
                        comments: { $size: { $ifNull: ['$comments', []] } },
                        shares: { $size: { $ifNull: ['$shares', []] } },
                        author: { $arrayElemAt: ['$authorInfo.name', 0] },
                        relevanceScore: 1
                    }
                }
            ];

            const posts = await Post.aggregate(pipeline);
            console.log(`📊 Retrieved ${posts.length} relevant posts`);
            return posts;

        } catch (error) {
            console.error('Post retrieval error:', error);
            return [];
        }
    }

    async retrieveActiveUsers(query, timeThreshold, User) {
        try {
            const searchTerms = this.extractSearchTerms(query);
            
            const pipeline = [
                // Match active users
                {
                    $match: {
                        $or: [
                            { skills: { $in: searchTerms } },
                            { interests: { $in: searchTerms } },
                            { name: { $regex: searchTerms.join('|'), $options: 'i' } }
                        ],
                        lastActive: { $gte: timeThreshold }
                    }
                },
                // Calculate user activity score
                {
                    $lookup: {
                        from: 'posts',
                        localField: '_id',
                        foreignField: 'author',
                        as: 'recentPosts'
                    }
                },
                {
                    $addFields: {
                        activityScore: {
                            $add: [
                                { $size: '$recentPosts' },
                                { $multiply: [{ $size: { $ifNull: ['$skills', []] } }, 0.5] },
                                { $multiply: [{ $size: { $ifNull: ['$connections', []] } }, 0.1] }
                            ]
                        }
                    }
                },
                {
                    $sort: {
                        activityScore: -1,
                        lastActive: -1
                    }
                },
                { $limit: this.retrievalConfig.maxUsers },
                {
                    $project: {
                        name: 1,
                        skills: 1,
                        interests: 1,
                        bio: 1,
                        lastActive: 1,
                        postCount: { $size: '$recentPosts' },
                        activityScore: 1
                    }
                }
            ];

            const users = await User.aggregate(pipeline);
            console.log(`👥 Retrieved ${users.length} active users`);
            return users;

        } catch (error) {
            console.error('User retrieval error:', error);
            return [];
        }
    }

    async retrieveTrendingComments(timeThreshold, Comment) {
        try {
            const pipeline = [
                {
                    $match: {
                        createdAt: { $gte: timeThreshold }
                    }
                },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'author',
                        foreignField: '_id',
                        as: 'authorInfo'
                    }
                },
                {
                    $lookup: {
                        from: 'posts',
                        localField: 'post',
                        foreignField: '_id',
                        as: 'postInfo'
                    }
                },
                {
                    $addFields: {
                        engagementScore: {
                            $add: [
                                { $size: { $ifNull: ['$likes', []] } },
                                { $size: { $ifNull: ['$replies', []] } }
                            ]
                        }
                    }
                },
                {
                    $sort: {
                        engagementScore: -1,
                        createdAt: -1
                    }
                },
                { $limit: this.retrievalConfig.maxComments },
                {
                    $project: {
                        content: 1,
                        createdAt: 1,
                        author: { $arrayElemAt: ['$authorInfo.name', 0] },
                        postTitle: { $arrayElemAt: ['$postInfo.title', 0] },
                        likes: { $size: { $ifNull: ['$likes', []] } },
                        replies: { $size: { $ifNull: ['$replies', []] } },
                        engagementScore: 1
                    }
                }
            ];

            const comments = await Comment.aggregate(pipeline);
            console.log(`💬 Retrieved ${comments.length} trending comments`);
            return comments;

        } catch (error) {
            console.error('Comment retrieval error:', error);
            return [];
        }
    }

    async identifyTrends(posts, users, comments) {
        try {
            const trends = [];
            
            // Analyze skill trends
            const skillCounts = {};
            users.forEach(user => {
                if (user.skills) {
                    user.skills.forEach(skill => {
                        skillCounts[skill] = (skillCounts[skill] || 0) + 1;
                    });
                }
            });
            
            // Get top skills
            const trendingSkills = Object.entries(skillCounts)
                .sort(([,a], [,b]) => b - a)
                .slice(0, 5)
                .map(([skill, count]) => ({ type: 'skill', name: skill, count }));
            
            trends.push(...trendingSkills);
            
            // Analyze post tags trends
            const tagCounts = {};
            posts.forEach(post => {
                if (post.tags) {
                    post.tags.forEach(tag => {
                        tagCounts[tag] = (tagCounts[tag] || 0) + 1;
                    });
                }
            });
            
            const trendingTags = Object.entries(tagCounts)
                .sort(([,a], [,b]) => b - a)
                .slice(0, 5)
                .map(([tag, count]) => ({ type: 'tag', name: tag, count }));
            
            trends.push(...trendingTags);
            
            console.log(`📈 Identified ${trends.length} trends`);
            return trends;

        } catch (error) {
            console.error('Trend analysis error:', error);
            return [];
        }
    }

    async calculateEngagementMetrics(posts, comments) {
        try {
            const totalPosts = posts.length;
            const totalLikes = posts.reduce((sum, post) => sum + post.likes, 0);
            const totalComments = posts.reduce((sum, post) => sum + post.comments, 0);
            const totalShares = posts.reduce((sum, post) => sum + (post.shares || 0), 0);
            
            return {
                totalPosts,
                totalLikes,
                totalComments,
                totalShares,
                avgLikesPerPost: totalPosts ? (totalLikes / totalPosts).toFixed(2) : 0,
                avgCommentsPerPost: totalPosts ? (totalComments / totalPosts).toFixed(2) : 0,
                engagementRate: totalPosts ? ((totalLikes + totalComments) / totalPosts).toFixed(2) : 0
            };

        } catch (error) {
            console.error('Engagement calculation error:', error);
            return {};
        }
    }

    extractSearchTerms(query) {
        // Extract meaningful terms from user query
        const stopWords = ['what', 'are', 'the', 'is', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'];
        const terms = query.toLowerCase()
            .replace(/[^\w\s]/g, ' ')
            .split(/\s+/)
            .filter(term => term.length > 2 && !stopWords.includes(term));
        
        return [...new Set(terms)]; // Remove duplicates
    }

    buildRAGPrompt(query, retrievedData, userContext) {
        return `
You are an intelligent community analysis assistant with access to real-time community data.

User Query: "${query}"

RETRIEVED COMMUNITY DATA:

📊 Recent Posts (${retrievedData.posts.length} posts):
${retrievedData.posts.map(post => `
- "${post.title}" by ${post.author}
  Content: ${post.content.substring(0, 150)}...
  Tags: [${post.tags ? post.tags.join(', ') : 'none'}]
  Engagement: ${post.likes} likes, ${post.comments} comments
  Relevance Score: ${post.relevanceScore}
  Date: ${new Date(post.createdAt).toDateString()}
`).join('')}

👥 Active Users (${retrievedData.users.length} users):
${retrievedData.users.map(user => `
- ${user.name} (Activity Score: ${user.activityScore})
  Skills: [${user.skills ? user.skills.join(', ') : 'none'}]
  Recent Posts: ${user.postCount}
  Last Active: ${new Date(user.lastActive).toDateString()}
`).join('')}

💬 Trending Comments (${retrievedData.comments.length} comments):
${retrievedData.comments.map(comment => `
- "${comment.content.substring(0, 100)}..." 
  Post: ${comment.postTitle}
  Engagement: ${comment.likes} likes, ${comment.replies} replies
`).join('')}

📈 Identified Trends:
${retrievedData.trends.map(trend => `
- ${trend.type}: ${trend.name} (${trend.count} occurrences)
`).join('')}

📊 Engagement Metrics:
- Total Posts: ${retrievedData.engagement.totalPosts}
- Average Likes per Post: ${retrievedData.engagement.avgLikesPerPost}
- Average Comments per Post: ${retrievedData.engagement.avgCommentsPerPost}
- Overall Engagement Rate: ${retrievedData.engagement.engagementRate}

User Context:
- Role: ${userContext.role || 'member'}
- Interests: ${userContext.interests || 'general'}
- Activity Level: ${userContext.activity_level || 'moderate'}

Based on this real-time community data, provide a comprehensive analysis that:
1. Directly answers the user's question using the retrieved data
2. Highlights relevant trends and patterns
3. Provides actionable insights and recommendations
4. Suggests specific posts, users, or discussions to explore
5. Identifies opportunities for community engagement

Be specific and reference the actual data retrieved. Make your response engaging and actionable.
        `;
    }

    async generateWithRAG(prompt) {
        try {
            const response = await this.client.chat.completions.create({
                messages: [
                    { 
                        role: 'system', 
                        content: 'You are an expert community analyst with access to real-time community data. Use the retrieved data to provide accurate, specific, and actionable insights.' 
                    },
                    { 
                        role: 'user', 
                        content: prompt 
                    }
                ],
                model: this.modelName,
                max_tokens: this.maxTokens,
                temperature: this.temperature,
                stream: false
            });

            return {
                content: response.choices[0].message.content,
                usage: response.usage
            };

        } catch (error) {
            console.error('Cerebras generation error:', error);
            throw error;
        }
    }

    async validateQuery(query) {
        const communityKeywords = [
            'community', 'posts', 'discussions', 'forum', 'recent', 'trending', 
            'popular', 'members', 'active', 'engagement', 'what\'s new', 
            'latest', 'activity', 'users', 'conversations'
        ];
        const queryLower = query.toLowerCase();
        
        return communityKeywords.some(keyword => queryLower.includes(keyword));
    }
}

module.exports = CommunityModel;