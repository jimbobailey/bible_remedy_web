import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String FEEDBACK_URL = '/.netlify/functions/feedback';

void main() {
  runApp(const CornerstoneApp());
}

class CornerstoneApp extends StatelessWidget {
  const CornerstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8C32);
    const black = Color(0xFF0F0F10);
    const darkGray = Color(0xFF1A1C1F);
    const midGray = Color(0xFF2A2D31);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cornerstone',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: black,
        colorScheme: const ColorScheme.dark(
          primary: orange,
          secondary: orange,
          surface: darkGray,
          background: black,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFFE7E7E7),
            height: 1.55,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFD2D2D2),
            height: 1.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkGray,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFF2D3136), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: midGray,
          hintStyle: const TextStyle(color: Color(0xFF9FA4AA)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF3A3E43)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF3A3E43)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: orange, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
      home: const CornerstoneHomePage(),
    );
  }
}

class CornerstoneHomePage extends StatefulWidget {
  const CornerstoneHomePage({super.key});

  @override
  State<CornerstoneHomePage> createState() => _CornerstoneHomePageState();
}

class _CornerstoneHomePageState extends State<CornerstoneHomePage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _feedbackSubmitting = false;
  CornerstoneResponse? _response;
  ConcernClassification? _lastClassification;

  static const String _introText =
      'Click the speak button or type what’s on your heart. Cornerstone provides a response grounded in biblical truth, Scripture, encouragement, and prayer.';

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSpeak() async {
    setState(() {
      _inputController.clear();
    });

    await Future.delayed(const Duration(milliseconds: 40));

    if (!mounted) return;

    _inputFocusNode.requestFocus();

    final bool isWindowsDesktop =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    final message = isWindowsDesktop
        ? 'Your text box is ready. Press Win + H to start Windows dictation.'
        : 'Your text box is ready. Use your keyboard mic to speak.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E2125),
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }

  Future<void> _handleArmorUp() async {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Type or speak what’s on your heart first.'),
          ),
        );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    final classification = _classifyConcern(input);
    final response = _buildResponse(
      userText: input,
      category: classification.category,
      subcategory: classification.subcategory,
    );

    if (!mounted) return;

    setState(() {
      _lastClassification = classification;
      _response = response;
      _isLoading = false;
    });

    await Future.delayed(const Duration(milliseconds: 120));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 320,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  ConcernClassification _classifyConcern(String text) {
    final t = text.toLowerCase();

    bool hasAny(List<String> words) => words.any(t.contains);

    if (hasAny([
      'alcohol',
      'drink',
      'drinking',
      'drugs',
      'porn',
      'lust',
      'relapse',
      'weed',
      'gambling',
      'nicotine',
      'smoke',
      'addiction',
      'addicted',
      'sober',
      'sobriety',
    ])) {
      if (hasAny(['alcohol', 'drink', 'drinking', 'sober', 'sobriety'])) {
        return const ConcernClassification('addiction', 'alcohol');
      }
      if (hasAny(['porn', 'lust'])) {
        return const ConcernClassification('temptation', 'sexual');
      }
      return const ConcernClassification('addiction', 'general');
    }

    if (hasAny([
      'panic',
      'anxiety',
      'afraid',
      'fear',
      'worried',
      'overthinking',
      'stress',
      'stressed',
      'nervous',
    ])) {
      if (hasAny(['panic', 'panicking', 'attack'])) {
        return const ConcernClassification('anxiety', 'panic');
      }
      if (hasAny(['overthinking', 'racing thoughts'])) {
        return const ConcernClassification('anxiety', 'overthinking');
      }
      return const ConcernClassification('anxiety', 'fear');
    }

    if (hasAny([
      'angry',
      'anger',
      'rage',
      'mad',
      'frustrated',
      'frustration',
      'bitter',
      'bitterness',
      'resent',
      'resentment',
    ])) {
      if (hasAny(['rage', 'furious'])) {
        return const ConcernClassification('anger', 'rage');
      }
      if (hasAny(['bitter', 'bitterness', 'resentment'])) {
        return const ConcernClassification('anger', 'bitterness');
      }
      return const ConcernClassification('anger', 'frustration');
    }

    if (hasAny([
      'grief',
      'grieving',
      'loss',
      'lost',
      'mourning',
      'death',
      'died',
      'regret',
      'miss them',
      'funeral',
    ])) {
      if (hasAny(['regret', 'guilt', 'if only'])) {
        return const ConcernClassification('grief', 'regret');
      }
      return const ConcernClassification('grief', 'loss');
    }

    if (hasAny([
      'lonely',
      'alone',
      'betrayed',
      'betrayal',
      'relationship',
      'marriage',
      'wife',
      'husband',
      'boyfriend',
      'girlfriend',
      'friend',
      'conflict',
      'argue',
      'argument',
      'rejected',
    ])) {
      if (hasAny(['betrayed', 'betrayal', 'cheated', 'cheating'])) {
        return const ConcernClassification('relationships', 'betrayal');
      }
      if (hasAny(['lonely', 'alone', 'rejected'])) {
        return const ConcernClassification('relationships', 'loneliness');
      }
      return const ConcernClassification('relationships', 'conflict');
    }

    if (hasAny([
      'purpose',
      'identity',
      'who am i',
      'calling',
      'doubt',
      'doubting',
      'confused',
      'confusion',
      'worthless',
      'not enough',
    ])) {
      if (hasAny(['doubt', 'doubting'])) {
        return const ConcernClassification('purpose', 'doubt');
      }
      if (hasAny(['identity', 'who am i', 'worthless', 'not enough'])) {
        return const ConcernClassification('purpose', 'identity');
      }
      return const ConcernClassification('purpose', 'calling');
    }

    if (hasAny([
      'tempted',
      'temptation',
      'pulled back',
      'falling back',
      'compromise',
      'sin',
      'urge',
      'desire',
    ])) {
      return const ConcernClassification('temptation', 'general');
    }

    return const ConcernClassification('general', 'general');
  }

  CornerstoneResponse _buildResponse({
    required String userText,
    required String category,
    required String subcategory,
  }) {
    final key = '$category::$subcategory';

    switch (key) {
      case 'addiction::alcohol':
        return const CornerstoneResponse(
          acknowledge:
              'That is serious, and I am glad you said it plainly. When thoughts of alcohol start pulling on you again, that does not mean you have failed. It means this is a battle moment, and battle moments need honesty, distance from the lie, and immediate action.',
          truth:
              'Alcohol will promise relief, but it cannot heal what is hurting underneath. God is not asking you to pretend you are strong. He is calling you to stay awake, tell the truth, and lean on Him right now. A craving is not a command. You do not have to bow to it. The urge may be loud, but the Lord is still greater, still present, and still able to carry you through this exact moment.',
          scripture: [
            '1 Corinthians 10:13 — God is faithful; He will not let you be tempted beyond what you can bear, but with the temptation will also provide the way of escape.',
            '2 Corinthians 12:9 — My grace is sufficient for you, for My strength is made perfect in weakness.',
            'Psalm 46:1 — God is our refuge and strength, a very present help in trouble.',
          ],
          nextStep:
              'Put space between you and the temptation right now. Get away from the drink, text or call one safe person, drink water, step outside, and say out loud: “I will not feed this today.” Then stay with the next right decision for the next ten minutes.',
          prayer:
              'Father, hold me steady right now. Quiet the pull of alcohol and break the lie that it can give me what only You can give. Strengthen my mind, guard my steps, and give me courage for the next right choice. Fill this weak place with Your power, Your peace, and Your presence. In Jesus’ name, amen.',
        );

      case 'anxiety::panic':
        return const CornerstoneResponse(
          acknowledge:
              'What you are feeling is heavy and intense, and panic can make everything feel urgent and unsafe. Even so, you are not abandoned in this moment. The fear may be rising fast, but God has not moved away from you.',
          truth:
              'Panic speaks in alarms, but not every alarm is truth. The Lord remains steady when your body feels unsteady. He is near, He sees you, and He is not confused by your distress. You do not have to solve your whole future right now. You only need to let God meet you in this moment and keep taking one grounded breath and one grounded step.',
          scripture: [
            'Isaiah 41:10 — Fear not, for I am with you; be not dismayed, for I am your God.',
            'Philippians 4:6-7 — Do not be anxious about anything... and the peace of God... will guard your hearts and your minds in Christ Jesus.',
            'Psalm 34:4 — I sought the Lord, and He answered me and delivered me from all my fears.',
          ],
          nextStep:
              'Relax your shoulders, plant both feet on the floor, and take five slow breaths. Name five things you can see. Then say: “God is with me right here.” Do not chase every thought. Let the moment slow down.',
          prayer:
              'Lord, calm my mind and settle my body. Interrupt the spiral of panic and remind me that You are here, You are near, and You are in control. Guard my thoughts, steady my breathing, and anchor me in Your peace. In Jesus’ name, amen.',
        );

      case 'anxiety::overthinking':
        return const CornerstoneResponse(
          acknowledge:
              'Overthinking can wear a person down because it keeps the mind running without rest. It can make small things feel massive and tomorrow feel heavier than today.',
          truth:
              'God did not design you to carry every outcome at once. When your thoughts keep looping, it helps to remember that endless analysis is not the same thing as wisdom. The Lord gives wisdom, peace, and direction, but He does not lead by confusion and mental torment. You can hand the pressure back to Him.',
          scripture: [
            'James 1:5 — If any of you lacks wisdom, let him ask of God.',
            'Isaiah 26:3 — You keep him in perfect peace whose mind is stayed on You.',
            'Matthew 6:34 — Do not worry about tomorrow, for tomorrow will worry about itself.',
          ],
          nextStep:
              'Write down the one issue that is bothering you most. Under it, write two lines only: “What I can do today” and “What I must leave with God.” Keep it simple.',
          prayer:
              'Father, quiet the noise in my mind. Pull me out of endless loops and into clear, grounded trust. Give me wisdom for what is mine to do and peace for what is beyond my control. In Jesus’ name, amen.',
        );

      case 'anger::rage':
        return const CornerstoneResponse(
          acknowledge:
              'Rage can make you feel like you need to release everything at once. That kind of heat is real, and if you ignore it, it can do damage fast.',
          truth:
              'Anger itself is not always sin, but uncontrolled anger can quickly take the wheel. God is able to meet you before your words, reactions, and impulses take over. Strength is not losing control loudly. Strength is bringing your fire under the rule of Christ before it burns what matters.',
          scripture: [
            'Ephesians 4:26 — Be angry and do not sin.',
            'Proverbs 16:32 — Whoever is slow to anger is better than the mighty.',
            'James 1:19-20 — Let every person be quick to hear, slow to speak, slow to anger.',
          ],
          nextStep:
              'Do not answer anybody while you are boiling. Step back, breathe, wash your face, take a short walk, and delay the response. Let your first move be restraint.',
          prayer:
              'Lord, rule over my anger before it rules over me. Help me not to react out of heat, pride, or wounded flesh. Put strength in my spirit, guard my mouth, and teach me self-control. In Jesus’ name, amen.',
        );

      case 'anger::bitterness':
        return const CornerstoneResponse(
          acknowledge:
              'Bitterness usually grows where there has been real hurt. It is not small, and it is not fake. It comes from wounds that keep speaking.',
          truth:
              'The danger of bitterness is that it keeps the offense alive inside you long after the moment has passed. God does not ask you to deny the pain, but He does call you not to let that pain become your master. Healing begins when the wound is brought into His light instead of fed in the dark.',
          scripture: [
            'Hebrews 12:15 — See to it that no root of bitterness springs up and causes trouble.',
            'Ephesians 4:31-32 — Let all bitterness and wrath... be put away from you.',
            'Romans 12:19 — Beloved, never avenge yourselves... leave it to the wrath of God.',
          ],
          nextStep:
              'Name the hurt honestly before God. Do not excuse it, but do not rehearse it all day either. Ask the Lord to start pulling the poison out of the wound.',
          prayer:
              'Father, I do not want to carry this bitterness any longer. You see the wound, the disappointment, and the offense. Start healing what is deep in me and keep this pain from turning my heart hard. In Jesus’ name, amen.',
        );

      case 'grief::loss':
        return const CornerstoneResponse(
          acknowledge:
              'Loss has a way of making the world feel different. Grief can hit in waves, and sometimes the smallest reminder can reopen everything.',
          truth:
              'Grief is not weakness. It is love carrying pain. God does not shame mourning hearts. He draws near to them. Even when you do not have the words, the Lord still understands the sorrow, the silence, and the ache that follows loss.',
          scripture: [
            'Psalm 34:18 — The Lord is near to the brokenhearted.',
            'Matthew 5:4 — Blessed are those who mourn, for they shall be comforted.',
            'John 14:27 — Peace I leave with you; My peace I give to you.',
          ],
          nextStep:
              'Do not force yourself to be okay. Give yourself room to grieve honestly today. Drink water, rest if you can, and talk to one trusted person instead of carrying it alone.',
          prayer:
              'Lord, meet me in this grief. Sit with me in what hurts and hold me in the places that feel empty. Bring comfort where words fail, peace where memories ache, and strength for today. In Jesus’ name, amen.',
        );

      case 'relationships::betrayal':
        return const CornerstoneResponse(
          acknowledge:
              'Betrayal cuts deep because it breaks trust where trust should have been safe. That kind of wound can leave a person shaken, angry, and confused all at once.',
          truth:
              'God sees betrayal clearly. He is not casual about what was done to you. At the same time, He does not want this wound to define your identity or your future. The Lord can protect your heart without hardening it beyond healing.',
          scripture: [
            'Psalm 55:12-14 — It is not an enemy who taunts me... but you, a man, my equal, my companion, my familiar friend.',
            'Romans 8:28 — God works all things together for good for those who love Him.',
            'Psalm 147:3 — He heals the brokenhearted and binds up their wounds.',
          ],
          nextStep:
              'Do not rush to fix the relationship today. Start by getting honest before God about the wound itself. Protect your peace, set needed boundaries, and move slowly.',
          prayer:
              'Father, You see the pain of this betrayal. Guard my heart from collapse, confusion, and hard hatred. Give me wisdom, healing, and clean judgment for what comes next. In Jesus’ name, amen.',
        );

      case 'relationships::loneliness':
        return const CornerstoneResponse(
          acknowledge:
              'Loneliness can be crushing because it makes a person feel unseen even when others are around. That ache is real, and it can get louder in quiet moments.',
          truth:
              'Your value is not measured by who has called, texted, shown up, or stayed. God has not misplaced you. He sees you fully, and He has not left you to walk this season alone. Loneliness is painful, but it is not proof that you are forgotten.',
          scripture: [
            'Deuteronomy 31:6 — He will not leave you or forsake you.',
            'Psalm 27:10 — Though my father and mother forsake me, the Lord will receive me.',
            'Hebrews 13:5 — I will never leave you nor forsake you.',
          ],
          nextStep:
              'Push back against isolation in one practical way today. Reach out to one trusted person, even if it is just a simple message. Do not let loneliness decide your next move.',
          prayer:
              'Lord, meet me in this lonely place. Remind my heart that I am seen, known, and not abandoned. Bring real comfort, real connection, and real strength today. In Jesus’ name, amen.',
        );

      case 'purpose::identity':
        return const CornerstoneResponse(
          acknowledge:
              'When identity gets shaken, everything can start to feel unstable. It is hard to move forward when you are questioning your worth, your place, or who you really are.',
          truth:
              'Your identity is not safely built on feelings, performance, or people’s opinions. In Christ, your identity is rooted deeper than that. God is not trying to figure out your worth. He already settled it in how He sees you and calls you His.',
          scripture: [
            '1 Peter 2:9 — You are a chosen race, a royal priesthood, a holy nation, a people for His own possession.',
            'Psalm 139:14 — I praise You, for I am fearfully and wonderfully made.',
            '2 Corinthians 5:17 — If anyone is in Christ, he is a new creation.',
          ],
          nextStep:
              'Do not speak against yourself all day. Replace one lie with one truth today: “I belong to God, and my worth is not up for vote.”',
          prayer:
              'Father, anchor me in who You say I am. Pull down the lies that have spoken over me and rebuild my thinking with Your truth. Help me stand in an identity that is secure in You. In Jesus’ name, amen.',
        );

      case 'purpose::doubt':
        return const CornerstoneResponse(
          acknowledge:
              'Doubt can feel unsettling because it touches the deepest parts of faith, direction, and trust. It can leave you wondering why clarity feels so far away.',
          truth:
              'Doubt does not automatically disqualify you. It does, however, need to be brought into the light. God is not threatened by your questions. He invites you to bring them honestly and keep walking with Him instead of stepping away from Him.',
          scripture: [
            'Mark 9:24 — I believe; help my unbelief!',
            'Jeremiah 29:13 — You will seek Me and find Me, when you seek Me with all your heart.',
            'Proverbs 3:5-6 — Trust in the Lord with all your heart... and He will make straight your paths.',
          ],
          nextStep:
              'Bring your questions to God plainly instead of hiding them. Keep praying, keep reading, and keep moving toward Him instead of away from Him.',
          prayer:
              'Lord, meet me in my questions and steady me where I feel uncertain. Grow real faith in me, not fake language. Give me clarity, hunger for truth, and the grace to keep seeking You. In Jesus’ name, amen.',
        );

      case 'temptation::sexual':
        return const CornerstoneResponse(
          acknowledge:
              'Sexual temptation can feel intense because it often hits both the body and the mind at the same time. That pull is real, and it needs immediate honesty and immediate boundaries.',
          truth:
              'Temptation grows in secrecy, proximity, and delay. God’s way out is often more practical than dramatic. You do not defeat this by pretending it is weak. You defeat it by treating it like a real threat and obeying quickly. Purity is not passive. It is protected on purpose.',
          scripture: [
            '1 Corinthians 6:18 — Flee from sexual immorality.',
            'Job 31:1 — I have made a covenant with my eyes.',
            'Psalm 119:9 — How can a young man keep his way pure? By guarding it according to Your word.',
          ],
          nextStep:
              'Cut off the access point right now. Close the app, leave the room, put the phone down, and move your body. Do not debate the temptation.',
          prayer:
              'Father, strengthen me against this temptation. Guard my eyes, my thoughts, and my choices. Give me quick obedience, clean desire, and the courage to run from what pulls me away from You. In Jesus’ name, amen.',
        );

      case 'temptation::general':
        return const CornerstoneResponse(
          acknowledge:
              'Temptation often shows up when a person is tired, discouraged, lonely, or restless. It knows how to make compromise sound small and urgent.',
          truth:
              'The enemy wants the moment to feel bigger than the consequence and the urge to feel stronger than obedience. But God always provides a way to stand. You are not powerless just because the pressure is real. You can choose what honors the Lord in this moment.',
          scripture: [
            '1 Corinthians 10:13 — God is faithful... with the temptation He will also provide the way of escape.',
            'Galatians 5:16 — Walk by the Spirit, and you will not gratify the desires of the flesh.',
            'Matthew 26:41 — Watch and pray that you may not enter into temptation.',
          ],
          nextStep:
              'Identify the doorway to the temptation and close it today. Then replace that opening with one better action that supports obedience.',
          prayer:
              'Lord, keep me alert and keep me obedient. Expose the lie in this temptation and strengthen me to choose what is right over what is easy. In Jesus’ name, amen.',
        );

      default:
        return const CornerstoneResponse(
          acknowledge:
              'Thank you for being honest about what is on your heart. Even when things feel tangled, naming the struggle is a strong step, not a weak one.',
          truth:
              'God is not distant from your situation. He sees the weight, the confusion, the emotion, and the need underneath it all. You do not have to carry everything at once. You can bring the real thing to Him and trust Him to meet you there with truth, wisdom, and grace.',
          scripture: [
            'Psalm 55:22 — Cast your burden on the Lord, and He will sustain you.',
            'Matthew 11:28 — Come to Me, all who labor and are heavy laden, and I will give you rest.',
            'Psalm 61:2 — When my heart is faint, lead me to the rock that is higher than I.',
          ],
          nextStep:
              'Slow down long enough to be honest with God about the real issue underneath the pressure. Keep it plain and simple. Start there.',
          prayer:
              'Father, You know exactly what I need right now. Meet me with truth, peace, wisdom, and strength. Help me not to run from You, but toward You. In Jesus’ name, amen.',
        );
    }
  }

  Future<void> _sendNotHelpful(CornerstoneResponse response) async {
    setState(() {
      _feedbackSubmitting = true;
    });

    try {
      final payload = {
        'helpful': 'false',
        'user_input': _inputController.text.trim(),
        'acknowledge': response.acknowledge,
        'truth': response.truth,
        'scripture': response.scripture,
        'next_step': response.nextStep,
        'prayer': response.prayer,
        'category': _lastClassification?.category ?? 'general',
        'subcategory': _lastClassification?.subcategory ?? 'general',
        'platform': kIsWeb ? 'web' : 'desktop',
      };

      final result = await http.post(
        Uri.parse(FEEDBACK_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (result.statusCode >= 200 && result.statusCode < 300) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Feedback captured'),
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Feedback failed: ${result.statusCode}'),
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Feedback error: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _feedbackSubmitting = false;
        });
      }
    }
  }

  void _markHelpful() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Thanks for the feedback'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8C32);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildInputCard(),
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const _LoadingCard()
                  else if (_response != null)
                    _buildResponseCard(_response!)
                  else
                    _buildIdleCard(),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Cornerstone',
                      style: TextStyle(
                        color: orange.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool narrow = constraints.maxWidth < 700;

        if (narrow) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF121315),
                  Color(0xFF181B1F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF2D3136),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cornerstone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _introText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 14.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF121315),
                Color(0xFF181B1F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF2D3136),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cornerstone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _introText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputCard() {
    const orange = Color(0xFFFF8C32);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What’s on your heart?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Speak or type freely. Categories stay hidden and are used internally only.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 13.4,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              maxLines: 6,
              minLines: 5,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Type here or press Speak and use your mic...',
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool narrow = constraints.maxWidth < 560;

                if (narrow) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _handleSpeak,
                          icon: const Icon(
                            Icons.mic_rounded,
                            color: Color(0xFFFF8C32),
                          ),
                          label: const Text(
                            'Speak',
                            style: TextStyle(
                              color: Color(0xFFFF8C32),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: orange.withOpacity(0.60)),
                            backgroundColor: const Color(0xFF20242A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleArmorUp,
                          icon: const Icon(
                            Icons.shield_rounded,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Armor Up',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: orange,
                            disabledForegroundColor: Colors.black54,
                            disabledBackgroundColor: orange.withOpacity(0.45),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _handleSpeak,
                          icon: const Icon(
                            Icons.mic_rounded,
                            color: Color(0xFFFF8C32),
                          ),
                          label: const Text(
                            'Speak',
                            style: TextStyle(
                              color: Color(0xFFFF8C32),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: orange.withOpacity(0.60)),
                            backgroundColor: const Color(0xFF20242A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleArmorUp,
                          icon: const Icon(
                            Icons.shield_rounded,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Armor Up',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: orange,
                            disabledForegroundColor: Colors.black54,
                            disabledBackgroundColor: orange.withOpacity(0.45),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF20242A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF30353B)),
              ),
              child: Text(
                'Your response will appear here in this exact order:\n\n'
                'acknowledge → truth → scripture → next step → prayer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard(CornerstoneResponse response) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _ResponseSection(
              icon: Icons.favorite_outline_rounded,
              title: 'Acknowledge',
              content: response.acknowledge,
            ),
            const SizedBox(height: 12),
            _ResponseSection(
              icon: Icons.gpp_good_outlined,
              title: 'Truth',
              content: response.truth,
            ),
            const SizedBox(height: 12),
            _ScriptureSection(scriptures: response.scripture),
            const SizedBox(height: 12),
            _ResponseSection(
              icon: Icons.directions_walk_rounded,
              title: 'Next Step',
              content: response.nextStep,
            ),
            const SizedBox(height: 12),
            _ResponseSection(
              icon: Icons.volunteer_activism_outlined,
              title: 'Prayer',
              content: response.prayer,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF20242A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF30353B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Was this helpful?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool narrow = constraints.maxWidth < 560;

                      if (narrow) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _markHelpful,
                                icon: const Icon(
                                  Icons.thumb_up_alt_outlined,
                                  color: Color(0xFFFF8C32),
                                ),
                                label: const Text(
                                  'Helpful',
                                  style: TextStyle(
                                    color: Color(0xFFFF8C32),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFFF8C32),
                                  ),
                                  backgroundColor: const Color(0xFF20242A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _feedbackSubmitting
                                    ? null
                                    : () => _sendNotHelpful(response),
                                icon: _feedbackSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.thumb_down_alt_outlined,
                                        color: Colors.black,
                                      ),
                                label: Text(
                                  _feedbackSubmitting
                                      ? 'Sending...'
                                      : 'Not Helpful',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: const Color(0xFFFF8C32),
                                  disabledForegroundColor: Colors.black54,
                                  disabledBackgroundColor:
                                      const Color(0x99FF8C32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _markHelpful,
                                icon: const Icon(
                                  Icons.thumb_up_alt_outlined,
                                  color: Color(0xFFFF8C32),
                                ),
                                label: const Text(
                                  'Helpful',
                                  style: TextStyle(
                                    color: Color(0xFFFF8C32),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFFF8C32),
                                  ),
                                  backgroundColor: const Color(0xFF20242A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _feedbackSubmitting
                                    ? null
                                    : () => _sendNotHelpful(response),
                                icon: _feedbackSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.thumb_down_alt_outlined,
                                        color: Colors.black,
                                      ),
                                label: Text(
                                  _feedbackSubmitting
                                      ? 'Sending...'
                                      : 'Not Helpful',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: const Color(0xFFFF8C32),
                                  disabledForegroundColor: Colors.black54,
                                  disabledBackgroundColor:
                                      const Color(0x99FF8C32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        child: Column(
          children: const [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            SizedBox(height: 14),
            Text(
              'Building your response...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _ResponseSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8C32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF20242A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30353B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: orange, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFE5E5E5),
              fontSize: 14.7,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScriptureSection extends StatelessWidget {
  final List<String> scriptures;

  const _ScriptureSection({required this.scriptures});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8C32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF20242A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30353B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: orange, size: 18),
              SizedBox(width: 8),
              Text(
                'Scripture',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...scriptures.map(
            (verse) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      verse,
                      style: const TextStyle(
                        color: Color(0xFFE5E5E5),
                        fontSize: 14.7,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConcernClassification {
  final String category;
  final String subcategory;

  const ConcernClassification(this.category, this.subcategory);
}

class CornerstoneResponse {
  final String acknowledge;
  final String truth;
  final List<String> scripture;
  final String nextStep;
  final String prayer;

  const CornerstoneResponse({
    required this.acknowledge,
    required this.truth,
    required this.scripture,
    required this.nextStep,
    required this.prayer,
  });
}