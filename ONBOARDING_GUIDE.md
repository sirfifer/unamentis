# UnaMentis: Complete Onboarding Guide for Non-Technical Team Members

Welcome to UnaMentis! This guide will explain the entire project in simple terms so you can understand what UnaMentis is, how it works, and how all the pieces fit together.

## Table of Contents

1. [What is UnaMentis?](#what-is-unamentis)
2. [The Big Picture](#the-big-picture)
3. [The Three Main Parts](#the-three-main-parts)
4. [Understanding the iPhone App](#understanding-the-iphone-app)
5. [Understanding the Web Servers](#understanding-the-web-servers)
6. [Understanding the Curriculum System](#understanding-the-curriculum-system)
7. [How Everything Works Together](#how-everything-works-together)
8. [Common Scenarios](#common-scenarios)
9. [Technical Terms Made Simple](#technical-terms-made-simple)
10. [Where to Learn More](#where-to-learn-more)

---

## What is UnaMentis?

UnaMentis is an **AI tutor that talks to you like a real person**. Imagine having a super smart teacher who:
- You can talk to using your voice (no typing needed)
- Explains topics at your exact level
- Remembers what you've learned
- Can teach you for an hour or more without getting tired
- Responds almost instantly (usually in less than half a second)

**What makes it special?**
- It can run entirely on your iPhone (no internet required, totally private)
- It follows actual lesson plans (like a real curriculum)
- It tracks your progress over time
- It costs very little or nothing to use

Think of it like having a personal tutor available 24/7 who never gets tired and adapts to exactly how you learn best.

---

## The Big Picture

UnaMentis is made up of three main parts that work together:

```
┌─────────────────────────────────────────────┐
│         1. iPhone App                       │
│    (The voice tutor you talk to)            │
│                                             │
│    "Explain photosynthesis to me"           │
│             ↓                               │
│    Voice → Text → AI Brain → Voice          │
└──────────────┬──────────────────────────────┘
               ↓
               Downloads lesson materials from...
               ↓
┌─────────────────────────────────────────────┐
│         2. Web Servers                      │
│    (The backend that manages content)       │
│                                             │
│    • Stores all the lesson materials        │
│    • Imports courses from universities      │
│    • Tracks your learning progress          │
└──────────────┬──────────────────────────────┘
               ↓
               Gets content from...
               ↓
┌─────────────────────────────────────────────┐
│         3. Curriculum System                │
│    (The lesson plans and materials)         │
│                                             │
│    • MIT courses                            │
│    • K-12 textbooks                         │
│    • Custom learning materials              │
└─────────────────────────────────────────────┘
```

Let's explore each part in detail.

---

## The Three Main Parts

### Part 1: The iPhone App (What You See and Use)

This is the app you open on your iPhone. It's what you interact with directly.

**What it does:**
- Listens to your voice through the microphone
- Converts your speech to text (so the AI can understand you)
- Sends your question to an AI brain
- Gets an answer back
- Converts the answer to speech (so you can hear it)
- Plays the answer through your speaker

**Why it's special:**
- It can work completely offline (if you have the right models downloaded)
- It responds incredibly fast (usually under 500 milliseconds)
- It can have conversations lasting over an hour without breaking
- It remembers context from earlier in your conversation

### Part 2: The Web Servers (The Behind-the-Scenes Helper)

These are programs that run on a computer (not your iPhone) that help manage everything.

**There are actually TWO web servers:**

**Server #1: UnaMentis Server (Port 3000)**
- This is like the "control panel" for the whole system
- You can see it in a web browser (like Safari or Chrome)
- It shows you:
  - How well the system is performing
  - What courses are available
  - A visual editor for creating/editing lessons
  - System health (CPU usage, memory, etc.)

**Server #2: Management API (Port 8766)**
- This is the "database manager"
- It stores all the lesson materials
- It imports courses from universities and educational websites
- It keeps track of your learning progress
- The iPhone app talks to this to get lesson materials

**Think of it like this:**
- Server #1 is the dashboard where humans manage things
- Server #2 is the engine that does the actual work

### Part 3: The Curriculum System (The Lesson Plans)

This is the special format we created for storing educational content in a way that works perfectly for voice-based AI tutoring.

**What makes it special:**
- It's designed specifically for talking, not reading
- Every lesson has both "text to read" and "text to speak" versions
- It includes images, diagrams, and equations
- It knows how to break lessons into bite-sized chunks
- It tracks prerequisites (what you need to know first)

**Where content comes from:**
- MIT OpenCourseWare (247 university courses)
- CK-12 (K-12 textbooks)
- EngageNY (New York State curriculum)
- MERLOT (digital learning materials)
- Custom content you create yourself

---

## Understanding the iPhone App

Let's break down how the iPhone app works step by step.

### The Voice Pipeline (How Your Voice Becomes an Answer)

Imagine a factory assembly line, but for conversations:

```
1. MICROPHONE
   ↓
   Your voice: "What is photosynthesis?"

2. VOICE ACTIVITY DETECTION (VAD)
   ↓
   Detects when you start and stop talking
   (So the app knows when you're done speaking)

3. SPEECH-TO-TEXT (STT)
   ↓
   Converts your voice to text: "What is photosynthesis?"

4. SESSION MANAGER
   ↓
   Adds context: "The user is learning about plants. They just
   learned about cells. This is an intermediate-level question."

5. PATCH PANEL (Smart Router)
   ↓
   Decides which AI brain to use based on:
   - How complex the question is
   - How fast you need an answer
   - How much it costs
   - Whether you're online or offline

6. LLM (Large Language Model - The AI Brain)
   ↓
   Generates an answer: "Photosynthesis is the process plants
   use to convert sunlight into food..."

7. TEXT-TO-SPEECH (TTS)
   ↓
   Converts the text answer to voice

8. SPEAKER
   ↓
   You hear the answer!
```

**Every step happens in REAL TIME.** The whole process takes less than 500 milliseconds (half a second)!

### The App's Main Components

Think of the app as having different "departments," each with a specific job:

#### Department 1: Audio Department
- **Job:** Handle all sound (recording your voice, playing answers)
- **Files:** AudioEngine.swift, AudioEngineConfig.swift
- **What it manages:**
  - Microphone input quality
  - Speaker output volume
  - Making sure your phone doesn't overheat during long sessions

#### Department 2: Session Department
- **Job:** Orchestrate the entire conversation
- **Files:** SessionManager.swift
- **What it manages:**
  - Knowing when it's your turn to speak
  - Knowing when it's the AI's turn to speak
  - Keeping track of conversation context
  - Managing the lesson plan context

#### Department 3: Curriculum Department
- **Job:** Manage all the lesson materials
- **Files:** CurriculumEngine.swift, ProgressTracker.swift
- **What it manages:**
  - Loading lesson materials
  - Tracking your progress through topics
  - Remembering what you've already learned
  - Knowing what you should learn next

#### Department 4: Routing Department (Patch Panel)
- **Job:** Decide which AI brain to use for each question
- **Files:** PatchPanelService.swift
- **What it manages:**
  - Choosing the fastest AI for urgent questions
  - Choosing the cheapest AI for simple questions
  - Choosing the smartest AI for complex questions
  - Automatically switching if one AI isn't available

#### Department 5: Services Department
- **Job:** Provide all the different AI options
- **What's available:**
  - **Speech-to-Text (9 options):**
    - Apple's built-in (free, always works)
    - DeepGram (super accurate, cloud-based)
    - AssemblyAI (great for technical terms)
    - Groq (extremely fast)
    - On-device GLM-ASR (runs on your phone)
    - And 4 more...

  - **Text-to-Speech (5 options):**
    - Apple's built-in (free, always works)
    - ElevenLabs (most natural sounding)
    - Deepgram (very fast)
    - Piper (self-hosted, free)
    - Chatterbox (experimental)

  - **AI Brains (5 options):**
    - OpenAI GPT-4o (smartest, expensive)
    - Anthropic Claude (very smart, good at explaining)
    - On-device Ministral-3B (runs on your phone, free)
    - Self-hosted Ollama (runs on your computer)
    - And more...

### What You See (The User Interface)

The app has several screens:

**1. Session Screen**
- This is where you have conversations
- Shows a microphone icon when listening
- Shows visual aids (images, diagrams) when relevant
- Displays real-time transcripts

**2. Curriculum Browser**
- Browse available courses and topics
- Select what you want to learn about
- See how topics are organized hierarchically

**3. History**
- See past conversation sessions
- Review transcripts
- Revisit topics you've learned

**4. Analytics**
- See how much time you've spent on each topic
- Track your learning progress
- View cost per session (if using paid services)

**5. Settings**
- Choose which AI services to use
- Enter API keys (like passwords for AI services)
- Configure self-hosted servers
- Adjust performance vs. quality trade-offs

**6. Debug Tools**
- Monitor CPU and memory usage
- Test individual components
- View system logs for troubleshooting

### How the App Stays Fast

The app uses several tricks to stay incredibly responsive:

**1. Streaming:** Everything happens in real-time as data arrives
- When you speak, transcription starts immediately (not after you finish)
- When AI responds, speech starts immediately (not after full response)
- It's like watching a video that starts playing before it's fully downloaded

**2. Concurrency:** Multiple things happen at the same time
- While the AI is generating text, speech synthesis is already starting
- While you're listening to an answer, the app is preparing for your next question
- Think of it like a restaurant where the chef starts cooking while you're still ordering dessert

**3. Smart Caching:** The app remembers things to avoid repetition
- Lesson materials are downloaded once and stored locally
- Common responses are reused when appropriate
- It's like keeping frequently used ingredients on your counter instead of in the pantry

**4. Thermal Management:** The app prevents overheating
- Monitors your phone's temperature
- Automatically switches to lighter AI models if it gets hot
- Reduces processing intensity when battery is low

---

## Understanding the Web Servers

The web servers are like the "headquarters" that support the iPhone app.

### Server #1: UnaMentis Server (Port 3000)

Think of this as the "control center" that humans use to manage the system.

**What "Port 3000" means:**
- A "port" is like a specific door on a building
- Your computer has thousands of doors (ports)
- Port 3000 is the door where this server listens for requests
- You access it by going to: http://localhost:3000 in a web browser

**What you can do here:**

**Curriculum Studio:**
- A visual editor for creating and editing lessons
- Like a word processor, but for educational content
- Lets you add images, equations, examples
- Previews how lessons will sound when spoken

**Plugin Manager:**
- Enable/disable different course importers
- Like an app store for educational content sources
- Turn on MIT OCW to import university courses
- Turn on CK-12 to import K-12 textbooks

**System Dashboard:**
- See real-time performance metrics
- Monitor CPU, memory, battery usage
- View latency statistics (how fast responses are)
- Track costs (if using paid AI services)

**Technology used:**
- Next.js (a framework for building websites)
- React (a library for interactive interfaces)
- TypeScript (a programming language)
- Tailwind CSS (a styling system)

### Server #2: Management API (Port 8766)

Think of this as the "database and file manager" that stores everything.

**What "Port 8766" means:**
- Same concept as port 3000, just a different door number
- The iPhone app talks to this server directly
- You can also access it at: http://localhost:8766

**What it does:**

**Stores Curriculum Data:**
- All lesson materials are stored in a SQLite database
- SQLite is like a super organized filing cabinet
- Every course, topic, image, and progress record has a specific place

**Manages Imports:**
- When you want to import a course from MIT, this server:
  1. Downloads the course materials
  2. Validates they're complete
  3. Extracts the content
  4. (Optionally) Enhances it with AI
  5. Converts it to our special format (UMCF)
  6. Stores it in the database

**Tracks Your Progress:**
- Every time you learn something, it's recorded here
- Time spent on each topic
- Mastery scores
- Conversation transcripts

**Provides API Endpoints:**
- An "API endpoint" is like a specific service desk
- Example endpoints:
  - GET /curricula → "Give me a list of all courses"
  - GET /topics/{id} → "Give me details about topic #42"
  - POST /progress → "Save that the user studied this topic"

**Technology used:**
- Python (a programming language)
- aiohttp (a library for async web servers)
- SQLite (a database system)

### How the Two Servers Work Together

```
┌──────────────────────────────────────────────────┐
│  You open http://localhost:3000 in browser       │
│  (UnaMentis Server)                              │
└────────────────┬─────────────────────────────────┘
                 │
                 ↓
     You click "Import MIT Course #42"
                 │
                 ↓
┌────────────────────────────────────────────────┐
│  UnaMentis Server sends request to:            │
│  http://localhost:8766/import/mit/42           │
│  (Management API)                              │
└────────────────┬───────────────────────────────┘
                 │
                 ↓
     Management API does the import
                 │
                 ↓
┌────────────────────────────────────────────────┐
│  Course saved to SQLite database               │
└────────────────┬───────────────────────────────┘
                 │
                 ↓
     iPhone app downloads course
                 │
                 ↓
┌────────────────────────────────────────────────┐
│  You can now learn from the course on iPhone   │
└────────────────────────────────────────────────┘
```

---

## Understanding the Curriculum System

The curriculum system is the "lesson plan format" we invented specifically for voice-based AI tutoring.

### What is UMCF?

**UMCF = Una Mentis Curriculum Format**

It's a special way of organizing educational content that's optimized for AI tutoring conversations.

**Why we needed our own format:**

Traditional e-learning formats (like SCORM, used in corporate training) were designed for:
- Clicking through slides
- Reading on a screen
- Taking quizzes with a mouse

We needed something designed for:
- Listening with your ears
- Speaking with your voice
- Having natural conversations
- Learning over extended periods

### What Makes UMCF Special?

**1. Voice-Optimized Text**
- Every piece of content has TWO versions:
  - Written text (for reading)
  - Spoken text (for listening)

Example:
```
Written: "H₂O (water) consists of 2 hydrogen atoms and 1 oxygen atom."
Spoken: "Water, or H 2 O, consists of 2 hydrogen atoms and 1 oxygen atom."
```

Notice how the spoken version spells out "H 2 O" instead of using subscripts, because you can't hear subscripts!

**2. Conversation Structure**
- Lessons are broken into small "segments" with natural stopping points
- Like chapters in a book, but for conversations
- The AI knows when to pause and check if you understand

**3. Tutoring Intelligence**
- **Learning Objectives:** Clear goals for what you'll learn
- **Prerequisites:** What you need to know first
- **Misconceptions:** Common mistakes and how to correct them
- **Examples:** Multiple ways to explain the same concept
- **Assessments:** Questions to check understanding

**4. Visual Assets**
- Links to images, diagrams, equations
- Synchronized with the voice (shows up at the right time)
- Includes "alt text" for accessibility

**5. Unlimited Depth**
- Topics can nest inside topics infinitely
- Like folders on your computer:
  ```
  Physics
    ├── Mechanics
    │   ├── Kinematics
    │   │   ├── Position
    │   │   ├── Velocity
    │   │   └── Acceleration
    │   └── Dynamics
    └── Thermodynamics
  ```

**6. Standards Alignment**
- Every lesson links to real educational standards
- Bloom's Taxonomy levels (Remember, Understand, Apply, Analyze, Evaluate, Create)
- Common Core standards (for K-12)
- University course competencies

### Where Curriculum Content Comes From

We have "importers" that automatically convert existing educational content into UMCF format.

**Current Sources:**

**MIT OpenCourseWare:**
- 247 university-level courses
- Physics, Math, Engineering, Computer Science, and more
- All freely available

**CK-12 FlexBooks:**
- K-12 textbooks (elementary through high school)
- Math, Science, Social Studies
- Focused on 8th-grade content currently

**EngageNY:**
- New York State curriculum materials
- Aligned to Common Core standards
- K-12 across all subjects

**MERLOT:**
- Higher education digital resources
- Curated by educators
- Peer-reviewed materials

### The Import Pipeline

When you want to add a new course, here's what happens:

```
1. DOWNLOAD
   ↓
   Fetch all course materials (PDFs, videos, HTML pages)

2. VALIDATE
   ↓
   Check that everything downloaded correctly
   Make sure there are no missing files

3. EXTRACT
   ↓
   Pull out the actual educational content
   Remove navigation menus, headers, footers
   Identify text, images, equations

4. ENRICH (Optional - Uses AI)
   ↓
   Stage 1: Analyze content quality and reading level
   Stage 2: Detect topic boundaries and create hierarchy
   Stage 3: Segment into conversation-sized chunks
   Stage 4: Extract learning objectives
   Stage 5: Generate comprehension questions
   Stage 6: Create spoken-text variants
   Stage 7: Build knowledge graph (how concepts connect)

5. GENERATE
   ↓
   Convert everything to UMCF JSON format

6. STORE
   ↓
   Save to SQLite database
   Make available to iPhone app
```

**The "Enrich" step is optional but powerful:**
- Without it: You get a basic conversion (faster, but less "smart")
- With it: You get AI-enhanced content with conversation scripts, questions, and more

### Example UMCF Structure

Here's a simplified example of what UMCF looks like:

```json
{
  "umcf": "1.0.0",
  "title": "Introduction to Photosynthesis",
  "description": "Learn how plants convert sunlight into energy",
  "educational": {
    "targetAudience": "High school biology students",
    "duration": "PT15M",  // 15 minutes
    "difficulty": "Intermediate"
  },
  "content": [
    {
      "id": "photo-001",
      "title": "What is Photosynthesis?",
      "type": "concept",
      "learningObjectives": [
        "Define photosynthesis in simple terms",
        "Identify the inputs and outputs of photosynthesis"
      ],
      "transcript": {
        "segments": [
          {
            "text": "Photosynthesis is the process by which plants...",
            "spokenText": "Let's start with the basics. Photosynthesis is the process by which plants...",
            "stoppingPoint": true,
            "comprehensionCheck": "Do you understand so far?"
          }
        ]
      },
      "media": [
        {
          "type": "diagram",
          "url": "photosynthesis-diagram.png",
          "altText": "Diagram showing sunlight, water, and CO2 entering a leaf",
          "segmentIndex": 0
        }
      ],
      "children": [
        {
          "id": "photo-002",
          "title": "The Role of Chlorophyll",
          "type": "concept"
        }
      ]
    }
  ]
}
```

---

## How Everything Works Together

Let's walk through a complete user journey to see how all the pieces connect.

### Scenario: Learning About Photosynthesis

**Step 1: Setting Up Content**

1. You open http://localhost:3000 (UnaMentis Server) in your browser
2. You go to the Plugin Manager
3. You enable the "CK-12" importer plugin
4. You browse the CK-12 course catalog
5. You find "8th Grade Biology"
6. You click "Import Course"

**What happens behind the scenes:**
- UnaMentis Server sends request to Management API (port 8766)
- Management API runs the CK-12 importer plugin
- Importer downloads the textbook chapters
- Importer converts content to UMCF format
- UMCF content is saved to SQLite database
- Import status shows "Complete"

**Step 2: Using the iPhone App**

1. You open UnaMentis app on your iPhone
2. You go to the Curriculum Browser
3. The app requests available courses from Management API
4. You see "8th Grade Biology" in the list
5. You tap to download it
6. The app stores it locally on your phone
7. You navigate to "Chapter 4: Photosynthesis"
8. You tap "Start Learning Session"

**What happens behind the scenes:**
- App downloads UMCF JSON from Management API
- App stores it in local Core Data database
- App parses the curriculum structure
- App loads learning objectives and prerequisites
- App prepares the voice pipeline

**Step 3: Having a Conversation**

1. You say: "Explain photosynthesis to me like I'm 10 years old"

**What happens (in 300-500 milliseconds):**

```
Your voice → Microphone
    ↓
AudioEngine captures audio buffer
    ↓
VAD (Voice Activity Detection) recognizes speech
    ↓
STT Service converts to text
    ↓ (Your words: "Explain photosynthesis to me like I'm 10 years old")
SessionManager receives transcript
    ↓
CurriculumEngine adds context:
    "The user is studying 8th Grade Biology, Chapter 4.
     They haven't learned about chlorophyll yet.
     Their preferred explanation style is 'simple analogies'."
    ↓
Patch Panel decides which AI to use:
    - Question is complex → Use Claude Sonnet (smart AI)
    - User is online → Cloud AI is available
    - Not urgent → Optimize for quality over speed
    ↓
LLM generates response (streaming):
    "Think of photosynthesis like a kitchen for plants.
     The plant uses sunlight as energy, like we use electricity.
     It takes in carbon dioxide (like ingredients) and water,
     and makes food (sugar) for itself. The leftover is oxygen,
     which is what we breathe! Let me show you a diagram..."
    ↓
TTS Service converts text to speech (streaming)
    ↓
AudioEngine plays audio
    ↓
You hear the response through your speaker
    ↓
(At the same time)
VisualAssetView displays the photosynthesis diagram
    ↓
ProgressTracker records:
    - 2 minutes spent on "Photosynthesis basics"
    - Concept "photosynthesis definition" marked as introduced
    ↓
TelemetryEngine records:
    - End-to-end latency: 450ms
    - Cost: $0.0023 (Claude API pricing)
```

2. You interrupt: "Wait, what's carbon dioxide?"

**What happens:**
- VAD detects you started speaking
- SessionManager pauses AI speech immediately
- Process repeats for your new question
- CurriculumEngine notes you need clarification on "carbon dioxide"
- AI provides definition before continuing with photosynthesis

**Step 4: Progress Tracking**

After your 15-minute session:

**On your iPhone:**
- Session history saved (full transcript)
- Progress tracker updated:
  - "Photosynthesis" topic: 15 minutes spent
  - Mastery level: "Introduced" (not yet mastered)
  - Related topics unlocked: "Cellular Respiration"

**On the Management API:**
- Sync progress to server database
- Update analytics:
  - Total learning time: 2 hours 34 minutes
  - Topics studied: 12
  - Sessions completed: 8
  - Average session length: 19 minutes

**Step 5: Later Review**

One week later:
- You open the app
- You go to History
- You see your "Photosynthesis" session
- You tap to review the transcript
- You can replay specific parts of the conversation
- Progress tracker suggests: "Ready to review Photosynthesis?"

---

## Common Scenarios

Let's explore how different use cases work:

### Scenario A: Student Using Only On-Device AI (Free, Private)

**Setup:**
- Download Ministral-3B model (1.7GB) to iPhone
- Use Apple's built-in Speech Recognition (free)
- Use Apple's built-in Text-to-Speech (free)
- No API keys needed
- No internet required after initial download

**Experience:**
- 100% private (nothing leaves your phone)
- Zero ongoing costs
- Works on airplane mode
- Slightly less capable AI (but still very good)
- Slightly slower responses (maybe 800ms instead of 400ms)

**Perfect for:**
- Privacy-conscious users
- Students without budgets
- Remote areas with poor internet
- Anyone wanting to avoid monthly subscriptions

### Scenario B: Professional Using Premium Services (Best Quality)

**Setup:**
- API keys for Claude Sonnet (best LLM)
- API key for ElevenLabs (most natural speech)
- API key for AssemblyAI (best transcription)
- Always online

**Experience:**
- Absolutely best quality responses
- Most natural-sounding voice
- Most accurate transcription
- Fastest response times (~300ms)
- Costs ~$3/hour

**Perfect for:**
- Medical/legal professionals needing accuracy
- Graduate students doing research
- Anyone prioritizing quality over cost

### Scenario C: Power User with Self-Hosted Servers (Best Value)

**Setup:**
- Run Ollama on Mac Mini (free LLM server)
- Run Piper TTS on Raspberry Pi (free voice)
- Run Whisper on GPU server (free transcription)
- One-time setup, zero ongoing costs

**Experience:**
- High quality (between free and premium)
- No API costs
- Full control and customization
- Requires technical setup
- Hardware investment (~$500-2000)

**Perfect for:**
- Tech-savvy users
- Developers and researchers
- Schools and institutions
- Anyone with heavy usage

### Scenario D: Teacher Creating Custom Curriculum

**Setup:**
- Access to UnaMentis Server (port 3000)
- Curriculum Studio editor
- Course materials (PDFs, documents)

**Process:**
1. Open Curriculum Studio in browser
2. Click "Create New Curriculum"
3. Fill in metadata (title, subject, grade level)
4. Create topic structure:
   ```
   Algebra Basics
   ├── Variables and Expressions
   ├── Solving Equations
   │   ├── One-Step Equations
   │   ├── Two-Step Equations
   │   └── Multi-Step Equations
   └── Word Problems
   ```
5. For each topic:
   - Write learning objectives
   - Add lesson content (with spoken variants)
   - Upload diagrams/images
   - Create comprehension questions
   - Add common misconceptions
6. Preview how it sounds with TTS
7. Publish to database
8. Students can now download and learn from it

**Perfect for:**
- Teachers creating custom lessons
- Curriculum designers
- Subject matter experts
- Corporate trainers

---

## Technical Terms Made Simple

Here's a quick reference for terms you'll hear around UnaMentis:

### AI/ML Terms

**LLM (Large Language Model)**
- The "AI brain" that understands and generates text
- Examples: GPT-4, Claude, Llama
- Think of it like an extremely knowledgeable assistant

**STT (Speech-to-Text)**
- Converts your voice to written words
- Like dictation on your phone
- Examples: Whisper, Deepgram, Apple Speech

**TTS (Text-to-Speech)**
- Converts written words to voice
- Like Siri reading text out loud
- Examples: ElevenLabs, Google TTS, Apple TTS

**VAD (Voice Activity Detection)**
- Detects when you're speaking vs. silence
- Prevents the app from listening to background noise
- Like the "push-to-talk" button, but automatic

**Embeddings**
- Converts text into numbers for comparison
- Helps find related topics
- Like a "similarity calculator" for concepts

### Architecture Terms

**API (Application Programming Interface)**
- A way for programs to talk to each other
- Like a menu at a restaurant (lists what's available)
- Example: iPhone app "orders" curriculum from Management API

**Endpoint**
- A specific function available through an API
- Like a specific item on a menu
- Example: GET /curricula is an endpoint

**Port**
- A numbered "door" where a server listens
- Your computer has 65,535 ports
- We use port 3000 and port 8766

**Database**
- Organized storage for data
- Like a super-smart filing cabinet
- We use SQLite

**JSON (JavaScript Object Notation)**
- A format for storing/sharing data
- Like a universal language for programs
- All UMCF files are in JSON format

**Streaming**
- Sending data in real-time as it's generated
- Like live TV vs. watching a downloaded video
- Why responses start immediately

### Performance Terms

**Latency**
- Time delay between action and response
- Like ping-pong: how long until ball returns
- We target <500ms end-to-end

**Throughput**
- How much data can flow per second
- Like water through a pipe
- Measured in tokens/second for LLMs

**Concurrency**
- Doing multiple things at the same time
- Like a chef cooking multiple dishes at once
- Critical for our <500ms target

**Cache**
- Temporary storage for frequent data
- Like keeping your favorite apps open
- Speeds up repeated operations

### Development Terms

**Swift**
- The programming language for iPhone apps
- Created by Apple
- Modern, fast, and safe

**Python**
- Programming language for servers/importers
- Easy to read and write
- Great for data processing

**TypeScript/React**
- Technologies for web interfaces
- TypeScript = JavaScript with types
- React = library for interactive UIs

**Core Data**
- Apple's framework for local database
- Stores data on your iPhone
- Like SQLite but integrated with Swift

**Git**
- Version control system
- Like "track changes" for code
- Lets us collaborate without conflicts

### Curriculum Terms

**UMCF (Una Mentis Curriculum Format)**
- Our special format for voice-optimized lessons
- JSON-based with specific structure
- Designed specifically for AI tutoring

**Topic**
- A unit of learning content
- Can contain other topics (nested)
- Like a chapter in a textbook

**Learning Objective**
- What you'll be able to do after learning
- Uses action verbs (identify, explain, analyze)
- Based on Bloom's Taxonomy

**Prerequisite**
- What you need to know before this topic
- Like needing addition before multiplication
- Ensures proper learning sequence

**Mastery**
- How well you've learned a topic
- Levels: Not Started, Introduced, Practiced, Mastered
- Tracked automatically

---

## Where to Learn More

Now that you understand the basics, here's where to dive deeper:

### For Learning to Use UnaMentis

**Start Here:**
- [QUICKSTART.md](QUICKSTART.md) - Get the app running in 5 minutes
- `docs/SETUP.md` - Detailed environment setup
- `docs/DEBUG_TESTING_UI.md` - Built-in troubleshooting tools

**For Users:**
- `docs/VISUAL_ASSET_SUPPORT.md` - How to use images and diagrams
- `docs/APPLE_INTELLIGENCE.md` - Using Siri commands with UnaMentis
- `docs/GLM_ASR_ON_DEVICE_GUIDE.md` - Setting up on-device speech recognition

### For Understanding the Technology

**Architecture:**
- `docs/PROJECT_OVERVIEW.md` - High-level system design
- `docs/ENTERPRISE_ARCHITECTURE.md` - Detailed technical architecture
- `docs/PATCH_PANEL_ARCHITECTURE.md` - How AI routing works
- `docs/FALLBACK_ARCHITECTURE.md` - How graceful degradation works

**Deep Dive:**
- `docs/UnaMentis_TDD.md` - Complete technical design (44,459 tokens!)
- `docs/IOS_STYLE_GUIDE.md` - Code standards and patterns
- `AGENTS.md` - How we build with AI assistance

### For Creating Content

**Curriculum:**
- `curriculum/README.md` - UMCF overview
- `curriculum/spec/UMCF_SPECIFICATION.md` - Full format specification
- `curriculum/importers/IMPORTER_ARCHITECTURE.md` - How imports work
- `curriculum/importers/AI_ENRICHMENT_PIPELINE.md` - AI enhancement details

**Examples:**
- `curriculum/examples/elementary-math.umcf` - 3rd-4th grade example
- `curriculum/examples/pytorch-fundamentals.umcf` - University-level example
- `curriculum/examples/corporate-security.umcf` - Corporate training example

### For Developers

**Getting Started:**
- `docs/DEV_ENVIRONMENT.md` - Complete development setup
- `docs/TESTING.md` - How to write and run tests
- `docs/IOS_BEST_PRACTICES_REVIEW.md` - iOS platform compliance

**Contributing:**
- `CLAUDE.md` - Instructions for AI agents working on the codebase
- `docs/TASK_STATUS.md` - Current development tasks
- `.claude/rules/writing-style.md` - Writing style guidelines

### For Project Management

**Status:**
- `docs/TASK_STATUS.md` - What's being worked on right now
- `.github/workflows/` - Automated testing and deployment
- GitHub Issues - Bug reports and feature requests

---

## Final Thoughts

UnaMentis is a sophisticated but well-organized system. The key things to remember:

**Three Main Parts:**
1. iPhone App (what you use)
2. Web Servers (what manages content)
3. Curriculum System (the lesson format)

**Core Philosophy:**
- Voice-first (designed for talking, not clicking)
- Privacy-conscious (can run 100% on-device)
- Cost-effective (free options available)
- Educational (follows real curriculum standards)
- AI-powered (built entirely with AI assistance)

**It's Flexible:**
- Works offline or online
- Works free or premium
- Works with any curriculum
- Works for kids or adults
- Works for casual learning or serious study

**Next Steps:**
1. Read [QUICKSTART.md](QUICKSTART.md) to get started
2. Try a sample conversation
3. Explore the curriculum browser
4. Review your progress in analytics
5. Experiment with different AI providers

Welcome to the team! You're now equipped to understand and discuss every aspect of UnaMentis.

---

**Questions?**
- Check the relevant documentation file listed above
- Review the inline code comments (all files have extensive documentation)
- Look at the test files (they show how components work)
- Examine the example UMCF files (they demonstrate the format)

Happy learning! 🎓
