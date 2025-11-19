import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/translated_text.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.onNavigateHome});

  final VoidCallback? onNavigateHome;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  List<int> _userAnswers = [];
  bool _quizCompleted = false;
  int _score = 0;
  bool _showResult = false;

  final List<QuizQuestion> _allQuestions = [
    QuizQuestion(
      question: "What is Flutter?",
      options: ["A mobile app framework", "A database", "A programming language", "A web server"],
      correctAnswer: 0,
      topic: "Flutter Development",
    ),
    QuizQuestion(
      question: "Which programming language is used in Flutter?",
      options: ["Java", "Swift", "Dart", "Kotlin"],
      correctAnswer: 2,
      topic: "Flutter Development",
    ),
    QuizQuestion(
      question: "What is a Widget in Flutter?",
      options: ["A database table", "A UI component", "A network protocol", "A file format"],
      correctAnswer: 1,
      topic: "Flutter Development",
    ),
    QuizQuestion(
      question: "What does HTML stand for?",
      options: ["Hyper Text Markup Language", "High Tech Modern Language", "Home Tool Markup Language", "Hyperlink and Text Markup Language"],
      correctAnswer: 0,
      topic: "Web Development",
    ),
    QuizQuestion(
      question: "Which of the following is a JavaScript framework?",
      options: ["Django", "Laravel", "React", "Flask"],
      correctAnswer: 2,
      topic: "Web Development",
    ),
    QuizQuestion(
      question: "What is CSS used for?",
      options: ["Database management", "Styling web pages", "Server-side programming", "Network security"],
      correctAnswer: 1,
      topic: "Web Development",
    ),
    QuizQuestion(
      question: "What does API stand for?",
      options: ["Application Programming Interface", "Advanced Programming Implementation", "Automated Program Integration", "Application Process Integration"],
      correctAnswer: 0,
      topic: "Programming Concepts",
    ),
    QuizQuestion(
      question: "What is a database?",
      options: ["A collection of programs", "A network protocol", "A structured collection of data", "A type of hardware"],
      correctAnswer: 2,
      topic: "Database Management",
    ),
    QuizQuestion(
      question: "Which of the following is NOT a programming paradigm?",
      options: ["Object-Oriented", "Functional", "Procedural", "Circular"],
      correctAnswer: 3,
      topic: "Programming Concepts",
    ),
    QuizQuestion(
      question: "What is Git used for?",
      options: ["Image editing", "Version control", "Database design", "Network monitoring"],
      correctAnswer: 1,
      topic: "Development Tools",
    ),
    QuizQuestion(
      question: "What is Machine Learning?",
      options: ["A type of computer hardware", "A programming language", "AI technique for learning from data", "A database system"],
      correctAnswer: 2,
      topic: "Artificial Intelligence",
    ),
    QuizQuestion(
      question: "What does UI stand for?",
      options: ["Universal Interface", "User Interface", "Unified Integration", "Ultimate Implementation"],
      correctAnswer: 1,
      topic: "Design",
    ),
    QuizQuestion(
      question: "Which is a NoSQL database?",
      options: ["MySQL", "PostgreSQL", "MongoDB", "SQLite"],
      correctAnswer: 2,
      topic: "Database Management",
    ),
    QuizQuestion(
      question: "What is responsive design?",
      options: ["Fast loading websites", "Design that adapts to different screen sizes", "Interactive animations", "Server optimization"],
      correctAnswer: 1,
      topic: "Web Development",
    ),
    QuizQuestion(
      question: "What is cloud computing?",
      options: ["Weather prediction", "Online data storage and processing", "Graphic design", "Video editing"],
      correctAnswer: 1,
      topic: "Cloud Technology",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startNewQuiz();
  }

  void _startNewQuiz() {
    setState(() {
      _currentQuestions = _getRandomQuestions();
      _currentQuestionIndex = 0;
      _userAnswers = List.filled(10, -1);
      _quizCompleted = false;
      _score = 0;
      _showResult = false;
    });
  }

  List<QuizQuestion> _getRandomQuestions() {
    final shuffled = List<QuizQuestion>.from(_allQuestions);
    shuffled.shuffle();
    return shuffled.take(10).toList();
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _completeQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _completeQuiz() {
    int correctAnswers = 0;
    for (int i = 0; i < _currentQuestions.length; i++) {
      if (_userAnswers[i] == _currentQuestions[i].correctAnswer) {
        correctAnswers++;
      }
    }
    
    setState(() {
      _score = correctAnswers;
      _quizCompleted = true;
      _showResult = true;
    });
  }

  bool get _isPassed => (_score / _currentQuestions.length) >= 0.8;

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _buildResultScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const TranslatedText('Quiz Challenge', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF2E7DFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildQuestionCard(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7DFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TranslatedText(
                'Question ${_currentQuestionIndex + 1} of ${_currentQuestions.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              TranslatedText(
                _currentQuestions[_currentQuestionIndex].topic,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _currentQuestions.length,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final question = _currentQuestions[_currentQuestionIndex];
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              question.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _userAnswers[_currentQuestionIndex] == index;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOptionButton(option, index, isSelected),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7DFF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7DFF) : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF2E7DFF).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : const Color(0xFFE5E7EB),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF2E7DFF) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TranslatedText(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), // Extra bottom padding to avoid FAB
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const TranslatedText('Previous'),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentQuestionIndex > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _userAnswers[_currentQuestionIndex] != -1
                  ? (_currentQuestionIndex == _currentQuestions.length - 1 ? _completeQuiz : _nextQuestion)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: TranslatedText(
                _currentQuestionIndex == _currentQuestions.length - 1 ? 'Finish Quiz' : 'Next Question',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / _currentQuestions.length * 100).round();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                _isPassed ? Icons.celebration : Icons.refresh,
                size: 80,
                color: _isPassed ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 24),
              TranslatedText(
                _isPassed ? 'Congratulations!' : 'Keep Learning!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              TranslatedText(
                _isPassed 
                    ? 'You passed the quiz with flying colors!'
                    : 'You need 80% to pass. Don\'t give up!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const TranslatedText('Score:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('$_score/${_currentQuestions.length}', style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const TranslatedText('Percentage:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('$percentage%', style: TextStyle(
                          fontSize: 18,
                          color: _isPassed ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const TranslatedText('Result:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isPassed ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TranslatedText(
                            _isPassed ? 'PASSED' : 'FAILED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startNewQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const TranslatedText('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (widget.onNavigateHome != null) {
                          widget.onNavigateHome!();
                        } else {
                          // Fallback: just restart the quiz if no navigation callback
                          _startNewQuiz();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const TranslatedText('Back to Home'),
                    ),
                  ),
                  const SizedBox(height: 80), // Extra space to avoid FAB overlap
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String topic;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.topic,
  });
}