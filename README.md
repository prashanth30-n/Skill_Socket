# 🚀 SkillSocket

**An AI-Powered Skill Exchange & Learning Platform**

SkillSocket is a revolutionary mobile application that connects learners with complementary skills through intelligent matching algorithms and AI-powered educational assistance. Built with Flutter and powered by advanced AI agents, it creates a collaborative learning ecosystem where users can exchange knowledge and grow together.


---

## 🌟 Key Features

### 🤖 **Advanced AI Features**

#### **1. Intelligent Skill Matching Agent**

- **AI-Powered Analysis**: Uses Large Language Models (LLM) to understand natural language queries and extract skill requirements
- **Smart Complementary Matching**: Finds users who offer what you need and need what you offer
- **Real-time Recommendations**: Instantly connects users with compatible learning partners
- **Natural Language Processing**: Understands queries like "I need to learn React and can teach Python"

#### **2. AI Study Assistant Chatbot**

- **Multi-Agent Architecture**: Powered by specialized AI agents for different tasks
  - **Perplexity Agent**: Provides research-based answers with credible sources
  - **Roadmap Agent**: Creates personalized learning paths and skill roadmaps
  - **SkillMatch Agent**: Finds skill exchange opportunities in real-time
- **Conversational Learning**: Natural chat interface for asking questions and getting help
- **Context-Aware Responses**: Understands your learning goals and provides relevant guidance
- **Trending Skills Analysis**: AI insights into current market demands and emerging technologies

#### **3. Intelligent Query Processing**

- **Multi-Modal Understanding**: Processes text queries and extracts meaningful skill data
- **Semantic Analysis**: Goes beyond keyword matching to understand intent and context
- **Automatic Skill Extraction**: Converts natural language into structured skill data
- **Smart Fallback System**: Graceful degradation with helpful responses even when backend services are unavailable

### 📱 **Core Application Features**

#### **User Experience**

- **Intuitive Mobile Interface**: Clean, modern Flutter UI optimized for mobile devices
- **Real-time Messaging**: Seamless communication between matched users
- **Profile Management**: Comprehensive skill portfolios and learning preferences
- **Community Features**: Connect with like-minded learners and educators

#### **Learning & Development**

- **Skill Exchange System**: Barter-based learning where users teach and learn simultaneously
- **Study Rooms**: Collaborative virtual spaces for group learning
- **Progress Tracking**: Monitor your learning journey and skill development
- **Notification System**: Stay updated on matches, messages, and learning opportunities

#### **Social Features**

- **User Reviews & Ratings**: Build trust through peer feedback
- **Learning History**: Track your educational interactions and achievements
- **Community Discussions**: Engage in skill-specific conversations
- **Mentorship Matching**: Connect with experienced professionals in your field of interest

---

## 🏗️ **Architecture Overview**

### **Frontend (Mobile App)**

- **Framework**: Flutter/Dart
- **Platform Support**: iOS, Android, Web
- **State Management**: Built-in Flutter state management
- **UI Components**: Custom Material Design components

### **Backend Services**

- **MCP Gateway**: Node.js/Express server handling AI agent orchestration
- **API Backend**: RESTful services for user management and data persistence
- **Database**: MongoDB for user profiles and skill data storage

### **AI Infrastructure**

- **LLM Integration**: Cerebras AI for natural language processing
- **Agent Framework**: Custom MCP (Model Context Protocol) implementation
- **Microservices Architecture**: Scalable, containerized AI agents

### **Deployment**

- **Containerization**: Docker for consistent deployment environments
- **Cloud Hosting**: Render.com for production deployment
- **CI/CD**: Automated build and deployment pipelines

---

## 🚀 **Getting Started**

### **Prerequisites**

- Flutter SDK (3.0 or higher)
- Node.js (18 or higher)
- Docker (optional, for containerized deployment)
- Git for version control

### **Installation**

#### **1. Clone the Repository**

```bash
git clone https://github.com/prashanth30-n/skillsocket.git
cd skillsocket
```

#### **2. Setup Flutter App**

```bash
cd 25AACR02
flutter pub get
flutter run
```

#### **3. Setup MCP Gateway (AI Backend)**

```bash
cd MCP_GATEWAY/SKill_SOCKET-Mcp_gateway
npm install
npm start
```

#### **4. Docker Deployment (Optional)**

```bash
cd MCP_GATEWAY/SKill_SOCKET-Mcp_gateway
docker build -t skillsocket-mcp-gateway .
docker run -p 3000:3000 skillsocket-mcp-gateway
```

---

## 🤖 **AI Agent System**

### **Agent Types**

#### **SkillMatch Agent**

```javascript
// Example usage
const query = "I need to learn Flutter and can teach Java";
const matches = await skillMatchAgent.run(query);
// Returns users with complementary skills
```

#### **Perplexity Agent**

- Provides research-based answers
- Includes credible source citations
- Handles complex educational queries

#### **Roadmap Agent**

- Creates structured learning paths
- Suggests skill progression routes
- Provides timeline estimates

### **Natural Language Processing**

- **Skill Extraction**: Converts natural language to structured data
- **Intent Recognition**: Understands user goals and preferences
- **Context Awareness**: Maintains conversation history and user preferences

---

## 📊 **API Endpoints**

### **MCP Gateway Endpoints**

```
POST /mcp/invoke
- Body: { "query": "natural language query" }
- Returns: AI agent response with skill matches or educational content

GET /health
- Returns: Service health status
```

### **Main Backend Endpoints**

```
GET /api/users/match
- Returns: Users with complementary skills

POST /api/chat
- Body: { "message": "user message" }
- Returns: AI chatbot response
```

---

## 🔧 **Configuration**

### **Environment Variables**

```bash
# MCP Gateway (.env)
PORT=3000
MONGODB_URI=your_mongodb_connection_string
CEREBRAS_API_KEY=your_cerebras_api_key
BACKEND_API_URL=https://skillsocket-backend.onrender.com

# Flutter App
# No additional configuration required for basic setup
```

---

## 🌐 **Live Demo**

- **Mobile App**: Available for iOS and Android
- **AI Gateway**: [https://skillsocket-mcp-gateway.onrender.com](https://skillsocket-mcp-gateway.onrender.com)
- **Main Backend**: [https://skillsocket-backend.onrender.com](https://skillsocket-backend.onrender.com)

---

## 🛠️ **Technology Stack**

### **Frontend**

- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language for Flutter
- **Material Design**: UI components and design system

### **Backend**

- **Node.js**: Runtime environment
- **Express.js**: Web framework
- **MongoDB**: NoSQL database
- **Mongoose**: MongoDB object modeling

### **AI & ML**

- **Cerebras AI**: Large Language Model provider
- **Custom NLP**: Natural language processing algorithms
- **Model Context Protocol**: AI agent communication framework

### **DevOps**

- **Docker**: Containerization
- **Render.com**: Cloud hosting platform
- **Git**: Version control
- **GitHub**: Code repository and CI/CD

---

## 📱 **Features Showcase**

### **AI-Powered Skill Matching**

1. User types: "I want to learn React and can teach Python"
2. AI extracts: `skillsRequired: ["React"]`, `skillsOffered: ["Python"]`
3. System finds users who offer React and need Python
4. Returns formatted matches with user details and skills

### **Intelligent Chatbot Conversations**

- **Context-Aware**: Remembers previous messages in conversation
- **Multi-Agent Routing**: Automatically selects the best AI agent for each query
- **Rich Responses**: Includes formatted text, sources, and actionable recommendations
- **Fallback Handling**: Graceful degradation when services are unavailable

### **Real-Time Learning Recommendations**

- Trending skills in technology
- Personalized learning paths
- Market demand analysis
- Career progression suggestions

---

## 🤝 **Contributing**

We welcome contributions! Please see our contributing guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### **Development Guidelines**

- Follow Flutter/Dart style guidelines
- Write unit tests for new features
- Update documentation for API changes
- Ensure Docker compatibility

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 **Team**

- **Development Lead**: Prashanth N
- **AI Engineering**: Advanced LLM integration and agent development
- **Mobile Development**: Flutter cross-platform application
- **Backend Architecture**: Scalable microservices design

---

## 📞 **Support**

- **Issues**: [GitHub Issues](https://github.com/prashanth30-n/skillsocket/issues)

- **Gmail**: prashanthnakerikanti@gmail.com

---

## 🎯 **Roadmap**

### **Upcoming Features**

- [ ] Video call integration for live skill sessions
- [ ] AI-powered skill assessment and certification
- [ ] Gamification with skill badges and leaderboards
- [ ] Advanced analytics and learning insights
- [ ] Multi-language support
- [ ] Integration with professional networks (LinkedIn, GitHub)

### **AI Enhancements**

- [ ] Voice-to-text query processing
- [ ] Image-based skill recognition
- [ ] Predictive learning path optimization
- [ ] Personalized content recommendation engine

---

**Built with ❤️ using Flutter, Node.js, and cutting-edge AI technologies**

_Empowering learners worldwide through intelligent skill exchange_
