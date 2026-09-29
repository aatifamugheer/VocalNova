import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'parent_home_screen.dart';

class CreateChildProfileScreen extends StatefulWidget {
  const CreateChildProfileScreen({super.key});

  @override
  State<CreateChildProfileScreen> createState() =>
      _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState
    extends State<CreateChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _therapistCodeController = TextEditingController();

  bool _withTherapist = false;
  bool _saving = false;

  bool _addingCustomTargetWord = false;
  bool _addingCustomInterest = false;

  final _customTargetWordController = TextEditingController();
  final _customInterestController = TextEditingController();

  final List<String> _targetWords = [
  'sun',
  'sock',
  'snake',
  'star',
  'rabbit',
  'red',
  'cat',
  'car',
  'cake',
];

final List<String> _interests = [
  'Dinosaurs',
  'Animals',
  'Cars',
  'Space',
  'Superheroes',
  'Ocean',
];

final Set<String> _selectedTargetWords = {};
final Set<String> _selectedInterests = {};

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _therapistCodeController.dispose();
    _customTargetWordController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  Future<void> _saveChildProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInterests.isEmpty) {
      _showMessage('Please choose at least one interest.');
      return;
    }

   if (_selectedTargetWords.isEmpty) {
  _showMessage('Please choose at least one target word.');
  return;
}

    if (_withTherapist &&
        _therapistCodeController.text.trim().isEmpty) {
      _showMessage('Please enter the therapist code.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Your session has expired. Please log in again.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final childRef =
          FirebaseFirestore.instance.collection('children').doc();

      String? therapistId;

      if (_withTherapist) {
        final therapistCode =
            _therapistCodeController.text.trim().toUpperCase();

        final therapistQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'therapist')
            .where('therapistCode', isEqualTo: therapistCode)
            .limit(1)
            .get();

        if (therapistQuery.docs.isEmpty) {
          if (mounted) {
            setState(() {
              _saving = false;
            });
            _showMessage(
              'Therapist code not found. Please check the code.',
            );
          }
          return;
        }

        therapistId = therapistQuery.docs.first.id;
      }

      await childRef.set({
        'childId': childRef.id,
        'parentId': user.uid,
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'targetWords': _selectedTargetWords
        .map((word) => word.toLowerCase())
        .toList(),
        'interests': _selectedInterests
            .map((interest) => interest.toLowerCase())
            .toList(),
        'practiceMode':
            _withTherapist ? 'therapist' : 'home',
        'therapistId': therapistId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const _ProfileCreatedScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Could not create the child profile. Please try again.',
      );
    }
  }
void _addCustomTargetWord() {
    setState(() {
      _addingCustomTargetWord = true;
    });
  }

  void _saveCustomTargetWord() {
    final word = _customTargetWordController.text.trim().toLowerCase();

    if (word.isEmpty) return;

    if (_targetWords.contains(word)) {
      _showMessage('That target word is already in the list.');
      return;
    }

    setState(() {
      _targetWords.add(word);
      _selectedTargetWords.add(word);
      _customTargetWordController.clear();
      _addingCustomTargetWord = false;
    });
  }

  void _cancelCustomTargetWord() {
    setState(() {
      _customTargetWordController.clear();
      _addingCustomTargetWord = false;
    });
  }

  void _addCustomInterest() {
    setState(() {
      _addingCustomInterest = true;
    });
  }

  void _saveCustomInterest() {
    final interest = _customInterestController.text.trim();

    if (interest.isEmpty) return;

    final exists = _interests.any(
      (item) => item.toLowerCase() == interest.toLowerCase(),
    );

    if (exists) {
      _showMessage('That interest is already in the list.');
      return;
    }

    setState(() {
      _interests.add(interest);
      _selectedInterests.add(interest);
      _customInterestController.clear();
      _addingCustomInterest = false;
    });
  }

  void _cancelCustomInterest() {
    setState(() {
      _customInterestController.clear();
      _addingCustomInterest = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Child Profile',
          style: TextStyle(
            color: Color(0xFF25213B),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF25213B),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildChildDetailsCard(),
              const SizedBox(height: 16),
              _buildTargetWordsCard(),
              const SizedBox(height: 16),
              _buildInterestsCard(),
              const SizedBox(height: 16),
              _buildPracticeModeCard(),
              const SizedBox(height: 28),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7657F4),
            Color(0xFF9B7BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.child_care_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let’s meet your little speaker!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tell us a little about your child so VocalNova can personalize practice.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildDetailsCard() {
    return _sectionCard(
      title: 'Child details',
      icon: Icons.face_rounded,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              'Child name',
              Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter the child’s name';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              'Age',
              Icons.cake_outlined,
            ),
            validator: (value) {
              final age = int.tryParse(value ?? '');

              if (age == null || age < 2 || age > 18) {
                return 'Enter an age between 2 and 18';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

 Widget _buildTargetWordsCard() {
  return _sectionCard(
    title: 'Target words',
    icon: Icons.record_voice_over_rounded,
    subtitle:
        'Choose as many words as your child needs to practice.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._targetWords.map((word) {
              final selected =
                  _selectedTargetWords.contains(word);

              return FilterChip(
                label: Text(
                  word,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF7657F4)
                        : const Color(0xFF4D4668),
                  ),
                ),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedTargetWords.add(word);
                    } else {
                      _selectedTargetWords.remove(word);
                    }
                  });
                },
                selectedColor: const Color(0xFFE7DEFF),
                backgroundColor: const Color(0xFFF5F2FC),
                checkmarkColor: const Color(0xFF7657F4),
                side: BorderSide.none,
              );
            }),

            ActionChip(
              avatar: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text('Add custom word'),
              onPressed: _addCustomTargetWord,
            ),
          ],
        ),

        if (_addingCustomTargetWord) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTargetWordController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'New target word',
                    hintText: 'Example: sky',
                    filled: true,
                    fillColor: const Color(0xFFF7F5FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _saveCustomTargetWord(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add word',
                onPressed: _saveCustomTargetWord,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF7657F4),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_rounded),
              ),
              IconButton(
                tooltip: 'Cancel',
                onPressed: _cancelCustomTargetWord,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],

        if (_selectedTargetWords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_selectedTargetWords.length} words selected',
            style: const TextStyle(
              color: Color(0xFF7657F4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    ),
  );
}

 Widget _buildInterestsCard() {
  return _sectionCard(
    title: 'Things your child loves',
    icon: Icons.favorite_rounded,
    subtitle:
        'Choose as many interests as you want. They personalize missions.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._interests.map((interest) {
              final selected =
                  _selectedInterests.contains(interest);

              return FilterChip(
                label: Text(interest),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                selectedColor: const Color(0xFFE7DEFF),
                backgroundColor: const Color(0xFFF5F2FC),
                checkmarkColor: const Color(0xFF7657F4),
                side: BorderSide.none,
              );
            }),

            ActionChip(
              avatar: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text('Add custom interest'),
              onPressed: _addCustomInterest,
            ),
          ],
        ),

        if (_addingCustomInterest) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customInterestController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'New interest',
                    hintText: 'Example: Football',
                    filled: true,
                    fillColor: const Color(0xFFF7F5FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _saveCustomInterest(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add interest',
                onPressed: _saveCustomInterest,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF7657F4),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_rounded),
              ),
              IconButton(
                tooltip: 'Cancel',
                onPressed: _cancelCustomInterest,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],

        if (_selectedInterests.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_selectedInterests.length} interests selected',
            style: const TextStyle(
              color: Color(0xFF7657F4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _buildPracticeModeCard() {
    return _sectionCard(
      title: 'Practice mode',
      icon: Icons.groups_rounded,
      child: Column(
        children: [
          _modeTile(
            icon: Icons.home_rounded,
            title: 'Practice at home',
            subtitle:
                'Your child can practice with a parent or guardian.',
            selected: !_withTherapist,
            onTap: () {
              setState(() {
                _withTherapist = false;
              });
            },
          ),
          const SizedBox(height: 10),
          _modeTile(
            icon: Icons.medical_services_rounded,
            title: 'With a therapist',
            subtitle:
                'Connect your child to a therapist using their code.',
            selected: _withTherapist,
            onTap: () {
              setState(() {
                _withTherapist = true;
              });
            },
          ),
          if (_withTherapist) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _therapistCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration(
                'Therapist code',
                Icons.vpn_key_outlined,
              ).copyWith(
                hintText: 'Example: VN-7K4P92',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEDE7FF)
              : const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF7657F4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected
                  ? const Color(0xFF7657F4)
                  : const Color(0xFFE7E2F4),
              child: Icon(
                icon,
                color: selected
                    ? Colors.white
                    : const Color(0xFF665D7F),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF29243E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF77708D),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? const Color(0xFF7657F4)
                  : const Color(0xFFAAA4BC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveChildProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7657F4),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBDB5DA),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _saving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Child Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF7657F4),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF29243E),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF77708D),
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F5FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF7657F4),
          width: 1.5,
        ),
      ),
    );
  }
}

class _ProfileCreatedScreen extends StatelessWidget {
  const _ProfileCreatedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8E1FF),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 65,
                    color: Color(0xFF7657F4),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Profile created! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF29243E),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your child is ready to begin personalized VocalNova practice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF77708D),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const ParentHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7657F4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Continue to VocalNova',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
