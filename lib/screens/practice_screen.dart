import 'dart:io';

import 'package:flutter/material.dart';
import '../models/learner_state.dart';
import '../models/child_profile.dart';
import '../models/recommendation.dart';
import '../models/speech_result.dart';
import '../services/audio_recording_service.dart';
import '../services/vocalnova_app_service.dart';
import '../widgets/child_bottom_nav.dart';
import '../services/teaching_service.dart';


/// Child-facing adaptive speech practice.
///
/// Practice modes:
/// - Sound Adventure -> focuses on target sounds such as s/r.
/// - Word Explorer -> focuses on the child's target words.
/// - Picture Quest -> picture-oriented practice.
///
/// The backend still receives a concrete target word for speech analysis.
/// For Sound Adventure, an example word containing the target sound is used
/// internally while the child-facing UI displays the target sound.
class PracticeScreen extends StatefulWidget {
  final String exerciseName;
  final ChildProfile? child;
  final ValueChanged<PracticeCompletionData>? onSessionCompleted;

  const PracticeScreen({
    super.key,
    required this.exerciseName,
    this.child,
    this.onSessionCompleted,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class PracticeCompletionData {
  final String exerciseName;
  final int durationSeconds;
  final int attempts;
  final int successes;
  final int skips;
  final int difficultyLevel;

  const PracticeCompletionData({
    required this.exerciseName,
    required this.durationSeconds,
    required this.attempts,
    required this.successes,
    required this.skips,
    required this.difficultyLevel,
  });
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  late final String sessionId;
  late final ChildProfile _child;

  final Stopwatch _stopwatch = Stopwatch();
  final VocalNovaAppService _appService = VocalNovaAppService();
  final AudioRecordingService _audioRecorder = AudioRecordingService();
  final TeachingService _teachingService = TeachingService();

  late AnimationController _pulseController;

  int attempts = 0;
  int successes = 0;
  int skipped = 0;
  int difficultyLevel = 2;

  bool completed = false;
  bool isRecording = false;
  bool isAnalyzing = false;

  String? lastFeedback;
  SpeechResult? lastSpeech;
  Recommendation? recommendation;
  LearnerState? learnerState;
  String _currentTarget = 'cat';
  String _currentActivity = 'WORD_REPEAT';
  String _currentTheme = 'GENERAL';
  int _missionItems = 5;

  /// True when the user entered through Sound Adventure.
  bool _isSoundAdventure = false;

  /// True when the user entered through Word Explorer.
  bool _isWordExplorer = false;

  /// True when the user entered through Picture Quest.
  bool _isPictureQuest = false;

  int _interestIndex = 0;
  int _successfulTargetChanges = 0;

  bool _showCelebration = false;
  String _celebrationTitle = '';
  String _celebrationMessage = '';
  IconData _celebrationIcon = Icons.celebration_rounded;

  @override
  void initState() {
    super.initState();
    _teachingService.initialize();

    _child = widget.child ??
        const ChildProfile(
          childId: 'child001',
          displayName: 'Demo Child',
          ageBand: '7',
          interests: ['Dinosaurs', 'Animals', 'Cars'],
          targetSounds: ['s'],
          targetWords: [
            'sun',
            'sock',
            'snake',
          ],
        );

    sessionId =
        '${_child.childId}_${DateTime.now().millisecondsSinceEpoch}';

    _setPracticeMode();

    learnerState = LearnerState(
      childId: _child.childId,
      target: _currentTarget,
      preferredTheme: _child.interests.isNotEmpty
          ? _child.interests.first.toUpperCase()
          : 'GENERAL',
    );

    _loadLearnerState();

    if (_child.interests.isNotEmpty) {
      _currentTheme = _child.interests.first.trim().toUpperCase();
    }

    _stopwatch.start();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.94,
      upperBound: 1.06,
    )..repeat(reverse: true);

    _startBackendSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _speakTeachingModel();
      }
    });
  }

  String _teachingWordForTarget(String target) {
  final sound = target.trim().toLowerCase();

  final matchingWords = _child.targetWords
      .map((word) => word.trim().toLowerCase())
      .where(
        (word) =>
            word.isNotEmpty &&
            word.startsWith(sound),
      )
      .toList();

  if (matchingWords.isNotEmpty) {
    final index = attempts % matchingWords.length;
    return matchingWords[index];
  }

  const examples = {
    's': 'sun',
    'r': 'rabbit',
    'c': 'cat',
    'k': 'cat',
    'b': 'ball',
    'm': 'moon',
    'p': 'pig',
    't': 'top',
    'd': 'dog',
    'f': 'fish',
    'sh': 'ship',
  };

  return examples[sound] ?? sound;
}
String _teachingEmojiForWord(String word) {
  final normalized = word.trim().toLowerCase();

  const pictures = {
    'sun': '☀️',
    'rabbit': '🐰',
    'cat': '🐱',
    'ball': '⚽',
    'moon': '🌙',
    'pig': '🐷',
    'top': '🪀',
    'dog': '🐶',
    'fish': '🐟',
    'sock': '🧦',
    'snake': '🐍',
    'star': '⭐',
    'car': '🚗',
    'cake': '🎂',
    'red': '🔴',
  };

  return pictures[normalized] ?? '🖼️';
}
  void _setPracticeMode() {
    final exercise = widget.exerciseName.toLowerCase();

    _isSoundAdventure = exercise.contains('sound adventure');
    _isWordExplorer = exercise.contains('word explorer');
    _isPictureQuest = exercise.contains('picture quest');

    if (_isSoundAdventure) {
      _currentTarget = _firstTargetSound();
      _currentActivity = 'SOUND_PRACTICE';
      return;
    }

    if (_isWordExplorer) {
      _currentTarget = _firstTargetWord();
      _currentActivity = 'WORD_REPEAT';
      return;
    }

    if (_isPictureQuest) {
      _currentTarget = _firstTargetWord();
      _currentActivity = 'PICTURE_NAMING';
      return;
    }

    _currentTarget = _targetWordFromExercise(widget.exerciseName);
  }

  Future<void> _loadLearnerState() async {
    try {
      final savedState =
          await _appService.getLearnerState(_child.childId);

      if (!mounted || savedState == null) {
        return;
      }

      setState(() {
        learnerState = savedState.copyWith(
          target: _currentTarget,
          preferredTheme: _child.interests.isNotEmpty
              ? _child.interests.first.toUpperCase()
              : savedState.preferredTheme,
        );
      });

      debugPrint(
        'Loaded learner state: '
        'attempts=${savedState.totalAttempts}, '
        'successes=${savedState.successfulAttempts}, '
        'average=${savedState.averageScore.toStringAsFixed(1)}, '
        'engagement=${savedState.engagementScore}',
      );
    } catch (e) {
      debugPrint('Could not load learner state: $e');
    }
  }

  Future<void> _startBackendSession() async {
    try {
      await _appService.startSession(
        childId: _child.childId,
        sessionId: sessionId,
      );
    } catch (e) {
      debugPrint('Backend session start failed: $e');
    }
  }
List<String> _availableTargetSounds() {
  final sounds = <String>{};

  for (final sound in _child.targetSounds) {
    final value = sound.trim().toLowerCase();

    if (value.isNotEmpty) {
      sounds.add(value);
    }
  }

  for (final word in _child.targetWords) {
    final value = word.trim().toLowerCase();

    if (value.isNotEmpty) {
      sounds.add(value[0]);
    }
  }

  if (sounds.isEmpty) {
    sounds.add('s');
  }

  return sounds.toList();
}
  String _firstTargetSound() {
  final sounds = _availableTargetSounds();

  return sounds.first;
}

  String _firstTargetWord() {
    if (_child.targetWords.isNotEmpty) {
      return _child.targetWords.first.trim().toLowerCase();
    }

    final words = _adaptiveWordsForSound();

    return words.isEmpty ? 'sun' : words.first;
  }

  String _targetWordFromExercise(String exercise) {
    final value = exercise.toLowerCase();

    if (value.contains('s" sound') ||
        value.contains('s sound') ||
        value.contains('/s/')) {
      return 'sun';
    }

    if (value.contains('picture') || value.contains('dog')) {
      return 'dog';
    }

    if (value.contains('word practice') ||
        value.contains('cat')) {
      return 'cat';
    }

    return _firstTargetWord();
  }

  /// Returns example words for a target sound.
  ///
  /// The child sees the sound in Sound Adventure, but the speech backend
  /// receives one of these concrete words for analysis.
  List<String> _wordsForSound(String sound) {
    switch (sound.toLowerCase().trim()) {
      case 's':
        return [
          'sun',
          'star',
          'sock',
          'soap',
          'snake',
          'soup',
          'seal',
        ];

      case 'r':
        return [
          'red',
          'rain',
          'rabbit',
          'robot',
          'road',
          'rose',
        ];

      case 'k':
      case 'c':
        return [
          'cat',
          'car',
          'cow',
          'cake',
          'cup',
          'key',
        ];

      case 'sh':
        return [
          'ship',
          'shoe',
          'shark',
          'shell',
          'sheep',
        ];

      default:
        return [
          'sun',
          'star',
          'sock',
          'soap',
        ];
    }
  }

  List<String> _adaptiveWordsForSound() {
    final sound = _child.targetSounds.isNotEmpty
        ? _child.targetSounds.first.toLowerCase().trim()
        : 's';

    return _wordsForSound(sound);
  }

  String _currentAnalysisWord() {
  if (!_isSoundAdventure) {
    return _currentTarget;
  }

  final matchingWords = _child.targetWords
      .map((word) => word.trim().toLowerCase())
      .where(
        (word) =>
            word.isNotEmpty &&
            word.startsWith(
              _currentTarget.toLowerCase(),
            ),
      )
      .toList();

  if (matchingWords.isNotEmpty) {
    final index = attempts % matchingWords.length;
    return matchingWords[index];
  }

  final soundWords =
      _wordsForSound(_currentTarget);

  if (soundWords.isEmpty) {
    return 'sun';
  }

  return soundWords[
      attempts % soundWords.length];
}
  String _nextAdaptiveTarget() {
    if (_isSoundAdventure) {
      return _nextTargetSound();
    }

    if (_isWordExplorer || _isPictureQuest) {
      return _nextTargetWord();
    }

    final words = _adaptiveWordsForSound();

    if (words.isEmpty) {
      return _currentTarget;
    }

    final currentIndex = words.indexOf(_currentTarget);

    if (currentIndex == -1) {
      return words.first;
    }

    return words[(currentIndex + 1) % words.length];
  }

  String _nextTargetSound() {
  final sounds = _availableTargetSounds();

  final currentIndex =
      sounds.indexOf(_currentTarget);

  if (currentIndex == -1) {
    return sounds.first;
  }

  return sounds[
      (currentIndex + 1) % sounds.length];
}

  String _nextTargetWord() {
    final words = _child.targetWords
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return _firstTargetWord();
    }

    final currentIndex = words.indexOf(_currentTarget);

    if (currentIndex == -1) {
      return words.first;
    }

    return words[(currentIndex + 1) % words.length];
  }

  String _nextInterestTheme() {
    final interests = _child.interests
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toList();

    if (interests.isEmpty) {
      return 'GENERAL';
    }

    _interestIndex = (_interestIndex + 1) % interests.length;

    return interests[_interestIndex].toUpperCase();
  }

  String _challengeTextForTheme() {
    final theme = _currentTheme.toLowerCase();

    if (_isSoundAdventure) {
      return 'Make the “$_currentTarget” sound! 🎤';
    }

    if (_isWordExplorer) {
      if (theme.contains('dinosaur')) {
        return '🦖 Help the dinosaur say “$_currentTarget”!';
      }

      if (theme.contains('car')) {
        return '🚗 Start the car with “$_currentTarget”!';
      }

      if (theme.contains('animal')) {
        return '🐾 Help the animal say “$_currentTarget”!';
      }

      if (theme.contains('space')) {
        return '🚀 Launch the rocket with “$_currentTarget”!';
      }

      if (theme.contains('ocean')) {
        return '🌊 Explore the ocean: “$_currentTarget”';
      }

      if (theme.contains('superhero')) {
        return '🦸 Power up with “$_currentTarget”!';
      }
    }

    if (_isPictureQuest) {
      return '🖼️ Look at the picture and say “$_currentTarget”';
    }

    if (theme.contains('dinosaur')) {
      return _currentActivity == 'PHRASE_PRACTICE'
          ? '🦖 Help the dinosaur say “$_currentTarget”!'
          : '🦖 Find the dinosaur: “$_currentTarget”';
    }

    if (theme.contains('car')) {
      return _currentActivity == 'PHRASE_PRACTICE'
          ? '🚗 Start the car with “$_currentTarget”!'
          : '🚗 Start the car: “$_currentTarget”';
    }

    if (theme.contains('animal')) {
      return _currentActivity == 'PHRASE_PRACTICE'
          ? '🐾 Help the animal say “$_currentTarget”!'
          : '🐾 Find the animal: “$_currentTarget”';
    }

    if (theme.contains('space')) {
      return _currentActivity == 'PHRASE_PRACTICE'
          ? '🚀 Launch the rocket with “$_currentTarget”!'
          : '🚀 Launch the rocket: “$_currentTarget”';
    }

    if (theme.contains('ocean')) {
      return '🌊 Explore the ocean: “$_currentTarget”';
    }

    if (theme.contains('superhero')) {
      return '🦸 Power up with “$_currentTarget”!';
    }

    return _currentActivity == 'PHRASE_PRACTICE'
        ? 'Say a phrase with “$_currentTarget”'
        : 'Say “$_currentTarget”';
  }

  String _instructionForTheme() {
    if (_isSoundAdventure) {
      return 'Listen, watch your target sound, and say it clearly. 🎤';
    }

    if (_isWordExplorer) {
      return 'Say the word clearly to continue your adventure. 🌟';
    }

    if (_isPictureQuest) {
      return 'Look carefully, name the picture, and earn a star! ⭐';
    }

    switch (_currentActivity) {
      case 'MODELED_WORD':
        return 'Listen carefully, then try it with me. 👂';

      case 'PHRASE_PRACTICE':
        return 'You mastered the word! Now make it part of a little adventure. ⭐';

      case 'WORD_REPEAT':
      default:
        return 'Say it clearly to continue your adventure. 🎤';
    }
  }

  String _difficultyName() {
    switch (difficultyLevel) {
      case 1:
        return 'EASY';

      case 3:
        return 'HARD';

      default:
        return 'MEDIUM';
    }
  }

  int _difficultyNumber(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 1;

      case 'HARD':
        return 3;

      default:
        return 2;
    }
  }

  String _prettyTheme(String theme) {
    if (theme.isEmpty || theme == 'GENERAL') {
      return 'My Adventure';
    }

    return theme
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _activityTitle() {
    if (_isSoundAdventure) {
      return 'Sound Adventure';
    }

    if (_isWordExplorer) {
      return 'Word Explorer';
    }

    if (_isPictureQuest) {
      return 'Picture Quest';
    }

    switch (_currentActivity) {
      case 'MODELED_WORD':
        return 'Listen & Try';

      case 'PHRASE_PRACTICE':
        return 'Phrase Adventure';

      case 'WORD_REPEAT':
      default:
        return 'Word Adventure';
    }
  }
  String _activityInstruction() {
    return _instructionForTheme();
  }

  String _challengeText() {
    return _challengeTextForTheme();
  }

  IconData _themeIcon() {
    final theme = _currentTheme.toLowerCase();

    if (theme.contains('dinosaur')) {
      return Icons.pets_rounded;
    }

    if (theme.contains('animal')) {
      return Icons.emoji_nature_rounded;
    }

    if (theme.contains('car')) {
      return Icons.directions_car_rounded;
    }

    if (theme.contains('space')) {
      return Icons.rocket_launch_rounded;
    }

    if (theme.contains('ocean')) {
      return Icons.water_rounded;
    }

    if (theme.contains('superhero')) {
      return Icons.auto_awesome_rounded;
    }

    if (_isSoundAdventure) {
      return Icons.record_voice_over_rounded;
    }

    if (_isWordExplorer) {
      return Icons.chat_bubble_rounded;
    }

    if (_isPictureQuest) {
      return Icons.image_rounded;
    }

    return Icons.explore_rounded;
  }

  String _themeMessage() {
    final theme = _prettyTheme(_currentTheme);

    if (_currentTheme == 'GENERAL') {
      return 'Complete your speaking mission!';
    }

    return '$theme mission unlocked! 🚀';
  }

  Future<void> _toggleRecording() async {
    if (completed || isAnalyzing) {
      return;
    }

    if (isRecording) {
      await _finishRecording();
      return;
    }

    final permission = await _audioRecorder.hasPermission();

    if (!permission) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is required.',
          ),
        ),
      );

      return;
    }

    final path =
        '${Directory.systemTemp.path}/vocalnova_'
        '${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _audioRecorder.startRecording(path);

      if (!mounted) return;

      setState(() {
        isRecording = true;
        lastFeedback = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not start recording: $e',
          ),
        ),
      );
    }
  }

  Future<void> _finishRecording() async {
    if (!mounted) return;

    setState(() {
      isRecording = false;
      isAnalyzing = true;
    });

    try {
      final audioFile =
          await _audioRecorder.stopRecording();

      if (audioFile == null) {
        throw Exception(
          'No audio recording was created.',
        );
      }

      final attemptId =
          '${sessionId}_attempt_'
          '${DateTime.now().millisecondsSinceEpoch}';

      final analysisWord = _currentAnalysisWord();

      final result =
          await _appService.analyzeAndAdapt(
        child: _child,
        sessionId: sessionId,
        targetWord: analysisWord,
        attemptId: attemptId,
        audioFile: audioFile,
        currentDifficulty: _difficultyName(),
        learnerState: learnerState!,
      );

      if (!mounted) return;

      final speech = result.speechResult;
      final adaptive = result.recommendation;

      final wasSuccessful =
          speech.feedbackType == 'SUCCESS' ||
          speech.speechScore >= 70;

      final shouldAdvance =
          speech.speechScore >= 80;

      final shouldUnlockPhrase =
          speech.speechScore >= 90;
      final engagementEvents =
    await _appService.getEngagementEvents(
  childId: _child.childId,
  sessionId: sessionId,
);

final engagementScore =
    _appService.calculateEngagementScore(
  engagementEvents,
);

learnerState = learnerState?.addAttempt(
  score: speech.speechScore,
  successful: wasSuccessful,
  engagement: engagementScore.round(),
);

      if (learnerState != null) {
        await _appService.saveLearnerState(
          learnerState!,
        );
      }

      setState(() {
        attempts++;

        if (wasSuccessful) {
          successes++;
        }

        lastSpeech = speech;
        recommendation = adaptive;

        difficultyLevel =
            _difficultyNumber(
          adaptive.difficulty,
        );

        _missionItems =
            adaptive.sessionItems;

        if (shouldAdvance) {
          _successfulTargetChanges++;

          _currentTarget =
              _nextAdaptiveTarget();

          _currentTheme =
              _nextInterestTheme();
        }

        if (_isSoundAdventure) {
          _currentActivity =
              'SOUND_PRACTICE';
        } else if (_isWordExplorer) {
          _currentActivity =
              shouldUnlockPhrase
                  ? 'PHRASE_PRACTICE'
                  : 'WORD_REPEAT';
        } else if (_isPictureQuest) {
          _currentActivity =
              'PICTURE_NAMING';
        } else {
          _currentActivity =
              shouldUnlockPhrase
                  ? 'PHRASE_PRACTICE'
                  : adaptive.nextActivity;
        }

        lastFeedback =
            _buildSpeechFeedback(
          speech,
          adaptive.reason,
        );
      });

      if (shouldAdvance) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _speakTeachingModel();
          }
        });

        _triggerCelebration(
          masteredWord: speech.targetWord,
          nextWord: _isSoundAdventure
              ? _currentAnalysisWord()
              : _currentTarget,
          nextTheme: _currentTheme,
          phraseUnlocked: shouldUnlockPhrase,
        );
      }

      _showResultSheet(
        speech,
        adaptive,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Speech analysis failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  String _buildSpeechFeedback(
    SpeechResult speech,
    String adaptiveReason,
  ) {
    if (speech.error != null &&
        speech.error!.isNotEmpty) {
      return 'Let’s try that one more time! 💜';
    }

    if (speech.feedbackType == 'NO_SPEECH') {
      return 'I didn’t hear your voice. '
          'Try speaking a little louder! 🎤';
    }

    if (speech.speechScore >= 85) {
      return speech.recognizedText.isNotEmpty
          ? 'Amazing! I heard '
              '“${speech.recognizedText}”. 🌟'
          : 'Amazing speaking! 🌟';
    }

    if (speech.speechScore >= 70) {
      return 'Great try! You are ready '
          'for the next challenge. 🚀';
    }

    if (speech.speechScore >= 40) {
      return 'Good effort! Let’s slow it down '
          'and try again. 💪';
    }

    return adaptiveReason.isNotEmpty
        ? 'Nice try! Listen to the model '
            'and give it another go. 💜'
        : 'Nice try! Let’s practice it together. 💜';
  }

  void _triggerCelebration({
    required String masteredWord,
    required String nextWord,
    required String nextTheme,
    required bool phraseUnlocked,
  }) {
    _celebrationTitle = phraseUnlocked
        ? 'Amazing! You unlocked the next level! 🌟'
        : 'Great job! You mastered it! 🎉';

    if (_isSoundAdventure) {
      _celebrationMessage =
          'Great work on the “$masteredWord” sound! \n'
          'Your next sound adventure is '
          '“$nextWord”.';

      _celebrationIcon =
          Icons.record_voice_over_rounded;
    } else {
      _celebrationMessage = phraseUnlocked
          ? '“$masteredWord” was fantastic!\n'
              'Your next adventure is '
              '${_prettyTheme(nextTheme)}.\n'
              'Get ready for “$nextWord”!'
          : 'You did it with “$masteredWord”!\n'
              'Now let’s explore '
              '${_prettyTheme(nextTheme)} '
              'with “$nextWord”!';

      _celebrationIcon = phraseUnlocked
          ? Icons.auto_awesome_rounded
          : Icons.emoji_events_rounded;
    }

    setState(() {
      _showCelebration = true;
    });

    Future.delayed(
      const Duration(milliseconds: 1800),
      () {
        if (!mounted) return;

        setState(() {
          _showCelebration = false;
        });
      },
    );
  }

  Widget _celebrationOverlay() {
    if (!_showCelebration) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showCelebration ? 1 : 0,
          duration: const Duration(
            milliseconds: 250,
          ),
          child: Container(
            color: Colors.black.withAlpha(90),
            alignment: Alignment.center,
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0.75,
                end: 1.0,
              ),
              duration: const Duration(
                milliseconds: 450,
              ),
              curve: Curves.elasticOut,
              builder: (
                context,
                scale,
                child,
              ) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 28,
                ),
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  26,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF7C5CFC,
                      ).withAlpha(70),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '⭐  ✨  🎉  ✨  ⭐',
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CircleAvatar(
                      radius: 38,
                      backgroundColor:
                          const Color(
                        0xFFEDE7FF,
                      ),
                      child: Icon(
                        _celebrationIcon,
                        color: const Color(
                          0xFF7C5CFC,
                        ),
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _celebrationTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _celebrationMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color:
                            Colors.grey.shade700,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResultSheet(
    SpeechResult speech,
    Recommendation adaptive,
  ) {
    final score =
        speech.speechScore.clamp(0, 100).round();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            18,
            24,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
                CircleAvatar(
                  radius: 34,
                  backgroundColor:
                      const Color(0xFFEDE7FF),
                  child: Icon(
                    score >= 70
                        ? Icons.celebration_rounded
                        : Icons.favorite_rounded,
                    color: const Color(0xFF7C5CFC),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  score >= 85
                      ? 'Fantastic! 🌟'
                      : score >= 70
                          ? 'Great job! 🎉'
                          : 'Keep going! 💜',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Speech score: $score%',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (speech.recognizedText
                    .isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'I heard: '
                    '“${speech.recognizedText}”',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFFEDE7FF),
        Color(0xFFF7F3FF),
      ],
    ),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: const Color(0xFFD8CCFF),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF7C5CFC),
          ),
          const SizedBox(width: 8),
          const Text(
            'Adaptive Mission',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        adaptive.nextActivity.replaceAll('_', ' '),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Theme: ${adaptive.theme} • '
        'Difficulty: ${adaptive.difficulty} • '
        '${adaptive.sessionItems} items',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        adaptive.reason,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
      ),
    ],
  ),
),
const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF4F0FF),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _themeIcon(),
                        color:
                            const Color(0xFF7C5CFC),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isSoundAdventure
                              ? 'Next sound: '
                                '“$_currentTarget”'
                              : _currentTarget !=
                                      speech.targetWord
                                  ? 'Next: Say '
                                    '“$_currentTarget” • '
                                    '${_prettyTheme(_currentTheme)}'
                                  : 'Next: '
                                    '${_activityTitle()} • '
                                    '${_prettyTheme(_currentTheme)}',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(
                    sheetContext,
                  ),
                  style:
                      FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(
                      52,
                    ),
                    backgroundColor:
                        const Color(0xFF7C5CFC),
                  ),
                  child: const Text(
                    'Continue Adventure',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _skipExercise() async {
    if (completed ||
        isAnalyzing ||
        isRecording) {
      return;
    }

    setState(() {
      skipped++;

      _currentTarget =
          _nextAdaptiveTarget();

      _currentTheme =
          _nextInterestTheme();

      if (_isSoundAdventure) {
        _currentActivity =
            'SOUND_PRACTICE';
      } else if (_isWordExplorer) {
        _currentActivity =
            'WORD_REPEAT';
      } else if (_isPictureQuest) {
        _currentActivity =
            'PICTURE_NAMING';
      } else {
        _currentActivity =
            'WORD_REPEAT';
      }

      lastFeedback =
          'No problem! Here is a new '
          '${_prettyTheme(_currentTheme)} '
          'challenge. 🌈';
    });

    try {
      await _appService.recordSkip(
        childId: _child.childId,
        sessionId: sessionId,
      );
    } catch (e) {
      debugPrint(
        'Failed to record skip: $e',
      );
    }
  }

  Future<void> _completeSession() async {
    if (completed ||
        attempts == 0 ||
        isRecording ||
        isAnalyzing) {
      return;
    }

    _stopwatch.stop();

    final duration =
        _stopwatch.elapsed.inSeconds;

    try {
      await _appService.completeMission(
        childId: _child.childId,
        sessionId: sessionId,
        durationSec: duration,
      );
    } catch (e) {
      debugPrint(
        'Failed to complete backend session: $e',
      );
    }

    widget.onSessionCompleted?.call(
      PracticeCompletionData(
        exerciseName: _activityTitle(),
        durationSeconds: duration,
        attempts: attempts,
        successes: successes,
        skips: skipped,
        difficultyLevel: difficultyLevel,
      ),
    );

    if (!mounted) return;

    setState(() {
      completed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Practice mission completed! 🎉',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopwatch.stop();

    if (_stopwatch.elapsed.inSeconds > 0 &&
        !completed) {
      _appService.recordPracticeTime(
        childId: _child.childId,
        sessionId: sessionId,
        seconds:
            _stopwatch.elapsed.inSeconds,
      );
    }

    _pulseController.dispose();
    _audioRecorder.dispose();
    _teachingService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final successRate = attempts == 0
        ? 0
        : (successes / attempts * 100).round();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF9F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _activityTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (attempts > 0)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 16,
              ),
              child: Center(
                child: Text(
                  '$successRate%',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF7C5CFC),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                4,
                18,
                28,
              ),
              child: Column(
                children: [
                  _progressHeader(),
                  const SizedBox(height: 14),
                  _interestBanner(),
                  const SizedBox(height: 16),
                  _teachingCard(),
                  const SizedBox(height: 16),
                  _missionCard(),
                  const SizedBox(height: 16),
                  _speechCard(),
                  const SizedBox(height: 16),
                  _statsRow(),
                  if (lastFeedback != null) ...[
                    const SizedBox(height: 14),
                    _feedbackCard(),
                  ],
                  const SizedBox(height: 16),
                  _actions(),
                  const SizedBox(height: 8),
                  _adaptiveHint(),
                ],
              ),
            ),
            _celebrationOverlay(),
          ],
        ),
      ),
      bottomNavigationBar:
          ChildBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;

          if (index == 0) {
            Navigator.pop(context);
            return;
          }

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                index == 2
                    ? 'Progress is coming next! 📊'
                    : 'Profile is coming next! 👤',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _progressHeader() {
    final progress = _missionItems == 0
        ? 0.0
        : (attempts / _missionItems)
            .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF7C5CFC),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Today’s mission',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                '$attempts/$_missionItems',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor:
                  const Color(0xFFEDE7FF),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Color(0xFF7C5CFC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interestBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE7FF),
            Color(0xFFF7EFFF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseController,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Icon(
                _themeIcon(),
                size: 32,
                color:
                    const Color(0xFF7C5CFC),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _themeMessage(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_prettyTheme(_currentTheme)} • '
                  '${_activityTitle()}',
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _teachingTargetWord() {
    if (_isSoundAdventure) {
      return _teachingWordForTarget(_currentTarget);
    }

    return _currentTarget.trim().toLowerCase();
  }

  String _teachingTargetEmoji() {
    return _teachingEmojiForWord(_teachingTargetWord());
  }

  String _teachingMode() {
    if (recommendation == null) {
      return 'FULL MODEL';
    }

    switch (recommendation!.nextActivity) {
      case 'MODELED_WORD':
        return 'FULL MODEL';
      case 'FOCUSED_WORD':
        return 'GUIDED';
      case 'WORD_REPEAT':
      case 'PICTURE_NAMING':
        return 'INDEPENDENT';
      case 'PHRASE_PRACTICE':
        return 'PHRASE PRACTICE';
      default:
        return 'GUIDED';
    }
  }

  String _teachingSentence() {
    final word = _teachingTargetWord();

    if (_isSoundAdventure) {
      return 'Listen to “$word”, then make the “$_currentTarget” sound.';
    }

    if (_isPictureQuest) {
      return 'Look at the picture, listen to the word, then say it.';
    }

    if (_teachingMode() == 'FULL MODEL') {
      return 'Listen carefully, watch the picture, and say it with me.';
    }

    if (_teachingMode() == 'GUIDED') {
      return 'Listen once, look at the picture, then try it yourself.';
    }

    if (_teachingMode() == 'PHRASE PRACTICE') {
      return 'Say the word, then use it in a little phrase.';
    }

    return 'Look at the picture and say the word by yourself.';
  }

  String _spokenSoundCue(String sound) {
  switch (sound.trim().toLowerCase()) {
    case 's':
      return 'Ssss';

    case 'r':
      return 'Rrrr';

    case 'c':
    case 'k':
      return 'Kkk';

    case 'b':
      return 'Bbb';

    case 'm':
      return 'Mmm';

    case 'p':
      return 'Ppp';

    case 't':
      return 'Ttt';

    case 'd':
      return 'Ddd';

    case 'f':
      return 'Fff';

    case 'sh':
      return 'Shhh';

    default:
      return sound;
  }
}

Future<void> _speakTeachingModel() async {
  final word = _teachingTargetWord();
  final mode = _teachingMode();

  try {
    if (mode == 'FULL MODEL') {
      if (_isSoundAdventure) {
        final soundCue = _spokenSoundCue(_currentTarget);

        await _teachingService.speak(
          'Listen carefully. '
          '$word. '
          'The target sound is $soundCue. '
          '$word. '
          'Now say $soundCue with me.',
        );
      } else {
        await _teachingService.speak(
          'Listen carefully. '
          '$word. '
          'Now say $word with me.',
        );
      }

      return;
    }

    if (mode == 'GUIDED') {
      if (_isSoundAdventure) {
        final soundCue = _spokenSoundCue(_currentTarget);

        await _teachingService.speak(
          '$word. '
          'Listen once. '
          'The sound is $soundCue. '
          'Now try it yourself.',
        );
      } else {
        await _teachingService.speak(
          '$word. '
          'Listen once, then try it yourself.',
        );
      }

      return;
    }

    if (mode == 'PHRASE PRACTICE') {
      await _teachingService.speak(
        'Say $word. '
        'Now use $word in a little phrase.',
      );

      return;
    }

    // INDEPENDENT
    await _teachingService.speak(
      'Your turn. '
      'Say $word.',
    );
  } catch (e) {
    debugPrint(
      'Teaching speech failed: $e',
    );
  }
}

  Future<void> _speakTeachingInstruction() async {
  final word = _teachingTargetWord();

  try {
    if (_isSoundAdventure) {
      final soundCue =
          _spokenSoundCue(_currentTarget);

      await _teachingService.speak(
        'Say $soundCue. '
        'Like in $word.',
      );
    } else {
      await _teachingService.speak(
        'Say $word.',
      );
    }
  } catch (e) {
    debugPrint(
      'Teaching instruction failed: $e',
    );
  }
}

  Widget _teachingCard() {
    final word = _teachingTargetWord();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD8CCFF),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CFC).withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF7C5CFC),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Learn first',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _teachingMode(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C5CFC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF7F3FF),
                  Color(0xFFFFF9FF),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Text(
                  _teachingTargetEmoji(),
                  style: const TextStyle(fontSize: 58),
                ),
                const SizedBox(height: 8),
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_isSoundAdventure) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Target sound: “$_currentTarget”',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _teachingSentence(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isAnalyzing || isRecording
                      ? null
                      : _speakTeachingModel,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                  ),
                  label: const Text('Listen'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: const Color(0xFF7C5CFC),
                    side: const BorderSide(
                      color: Color(0xFFD8CCFF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isAnalyzing || isRecording
                      ? null
                      : _speakTeachingInstruction,
                  icon: const Icon(
                    Icons.record_voice_over_rounded,
                  ),
                  label: const Text('Say with me'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0xFF7C5CFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionCard() {
    final displayTarget =
        _isSoundAdventure
            ? _currentTarget
            : _currentTarget;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF7C5CFC),
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF7C5CFC,
            ).withAlpha(45),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _activityTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isSoundAdventure)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.white
                    .withAlpha(30),
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Text(
                '“$displayTarget”',
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            )
          else
            Text(
              _challengeText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          const SizedBox(height: 9),
          Text(
            _activityInstruction(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _speechCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            isAnalyzing
                ? 'Checking your speaking...'
                : isRecording
                    ? 'I’m listening 👂'
                    : 'Ready when you are!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _toggleRecording,
            child: ScaleTransition(
              scale: isRecording
                  ? _pulseController
                  : const AlwaysStoppedAnimation<
                      double>(
                      1,
                    ),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? Colors.redAccent
                      : const Color(
                          0xFF7C5CFC,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording
                              ? Colors.redAccent
                              : const Color(
                                  0xFF7C5CFC,
                                ))
                          .withAlpha(55),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  isAnalyzing
                      ? Icons.hourglass_top_rounded
                      : isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isAnalyzing
                ? 'Analyzing...'
                : isRecording
                    ? 'Tap to stop'
                    : 'Tap the microphone to speak',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final successRate = attempts == 0
        ? 0
        : (successes / attempts * 100)
            .round();

    return Row(
      children: [
        _statCard(
          Icons.mic_rounded,
          '$attempts',
          'Attempts',
        ),
        const SizedBox(width: 10),
        _statCard(
          Icons.star_rounded,
          '$successes',
          'Stars',
        ),
        const SizedBox(width: 10),
        _statCard(
          Icons.local_fire_department_rounded,
          '$successRate%',
          'Score',
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  const Color(0xFF7C5CFC),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackCard() {
    final score =
        lastSpeech?.speechScore.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: score != null &&
                score >= 70
            ? const Color(0xFFEAF8EF)
            : const Color(0xFFF2EEFF),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            score != null &&
                    score >= 70
                ? Icons.check_circle_rounded
                : Icons.auto_awesome_rounded,
            color: score != null &&
                    score >= 70
                ? Colors.green
                : const Color(
                    0xFF7C5CFC,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lastFeedback!,
              style: const TextStyle(
                height: 1.4,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed:
                completed ||
                        isAnalyzing
                    ? null
                    : _toggleRecording,
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  isRecording
                      ? Colors.redAccent
                      : const Color(
                          0xFF7C5CFC,
                        ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
            ),
            icon: Icon(
              isRecording
                  ? Icons.stop_rounded
                  : Icons.mic_rounded,
            ),
            label: Text(
              isAnalyzing
                  ? 'Analyzing...'
                  : isRecording
                      ? 'Stop & Check'
                      : 'Speak',
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child:
                  OutlinedButton.icon(
                onPressed:
                    completed ||
                            isAnalyzing ||
                            isRecording
                        ? null
                        : _skipExercise,
                icon: const Icon(
                  Icons.skip_next_rounded,
                ),
                label: const Text(
                  'Change',
                ),
                style:
                    OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(
                    48,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  OutlinedButton.icon(
                onPressed:
                    completed ||
                            attempts == 0 ||
                            isRecording ||
                            isAnalyzing
                        ? null
                        : _completeSession,
                icon: const Icon(
                  Icons.flag_rounded,
                ),
                label: const Text(
                  'Finish',
                ),
                style:
                    OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(
                    48,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adaptiveHint() {
    return AnimatedSwitcher(
      duration:
          const Duration(milliseconds: 250),
      child: Text(
        recommendation == null
            ? 'Your adventure changes when you are ready. ✨'
            : _successfulTargetChanges == 0
                ? _isSoundAdventure
                    ? 'Adaptive: sound “$_currentTarget” • '
                      '$_missionItems attempts'
                    : 'Adaptive: '
                      '${_prettyTheme(_currentTheme)} • '
                      '$_currentTarget • '
                      '$_missionItems items'
                : _isSoundAdventure
                    ? 'Adaptive: next sound unlocked! ✨'
                    : 'Adaptive: new word + '
                      '${_prettyTheme(_currentTheme)} '
                      'unlocked! ✨',
        key: ValueKey(
          '${_currentActivity}_'
          '${_currentTheme}_'
          '$_missionItems'
          '$_currentTarget',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}