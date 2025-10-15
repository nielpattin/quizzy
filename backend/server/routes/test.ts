import { Hono } from 'hono'

const app = new Hono()

app.get('/homepage/featured', (c) => {
  return c.json([
    {
      id: 'f1',
      title: 'Herbs vs. Weeds: Can You Tell?',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Plants',
      count: 16,
      type: 'session',
    },
    {
      id: 'f2',
      title: 'World History: Ancient Civilizations',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'History',
      count: 24,
      type: 'quiz',
    },
    {
      id: 'f3',
      title: 'Tech Giants Quiz Challenge',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Technology',
      count: 18,
      type: 'session',
    },
  ])
})

app.get('/homepage/topics', (c) => {
  return c.json([
    { id: 't1', label: 'Education', icon: 'school' },
    { id: 't2', label: 'Game', icon: 'games' },
    { id: 't3', label: 'Business', icon: 'business' },
    { id: 't4', label: 'Science', icon: 'science' },
    { id: 't5', label: 'Sports', icon: 'sports' },
    { id: 't6', label: 'Music', icon: 'music' },
    { id: 't7', label: 'Art', icon: 'art' },
    { id: 't8', label: 'History', icon: 'history' },
    { id: 't9', label: 'Geography', icon: 'geography' },
    { id: 't10', label: 'Technology', icon: 'technology' },
  ])
})

app.get('/homepage/trending', (c) => {
  return c.json([
    {
      id: 'tr1',
      title: 'Modern Art or\nJust Scribbles?',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Art',
      count: 16,
      isSessions: false,
    },
    {
      id: 'tr2',
      title: 'Guess the Song\nfrom 3 Words',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Entertainment',
      count: 16,
      isSessions: true,
    },
    {
      id: 'tr3',
      title: 'World Capitals\nChallenge',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Geography',
      count: 20,
      isSessions: false,
    },
  ])
})

app.get('/homepage/continue-playing', (c) => {
  return c.json([
    {
      id: 'cp1',
      title: 'Herbs vs. Weeds: Can You Tell?',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Plants',
      count: 16,
    },
    {
      id: 'cp2',
      title: 'Modern Art or Just Scribbles?',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Art',
      count: 16,
    },
    {
      id: 'cp3',
      title: 'Guess the Song from 3 Words',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Entertainment',
      count: 16,
    },
    {
      id: 'cp4',
      title: 'Famous Entrepreneurs and Their Companies',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Business',
      count: 16,
    },
  ])
})

app.get('/feed', (c) => {
  return c.json([
    {
      id: 'fd1',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Animal',
      question: "What is the surprising real color of a Polar Bear's skin, which helps it absorb heat in the Arctic environment",
      likes: 152,
      comments: 28,
      isAnswered: false,
    },
    {
      id: 'fd2',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Science',
      question: 'Which planet in our solar system rotates on its side, making it unique among all the planets?',
      likes: 203,
      comments: 45,
      isAnswered: true,
    },
    {
      id: 'fd3',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'History',
      question: 'What ancient wonder of the world is the only one still standing today?',
      likes: 178,
      comments: 34,
      isAnswered: false,
    },
    {
      id: 'fd4',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Technology',
      question: 'Which programming language was named after a type of coffee?',
      likes: 289,
      comments: 67,
      isAnswered: true,
    },
    {
      id: 'fd5',
      author: 'Ly Nguyên',
      authorId: 'user123',
      category: 'Geography',
      question: 'What is the only country that spans two continents?',
      likes: 156,
      comments: 41,
      isAnswered: false,
    },
  ])
})

app.get('/library/created', (c) => {
  return c.json([
    {
      id: 'q1',
      title: 'Having Fun & Always Smile!',
      timeAgo: '1d',
      plays: 10,
      questions: 16,
      isPublic: true,
    },
    {
      id: 'q2',
      title: 'Identify the Famous Painting',
      timeAgo: '2d',
      plays: 20,
      questions: 16,
      isPublic: false,
    },
    {
      id: 'q3',
      title: 'Science Facts Everyone Gets Wrong',
      timeAgo: '3d',
      plays: 30,
      questions: 16,
      isPublic: true,
    },
    {
      id: 'q4',
      title: 'Pop Culture Trivia 2024',
      timeAgo: '4d',
      plays: 40,
      questions: 16,
      isPublic: false,
    },
    {
      id: 'q5',
      title: 'Geography Challenge',
      timeAgo: '5d',
      plays: 50,
      questions: 16,
      isPublic: true,
    },
    {
      id: 'q6',
      title: 'Movie Quotes Master',
      timeAgo: '6d',
      plays: 60,
      questions: 16,
      isPublic: false,
    },
    {
      id: 'q7',
      title: 'Music Legends Quiz',
      timeAgo: '7d',
      plays: 70,
      questions: 16,
      isPublic: true,
    },
    {
      id: 'q8',
      title: 'Sports History',
      timeAgo: '8d',
      plays: 80,
      questions: 16,
      isPublic: false,
    },
  ])
})

app.get('/library/saved', (c) => {
  return c.json([
    {
      id: 's1',
      title: 'World Capitals Master',
      timeAgo: '2d',
      plays: 526,
      questions: 20,
      isPublic: null,
    },
    {
      id: 's2',
      title: 'Classic Literature Quiz',
      timeAgo: '3d',
      plays: 1052,
      questions: 20,
      isPublic: null,
    },
    {
      id: 's3',
      title: '90s Movies Trivia',
      timeAgo: '4d',
      plays: 1578,
      questions: 20,
      isPublic: null,
    },
    {
      id: 's4',
      title: 'Ancient Civilizations',
      timeAgo: '5d',
      plays: 893,
      questions: 20,
      isPublic: null,
    },
    {
      id: 's5',
      title: 'Modern Tech Innovations',
      timeAgo: '6d',
      plays: 742,
      questions: 20,
      isPublic: null,
    },
    {
      id: 's6',
      title: 'Food & Cuisine Around the World',
      timeAgo: '7d',
      plays: 431,
      questions: 20,
      isPublic: null,
    },
  ])
})

app.get('/library/collections', (c) => {
  return c.json([
    { id: 'c1', title: 'Tech & Science', quizCount: 24 },
    { id: 'c2', title: 'Entertainment', quizCount: 18 },
    { id: 'c3', title: 'General Knowledge', quizCount: 30 },
    { id: 'c4', title: 'Sports & Games', quizCount: 12 },
    { id: 'c5', title: 'History & Geography', quizCount: 16 },
  ])
})

app.get('/library/solo-plays', (c) => {
  return c.json([
    {
      id: 'sp1',
      title: 'Daily Geography Sprint',
      timeAgo: '1d',
      plays: 234,
      questions: 10,
      isPublic: null,
    },
    {
      id: 'sp2',
      title: 'Quick Space Facts',
      timeAgo: '2d',
      plays: 156,
      questions: 8,
      isPublic: null,
    },
    {
      id: 'sp3',
      title: 'Music Year Match',
      timeAgo: '4d',
      plays: 89,
      questions: 12,
      isPublic: null,
    },
  ])
})

app.get('/library/game-sessions', (c) => {
  return c.json([
    {
      id: 'gs1',
      title: 'World History Marathon: Ancient Civilizations Through Modern Times',
      topic: 'History',
      length: '25 Questions',
      date: '1d',
      isLive: true,
      joined: 142,
    },
    {
      id: 'gs2',
      title: 'Quick Math Challenge',
      topic: 'Mathematics',
      length: '10 Questions',
      date: '2d',
      isLive: false,
      joined: 67,
    },
    {
      id: 'gs3',
      title: 'Ultimate Pop Culture Trivia Night Extravaganza 2024 Edition',
      topic: 'Entertainment',
      length: '30 Questions',
      date: '3d',
      isLive: true,
      joined: 201,
    },
    {
      id: 'gs4',
      title: 'Science Lightning Round',
      topic: 'Science',
      length: '15 Questions',
      date: '5d',
      isLive: false,
      joined: 98,
    },
    {
      id: 'gs5',
      title: 'Geography Masters Championship 2024',
      topic: 'Geography',
      length: '40 Questions',
      date: '7d',
      isLive: false,
      joined: 289,
    },
  ])
})

app.get('/sessions/live', (c) => {
  return c.json([
    {
      id: 'ls1',
      title: 'Tech Trivia Night',
      topic: 'Technology',
      host: 'Ly Nguyên',
      hostId: 'user123',
      length: '20 Questions',
      joined: 45,
      maxPlayers: 100,
      code: 'ABC123',
    },
    {
      id: 'ls2',
      title: 'History Marathon',
      topic: 'History',
      host: 'Ly Nguyên',
      hostId: 'user123',
      length: '30 Questions',
      joined: 78,
      maxPlayers: 150,
      code: 'XYZ789',
    },
    {
      id: 'ls3',
      title: 'Pop Culture Quiz',
      topic: 'Entertainment',
      host: 'Ly Nguyên',
      hostId: 'user123',
      length: '15 Questions',
      joined: 62,
      maxPlayers: 80,
      code: 'POP456',
    },
  ])
})

app.get('/profile/stats', (c) => {
  return c.json({
    followers: 1200,
    following: 342,
    quizzes: 28,
    sessions: 156,
  })
})

app.get('/profile/bio', (c) => {
  return c.json({
    bio: 'Quiz enthusiast 🎯 | Learning through play',
    location: 'Vietnam',
    birthday: 'Jan 15, 2000',
  })
})

app.get('/profile/quizzes', (c) => {
  return c.json([
    {
      id: 'pq1',
      title: 'Modern Art Quiz',
      category: 'Art',
      plays: 127,
    },
    {
      id: 'pq2',
      title: 'Tech Trivia',
      category: 'Technology',
      plays: 254,
    },
    {
      id: 'pq3',
      title: 'Science Facts',
      category: 'Science',
      plays: 381,
    },
    {
      id: 'pq4',
      title: 'Pop Culture',
      category: 'Culture',
      plays: 508,
    },
    {
      id: 'pq5',
      title: 'History Challenge',
      category: 'History',
      plays: 635,
    },
    {
      id: 'pq6',
      title: 'Geography Test',
      category: 'Geography',
      plays: 762,
    },
    {
      id: 'pq7',
      title: 'Movie Quotes',
      category: 'Movies',
      plays: 889,
    },
    {
      id: 'pq8',
      title: 'Music Legends',
      category: 'Music',
      plays: 1016,
    },
    {
      id: 'pq9',
      title: 'Sports Trivia',
      category: 'Sports',
      plays: 1143,
    },
    {
      id: 'pq10',
      title: 'Food & Cooking',
      category: 'Food',
      plays: 1270,
    },
    {
      id: 'pq11',
      title: 'Animals World',
      category: 'Animals',
      plays: 1397,
    },
    {
      id: 'pq12',
      title: 'Space Exploration',
      category: 'Space',
      plays: 1524,
    },
  ])
})

app.get('/profile/sessions', (c) => {
  return c.json([
    {
      id: 'ps1',
      title: 'Tech Trivia Session #1',
      date: '2 days ago',
      score: 850,
      rank: 1,
      totalPlayers: 24,
    },
    {
      id: 'ps2',
      title: 'Tech Trivia Session #2',
      date: '2 days ago',
      score: 1700,
      rank: 2,
      totalPlayers: 24,
    },
    {
      id: 'ps3',
      title: 'Tech Trivia Session #3',
      date: '2 days ago',
      score: 2550,
      rank: 3,
      totalPlayers: 24,
    },
    {
      id: 'ps4',
      title: 'Tech Trivia Session #4',
      date: '2 days ago',
      score: 3400,
      rank: 4,
      totalPlayers: 24,
    },
    {
      id: 'ps5',
      title: 'Tech Trivia Session #5',
      date: '2 days ago',
      score: 4250,
      rank: 5,
      totalPlayers: 24,
    },
    {
      id: 'ps6',
      title: 'Tech Trivia Session #6',
      date: '2 days ago',
      score: 5100,
      rank: 6,
      totalPlayers: 24,
    },
    {
      id: 'ps7',
      title: 'Tech Trivia Session #7',
      date: '2 days ago',
      score: 5950,
      rank: 7,
      totalPlayers: 24,
    },
    {
      id: 'ps8',
      title: 'Tech Trivia Session #8',
      date: '2 days ago',
      score: 6800,
      rank: 8,
      totalPlayers: 24,
    },
  ])
})

app.get('/profile/posts', (c) => {
  return c.json([
    {
      id: 'pp1',
      text: 'Just created a new quiz about modern art! Check it out 🎨',
      likes: 45,
      comments: 12,
      time: '1d ago',
    },
    {
      id: 'pp2',
      text: 'Reached 1K plays on my Tech Trivia quiz! Thanks everyone! 🚀',
      likes: 90,
      comments: 24,
      time: '2d ago',
    },
    {
      id: 'pp3',
      text: 'Working on a new series of science quizzes. Stay tuned! 🔬',
      likes: 135,
      comments: 36,
      time: '3d ago',
    },
    {
      id: 'pp4',
      text: 'Had an amazing quiz session today with 50+ players! 🎯',
      likes: 180,
      comments: 48,
      time: '4d ago',
    },
    {
      id: 'pp5',
      text: 'New collection dropping next week. Get ready! 📚',
      likes: 225,
      comments: 60,
      time: '5d ago',
    },
  ])
})

export default app
