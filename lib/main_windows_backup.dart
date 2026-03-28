import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';

void main() {
  runApp(const CornerstoneApp());
}

class CornerstoneApp extends StatelessWidget {
  const CornerstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cornerstone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFFFF7A00),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF7A00),
          secondary: Color(0xFFFF7A00),
          surface: Color(0xFF121212),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 2),
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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  bool _isLaunchingDictation = false;
  Map<String, dynamic>? response;

  final Random _random = Random();
  final Map<String, int> _rotation = {};

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll("’", "'")
        .replaceAll("‘", "'")
        .replaceAll("“", '"')
        .replaceAll("”", '"')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _hasAny(String text, List<String> phrases) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) return true;
    }
    return false;
  }

  Future<void> _startWindowsDictation() async {
    if (!Platform.isWindows) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This Speak button is set up for Windows only.'),
        ),
      );
      return;
    }

    setState(() {
      _isLaunchingDictation = true;
    });

    try {
      _textFocusNode.requestFocus();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );

      await Future.delayed(const Duration(milliseconds: 250));
      _sendWinH();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Windows dictation launched. Start speaking.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch Windows dictation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingDictation = false;
        });
      }
    }
  }

  void _sendWinH() {
    const int hKey = 0x48;
    final inputs = calloc<INPUT>(4);

    try {
      inputs[0].type = INPUT_KEYBOARD;
      inputs[0].ki.wVk = VK_LWIN;

      inputs[1].type = INPUT_KEYBOARD;
      inputs[1].ki.wVk = hKey;

      inputs[2].type = INPUT_KEYBOARD;
      inputs[2].ki.wVk = hKey;
      inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;

      inputs[3].type = INPUT_KEYBOARD;
      inputs[3].ki.wVk = VK_LWIN;
      inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;

      SendInput(4, inputs, sizeOf<INPUT>());
    } finally {
      calloc.free(inputs);
    }
  }

  String detectSubcategory(String input) {
    final t = _normalize(input);

    // ADDICTION
    if (_hasAny(t, [
      'i relapsed',
      'i drank again',
      'i used again',
      'i went back to drinking',
      'i went back to using',
      'i messed up and drank',
      'i messed up and used',
      'i slipped and drank',
    ])) {
      return 'addiction_active_relapse';
    }

    if (_hasAny(t, [
      'i feel ashamed i relapsed',
      'i am ashamed i relapsed',
      'im ashamed i relapsed',
      'i feel dirty after relapsing',
      'i feel disgusting after drinking',
      'i hate that i drank',
      'i hate that i used',
      'i feel filthy after relapsing',
      'i used again and now i feel ashamed',
    ])) {
      return 'addiction_shame_after_using';
    }

    if (_hasAny(t, [
      'craving alcohol',
      'craving a drink',
      'the cravings are strong',
      'these cravings are strong',
      'i want a drink so bad',
      'i want to use so bad',
      'the craving is strong',
      'cravings are strong',
    ])) {
      return 'addiction_cravings';
    }

    if (_hasAny(t, [
      'i do not want to go back',
      'i dont want to go back',
      'i am scared i will go back',
      'im scared i will go back',
      'i am afraid i will relapse',
      'im afraid i will relapse',
      'i do not want my old life back',
      'i dont want my old life back',
      'i am scared i am going to go back',
      "i'm scared i'm going to go back",
    ])) {
      return 'addiction_fear_of_returning';
    }

    if (_hasAny(t, [
      'quit drinking',
      'stopped drinking',
      'thinking about alcohol again',
      'thinking about drinking again',
      'thinking about alcohol',
      'thinking about drinking',
      'starting to think about alcohol again',
      'part of me wants to drink',
      'my mind is going back there',
      'miss drinking',
      'want to go back to the bottle',
    ])) {
      return 'addiction_relapse_thoughts';
    }

    // GRIEF
    if (_hasAny(t, [
      'my dog died',
      'my cat died',
      'my pet died',
      'i lost my dog',
      'i lost my cat',
      'i lost my pet',
      'had to put my dog down',
      'had to put my cat down',
      'had to put my pet down',
    ])) {
      return 'grief_loss_of_pet';
    }

    if (_hasAny(t, [
      'my mom died',
      'my mother died',
      'my dad died',
      'my father died',
      'my wife died',
      'my husband died',
      'my son died',
      'my daughter died',
      'my brother died',
      'my sister died',
      'my grandma died',
      'my grandpa died',
      'i lost my mom',
      'i lost my mother',
      'i lost my dad',
      'i lost my father',
      'i lost my wife',
      'i lost my husband',
      'i lost my son',
      'i lost my daughter',
      'i lost my brother',
      'i lost my sister',
      'i lost a loved one',
      'someone close to me died',
    ])) {
      return 'grief_loss_of_loved_one';
    }

    if (_hasAny(t, [
      'just died',
      'just passed away',
      'it just happened',
      'today i lost',
      'this week i lost',
      'fresh loss',
      'just lost',
    ])) {
      return 'grief_fresh_loss';
    }

    if (_hasAny(t, [
      'their birthday is coming up',
      'the anniversary is coming up',
      'today is the anniversary',
      'this time of year is hard',
      'anniversary of their death',
    ])) {
      return 'grief_anniversary_grief';
    }

    if (_hasAny(t, [
      'i wish i had said more',
      'i wish i had done more',
      'i regret how things ended',
      'i did not get to say goodbye',
      'i didnt get to say goodbye',
      'i should have been there',
    ])) {
      return 'grief_with_regret';
    }

    // ANXIETY
    if (_hasAny(t, [
      'i am panicking',
      'im panicking',
      'i feel panicked',
      'my mind is spiraling',
      'i am spiraling',
      'im spiraling',
      'worst case scenario',
      'i cannot calm down',
      'i cant calm down',
      'my chest is tight',
    ])) {
      return 'anxiety_panic_spiral';
    }

    if (_hasAny(t, [
      'i cannot sleep',
      'i cant sleep',
      'i am up all night worrying',
      'im up all night worrying',
      'my mind races at night',
      'sleepless worry',
    ])) {
      return 'anxiety_sleepless_worry';
    }

    if (_hasAny(t, [
      'i am scared about the future',
      'im scared about the future',
      'i am afraid of what comes next',
      'im afraid of what comes next',
      'fear of the future',
      'i do not know what is coming',
      'i dont know what is coming',
    ])) {
      return 'anxiety_future_fear';
    }

    if (_hasAny(t, [
      'i am scared about my health',
      'im scared about my health',
      'i think something is wrong with me',
      'i am worried about my test results',
      'im worried about my test results',
      'health anxiety',
    ])) {
      return 'anxiety_health_anxiety';
    }

    if (_hasAny(t, [
      'i am scared about money',
      'im scared about money',
      'i do not know how i will pay',
      'i dont know how i will pay',
      'i am worried about bills',
      'im worried about bills',
      'money is tight',
      'financial fear',
      'financial anxiety',
    ])) {
      return 'anxiety_financial_anxiety';
    }

    // ANGER
    if (_hasAny(t, [
      'i am angry at them',
      'im angry at them',
      'they made me so mad',
      'i am furious with them',
      'im furious with them',
      'anger at a person',
    ])) {
      return 'anger_at_person';
    }

    if (_hasAny(t, [
      'they betrayed me',
      'i feel betrayed',
      'they stabbed me in the back',
      'they broke my trust',
      'cheated on me',
      'betrayal',
    ])) {
      return 'anger_betrayal';
    }

    if (_hasAny(t, [
      'i still resent them',
      'resentment',
      'i am holding onto this',
      'im holding onto this',
      'i cannot let this go',
      'i cant let this go',
    ])) {
      return 'anger_resentment';
    }

    if (_hasAny(t, [
      'i am mad at myself',
      'im mad at myself',
      'i am angry at myself',
      'im angry at myself',
      'i hate myself for this',
    ])) {
      return 'anger_at_self';
    }

    if (_hasAny(t, [
      'i am angry at god',
      'im angry at god',
      'i am mad at god',
      'im mad at god',
    ])) {
      return 'anger_at_god';
    }

    // LONELINESS
    if (_hasAny(t, [
      'i feel unseen',
      'nobody sees me',
      'no one sees me',
      'i feel invisible',
      'feeling unseen',
    ])) {
      return 'loneliness_feeling_unseen';
    }

    if (_hasAny(t, [
      'i feel isolated',
      'i am isolated',
      'im isolated',
      'i feel alone',
      'i am alone',
      'im alone',
      'isolation',
    ])) {
      return 'loneliness_isolation';
    }

    if (_hasAny(t, [
      'everyone left',
      'i feel abandoned',
      'they left me alone',
      'abandonment',
    ])) {
      return 'loneliness_abandonment';
    }

    if (_hasAny(t, [
      'after the breakup i feel empty',
      'the breakup left me lonely',
      'i miss them after the breakup',
      'lonely after breakup',
      'breakup loneliness',
    ])) {
      return 'loneliness_after_breakup';
    }

    if (_hasAny(t, [
      'i feel far from god and alone',
      'god feels distant and i feel alone',
      'spiritual loneliness',
      'alone with god feeling distant',
    ])) {
      return 'loneliness_spiritual_loneliness';
    }

    // SHAME / GUILT
    if (_hasAny(t, [
      'i sinned',
      'i know i sinned',
      'i feel guilty before god',
      'i disobeyed god',
      'i did what i knew was wrong',
    ])) {
      return 'shame_guilt_after_sin';
    }

    if (_hasAny(t, [
      'i am ashamed i went back',
      'im ashamed i went back',
      'i feel filthy after relapsing',
      'i cannot believe i did this again',
      'i cant believe i did this again',
    ])) {
      return 'shame_after_relapse';
    }

    if (_hasAny(t, [
      'i hate myself',
      'i cannot forgive myself',
      'i cant forgive myself',
      'i keep condemning myself',
      'i feel like trash',
      'self condemnation',
    ])) {
      return 'shame_self_condemnation';
    }

    if (_hasAny(t, [
      'i am not worthy',
      'im not worthy',
      'i do not deserve grace',
      'i dont deserve grace',
      'god should be done with me',
      'feeling unworthy',
    ])) {
      return 'shame_feeling_unworthy';
    }

    if (_hasAny(t, [
      'i wish i could take it back',
      'i said the wrong thing',
      'i did the wrong thing',
      'i hurt someone with my words',
      'regret over actions',
    ])) {
      return 'shame_regret_over_actions';
    }

    // RELATIONSHIPS
    if (_hasAny(t, [
      'my husband and i keep fighting',
      'my wife and i keep fighting',
      'my marriage is hurting',
      'marriage conflict',
      'we keep arguing',
    ])) {
      return 'relationship_marriage_conflict';
    }

    if (_hasAny(t, [
      'my family is a mess',
      'family tension',
      'my family keeps fighting',
      'there is tension at home',
      'family conflict',
    ])) {
      return 'relationship_family_tension';
    }

    if (_hasAny(t, [
      'my friend hurt me',
      'a friend hurt me',
      'friendship is broken',
      'my friend walked away',
      'friendship hurt',
    ])) {
      return 'relationship_friendship_hurt';
    }

    if (_hasAny(t, [
      'trust is broken',
      'i cannot trust them anymore',
      'i cant trust them anymore',
      'they broke my trust',
      'broken trust',
    ])) {
      return 'relationship_broken_trust';
    }

    if (_hasAny(t, [
      'we left it unresolved',
      'we never dealt with it',
      'that argument is still hanging over us',
      'unresolved argument',
    ])) {
      return 'relationship_unresolved_argument';
    }

    // PURPOSE / IDENTITY
    if (_hasAny(t, [
      'i feel lost',
      'i do not know where i am going',
      'i dont know where i am going',
      'feeling lost',
    ])) {
      return 'purpose_feeling_lost';
    }

    if (_hasAny(t, [
      'i have no direction',
      'i do not know what to do next',
      'i dont know what to do next',
      'i do not know where to go from here',
      'i dont know where to go from here',
      'no direction',
    ])) {
      return 'purpose_no_direction';
    }

    if (_hasAny(t, [
      'i do not know who i am',
      'i dont know who i am',
      'i have lost myself',
      'i do not recognize myself',
      'i dont recognize myself',
      'identity confusion',
    ])) {
      return 'identity_confusion';
    }

    if (_hasAny(t, [
      'i feel worthless',
      'i do not matter',
      'i dont matter',
      'i have no value',
      'low self worth',
      'i feel useless',
    ])) {
      return 'identity_low_self_worth';
    }

    if (_hasAny(t, [
      'why am i here',
      'what am i here for',
      'what is my purpose',
      'questioning my purpose',
    ])) {
      return 'purpose_questioning_purpose';
    }

    // TEMPTATION
    if (_hasAny(t, [
      'lust',
      'porn',
      'pornography',
      'sexual temptation',
      'tempted sexually',
      'i want to look at porn',
      'i keep falling into lust',
      'i am struggling with lust',
      'im struggling with lust',
    ])) {
      return 'temptation_sexual_temptation';
    }

    if (_hasAny(t, [
      'go back to my old life',
      'go back to the old me',
      'go back to what i used to do',
      'old habits are calling me',
      'tempted to go back',
    ])) {
      return 'temptation_to_go_back';
    }

    if (_hasAny(t, [
      'i want to give up',
      'i want to quit',
      'i am tempted to quit',
      'im tempted to quit',
      'i am tired of trying',
      'im tired of trying',
      'what is the point of trying',
    ])) {
      return 'temptation_to_give_up';
    }

    if (_hasAny(t, [
      'i want to snap',
      'i want to explode',
      'i want to go off',
      'i want to cuss them out',
      'i am about to lose it',
      'im about to lose it',
    ])) {
      return 'temptation_to_react_in_anger';
    }

    if (_hasAny(t, [
      'i just want to numb out',
      'i want to escape',
      'i want to stop feeling',
      'i do not want to feel this',
      'i dont want to feel this',
      'temptation to numb',
    ])) {
      return 'temptation_to_numb';
    }

    // CATEGORY FALLBACKS
    if (_hasAny(t, [
      'alcohol',
      'drink',
      'drinking',
      'sober',
      'sobriety',
      'relapse',
      'addiction',
      'addicted',
    ])) {
      return 'addiction_relapse_thoughts';
    }

    if (_hasAny(t, [
      'grief',
      'grieving',
      'loss',
      'passed away',
      'death',
      'funeral',
      'mourning',
    ])) {
      return 'grief_loss_of_loved_one';
    }

    if (_hasAny(t, [
      'anxious',
      'anxiety',
      'worried',
      'worry',
      'panic',
      'nervous',
      'uneasy',
      'restless',
    ])) {
      return 'anxiety_future_fear';
    }

    if (_hasAny(t, [
      'angry',
      'mad',
      'furious',
      'rage',
      'resentment',
      'bitter',
    ])) {
      return 'anger_at_person';
    }

    if (_hasAny(t, [
      'alone',
      'lonely',
      'isolated',
      'abandoned',
    ])) {
      return 'loneliness_isolation';
    }

    if (_hasAny(t, [
      'ashamed',
      'shame',
      'guilty',
      'condemned',
      'unworthy',
      'regret',
    ])) {
      return 'shame_guilt_after_sin';
    }

    if (_hasAny(t, [
      'marriage',
      'husband',
      'wife',
      'family',
      'friend',
      'relationship',
      'argument',
      'conflict',
    ])) {
      return 'relationship_unresolved_argument';
    }

    if (_hasAny(t, [
      'purpose',
      'calling',
      'direction',
      'who am i',
      'worthless',
      'lost',
    ])) {
      return 'purpose_feeling_lost';
    }

    if (_hasAny(t, [
      'tempted',
      'temptation',
      'lust',
      'urge',
      'craving',
    ])) {
      return 'temptation_to_go_back';
    }

    return 'default_general';
  }

  String categoryFromSubcategory(String subcategory) {
    if (subcategory.startsWith('addiction_')) return 'addiction';
    if (subcategory.startsWith('grief_')) return 'grief';
    if (subcategory.startsWith('anxiety_')) return 'anxiety';
    if (subcategory.startsWith('anger_')) return 'anger';
    if (subcategory.startsWith('loneliness_')) return 'loneliness';
    if (subcategory.startsWith('shame_')) return 'shame / guilt';
    if (subcategory.startsWith('relationship_')) return 'relationships';
    if (subcategory.startsWith('purpose_') || subcategory.startsWith('identity_')) {
      return 'purpose / identity';
    }
    if (subcategory.startsWith('temptation_')) return 'temptation';
    return 'general';
  }

  String friendlySubcategory(String subcategory) {
    const labels = {
      'addiction_relapse_thoughts': 'addiction / relapse thoughts',
      'addiction_active_relapse': 'addiction / active relapse',
      'addiction_cravings': 'addiction / cravings',
      'addiction_fear_of_returning': 'addiction / fear of returning',
      'addiction_shame_after_using': 'addiction / shame after using',
      'grief_loss_of_loved_one': 'grief / loss of loved one',
      'grief_loss_of_pet': 'grief / loss of pet',
      'grief_fresh_loss': 'grief / fresh loss',
      'grief_anniversary_grief': 'grief / anniversary grief',
      'grief_with_regret': 'grief / regret after loss',
      'anxiety_panic_spiral': 'anxiety / panic spiral',
      'anxiety_sleepless_worry': 'anxiety / sleepless worry',
      'anxiety_future_fear': 'anxiety / fear of the future',
      'anxiety_health_anxiety': 'anxiety / health anxiety',
      'anxiety_financial_anxiety': 'anxiety / financial anxiety',
      'anger_at_person': 'anger / anger at a person',
      'anger_betrayal': 'anger / betrayal',
      'anger_resentment': 'anger / resentment',
      'anger_at_self': 'anger / anger at self',
      'anger_at_god': 'anger / anger at God',
      'loneliness_feeling_unseen': 'loneliness / feeling unseen',
      'loneliness_isolation': 'loneliness / isolation',
      'loneliness_abandonment': 'loneliness / abandonment',
      'loneliness_after_breakup': 'loneliness / after breakup',
      'loneliness_spiritual_loneliness': 'loneliness / spiritual loneliness',
      'shame_guilt_after_sin': 'shame / guilt after sin',
      'shame_after_relapse': 'shame / after relapse',
      'shame_self_condemnation': 'shame / self-condemnation',
      'shame_feeling_unworthy': 'shame / feeling unworthy',
      'shame_regret_over_actions': 'shame / regret over actions',
      'relationship_marriage_conflict': 'relationships / marriage conflict',
      'relationship_family_tension': 'relationships / family tension',
      'relationship_friendship_hurt': 'relationships / friendship hurt',
      'relationship_broken_trust': 'relationships / broken trust',
      'relationship_unresolved_argument': 'relationships / unresolved argument',
      'purpose_feeling_lost': 'purpose / feeling lost',
      'purpose_no_direction': 'purpose / no direction',
      'identity_confusion': 'identity / confusion',
      'identity_low_self_worth': 'identity / low self-worth',
      'purpose_questioning_purpose': 'purpose / questioning purpose',
      'temptation_sexual_temptation': 'temptation / sexual temptation',
      'temptation_to_go_back': 'temptation / go back',
      'temptation_to_give_up': 'temptation / give up',
      'temptation_to_react_in_anger': 'temptation / react in anger',
      'temptation_to_numb': 'temptation / numb the pain',
      'default_general': 'general',
    };

    return labels[subcategory] ?? subcategory.replaceAll('_', ' ');
  }

  String _rotating(String key, List<String> values) {
    final start = _rotation[key] ?? _random.nextInt(values.length);
    final value = values[start % values.length];
    _rotation[key] = start + 1;
    return value;
  }

  List<Map<String, String>> _verses(String subcategory) {
    switch (subcategory) {
      case 'addiction_relapse_thoughts':
        return [
          {
            'ref': '1 Corinthians 10:13',
            'text':
                'There hath no temptation taken you but such as is common to man: but God is faithful.',
          },
          {
            'ref': 'James 4:7',
            'text':
                'Submit yourselves therefore to God. Resist the devil, and he will flee from you.',
          },
          {
            'ref': 'Galatians 5:1',
            'text':
                'Stand fast therefore in the liberty wherewith Christ hath made us free.',
          },
        ];
      case 'addiction_active_relapse':
        return [
          {
            'ref': '1 John 1:9',
            'text':
                'If we confess our sins, he is faithful and just to forgive us our sins.',
          },
          {
            'ref': 'Proverbs 24:16',
            'text':
                'For a just man falleth seven times, and riseth up again.',
          },
          {
            'ref': 'Psalm 51:10',
            'text': 'Create in me a clean heart, O God.',
          },
        ];
      case 'addiction_cravings':
        return [
          {
            'ref': 'Romans 6:12',
            'text':
                'Let not sin therefore reign in your mortal body, that ye should obey it.',
          },
          {
            'ref': '2 Timothy 1:7',
            'text':
                'For God hath not given us the spirit of fear; but of power, and of love, and of a sound mind.',
          },
          {
            'ref': 'Psalm 46:1',
            'text':
                'God is our refuge and strength, a very present help in trouble.',
          },
        ];
      case 'addiction_fear_of_returning':
        return [
          {
            'ref': '1 Peter 5:8',
            'text':
                'Be sober, be vigilant; because your adversary the devil, as a roaring lion, walketh about.',
          },
          {
            'ref': 'Galatians 5:1',
            'text':
                'Stand fast therefore in the liberty wherewith Christ hath made us free.',
          },
          {
            'ref': 'Psalm 121:3',
            'text': 'He will not suffer thy foot to be moved.',
          },
        ];
      case 'addiction_shame_after_using':
      case 'shame_after_relapse':
        return [
          {
            'ref': 'Romans 8:1',
            'text':
                'There is therefore now no condemnation to them which are in Christ Jesus.',
          },
          {
            'ref': '1 John 1:9',
            'text':
                'If we confess our sins, he is faithful and just to forgive us our sins.',
          },
          {
            'ref': 'Psalm 51:17',
            'text':
                'A broken and a contrite heart, O God, thou wilt not despise.',
          },
        ];
      case 'grief_loss_of_pet':
      case 'grief_loss_of_loved_one':
      case 'grief_fresh_loss':
      case 'grief_anniversary_grief':
      case 'grief_with_regret':
        return [
          {
            'ref': 'Psalm 34:18',
            'text':
                'The Lord is nigh unto them that are of a broken heart.',
          },
          {
            'ref': 'Matthew 5:4',
            'text':
                'Blessed are they that mourn: for they shall be comforted.',
          },
          {
            'ref': 'John 11:35',
            'text': 'Jesus wept.',
          },
        ];
      case 'anxiety_panic_spiral':
      case 'anxiety_sleepless_worry':
      case 'anxiety_future_fear':
      case 'anxiety_health_anxiety':
      case 'anxiety_financial_anxiety':
        return [
          {
            'ref': 'Philippians 4:6-7',
            'text':
                'Be careful for nothing; but in every thing by prayer and supplication let your requests be made known unto God.',
          },
          {
            'ref': '2 Timothy 1:7',
            'text':
                'For God hath not given us the spirit of fear; but of power, and of love, and of a sound mind.',
          },
          {
            'ref': 'Isaiah 41:10',
            'text':
                'Fear thou not; for I am with thee: be not dismayed; for I am thy God.',
          },
        ];
      case 'anger_at_person':
      case 'anger_betrayal':
      case 'anger_resentment':
      case 'anger_at_self':
      case 'anger_at_god':
        return [
          {
            'ref': 'James 1:19-20',
            'text':
                'Let every man be swift to hear, slow to speak, slow to wrath.',
          },
          {
            'ref': 'Ephesians 4:26',
            'text': 'Be ye angry, and sin not.',
          },
          {
            'ref': 'Proverbs 15:1',
            'text': 'A soft answer turneth away wrath.',
          },
        ];
      case 'loneliness_feeling_unseen':
      case 'loneliness_isolation':
      case 'loneliness_abandonment':
      case 'loneliness_after_breakup':
      case 'loneliness_spiritual_loneliness':
        return [
          {
            'ref': 'Hebrews 13:5',
            'text': 'I will never leave thee, nor forsake thee.',
          },
          {
            'ref': 'John 14:18',
            'text': 'I will not leave you comfortless: I will come to you.',
          },
          {
            'ref': 'Psalm 34:18',
            'text':
                'The Lord is nigh unto them that are of a broken heart.',
          },
        ];
      case 'shame_guilt_after_sin':
      case 'shame_self_condemnation':
      case 'shame_feeling_unworthy':
      case 'shame_regret_over_actions':
        return [
          {
            'ref': '1 John 1:9',
            'text':
                'If we confess our sins, he is faithful and just to forgive us our sins.',
          },
          {
            'ref': 'Romans 8:1',
            'text':
                'There is therefore now no condemnation to them which are in Christ Jesus.',
          },
          {
            'ref': 'Psalm 51:10',
            'text': 'Create in me a clean heart, O God.',
          },
        ];
      case 'relationship_marriage_conflict':
      case 'relationship_family_tension':
      case 'relationship_friendship_hurt':
      case 'relationship_broken_trust':
      case 'relationship_unresolved_argument':
        return [
          {
            'ref': 'James 1:19',
            'text':
                'Let every man be swift to hear, slow to speak, slow to wrath.',
          },
          {
            'ref': 'Proverbs 15:1',
            'text': 'A soft answer turneth away wrath.',
          },
          {
            'ref': 'Colossians 3:13',
            'text':
                'Forbearing one another, and forgiving one another.',
          },
        ];
      case 'purpose_feeling_lost':
      case 'purpose_no_direction':
      case 'identity_confusion':
      case 'identity_low_self_worth':
      case 'purpose_questioning_purpose':
        return [
          {
            'ref': 'Proverbs 3:5-6',
            'text':
                'Trust in the Lord with all thine heart; and lean not unto thine own understanding.',
          },
          {
            'ref': 'Jeremiah 29:11',
            'text':
                'For I know the thoughts that I think toward you, saith the Lord.',
          },
          {
            'ref': 'Ephesians 2:10',
            'text':
                'For we are his workmanship, created in Christ Jesus unto good works.',
          },
        ];
      case 'temptation_sexual_temptation':
      case 'temptation_to_go_back':
      case 'temptation_to_give_up':
      case 'temptation_to_react_in_anger':
      case 'temptation_to_numb':
        return [
          {
            'ref': '1 Corinthians 10:13',
            'text':
                'There hath no temptation taken you but such as is common to man: but God is faithful.',
          },
          {
            'ref': 'James 4:7',
            'text':
                'Submit yourselves therefore to God. Resist the devil, and he will flee from you.',
          },
          {
            'ref': 'Matthew 26:41',
            'text':
                'Watch and pray, that ye enter not into temptation.',
          },
        ];
      default:
        return [
          {
            'ref': 'Psalm 46:1',
            'text':
                'God is our refuge and strength, a very present help in trouble.',
          },
          {
            'ref': 'Isaiah 41:10',
            'text':
                'Fear thou not; for I am with thee: be not dismayed; for I am thy God.',
          },
          {
            'ref': 'Proverbs 3:5-6',
            'text':
                'Trust in the Lord with all thine heart; and lean not unto thine own understanding.',
          },
        ];
    }
  }

  String _acknowledge(String subcategory) {
    switch (subcategory) {
      case 'addiction_relapse_thoughts':
        return _rotating('ack_$subcategory', [
          'You fought hard to leave alcohol behind, so having those thoughts come back is not a small thing. It can feel alarming, disappointing, and exhausting when something you already battled starts reaching for your mind again. But the fact that you said it out loud matters. You are not blindly drifting. You recognized the danger early, and that honesty is a strong move in a moment that could have stayed hidden.',
          'After coming this far, it makes sense that these thoughts would feel serious. You already know what alcohol can take, which is why even the mental pull can feel heavy. This does not mean you have already failed. It means the fight is real right now. Bringing it into the light instead of quietly entertaining it is wisdom, and wisdom matters most at the beginning of a battle like this.',
        ]);
      case 'addiction_active_relapse':
        return _rotating('ack_$subcategory', [
          'Relapsing after fighting to get free can land with a deep wave of disappointment, regret, and fear. It can make you feel like all your progress just collapsed in one moment. But this is not the time to disappear into shame. It is the time to tell the truth. What happened is serious, but it does not have to become the rest of your story. Being honest right now matters more than pretending it did not happen.',
          'If you have already gone back and used or drank again, it makes sense that your heart would feel heavy. Relapse can come with shock, self-anger, and a sense of failure that hits hard. But falling is not the same thing as being abandoned by God. This moment needs honesty, repentance, and quick course correction, not hiding. The enemy wants secrecy after failure. God calls you back into the light.',
        ]);
      case 'addiction_cravings':
        return _rotating('ack_$subcategory', [
          'Cravings can hit with real force. They are not imaginary, and they are not always mild. They can press on your body, your thoughts, and your emotions all at once until it feels like the urge is trying to take over the whole moment. That kind of pressure is exhausting. But naming it honestly matters. You are not crazy for feeling the fight, and you are not wrong for taking it seriously.',
          'A strong craving can make everything else in the room feel quieter while the urge itself gets louder and louder. That is part of why it feels so intense. It narrows your focus and tries to convince you that relief is only one bad choice away. It makes sense if you feel worn down by that pressure. But saying what is happening instead of silently giving into it is already a move toward truth.',
        ]);
      case 'addiction_fear_of_returning':
        return _rotating('ack_$subcategory', [
          'It is a hard thing to feel afraid of going back to a life you already know can hurt you. That fear can sit in the chest like a warning because you remember what it cost, what it touched, and how hard it was to get out. It makes sense that this would feel serious. Fear of returning is not foolish. It is often the soul remembering what the flesh sometimes tries to romanticize.',
          'When you have already lived through the damage, even the possibility of returning can feel frightening. You may not only fear the substance itself. You may fear the whole chain reaction that could come with it. That kind of concern is understandable. It means this matters to you. And bringing that fear into the light is far better than pretending you are not vulnerable.',
        ]);
      case 'addiction_shame_after_using':
      case 'shame_after_relapse':
        return _rotating('ack_$subcategory', [
          'Shame after using can hit hard and fast. It can make you feel dirty, disappointed, exposed, and tempted to hide from God and from people. That is a brutal place to sit in. It often feels like the failure itself was not enough, and now shame wants to bury you under its own weight too. But bringing that shame into the open matters because secrecy is where it tries to tighten its grip.',
          'When you have gone back and shame floods in behind it, it can feel like your whole identity is being dragged down with the failure. That kind of heaviness is exhausting. You may want to disappear, stay quiet, or punish yourself internally. But shame is a terrible guide. It can make a bad moment worse by pushing you away from the very truth and mercy you need most.',
        ]);
      case 'grief_loss_of_loved_one':
        return _rotating('ack_$subcategory', [
          'Losing someone you love leaves a kind of ache that reaches into ordinary moments and changes how everything feels. Grief can come in waves, and sometimes those waves hit without warning. It makes sense if your heart feels tender, tired, confused, or just heavy. This is not small pain. Love and loss often travel together, and what you are carrying deserves room, honesty, and compassion.',
          'The death of a loved one can leave a silence in life that is difficult to explain. A chair is empty, a voice is missing, and parts of daily life feel altered in a way other people do not always fully understand. That kind of grief is real. You do not need to rush it, minimize it, or pretend your heart is unaffected when it has clearly been touched deeply.',
        ]);
      case 'grief_loss_of_pet':
        return _rotating('ack_$subcategory', [
          'Losing a pet can hurt more deeply than some people understand, because that loss touches daily routines, companionship, comfort, and quiet moments that mattered. The emptiness left behind can feel surprisingly sharp. It makes sense if your heart is heavy. Love was there, attachment was there, and grief is often the price of that kind of bond. You do not need to act like this should not affect you.',
          'A pet can become woven into the rhythm of home, comfort, and daily life, so when that presence is suddenly gone, the loss can feel very real and very personal. It is not silly to grieve that. It is honest. The ache that comes after that kind of loss deserves gentleness, not dismissal.',
        ]);
      case 'grief_fresh_loss':
        return _rotating('ack_$subcategory', [
          'Fresh loss often feels raw in a way that is hard to describe. The mind can struggle to keep up with what the heart has already felt. It makes sense if everything feels tender, surreal, or emotionally exposed right now. When something just happened, the pain can feel especially close to the surface, and even basic moments can take more strength than they normally would.',
          'When grief is fresh, the weight of it can feel immediate and unfinished, as if your whole inner world is still trying to catch up to what has happened. That kind of pain is not meant to be rushed. If your emotions feel raw, uneven, or intense, that is understandable in a moment like this.',
        ]);
      case 'grief_anniversary_grief':
        return _rotating('ack_$subcategory', [
          'Certain dates can reopen grief in a powerful way. Anniversaries, birthdays, seasons, and familiar times of year can bring the ache back to the surface even when you thought you were doing better. That does not mean you are going backward. It means love still remembers. This kind of grief can feel unexpectedly heavy, and there is nothing weak about feeling its weight again.',
          'Anniversary grief can be especially difficult because it catches memory, emotion, and time all in the same place. A certain date can suddenly make the absence feel close again. If that is what is happening, it makes sense that your heart feels stirred. This is not strange. It is part of how love and remembrance often move together.',
        ]);
      case 'grief_with_regret':
        return _rotating('ack_$subcategory', [
          'Grief mixed with regret can feel especially painful because sorrow is carrying not only the loss itself, but also the ache of things left unsaid, undone, or unresolved. That can leave the heart replaying moments and wondering what could have been different. It makes sense that this feels heavy. Regret has a way of pressing on grief in a very personal way.',
          'When grief is carrying regret, the pain often becomes more tangled. You may miss the person deeply and also feel haunted by what you wish you had said or done. That is an exhausting weight to bear. It deserves honesty and tenderness, because the heart can be bruised by both love and unfinished memories at the same time.',
        ]);
      case 'anxiety_panic_spiral':
        return _rotating('ack_$subcategory', [
          'A panic spiral can make the mind feel like it is racing faster than the heart can handle. Thoughts begin multiplying, the body tightens, and fear starts making everything feel urgent all at once. That is exhausting and unsettling. If this is where you are right now, it makes sense that you feel overwhelmed. Panic has a way of crowding out perspective until even simple calm feels far away.',
          'When anxiety turns into spiraling, it can feel like your thoughts are no longer staying in one lane. One fear becomes five, then ten, and the whole moment starts feeling too big to hold. That kind of pressure is real. You do not need to pretend it is not. What matters now is slowing the spiral before fear gets to keep writing the whole story.',
        ]);
      case 'anxiety_sleepless_worry':
        return _rotating('ack_$subcategory', [
          'Sleepless worry can wear a person down because the body is tired but the mind refuses to stop. Night can make concerns feel bigger, quieter, and harder to escape. It makes sense if you feel drained by that kind of cycle. When rest is interrupted by fear and overthinking, even the next day can start already carrying the weight of the night before.',
          'There is a particular heaviness that comes with trying to sleep while your mind keeps turning over the same concerns. It can make the night feel long and the heart feel tired before morning even comes. That kind of strain is real. It matters, and it deserves more than just being brushed off.',
        ]);
      case 'anxiety_future_fear':
        return _rotating('ack_$subcategory', [
          'Fear of the future can weigh on the heart because it pulls your mind toward what has not happened yet and then asks you to carry it as if it already has. That kind of pressure is exhausting. It makes sense if uncertainty is making you feel tense, unsettled, or mentally crowded. The unknown can feel heavy when your heart wants stability and clear answers.',
          'When the future feels uncertain, the mind often tries to rush ahead and solve what is not yet here. That can leave you carrying imagined weight before the real moment even arrives. If that is what is happening, it makes sense that you feel worn down. Uncertainty can be a real burden when it keeps asking your heart to live too far ahead.',
        ]);
      case 'anxiety_health_anxiety':
        return _rotating('ack_$subcategory', [
          'Health anxiety can feel especially consuming because it touches your body, your safety, and your sense of control all at once. Symptoms, test results, or even unfamiliar sensations can quickly become heavy in the mind. That kind of fear is not light. It makes sense if your thoughts keep returning there and your peace feels harder to hold.',
          'When concern about health starts dominating the mind, it can make the body feel like a constant source of alarm. Every symptom can feel loaded, every unknown can feel larger, and peace can feel fragile. That is an exhausting place to be. It deserves honesty and a steady response grounded in truth rather than panic.',
        ]);
      case 'anxiety_financial_anxiety':
        return _rotating('ack_$subcategory', [
          'Financial anxiety can press hard because it touches provision, stability, responsibility, and fear about what happens if things do not stretch far enough. Bills, expenses, and uncertainty about money can quietly sit on the mind all day and all night. That kind of pressure is real. It makes sense if it has your heart feeling tense and your thoughts moving fast.',
          'Money stress can feel heavy because it is not just numbers on a page. It often carries fear about safety, future needs, and whether you will be able to cover what matters. That kind of concern can quickly become exhausting. It deserves honesty, wisdom, and a response that is calmer than the pressure itself.',
        ]);
      case 'anger_at_person':
        return _rotating('ack_$subcategory', [
          'Anger at another person can flare up fast, especially when you feel hurt, disrespected, misunderstood, or crossed. It can make your thoughts feel hot and your next words feel dangerously close to coming out before wisdom can catch them. That kind of internal pressure is real. It makes sense if you feel stirred up. What matters now is not denial, but direction.',
          'When someone gets under your skin in a deep way, anger can rise with real force. It may feel like they touched something painful, unfair, or deeply frustrating. That is not a light moment. But bringing it into the light before it becomes a reaction is wise. Anger speaks loudly, and that is exactly why it needs to be slowed down.',
        ]);
      case 'anger_betrayal':
        return _rotating('ack_$subcategory', [
          'Betrayal often cuts deeper than ordinary conflict because it touches trust, loyalty, and the place where you expected safety or honesty. That kind of wound can produce anger that feels sharper and more personal than usual. It makes sense if this has stirred a lot in you. Betrayal leaves a different kind of pain, and your heart is feeling the weight of that.',
          'When trust is broken by someone close, anger can come mixed with hurt, disbelief, and grief all at the same time. That is part of why betrayal can feel so intense. This is not just irritation. It is pain with heat on it. It deserves honesty, but it also needs wisdom before the wound becomes the one deciding what happens next.',
        ]);
      case 'anger_resentment':
        return _rotating('ack_$subcategory', [
          'Resentment often builds slowly. It may not always look explosive on the outside, but inside it can sit like a hard knot that keeps replaying the offense and refusing to let it go. That kind of anger can quietly shape the heart over time. It makes sense if it feels heavy. Long-held hurt tends to do that.',
          'When resentment has taken root, the heart often feels tired because it has been carrying the same offense, the same frustration, or the same injury for too long. That kind of emotional weight is not small. It may feel familiar now, but that does not mean it is harmless. The longer resentment sits, the more it tries to shape the heart around itself.',
        ]);
      case 'anger_at_self':
        return _rotating('ack_$subcategory', [
          'Anger at yourself can be especially painful because there is no easy distance from it. You may feel frustrated with your choices, disappointed in your weakness, or stuck replaying what you wish had gone differently. That kind of internal pressure is exhausting. It makes sense if you feel hard on yourself right now, but self-anger can turn cruel quickly if it is left unchecked.',
          'When you are angry at yourself, the mind often becomes its own accuser. It keeps revisiting mistakes, missed chances, or failures and speaking harshly in response. That is a painful place to live inside. The frustration may be real, but it still needs truth and mercy so it does not become a deeper form of self-destruction.',
        ]);
      case 'anger_at_god':
        return _rotating('ack_$subcategory', [
          'Anger at God can feel complicated because it often carries pain, disappointment, confusion, and questions all at once. If that is where you are, it makes sense that your heart feels conflicted. This is not a light struggle. It usually means something feels deeply painful or deeply unresolved inside you, and that pain is reaching upward in frustration.',
          'When someone is angry at God, it is often because hurt has collided with expectation. The heart expected one thing, life delivered another, and now the pain feels tangled with faith. That can be a very heavy place to stand. It deserves honesty, not pretending. God already sees it clearly.',
        ]);
      case 'loneliness_feeling_unseen':
        return _rotating('ack_$subcategory', [
          'Feeling unseen can wear on the heart because it creates the ache of being present but not really noticed, known, or understood. That kind of loneliness can quietly grow over time until it starts affecting how you see yourself. It makes sense if that hurts. Being overlooked does not feel small when the soul is longing to be genuinely seen.',
          'There is a specific pain that comes from feeling invisible in places where you hoped to feel known. It can make the heart feel small and the room feel bigger than it should. That ache is real. It deserves honesty, because the pain of being unseen often settles deeper than people realize.',
        ]);
      case 'loneliness_isolation':
        return _rotating('ack_$subcategory', [
          'Isolation can make life feel heavier because the heart was not meant to carry everything alone in silence. When loneliness stretches on, even ordinary hours can start feeling longer and more draining. If that is what you are facing, it makes sense that your spirit feels tired. Isolation has a way of pressing inward on the mind and emotions over time.',
          'Being alone for too long or feeling cut off from meaningful connection can create a kind of emptiness that is difficult to explain. It is not weakness to feel that. The ache for connection is deeply human, and isolation often presses harder than people on the outside can see.',
        ]);
      case 'loneliness_abandonment':
        return _rotating('ack_$subcategory', [
          'Loneliness tied to abandonment carries a particular sting because it is not just the absence of people. It is the ache of feeling left, overlooked, or not held onto the way you hoped. That kind of pain can touch trust very deeply. It makes sense if this feels especially heavy. Abandonment often leaves behind more than silence. It leaves questions and wounds.',
          'When loneliness carries the feeling of having been left behind, it can cut much deeper than simple solitude. It often reaches into worth, trust, and the fear of not mattering enough to be stayed with. That kind of pain is real. It should not be minimized just because it is quiet on the outside.',
        ]);
      case 'loneliness_after_breakup':
        return _rotating('ack_$subcategory', [
          'Loneliness after a breakup can feel especially sharp because it often comes with missing the person, missing the routine, and grieving the version of the future you had pictured. That kind of emptiness is not just about being alone. It is also about loss. It makes sense if this hurts more deeply than you want it to.',
          'A breakup can leave behind an emotional quiet that feels strange and painful. Someone who once occupied mental, emotional, or daily space is no longer there in the same way, and the absence can echo loudly. That kind of loneliness is real. It deserves honesty and gentleness.',
        ]);
      case 'loneliness_spiritual_loneliness':
        return _rotating('ack_$subcategory', [
          'Spiritual loneliness can feel disorienting because it is not only the ache of being alone. It is the ache of feeling alone while also feeling like God seems distant, quiet, or hard to sense. That combination can weigh heavily on the heart. If that is where you are, it makes sense that you feel unsettled and tired inside.',
          'When loneliness and spiritual distance seem to show up together, the heart can feel especially exposed. It can leave you wondering why comfort feels far and why prayer feels harder than usual. That is a real struggle. It should be named honestly, not covered over with forced language.',
        ]);
      case 'shame_guilt_after_sin':
        return _rotating('ack_$subcategory', [
          'Guilt after sin can sit heavily on the conscience because something in you knows the matter is real and cannot simply be brushed aside. That kind of inner weight can be painful, exhausting, and humbling. It makes sense if your heart feels troubled. A burdened conscience is not comfortable, but honesty here matters more than hiding or pretending the issue is smaller than it is.',
          'When you know you have missed the mark, guilt can become a constant pressure in the mind and heart. It can replay the moment, stir regret, and make peace feel harder to reach. That kind of heaviness is real. It deserves truth, repentance, and mercy instead of silence or self-protection.',
        ]);
      case 'shame_self_condemnation':
        return _rotating('ack_$subcategory', [
          'Self-condemnation can be brutal because it turns the mind into its own accuser and keeps replaying failure with no mercy attached. That kind of inner attack is exhausting. It can leave you feeling stuck, small, and unable to move forward. If that is where you are, it makes sense that your heart feels heavy. Condemnation presses hard.',
          'When your own thoughts keep speaking against you, the weight can become very personal and very difficult to escape. Self-condemnation often feels harsher than ordinary guilt because it starts attacking identity, worth, and hope at the same time. That is not a light burden. It needs truth and grace, not more agreement with the accusation.',
        ]);
      case 'shame_feeling_unworthy':
        return _rotating('ack_$subcategory', [
          'Feeling unworthy can quietly distort the heart by making you believe grace belongs to other people more than it belongs to you. That kind of shame can make prayer feel smaller and mercy feel farther away. If that is what you are carrying, it makes sense that your spirit feels low. Unworthiness often speaks softly, but it cuts deeply.',
          'When shame turns into a sense of unworthiness, it can make you feel like you should stay back, stay hidden, or stop expecting goodness from God. That is a painful place to live inside. It deserves to be confronted with truth, because feelings of unworthiness can become deeply misleading if left unchallenged.',
        ]);
      case 'shame_regret_over_actions':
        return _rotating('ack_$subcategory', [
          'Regret over your actions can weigh heavily because it keeps reaching backward toward something you wish could be undone. That kind of pain can leave the heart replaying words, choices, and consequences again and again. It makes sense if that feels exhausting. Regret often hurts precisely because the moment mattered.',
          'When you regret what you did or said, the mind can circle the same memory over and over, wishing for a different version of the story. That is a painful place to be. It deserves honesty and repentance where needed, but not endless punishment with no mercy attached.',
        ]);
      case 'relationship_marriage_conflict':
        return _rotating('ack_$subcategory', [
          'Marriage conflict can feel heavy because it touches trust, communication, daily life, and the place where you expected steadiness and closeness. When tension keeps showing up in that relationship, it often affects far more than just one conversation. It makes sense if this has your heart feeling tired, guarded, or emotionally stretched. Marriage strain rarely stays small on the inside.',
          'When a marriage is under pressure, even ordinary moments can start feeling loaded. Arguments, silence, tension, and disappointment have a way of spreading into the whole atmosphere of life. That kind of strain is real. It deserves wisdom, not careless reaction.',
        ]);
      case 'relationship_family_tension':
        return _rotating('ack_$subcategory', [
          'Family tension can be especially draining because family relationships often reach deep into history, expectation, and belonging. When there is conflict there, it can stir a lot at once. It makes sense if this feels exhausting or emotionally tangled. Family pain often hits multiple layers of the heart at the same time.',
          'When the pressure is inside your family, it can be hard to simply step away emotionally, because those relationships often carry years of history and deep personal meaning. That kind of conflict can feel especially heavy. It should not be treated like a small thing.',
        ]);
      case 'relationship_friendship_hurt':
        return _rotating('ack_$subcategory', [
          'Friendship hurt can cut deeper than people sometimes admit, because friendship often carries trust, loyalty, comfort, and emotional safety. When that is wounded, the heart can feel both disappointed and exposed. It makes sense if this feels heavier than it might look from the outside. Hurt from a friend can reach deeply.',
          'A wounded friendship can leave behind confusion, sadness, frustration, and a sense of loss all at once. That is part of why it can feel so draining. When someone you trusted hurts you, even in a quieter way, it can affect the heart more than people realize.',
        ]);
      case 'relationship_broken_trust':
        return _rotating('ack_$subcategory', [
          'Broken trust leaves a person feeling exposed because the place that once seemed safe now feels uncertain. That kind of pain is not only emotional. It often shakes confidence, steadiness, and peace. It makes sense if this has stirred a lot in you. Trust, once broken, leaves behind real questions and real wounds.',
          'When trust is broken, it is hard not to feel unsettled. The mind starts revisiting words, actions, and warning signs, and the heart can become guarded very quickly. That kind of relational pain is real. It deserves care, wisdom, and honesty.',
        ]);
      case 'relationship_unresolved_argument':
        return _rotating('ack_$subcategory', [
          'An unresolved argument can linger longer than the conversation itself. It can keep replaying in the mind, leave tension sitting in the heart, and make the atmosphere feel unsettled even after the words stop. That kind of unfinished conflict can quietly drain a person. It makes sense if this is still bothering you.',
          'When a conflict remains unresolved, the heart often keeps carrying the pressure of what was said, what was not said, and what still feels unfinished. That can be exhausting. Unresolved tension rarely stays contained to one moment. It often keeps echoing after the argument is over.',
        ]);
      case 'purpose_feeling_lost':
        return _rotating('ack_$subcategory', [
          'Feeling lost can be deeply unsettling because it often touches direction, meaning, confidence, and the sense of whether your life is moving with purpose or simply drifting. That kind of uncertainty can weigh quietly but heavily. It makes sense if your heart feels unsettled by it. Questions about direction are rarely small when they sit deep in the soul.',
          'When you feel lost, it can seem like you are moving through life without the clarity or steadiness you want. That can leave the heart tired and the mind searching constantly for something more solid. That is a real burden. It deserves honesty rather than pretending you are more certain than you are.',
        ]);
      case 'purpose_no_direction':
        return _rotating('ack_$subcategory', [
          'Not knowing what to do next can create a lot of internal pressure because the heart wants clarity, and the mind keeps trying to force it before it is ready. That kind of stuck feeling can be exhausting. It makes sense if this has been weighing on you. Unclear direction often affects confidence more than people realize.',
          'When you feel like you have no direction, even ordinary decisions can start to feel bigger and heavier than they should. The uncertainty can drain energy because the mind keeps reaching for an answer that feels just out of sight. That is a real weight to carry.',
        ]);
      case 'identity_confusion':
        return _rotating('ack_$subcategory', [
          'Identity confusion can be deeply disorienting because it touches the core questions of who you are, what defines you, and how you are supposed to understand yourself. That is not a light internal struggle. It makes sense if this feels unsettling. When identity feels blurry, a lot of other parts of life can start feeling unstable too.',
          'Not knowing who you are anymore, or feeling disconnected from yourself, can leave the heart feeling shaky in a very personal way. That kind of confusion is exhausting because it affects not only decisions, but also confidence, belonging, and inner stability. It deserves a truthful and grounded response.',
        ]);
      case 'identity_low_self_worth':
        return _rotating('ack_$subcategory', [
          'Low self-worth can make the heart feel smaller than it should, as if your value rises and falls with your failures, your usefulness, or how others respond to you. That kind of internal pressure is painful. It makes sense if this has left you feeling discouraged or diminished. Worth questions tend to cut deeply.',
          'When you feel worthless or like you do not matter, the pain often reaches farther than one bad moment. It can start shaping the way you read everything about yourself. That is a serious burden. It should not be fed with silence or accepted as truth just because it feels loud.',
        ]);
      case 'purpose_questioning_purpose':
        return _rotating('ack_$subcategory', [
          'Questions about purpose often carry more emotional weight than they first appear to. They touch significance, value, direction, and the desire not to waste your life. That is part of why they can feel so heavy. It makes sense if this question is sitting deeply on you. Purpose questions usually reach the soul, not just the schedule.',
          'When you start asking why you are here or what your life is supposed to be for, it can leave you feeling restless and unsettled inside. That kind of searching is very real. It deserves more than a shallow answer, because the question itself comes from a deep place.',
        ]);
      case 'temptation_sexual_temptation':
        return _rotating('ack_$subcategory', [
          'Sexual temptation can feel intense because it often mixes desire, loneliness, secrecy, and immediacy all in the same moment. That kind of pressure can wear on the mind and body quickly. If this is your battle right now, it makes sense that it feels difficult. Temptation here is not harmless, and pretending it is small rarely helps.',
          'When lust or sexual temptation presses in, it can make the mind feel narrow and urgent, as if relief is the only thing that matters in the moment. That is part of why it can feel so strong. It deserves honesty and quick wisdom, not quiet compromise.',
        ]);
      case 'temptation_to_go_back':
        return _rotating('ack_$subcategory', [
          'Temptation to go back often carries a strange mix of familiarity and danger. Part of you remembers the old pattern, while another part of you knows exactly why you left it. That tension can feel exhausting. It makes sense if the pull feels real. Old habits often try to return through the door of familiarity first.',
          'When you feel pulled toward an old life, an old habit, or an old version of yourself, the temptation can feel personal because it touches things you have already battled before. That is a real fight. It matters that you are naming it instead of drifting toward it quietly.',
        ]);
      case 'temptation_to_give_up':
        return _rotating('ack_$subcategory', [
          'Temptation to give up can show up when you feel tired, discouraged, disappointed, or worn down from trying for a long time. It can whisper that it would be easier to stop caring, stop fighting, or stop hoping. That is a heavy place to stand. If that is where you are, it makes sense that your heart feels weary.',
          'There are moments when the pressure of continuing feels so heavy that giving up starts sounding like relief. That is a painful internal battle. It deserves honesty, because the temptation to quit often shows up when the soul is already tired.',
        ]);
      case 'temptation_to_react_in_anger':
        return _rotating('ack_$subcategory', [
          'Temptation to react in anger can feel sudden and hot, especially when hurt, disrespect, or frustration is involved. In those moments, the urge to explode can feel like the most natural thing in the world. That does not make it wise. If this is the pressure you are feeling, it makes sense that your heart feels stirred. This kind of temptation needs quick restraint.',
          'When the urge to snap, lash out, or go off starts rising, it can feel as though the moment is demanding an immediate answer. That kind of emotional pressure is real. What matters now is not pretending you do not feel it, but refusing to let it choose for you.',
        ]);
      case 'temptation_to_numb':
        return _rotating('ack_$subcategory', [
          'Temptation to numb the pain often shows up when the heart feels overloaded and wants relief more than anything else. In those moments, the desire is usually not just for pleasure. It is often for escape. That kind of pressure is deeply human, but it can also become dangerous if it quietly starts deciding your next move.',
          'When you want to stop feeling for a while, that usually means something inside has been carrying more than it wants to carry anymore. That ache is real. It makes sense that escape sounds appealing when the heart is tired. But the desire to numb needs truth before it becomes permission.',
        ]);
      default:
        return _rotating('ack_$subcategory', [
          'What you are carrying matters, and it deserves more than a rushed or shallow response. Even if the full weight of it is difficult to put into words, it is still real. Sometimes the heart knows something is heavy before the mind has sorted out all the details. That is enough reason to bring it honestly before God instead of trying to hold it together by yourself.',
          'You brought something real into the light, and that matters. Not every struggle arrives with a neat label, but many of them still carry genuine weight in the heart. The fact that you are naming it instead of burying it is already a better step than silence.',
        ]);
    }
  }

  String _truth(String subcategory) {
    switch (subcategory) {
      case 'addiction_relapse_thoughts':
        return _rotating('truth_$subcategory', [
          'Temptation is not the same as surrender. The return of an old thought does not erase the progress God has already helped you make. The enemy wants you to believe that because the thought showed up, the fall is already on the way. That is a lie. God is present in this moment, able to strengthen your mind, steady your will, and help you interrupt the pattern before thought becomes action. This is serious, but it is not hopeless.',
          'Freedom is not proven by never feeling pressure again. Freedom is often proven by what you do when the pressure returns. Right now, the fact that alcohol came back to your mind does not mean it owns you. God is still able to help you stand. He is not watching this from a distance. He is near in the fight, faithful in the temptation, and strong enough to keep this from becoming more than a thought.',
        ]);
      case 'addiction_active_relapse':
        return _rotating('truth_$subcategory', [
          'Relapse is serious, but it is not greater than repentance, mercy, and the restoring power of God. The enemy wants you to treat this moment like final proof that change is impossible. But God still calls people out of failure and back into truth. You do not honor God by hiding in self-condemnation. You honor Him by coming honestly, turning quickly, and refusing to let one failure grow into a season of surrender.',
          'The Lord is not confused by what happened, and He is not powerless in the aftermath of it. He sees the fall clearly, and He still invites you back into the light. Grace does not pretend relapse is harmless, but it also does not leave you chained to it as if there is no way back. God can interrupt what started, restore what was shaken, and help you stand again before this grows into more damage.',
        ]);
      case 'addiction_cravings':
        return _rotating('truth_$subcategory', [
          'A craving may be intense, but it is not a command. You do not have to obey everything your body or mind is shouting in a weak moment. God is able to meet you even when the urge feels physical, immediate, and loud. He can strengthen your self-control, remind you of what is true, and help you endure the pressure without surrendering to it. The craving is real, but it is not your master.',
          'Cravings often lie by saying relief is the same thing as healing. It is not. Temporary escape has cost too much before, and God’s way is still the way of life even when your flesh wants immediate relief. The Lord can help you survive this wave without bowing to it. You are not powerless because the urge feels strong.',
        ]);
      case 'addiction_fear_of_returning':
        return _rotating('truth_$subcategory', [
          'Fear of returning does not have to become a prophecy of returning. God can use that awareness to keep you watchful, honest, and dependent on Him rather than careless. The Lord is not asking you to trust yourself blindly. He is calling you to trust Him actively. He can help you build guardrails, stay in the light, and walk wisely without living in constant dread that relapse is inevitable.',
          'You are not doomed to repeat the past just because you remember it clearly. The same God who helped you leave can help you remain. He can strengthen your discernment, keep your heart awake, and teach you how to walk carefully without being consumed by fear. Awareness is useful when it drives you toward truth, prayer, and wisdom instead of despair.',
        ]);
      case 'addiction_shame_after_using':
      case 'shame_after_relapse':
        return _rotating('truth_$subcategory', [
          'God does not call you to answer failure with hiding. He calls you to answer it with truth, repentance, and coming back into the light. Shame wants to make you believe that because you failed, you are now disqualified from mercy. But mercy is for the honest, not the perfect. The Lord can forgive, cleanse, correct, and restore without pretending that what happened was harmless.',
          'There is a difference between conviction that leads you toward God and shame that drives you away from Him. Conviction says, “Come into the light and turn.” Shame says, “Stay hidden and call yourself ruined.” God is not asking you to agree with the voice of condemnation. He is calling you to bring the failure to Him honestly so grace can do its work.',
        ]);
      case 'grief_loss_of_loved_one':
      case 'grief_loss_of_pet':
      case 'grief_fresh_loss':
      case 'grief_anniversary_grief':
      case 'grief_with_regret':
        return _rotating('truth_$subcategory', [
          'God does not rush mourners, shame tears, or demand that sorrow disappear on command. He draws near to the brokenhearted, and His nearness is not cancelled by your pain. Grief may make life feel unfamiliar for a while, but the Lord is still present in the unfamiliar place. He can hold your sadness, your memories, and even your unanswered questions without turning away from you.',
          'The truth is not that you should be over this already. The truth is that grief has weight, and God meets people in weighted places. He is compassionate toward sorrow, patient with mourning, and close to those whose hearts feel crushed. Even when comfort feels slow, He has not stepped away.',
        ]);
      case 'anxiety_panic_spiral':
      case 'anxiety_sleepless_worry':
      case 'anxiety_future_fear':
      case 'anxiety_health_anxiety':
      case 'anxiety_financial_anxiety':
        return _rotating('truth_$subcategory', [
          'Anxiety speaks urgently, but God remains steady. The Lord is not thrown off by racing thoughts, fearful scenarios, or the pressure you feel in your chest. His presence does not disappear because your peace does. He is able to calm what fear keeps stirring up, and He invites you to bring your concerns to Him instead of carrying them alone. You are not abandoned in your mind’s loudest moments.',
          'Fear wants to make you believe that everything depends on your ability to control, predict, and fix what is in front of you. But God never asked you to hold the world together. He calls you to trust Him in the middle of uncertainty. Even now, with your mind unsettled, He is still near and still faithful.',
        ]);
      case 'anger_at_person':
      case 'anger_betrayal':
      case 'anger_resentment':
      case 'anger_at_self':
      case 'anger_at_god':
        return _rotating('truth_$subcategory', [
          'God is not asking you to pretend that wrong did not happen, but He is calling you to self-control in the middle of strong emotion. Anger may tell you that immediate reaction is strength, but often true strength is restraint under the rule of God. The Lord can steady your spirit, guard your words, and help you respond in truth without letting sin hitch a ride on your pain.',
          'The presence of anger does not mean you must surrender to it. God cares about justice, truth, and righteousness, but He also cares about the condition of your heart. He can help you separate what is valid in your hurt from what would become destructive in your reaction.',
        ]);
      case 'loneliness_feeling_unseen':
      case 'loneliness_isolation':
      case 'loneliness_abandonment':
      case 'loneliness_after_breakup':
      case 'loneliness_spiritual_loneliness':
        return _rotating('truth_$subcategory', [
          'People may fail to show up the way you need, but God does not abandon His children. His presence is not cancelled by silence, distance, or the absence of human understanding. The Lord sees what others overlook and stays near in places where loneliness tries to speak lies. Even if your emotions do not feel instantly comforted, the truth remains that you are not invisible and not forgotten.',
          'Loneliness often lies by saying that because you feel alone, you truly are alone. But feeling isolated and being abandoned by God are not the same thing. The Lord remains near to the brokenhearted, attentive to the unseen, and faithful in quiet places.',
        ]);
      case 'shame_guilt_after_sin':
      case 'shame_self_condemnation':
      case 'shame_feeling_unworthy':
      case 'shame_regret_over_actions':
        return _rotating('truth_$subcategory', [
          'God deals truthfully with sin and failure, but He does not call you to live forever under unending self-punishment. Confession opens the door to forgiveness, cleansing, and restored fellowship with Him. Grace does not deny what happened, but it does prevent guilt and shame from becoming your permanent dwelling place. The Lord can forgive what is confessed and guide what still needs to be made right.',
          'There is a difference between healthy repentance and living chained to guilt or condemnation. Repentance moves toward God, truth, and change. Shame and self-condemnation often just circle the wound without receiving mercy. The Lord invites you to come honestly, confess clearly, and be cleansed.',
        ]);
      case 'relationship_marriage_conflict':
      case 'relationship_family_tension':
      case 'relationship_friendship_hurt':
      case 'relationship_broken_trust':
      case 'relationship_unresolved_argument':
        return _rotating('truth_$subcategory', [
          'God cares about the condition of your heart in the middle of difficult relationships. He is able to give wisdom where emotions are mixed, restraint where reactions are rising, and clarity where things feel tangled. The Lord can help you walk in truth without losing love, and in love without surrendering truth. He is not absent from relational pain.',
          'When relationships hurt, the temptation is often to either explode, withdraw, or harden. But God can lead you in a better path. He can help you discern what needs to be confronted, what needs to be forgiven, and what needs healthy boundaries. You do not have to let pain drive the whole moment.',
        ]);
      case 'purpose_feeling_lost':
      case 'purpose_no_direction':
      case 'identity_confusion':
      case 'identity_low_self_worth':
      case 'purpose_questioning_purpose':
        return _rotating('truth_$subcategory', [
          'Your life is not random, and your existence is not accidental. God is intentional, and He is able to shape purpose through faithful steps even before the full picture becomes clear. Often purpose is not revealed all at once in a dramatic moment. It is built through obedience, character, service, and trust. The Lord is not confused about your life just because you feel uncertain about it right now.',
          'Feeling uncertain does not mean you are purposeless. It may simply mean you are in a season where God is developing trust, obedience, and clarity over time instead of all at once. Your worth is not suspended until you find the perfect role. The Lord can guide you as you walk.',
        ]);
      case 'temptation_sexual_temptation':
      case 'temptation_to_go_back':
      case 'temptation_to_give_up':
      case 'temptation_to_react_in_anger':
      case 'temptation_to_numb':
        return _rotating('truth_$subcategory', [
          'God is faithful in the middle of temptation, not only after it has passed. The presence of pressure does not mean the absence of help. He is able to strengthen your mind, redirect your steps, and provide a way to stand when your flesh is trying to bargain with compromise. Temptation may be loud, but it is not sovereign.',
          'The enemy loves to make temptation feel inevitable, but Scripture points to God’s faithfulness in the middle of the fight. You do not have to wait until you feel stronger before choosing what is right. Sometimes strength is given while you obey, not before.',
        ]);
      default:
        return _rotating('truth_$subcategory', [
          'God is a present help in trouble, and His help is not limited only to moments that are easy to define. He sees the weight behind your words and understands what feels tangled, unfinished, or hard to explain. You do not have to carry this alone or wait until you can describe it perfectly before bringing it to Him.',
          'The Lord is able to meet you right in the middle of what feels heavy, uncertain, or unresolved. He is not confused by what you feel, and He is not distant from your need. Even when you do not have every answer, God is still near and still able to bring wisdom, comfort, and strength.',
        ]);
    }
  }

  String _nextStep(String subcategory) {
    switch (subcategory) {
      case 'addiction_relapse_thoughts':
        return _rotating('step_$subcategory', [
          'Do not stay alone with this thought and do not treat it like a harmless mental passing moment. Break the momentum early. Change your environment if needed, get away from anything that feeds the urge, and bring the temptation directly to God in prayer. If you have a safe person to contact, reach out now instead of later. Early obedience matters here. The goal is not to prove how strong you are. The goal is to make the wise move before the pressure grows.',
          'Your next step is to interrupt the spiral quickly. Stand up, move, get distance from access, and do not sit still negotiating with the thought. Speak truth out loud if you need to. Remind yourself why you walked away from alcohol in the first place. If there is someone safe you can text or call, do it now. Wisdom acts early.',
        ]);
      case 'addiction_active_relapse':
        return _rotating('step_$subcategory', [
          'Do not hide this and do not minimize it. Bring it to God honestly right now. If there is a trusted person you need to tell, do that quickly. Break the secrecy immediately. Then remove access to whatever keeps this open and take the next practical step that protects you from going deeper tonight. The goal is not to sit in guilt. The goal is to stop the slide, come into the light, and turn fast.',
          'Your next step is immediate honesty and immediate correction. Confess it plainly to God. Do not label it as a small slip if you know it is the beginning of a dangerous turn. Change your environment, cut off access if needed, and do not allow the thought of “I already messed up” to become permission to keep going.',
        ]);
      case 'addiction_cravings':
        return _rotating('step_$subcategory', [
          'Do not sit still and feed the craving with attention. Move. Change your environment. Drink water. Pray out loud. Get away from access. If there is a known trigger nearby, remove yourself from it immediately. Cravings often lose power when they are interrupted early instead of studied and entertained.',
          'Your next step is to break the physical and mental momentum of the craving. Stand up, walk, breathe deeply, and get your focus onto something truthful and immediate. Do not let the urge keep talking without being challenged. If needed, contact someone safe.',
        ]);
      case 'addiction_fear_of_returning':
        return _rotating('step_$subcategory', [
          'Let this fear push you toward wisdom, not panic. Ask yourself what guardrails need strengthening right now. What has gotten loose? Where have you gotten too casual? Tighten the weak places early. Return to what helped keep you steady before. Bring the concern to God directly, and if needed, tell a safe person that you are feeling vulnerable.',
          'Your next step is not to sit and fear the worst. Your next step is to strengthen your protection. Review your weak spots honestly, cut off what is making you careless, and move back toward the habits that help keep you grounded. God often uses clarity like this to wake us up before compromise grows.',
        ]);
      case 'addiction_shame_after_using':
      case 'shame_after_relapse':
        return _rotating('step_$subcategory', [
          'Do not obey the urge to hide. Bring what happened plainly to God, and if there is a safe person you need to tell, do that quickly. Break secrecy before shame gets stronger. Confess clearly, reject self-hatred, and take one practical step that moves you back toward light and safety. The goal is not to pretend the failure was small. The goal is to keep shame from becoming a second trap after the first one.',
          'Your next step is honesty without excuses and honesty without self-destruction. Name what happened. Refuse to keep circling in private condemnation. If you need help, ask for it. If you need boundaries reset, reset them now. Shame will try to keep you stuck in internal punishment, but repentance moves.',
        ]);
      case 'grief_loss_of_loved_one':
      case 'grief_loss_of_pet':
      case 'grief_fresh_loss':
      case 'grief_anniversary_grief':
      case 'grief_with_regret':
        return _rotating('step_$subcategory', [
          'Give yourself permission to grieve honestly before God instead of trying to manage other people’s timelines or expectations. If tears come, let them come. If words are hard, pray what you can. Speak the loss plainly. Remember honestly. Do not isolate in silence if you have a safe person who can listen. Healing does not mean forgetting. It means letting God meet you in the pain instead of burying it.',
          'Your next step is not to force yourself to be fine. Your next step is to be truthful. Tell God what hurts, what you miss, what feels empty, and what still catches you off guard. Take the day in smaller pieces if you need to. Let grief be spoken, prayed, and carried in the open.',
        ]);
      case 'anxiety_panic_spiral':
      case 'anxiety_sleepless_worry':
      case 'anxiety_future_fear':
      case 'anxiety_health_anxiety':
      case 'anxiety_financial_anxiety':
        return _rotating('step_$subcategory', [
          'Slow down your body before trying to solve everything in your mind. Breathe deeply, unclench your hands, and refuse to run ten steps ahead in fear. Bring one thing at a time before God instead of feeding the whole storm at once. If your thoughts are spiraling, write down the specific fear and answer it with truth. You do not need to conquer the whole future tonight. You need the next faithful step.',
          'Do not let anxiety decide the pace of your next move. Pause. Sit still for a minute. Pray specifically instead of vaguely. Name what you fear, then place that exact concern before God. Step away from anything that is intensifying your mind unnecessarily. Return to what is true, present, and in front of you.',
        ]);
      case 'anger_at_person':
      case 'anger_betrayal':
      case 'anger_resentment':
      case 'anger_at_self':
      case 'anger_at_god':
        return _rotating('step_$subcategory', [
          'Pause before you answer anyone. If needed, step away physically for a moment and let your body calm down before your mouth gets ahead of wisdom. Bring the raw feeling to God first. Name what hurt you, what felt unfair, and what you want to do about it. Then ask yourself whether your next words would heal, clarify, or simply wound back. Do not let speed rule this moment.',
          'Your next step is not to win the emotional moment. It is to keep your spirit under control. Slow down, breathe, and refuse to fire off the first thing that comes to mind. If you need time, take time. If you need prayer, stop and pray before speaking.',
        ]);
      case 'loneliness_feeling_unseen':
      case 'loneliness_isolation':
      case 'loneliness_abandonment':
      case 'loneliness_after_breakup':
      case 'loneliness_spiritual_loneliness':
        return _rotating('step_$subcategory', [
          'Do not let loneliness become total isolation. Bring it honestly to God, and if there is one safe person you can reach toward, take that step instead of withdrawing deeper. Tell the truth about how the silence feels. Refuse the lie that because this season feels empty, your life is empty. Let God meet you here, and do not make permanent conclusions from a temporary ache.',
          'Your next step is to speak against the lie of abandonment. Pray honestly. Open the Word. Step toward healthy connection if that is available. Do not just sit in the feeling and let it define the room. Loneliness grows louder in secrecy and passivity. Push back by choosing truth, presence, and one small move toward light.',
        ]);
      case 'shame_guilt_after_sin':
      case 'shame_self_condemnation':
      case 'shame_feeling_unworthy':
      case 'shame_regret_over_actions':
        return _rotating('step_$subcategory', [
          'Take this straight to God without softening it and without exaggerating it. Be honest. Confess what is true. If there is a practical step of repentance or repair you need to make, make it humbly. But stop feeding shame by going in circles without moving toward truth. Let confession become the doorway to cleansing instead of letting regret become a permanent prison.',
          'Your next step is not to crush yourself harder. Your next step is to repent clearly and receive mercy humbly. If you owe an apology, make it. If you need to stop a pattern, stop it. If you need to ask God to clean your conscience, ask boldly. Move in truth, not in endless replay.',
        ]);
      case 'relationship_marriage_conflict':
      case 'relationship_family_tension':
      case 'relationship_friendship_hurt':
      case 'relationship_broken_trust':
      case 'relationship_unresolved_argument':
        return _rotating('step_$subcategory', [
          'Slow down before speaking from hurt. Pray first, then decide whether the next move is a conversation, a boundary, an apology, patience, or simply time. Not every relationship problem should be handled in the first heat of emotion. Let God govern your tone and your timing. If you need to address something, do it clearly and honestly, but not from a place driven by raw reaction.',
          'Your next step is to ask God for wisdom before you choose your words. Decide whether you need to listen more, say less, clarify something, or set a boundary. Relationship pain can push you toward extremes. Resist that. Move toward truth with self-control.',
        ]);
      case 'purpose_feeling_lost':
      case 'purpose_no_direction':
      case 'identity_confusion':
      case 'identity_low_self_worth':
      case 'purpose_questioning_purpose':
        return _rotating('step_$subcategory', [
          'Do not demand the whole picture before taking the next faithful step. Ask God for wisdom about what is in front of you now, then obey there. Purpose often unfolds through consistency, not only through sudden revelation. Stop measuring your life only by what is not clear yet. Look at what God has already placed in your hands and be faithful with that while asking Him to shape the larger picture.',
          'Your next step is to trade panic for faithfulness. Bring your questions honestly to God, but do not freeze while waiting for a grand answer. Serve where you can. Obey what you already know. Stay teachable. Purpose is often lived before it is fully understood.',
        ]);
      case 'temptation_sexual_temptation':
      case 'temptation_to_go_back':
      case 'temptation_to_give_up':
      case 'temptation_to_react_in_anger':
      case 'temptation_to_numb':
        return _rotating('step_$subcategory', [
          'Do not stay close to whatever is feeding the temptation. Create distance fast. Move away from the trigger, change the environment, put the device down, or step out of the room if you need to. Then bring the battle into prayer immediately. Temptation grows when it is entertained. It weakens when it is exposed, interrupted, and answered with obedience in the early stage.',
          'Your next step is not to debate with the urge. Your next step is to cut off its fuel. Act quickly, not dramatically. Remove access, redirect your body, and bring your mind under truth. If the temptation is recurring, stop acting like it is random and start treating it as a real pattern that needs real guardrails.',
        ]);
      default:
        return _rotating('step_$subcategory', [
          'Slow down and bring this before God as honestly as you can. Do not wait for perfect wording. Start with what you know: what feels heavy, what feels unclear, what feels painful, or what feels urgent. Then take one wise next step instead of trying to solve everything at once. God often leads more clearly when the heart becomes honest and the pace becomes slower.',
          'Your next step is to stop carrying this alone in your head. Put words to it before the Lord, even if the words are simple. If there is one practical action you know is wise, take that step calmly. Let honesty, prayer, and truth shape the moment more than pressure or silence.',
        ]);
    }
  }

  String _prayer(String subcategory) {
    switch (subcategory) {
      case 'addiction_relapse_thoughts':
        return _rotating('prayer_$subcategory', [
          'Lord, I bring this temptation to You before it grows any stronger. You know how hard I fought to leave alcohol behind, and You know how serious this feels right now. Strengthen my mind where it feels vulnerable and guard me from agreeing with the lie behind this pull. Help me move quickly toward wisdom, honesty, and safety. Break the power of this thought before it becomes something more. Give me courage to reach for help if I need it, self-control to refuse what is calling me backward, and peace strong enough to steady me in this moment. Keep me from returning to what You already helped me leave. Amen.',
          'Father, these thoughts are trying to pull me backward, and I do not want to give them room. I ask You to quiet the voice of temptation and strengthen the part of me that wants to stay free. Help me not to sit in secrecy, not to test my limits, and not to make light of this battle. Give me wisdom for the next move, power to resist, and clarity to remember exactly why I left this behind. Guard my mind, steady my heart, and surround me with truth stronger than craving. Let this be a moment where I stand, not slide. In Jesus’ name, Amen.',
        ]);
      case 'addiction_active_relapse':
        return _rotating('prayer_$subcategory', [
          'Lord, I come to You honestly because I do not want to hide behind excuses or self-hatred. I have stumbled, and I need Your mercy, Your cleansing, and Your strength right now. Forgive me where I have gone back to what You were helping me leave. Break the power of secrecy over this moment. Help me turn fully instead of sliding deeper. Give me humility to tell the truth, courage to make the hard correction, and wisdom to cut off what is feeding this. Do not let this relapse become a surrender. Restore me, steady me, and help me get back up quickly under Your grace and truth. Amen.',
          'Father, I bring this failure to You plainly. You already see it, and I do not want to cover it or let shame drive me farther from You. Wash me, correct me, and help me turn fully back toward light. Keep me from the lie that says I have already ruined everything. Give me strength to stop now, wisdom to protect myself from going farther, and courage to reach out if I need help. Let repentance be stronger than embarrassment and mercy be stronger than self-condemnation. Rebuild what feels shaken in me and keep this from becoming more than it already has. In Jesus’ name, Amen.',
        ]);
      case 'addiction_cravings':
        return _rotating('prayer_$subcategory', [
          'Lord, this craving feels strong, and I need Your help right now. My body and mind both feel pulled, and I do not want to bow to this urge. Strengthen my self-control, break the intensity of this wave, and help me endure it without surrendering. Remind me that relief is not the same thing as healing and that one bad choice is not the answer my flesh is promising. Give me wisdom to move, to change my environment, and to do what is needed to stay safe. Guard my mind from fixation, my body from acting impulsively, and my heart from agreeing with lies. Carry me through this wave and help me stand until it passes. Amen.',
          'Father, I bring this craving to You honestly because it feels loud and urgent. I ask You to steady my body, quiet my thoughts, and help me not to act out of pressure. Keep me from treating this like something harmless or manageable in my own strength. Show me the wise move to make right now and give me power to do it quickly. Help me outlast the craving without romanticizing it, without feeding it, and without surrendering to it. Let Your presence be stronger than the pressure I feel, and let this moment end in obedience, not regret. In Jesus’ name, Amen.',
        ]);
      case 'addiction_fear_of_returning':
        return _rotating('prayer_$subcategory', [
          'Lord, I know what it cost me before, and I do not want to go back. You see the fear in me that comes from remembering how destructive that road can be. I ask You to use this awareness for wisdom, not panic. Keep me alert without making me hopeless. Show me where I have gotten too casual, too isolated, or too vulnerable. Strengthen the weak places, restore the right boundaries, and help me stay close to truth. Guard me from both pride and despair. Teach me to walk carefully, honestly, and dependently with You. Keep me from returning to what You have already helped me leave. Amen.',
          'Father, I bring this fear of going backward to You because I know I cannot trust carelessness. Help me not to ignore warning signs and not to collapse under them either. Give me discernment to see what needs attention, humility to make corrections, and courage to tell the truth if I am feeling vulnerable. Keep me close to You, grounded in truth, and protected from the lies that try to make old chains feel familiar or safe. Strengthen me where I feel exposed, and let this concern move me toward deeper wisdom and steadier obedience. In Jesus’ name, Amen.',
        ]);
      case 'addiction_shame_after_using':
      case 'shame_after_relapse':
        return _rotating('prayer_$subcategory', [
          'Lord, I bring this shame to You because it is sitting heavy on me, and I do not want to stay buried under it. You know what happened, You know how I feel, and You know how quickly my mind wants to turn this into a story about worthlessness and defeat. I ask You to forgive me, cleanse me, and break the power of condemnation over this moment. Help me confess honestly without hiding and repent genuinely without sinking into self-hatred. Give me courage to come into the light, wisdom to make the needed correction, and mercy strong enough to reach the places shame keeps accusing. Restore what feels bent low in me, and lead me back into truth. Amen.',
          'Father, shame is speaking loudly right now, and I need Your voice to be louder. I do not want to stay hidden, numb, or crushed under what happened. Wash me, steady me, and help me tell the truth without collapsing into despair. Keep me from calling myself what You have not called me. Show me the next right step, the correction I need, and the light I need to move toward. Let repentance be real, but do not let condemnation rule me. Pull me out of secrecy, out of self-hatred, and back under Your mercy and truth. In Jesus’ name, Amen.',
        ]);
      case 'grief_loss_of_loved_one':
      case 'grief_loss_of_pet':
      case 'grief_fresh_loss':
      case 'grief_anniversary_grief':
      case 'grief_with_regret':
        return _rotating('prayer_$subcategory', [
          'Lord, this loss hurts, and I bring that pain to You without pretending it is smaller than it is. You know the love behind this grief, the memories tied to it, and the emptiness that shows up in quiet moments. Comfort my heart where it feels tender and worn down. Be near to me in the waves of sorrow, in the reminders, and in the moments when the absence feels especially sharp. Help me not to carry this alone or hide it behind a false strength. Hold me together while I mourn, and let Your presence be real even when my emotions are heavy. Give me grace for today and peace for the next step. Amen.',
          'Father, I ask You to meet me in this grief with tenderness and strength. You see what I have lost, what I miss, and what still aches in ways I cannot fully put into words. Stay close to me when memories rise, when tears come, and when the room feels too quiet. Help me grieve honestly without losing hope in Your presence. Remind me that sorrow does not mean You have left me. Carry me through the heavy moments, steady my heart when it feels weak, and let Your comfort reach the places inside me that feel wounded and raw. Walk with me one day at a time through this loss. Amen.',
        ]);
      case 'anxiety_panic_spiral':
      case 'anxiety_sleepless_worry':
      case 'anxiety_future_fear':
      case 'anxiety_health_anxiety':
      case 'anxiety_financial_anxiety':
        return _rotating('prayer_$subcategory', [
          'Lord, my mind feels crowded and my heart feels unsettled, and I need Your peace right now. Quiet what is racing inside me. Help me stop living ten steps ahead in fear and come back to Your presence in this moment. I give You the concerns I cannot control, the outcomes I cannot predict, and the pressure I keep trying to carry by myself. Guard my thoughts from spiraling, calm my body, and teach me to trust You more than my anxious imagination. Let Your truth speak louder than fear, and let Your peace steady me where I feel shaken. Hold me together, Lord, and help me rest in You. Amen.',
          'Father, You see how fast my thoughts have been moving and how hard it has been to settle down. I ask You to interrupt the panic, quiet the noise in my mind, and breathe peace into the places where I feel tense and overwhelmed. Help me trust You with what I cannot fix tonight. Keep me from letting fear write the story before You have spoken. Give me wisdom for the next step, peace for this hour, and a sound mind anchored in Your presence. Remind me that I do not face uncertainty alone. You are here, and You are greater than what I feel right now. Amen.',
        ]);
      case 'anger_at_person':
      case 'anger_betrayal':
      case 'anger_resentment':
      case 'anger_at_self':
      case 'anger_at_god':
        return _rotating('prayer_$subcategory', [
          'Lord, You see how stirred up I am, and I do not want anger to rule me. Something in me feels hot, wounded, and ready to react, but I ask You to steady my spirit before I speak or act in a way that brings damage. Show me what is true in this situation and what needs restraint in me. Guard my mouth, govern my tone, and keep my thoughts from running into revenge, pride, or harshness. Help me respond with wisdom, courage, and self-control. If I need to confront something, let me do it clearly and rightly. If I need to wait, give me patience. Rule my heart, Lord, and keep anger from leading me into sin. Amen.',
          'Father, I bring this anger to You because I know how quickly it can push me in the wrong direction. I do not want to be mastered by what I feel. Calm the heat in me, expose anything sinful growing underneath it, and help me walk in truth without losing control. Give me a clean heart, a steady mind, and restrained words. Let me be strong enough to pause, wise enough to listen, and humble enough to be corrected if I need it. Keep me from saying what should not be said and from wounding others just because I am wounded. Lead me in righteousness and peace right here. Amen.',
        ]);
      case 'loneliness_feeling_unseen':
      case 'loneliness_isolation':
      case 'loneliness_abandonment':
      case 'loneliness_after_breakup':
      case 'loneliness_spiritual_loneliness':
        return _rotating('prayer_$subcategory', [
          'Lord, You see the ache in me that words do not always capture. You know what it feels like to be surrounded by people and still feel alone, or to sit in silence and wonder whether anyone really sees the weight I am carrying. I ask You to draw near to me in this place. Remind me that I am not forgotten, not invisible, and not abandoned by You. Strengthen my heart where loneliness has made it tired. Guard me from lies that try to define my worth by who has or has not shown up. Bring comfort, nearness, and healthy connection into my life, and help me stay open to Your presence. Amen.',
          'Father, I bring this loneliness to You because it is heavier than I want it to be. Some parts of this pain feel quiet on the outside but deep on the inside. Meet me where I feel unseen. Comfort me where I feel disconnected. Keep me from interpreting silence as abandonment or distance as proof that I do not matter. Help me remember that You stay near, even in places where my emotions feel empty. Give me courage to be honest, wisdom to seek healthy connection, and peace that does not depend entirely on what other people do. Let Your presence fill the spaces that feel especially empty right now. Amen.',
        ]);
      case 'shame_guilt_after_sin':
      case 'shame_self_condemnation':
      case 'shame_feeling_unworthy':
      case 'shame_regret_over_actions':
        return _rotating('prayer_$subcategory', [
          'Lord, I bring my guilt and shame to You because they have been weighing on me heavily. You know what happened, what I regret, and what keeps replaying in my mind. I do not want to hide, excuse, or harden myself. I ask You to forgive me where I have sinned, correct me where I need to change, and cleanse my conscience where guilt has been sitting like a stone. Show me any step of repentance or restoration I need to take, and give me humility to take it. But also keep me from living under endless self-punishment when You are offering mercy. Wash me, steady me, and help me walk forward in truth. Amen.',
          'Father, shame has been speaking loudly, and I need Your voice to be louder. Remind me that confession leads to cleansing, not rejection. Help me stop hiding, stop rehearsing lies, and stop agreeing with every accusation that rises in my mind. If I need to repent, give me humility. If I need to make things right, give me courage. But do not let shame drive me farther from You. Cover me with mercy, strengthen me with truth, and restore the parts of my heart that have been bowed low. Let grace reshape what shame has tried to define. In Jesus’ name, Amen.',
        ]);
      case 'relationship_marriage_conflict':
      case 'relationship_family_tension':
      case 'relationship_friendship_hurt':
      case 'relationship_broken_trust':
      case 'relationship_unresolved_argument':
        return _rotating('prayer_$subcategory', [
          'Lord, You see the pain and tension in this relationship, and I need Your wisdom more than my own emotion right now. Guard my mouth from saying what would deepen the wound. Guard my heart from bitterness, pride, fear, and reaction. Show me what is true, what is mine to own, and what is mine to release to You. If I need to speak, help me speak clearly and with grace. If I need to wait, help me wait without hardening my heart. If I need to set a boundary, give me courage and steadiness. Lead me in truth and love together, and do not let pain become my guide. Amen.',
          'Father, I bring this relationship before You because it is affecting my heart more than I want to admit. You know the strain, the hurt, the frustration, and the confusion that can come with people I care about. I ask You to give me wisdom for my next step, restraint over my emotions, and peace that does not depend on perfect outcomes. Help me respond in a way that honors You. Keep me from exploding, manipulating, withdrawing wrongly, or becoming bitter. Heal what can be healed, expose what must be faced, and strengthen me where this has left me tired. Lead me with clarity, humility, and truth. Amen.',
        ]);
      case 'purpose_feeling_lost':
      case 'purpose_no_direction':
      case 'identity_confusion':
      case 'identity_low_self_worth':
      case 'purpose_questioning_purpose':
        return _rotating('prayer_$subcategory', [
          'Lord, I bring You my questions about purpose, direction, identity, and why I am here. Sometimes I want more clarity than I have, and that uncertainty can feel heavy on my heart. I ask You to steady me where I feel unsettled and guide me where I feel unsure. Help me not to measure my worth by confusion or delay. Teach me to be faithful in what is in front of me while You unfold what I cannot yet see. Give me wisdom for the next step, humility to follow You, and patience when answers do not arrive quickly. Shape my life for Your glory and keep me from wasting energy on fear when I could be walking in trust. Amen.',
          'Father, You made me on purpose, and I ask You to help me live with that confidence even when my path does not feel fully clear. Keep me from comparing my timeline to everyone else around me. Guard me from feeling useless or forgotten just because I do not see the whole plan yet. Lead me one step at a time. Show me what obedience looks like in this season, and let faithfulness become more important than panic. Open the right doors, close the wrong ones, and form my character while You direct my future. Let my life be rooted in Your will and not in fear of missing it. Amen.',
        ]);
      case 'temptation_sexual_temptation':
      case 'temptation_to_go_back':
      case 'temptation_to_give_up':
      case 'temptation_to_react_in_anger':
      case 'temptation_to_numb':
        return _rotating('prayer_$subcategory', [
          'Lord, I need strength in this moment because temptation is pressing on me, and I do not want to give it ground. You know where I am vulnerable, where I get tired, and where my flesh tries to pull me away from wisdom and obedience. Help me refuse compromise while it is still in the thought stage. Give me clarity to see the lie, courage to move away from the trigger, and self-control to choose what honors You. Guard my eyes, my mind, my body, and my decisions. Keep me from secrecy and from bargaining with what I already know is dangerous. Let Your Spirit be stronger in me than the pull I feel right now. Amen.',
          'Father, I bring this temptation to You before it becomes something heavier. Strengthen my will, steady my thoughts, and expose anything in me that is trying to make peace with compromise. Help me resist quickly instead of lingering near what is pulling at me. Give me wisdom to put real boundaries in place and humility to seek help if I need it. Do not let this pressure become permission. Lead me away from what feeds the flesh and deeper into what keeps my spirit awake and clean. Let obedience come faster than excuse, and let Your truth have the final word over this battle. Amen.',
        ]);
      default:
        return _rotating('prayer_$subcategory', [
          'Lord, You know what is sitting on my heart, even the parts I cannot fully explain yet. I bring it to You honestly and ask for Your help, Your wisdom, and Your peace. Meet me in what feels heavy, unresolved, or difficult to sort through. Guard me from panic, isolation, and confusion. Help me slow down enough to hear Your truth and follow Your leading. Strengthen me where I feel weak, comfort me where I feel burdened, and guide me where I do not know what to do next. Thank You that I do not have to carry this alone. Stay close to me and help me take the next faithful step. Amen.',
          'Father, I place this moment before You because I need Your presence more than my own understanding. You see what is clear to me and what is not. You know what hurts, what confuses me, and what has been weighing on my mind. I ask You to settle my heart, sharpen my discernment, and guide my next step. Keep me from rushing, from shutting down, and from carrying this in isolation. Let Your peace steady me, Your truth lead me, and Your strength hold me up where I feel tired. Help me trust You with what I cannot yet fix and obey You in what I already know. Amen.',
        ]);
    }
  }

  Map<String, dynamic> buildResponse(String text) {
    final subcategory = detectSubcategory(text);
    final category = categoryFromSubcategory(subcategory);

    return {
      'category': category,
      'subcategory': subcategory,
      'acknowledge': _acknowledge(subcategory),
      'truth': _truth(subcategory),
      'scripture': _verses(subcategory),
      'nextStep': _nextStep(subcategory),
      'prayer': _prayer(subcategory),
    };
  }

  void armorUp() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      response = buildResponse(text);
    });
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFF7A00),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget responseCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2D2D2D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(title),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speakLabel = _isLaunchingDictation ? 'Starting...' : 'Speak';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cornerstone'),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFFFF7A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speak what is on your heart',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click the speak button or type what’s on your heart. Cornerstone provides a response grounded in biblical truth, Scripture, encouragement, and prayer.',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                focusNode: _textFocusNode,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText:
                      "Example: I quit drinking and I'm starting to think about alcohol again.",
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _startWindowsDictation,
                  icon: const Icon(Icons.mic_none),
                  label: Text(speakLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFFF7A00), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: const Color(0xFF111111),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: armorUp,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Armor Up',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (response != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Category: ${response!['category']}',
                  style: const TextStyle(
                    color: Color(0xFFFFB066),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subcategory: ${friendlySubcategory(response!['subcategory'] as String)}',
                  style: const TextStyle(
                    color: Color(0xFFFFB066),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                responseCard('Acknowledge', response!['acknowledge'] as String),
                responseCard('Biblical Truth', response!['truth'] as String),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2D2D2D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle('Scripture'),
                      ...(response!['scripture'] as List<Map<String, String>>)
                          .map(
                        (verse) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                verse['ref'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                verse['text'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                responseCard('Next Step', response!['nextStep'] as String),
                responseCard('Prayer', response!['prayer'] as String),
              ],
            ],
          ),
        ),
      ),
    );
  }
}