import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
    _controller.clear();
    _textFocusNode.requestFocus();
    _controller.selection = TextSelection.fromPosition(
      const TextPosition(offset: 0),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap your keyboard microphone to speak'),
      ),
    );
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
          'God does not rush mourners, shame tears, or demand that sorrow disappear on command. He draws near to the brokenhearted, and His nearness is not cancelled by your pain. Grief may make life feel unfamiliar for a while, but the Lord is still present in it. He is not offended by your tears, and He is not absent in the ache. Mourning can coexist with faith. Sorrow can coexist with His nearness. The pain matters, and so does the God who stays close inside it.',
          'Grief does not mean God has stepped away. It often means love has been wounded by loss, and the Lord meets wounded hearts with tenderness, not impatience. He is able to comfort without mocking the weight of what happened. He can hold you through the ache, through the missing, and through the memories. You do not have to force yourself into false strength to be spiritual. The Lord is still kind in sorrow, still near in mourning, and still faithful when the heart feels bruised.',
        ]);
      case 'anxiety_panic_spiral':
      case 'anxiety_sleepless_worry':
      case 'anxiety_future_fear':
      case 'anxiety_health_anxiety':
      case 'anxiety_financial_anxiety':
        return _rotating('truth_$subcategory', [
          'Fear can feel loud, but it is not automatically truthful. Anxiety often asks your heart to carry tomorrow’s weight in today’s body. God does not call you to deny that the pressure feels real. He calls you to bring it to Him instead of letting it rule you. His presence is still steady when your thoughts are not. He is able to calm what feels crowded inside you and help you return to what is true, one moment at a time.',
          'Anxiety makes urgent promises it cannot keep. It tells you that more fear will somehow produce more control, but it only drains peace while solving nothing. God offers something different. He offers Himself in the middle of uncertainty. He is not asking you to manufacture peace out of thin air. He is inviting you to hand over what is pressing on you and trust that His steadiness is stronger than your spiral.',
        ]);
      case 'anger_at_person':
      case 'anger_betrayal':
      case 'anger_resentment':
      case 'anger_at_self':
      case 'anger_at_god':
        return _rotating('truth_$subcategory', [
          'Anger can reveal that something in you feels wounded, crossed, or deeply burdened, but it is a dangerous master when it starts deciding your words and actions. God does not ask you to pretend the pain is not real. He does call you to bring the fire under His truth before it spreads into sin. He is able to help you slow down, speak carefully, and refuse to let raw emotion become destructive leadership inside you.',
          'Strong anger does not have to become sinful surrender. The Lord sees what hurt you, what frustrated you, or what feels deeply unfair, and He is not blind to it. But He is also wise enough to keep you from becoming captive to your own reaction. God can help you respond in a way that is honest without being destructive, firm without being flesh-led, and truthful without becoming toxic.',
        ]);
      case 'loneliness_feeling_unseen':
      case 'loneliness_isolation':
      case 'loneliness_abandonment':
      case 'loneliness_after_breakup':
      case 'loneliness_spiritual_loneliness':
        return _rotating('truth_$subcategory', [
          'Loneliness can make it feel like you are carrying life without witness, comfort, or closeness, but the absence of human warmth does not mean the absence of God. The Lord is able to be near even when your emotions are slow to sense it. He is not casual about the ache of isolation. He sees it fully. His presence does not erase the need for connection, but it does mean you are not abandoned in the deeper sense of the word.',
          'The ache of loneliness is real, but it is not final truth about your worth or your future. Feeling unseen by people does not mean you are unseen by God. He has not lost track of you, forgotten you, or stepped around your pain. He knows how to meet a lonely heart with steadiness and comfort, and He can also lead you toward healthy connection in His timing. Loneliness speaks loudly, but it does not get the final word.',
        ]);
      case 'shame_guilt_after_sin':
      case 'shame_self_condemnation':
      case 'shame_feeling_unworthy':
      case 'shame_regret_over_actions':
        return _rotating('truth_$subcategory', [
          'Conviction from God is meant to bring you into repentance and cleansing, not trap you in endless self-condemnation. Shame wants you staring at yourself without hope. God calls you to look at your sin honestly and then come to Him for mercy, forgiveness, and renewal. He does not excuse sin, but He also does not demand that you remain crushed under it as though grace were for everyone else but you.',
          'Feelings of guilt and shame may be loud, but they are not meant to become your identity. The Lord is able to forgive, restore, correct, and cleanse what is brought honestly into the light. There is a difference between repentance that turns you toward God and condemnation that locks you inside despair. God is not asking you to agree with every cruel thing your mind says about you. He is calling you back to truth and mercy.',
        ]);
      case 'relationship_marriage_conflict':
      case 'relationship_family_tension':
      case 'relationship_friendship_hurt':
      case 'relationship_broken_trust':
      case 'relationship_unresolved_argument':
        return _rotating('truth_$subcategory', [
          'Relationship pain can quickly tempt the heart toward pride, harshness, withdrawal, or hopelessness, but God is able to guide you in a better spirit than the wound alone would produce. He can help you speak truth without cruelty, set boundaries without bitterness, and pursue peace without pretending the pain is not real. The Lord cares about how you carry hurt, not just the fact that you were hurt.',
          'Conflict can cloud judgment because pain and reaction get loud quickly. God offers clarity in the middle of that noise. He is able to help you respond with wisdom, humility, and steadiness instead of letting emotion write the whole script. Even when the relationship feels strained, messy, or uncertain, the Lord can lead you into what is honest, healthy, and faithful.',
        ]);
      case 'purpose_feeling_lost':
      case 'purpose_no_direction':
      case 'identity_confusion':
      case 'identity_low_self_worth':
      case 'purpose_questioning_purpose':
        return _rotating('truth_$subcategory', [
          'Confusion about direction or identity does not mean your life is without value or that God is absent from the process. The Lord is not scrambling just because you feel unsure. He is able to guide slowly, clarify faithfully, and anchor your worth in something deeper than productivity, applause, or immediate certainty. You do not have to solve your whole future in one moment to still be held by God today.',
          'Questions about purpose can feel urgent, but your worth is not suspended until you figure everything out. God does not need you to have your entire path mapped before He can lead you. He is able to shepherd uncertain people, strengthen tired hearts, and give direction one faithful step at a time. Confusion may be present, but it does not cancel God’s involvement in your life.',
        ]);
      case 'temptation_sexual_temptation':
      case 'temptation_to_go_back':
      case 'temptation_to_give_up':
      case 'temptation_to_react_in_anger':
      case 'temptation_to_numb':
        return _rotating('truth_$subcategory', [
          'Temptation becomes dangerous when it is treated like destiny. Feeling pulled does not mean you have already lost the fight. God is faithful in temptation, able to expose the lie inside it and provide strength to resist it. The moment may feel urgent, but urgency is not authority. The Lord can help you step away, slow down, and refuse what your flesh is trying to sell as relief, release, or permission.',
          'The enemy often works through suggestion before he ever gets agreement. That is why temptation must be answered quickly and truthfully. You are not helpless just because the pull feels real. God can strengthen your mind, interrupt the momentum, and remind you that obedience is still possible in the very moment temptation is trying to feel inevitable. The pressure may be real, but so is the faithfulness of God.',
        ]);
      default:
        return _rotating('truth_$subcategory', [
          'Whatever this burden is, God is not absent from it. He is able to meet you in places that feel unclear, heavy, or difficult to explain. You do not need to have perfect words before He can respond with wisdom, steadiness, and help. The Lord is still near, still truthful, and still strong where you feel uncertain. He is not waiting for you to be less burdened before He becomes present.',
          'The Lord is able to bring clarity where things feel tangled, peace where things feel noisy, and strength where things feel thin. Even if this moment feels hard to define, God already understands it fully. He is not limited by your inability to explain everything. He can still guide, comfort, correct, and uphold you in what feels unresolved.',
        ]);
    }
  }

  String _nextStep(String subcategory) {
    switch (subcategory) {
      case 'addiction_relapse_thoughts':
        return _rotating('next_$subcategory', [
          'Do not sit with this thought and try to overpower it quietly. Interrupt it. Put distance between you and anything that feeds it. Say out loud that you are being tempted, text someone safe if you need to, and change the environment immediately. Then pray honestly, not vaguely. Treat this like a real battle because it is one.',
          'Move quickly instead of negotiating with the urge. Step away from isolation, remove yourself from triggers, and put something truthful in front of your mind right now. Read Scripture, pray aloud, or contact someone who knows your fight. The next right step is not to test your strength. It is to take the thought seriously and cut off its path forward.',
        ]);
      case 'addiction_active_relapse':
        return _rotating('next_$subcategory', [
          'Tell the truth quickly. Do not let this become a secret that grows. Remove whatever remains from reach, get honest with God, and reach out to a trusted person if that is available to you. This is not the time to spiral alone. The next right move is immediate honesty and immediate interruption of the cycle.',
          'Respond fast instead of hiding. Confess what happened to God plainly, cut off access to what fed it, and put yourself back in the light. Do one honest action right now that breaks agreement with secrecy. The goal is not to act like nothing happened. The goal is to stop one fall from becoming a deeper slide.',
        ]);
      case 'addiction_cravings':
        return _rotating('next_$subcategory', [
          'Treat this craving like a wave that must be survived, not obeyed. Change your environment, drink water, go where you are less isolated, and refuse to sit alone with the urge if you can avoid it. Put words to the truth: this is a craving, not a command. Then keep moving until the intensity drops.',
          'Do something immediate that breaks the momentum. Stand up, move rooms, step outside, pray out loud, and put distance between yourself and anything that makes the urge easier to act on. The next step is not deep reflection. It is quick disruption, honest prayer, and refusing to let the craving quietly lead the moment.',
        ]);
      case 'addiction_fear_of_returning':
        return _rotating('next_$subcategory', [
          'Use this fear as a cue to tighten what has become loose. Review your triggers, be honest about weak spots, and strengthen your boundaries before the pressure gets stronger. The next faithful step is not panic. It is sober watchfulness and practical honesty.',
          'Instead of just worrying about going back, do one concrete thing that protects you from it. Remove access, avoid the place, reset the routine, or reconnect with someone who helps keep you accountable. Let concern move you toward wisdom, not just fear.',
        ]);
      case 'addiction_shame_after_using':
      case 'shame_after_relapse':
        return _rotating('next_$subcategory', [
          'Refuse to let shame become the voice you listen to next. Confess honestly, reject secrecy, and take one action that agrees with truth instead of hiding. Shame wants stillness and silence. Break that agreement by coming into the light immediately.',
          'Do not spend the next hour calling yourself names. Bring the failure honestly to God, clean up whatever needs to be cleaned up practically, and move toward truth instead of hiding behind shame. The next step is not self-punishment. It is humble repentance and fast re-entry into the light.',
        ]);
      case 'grief_loss_of_loved_one':
      case 'grief_loss_of_pet':
      case 'grief_fresh_loss':
      case 'grief_anniversary_grief':
      case 'grief_with_regret':
        return _rotating('next_$subcategory', [
          'Give this grief honest space today instead of forcing yourself to act untouched. Pray plainly, let yourself feel what is there, and do one gentle thing that steadies you rather than drains you. The next step is not to rush your heart. It is to let truth and tenderness coexist.',
          'Slow down enough to be honest about what this loss is stirring. Speak to God directly, resist the urge to numb the ache, and choose one grounding act of care today. That may be rest, a walk, journaling, or quiet prayer. The next right step is gentleness with truth, not pressure to be unaffected.',
        ]);
      case 'anxiety_panic_spiral':
        return _rotating('next_$subcategory', [
          'Slow the moment down on purpose. Breathe, sit down if needed, and name what is actually true right now instead of everything fear is projecting. Do not keep feeding the spiral with more imagined outcomes. Bring one clear request to God and take the next small step, not all ten future ones at once.',
          'Interrupt the spiral physically and mentally. Stop pacing if you are pacing, unclench what you can unclench, and say out loud what is real in this moment. Then pray specifically instead of generically. The next step is to shrink the frame back down to what is actually in front of you right now.',
        ]);
      case 'anxiety_sleepless_worry':
        return _rotating('next_$subcategory', [
          'Do not let the whole night become a courtroom for your fears. Put the concern into a simple prayer, write it down if needed, and stop trying to mentally solve everything in the dark. The next step is to hand over what you cannot resolve tonight and let your body be still.',
          'When worry keeps the night awake, stop rehearsing the fear and turn toward God deliberately. Pray plainly, release what you cannot fix before morning, and choose calm input instead of more mental pressure. Your next step is not perfect sleep on command. It is refusing to keep feeding the worry cycle.',
        ]);
      case 'anxiety_future_fear':
        return _rotating('next_$subcategory', [
          'Pull your mind back from tomorrow and return it to today. Name one thing you actually need to do now and do only that. The next step is not to mentally live in five futures at once. It is to trust God with what is not here yet and obey Him in what is already in front of you.',
          'Stop trying to carry what has not arrived. Pray honestly about the future fear, then narrow your focus to one faithful next move. God gives grace for the moment you are in, not for every imagined outcome all at once. Let the next step be small, real, and grounded.',
        ]);
      case 'anxiety_health_anxiety':
        return _rotating('next_$subcategory', [
          'Do not let every thought become an alarm. If something practical needs to be handled, handle that practically. But the next step right now is to stop feeding panic with constant mental escalation. Pray clearly, breathe, and refuse to let fear narrate every sensation.',
          'Separate what is actually known from what fear is inventing. If there is a real step to take, take it wisely. But do not keep spiraling in the uncertainty. The next step is grounded action where needed and deliberate surrender where panic is trying to take over.',
        ]);
      case 'anxiety_financial_anxiety':
        return _rotating('next_$subcategory', [
          'Bring the money fear into the light with both prayer and honesty. Look clearly at what is real, not what panic is exaggerating, and take one practical step instead of drowning in the whole weight at once. God’s faithfulness is not blocked by your uncertainty.',
          'Do one concrete thing today that agrees with wisdom rather than fear. Review what is true, make the call, set the budget, ask the question, or take the next responsible step. Then hand the rest to God instead of trying to carry it all mentally by force.',
        ]);
      case 'anger_at_person':
      case 'anger_betrayal':
      case 'anger_resentment':
      case 'anger_at_self':
      case 'anger_at_god':
        return _rotating('next_$subcategory', [
          'Do not answer the heat with immediate words. Slow down before you speak, type, text, or confront. The next step is restraint first, clarity second. Bring the anger to God honestly, then decide your next move from a steadier place than the first emotional surge.',
          'Create a pause before reaction. Step back, breathe, pray, and refuse to let the first wave of anger pick your words for you. The next right step is not pretending you are fine. It is choosing self-control before the situation becomes more damaged by what comes out of your mouth.',
        ]);
      case 'loneliness_feeling_unseen':
      case 'loneliness_isolation':
      case 'loneliness_abandonment':
      case 'loneliness_after_breakup':
      case 'loneliness_spiritual_loneliness':
        return _rotating('next_$subcategory', [
          'Do not let loneliness keep you folded inward if there is any healthy way to step toward connection. Pray honestly, resist isolating even further, and choose one grounding act that reminds you you are not forgotten. The next step may be small, but let it move toward truth, not deeper retreat.',
          'Name the loneliness without agreeing with every lie it wants to attach to you. Then do one thing that breaks total isolation. Reach out, step outside, pray aloud, or put yourself in a healthier environment. The next step is not to wait until you feel less lonely to act. It is to act in a way that refuses loneliness full control.',
        ]);
      case 'shame_guilt_after_sin':
      case 'shame_self_condemnation':
      case 'shame_feeling_unworthy':
      case 'shame_regret_over_actions':
        return _rotating('next_$subcategory', [
          'Bring the issue plainly before God instead of circling it inside your head. Confess honestly, reject self-condemnation, and take one step that agrees with repentance rather than hiding. The next step is not endless self-accusation. It is truth, humility, and turning back toward the Lord.',
          'Stop replaying the failure as though punishing yourself longer will cleanse it. Bring it into the light. Pray specifically, confess where needed, and choose one obedient action that reflects repentance. The next step is not to make yourself feel worse. It is to come honestly to God and let grace lead the response.',
        ]);
      case 'relationship_marriage_conflict':
      case 'relationship_family_tension':
      case 'relationship_friendship_hurt':
      case 'relationship_broken_trust':
      case 'relationship_unresolved_argument':
        return _rotating('next_$subcategory', [
          'Before trying to fix the whole relationship, slow your own spirit down. Pray first, speak second. Decide that your next words will be truthful but not reckless. The next step may be a conversation, a boundary, or a pause, but let it come from wisdom rather than reaction.',
          'Choose one relational step that agrees with truth and self-control. That may mean apologizing, clarifying, pausing, setting a boundary, or refusing another useless argument. The next step is not to let pain run wild. It is to walk carefully, honestly, and without adding needless damage.',
        ]);
      case 'purpose_feeling_lost':
      case 'purpose_no_direction':
      case 'identity_confusion':
      case 'identity_low_self_worth':
      case 'purpose_questioning_purpose':
        return _rotating('next_$subcategory', [
          'Stop demanding a full map before you take a faithful step. Ask God for clarity, then focus on what you already know is right to do today. The next step is not solving your entire future tonight. It is obeying clearly in the next thing in front of you.',
          'When purpose feels blurry, return to what is solid. Pray, slow down, and do the next faithful thing rather than chasing total clarity all at once. God often leads step by step. The next move is grounded obedience, not frantic self-definition.',
        ]);
      case 'temptation_sexual_temptation':
      case 'temptation_to_go_back':
      case 'temptation_to_give_up':
      case 'temptation_to_react_in_anger':
      case 'temptation_to_numb':
        return _rotating('next_$subcategory', [
          'Interrupt the momentum immediately. Do not keep entertaining what is pulling at you. Move, shut it down, step away, pray aloud, and create distance from whatever is feeding the temptation. The next step is quick refusal, not prolonged negotiation.',
          'Treat this temptation like something that grows if you keep staring at it. Break the agreement now. Change the environment, pray specifically, and choose the action that makes obedience easier, not harder. The next step is decisive resistance, not passive hope.',
        ]);
      default:
        return _rotating('next_$subcategory', [
          'Take one honest step toward God and one practical step toward steadiness. Do not stay frozen in the weight of the whole thing. The next step does not have to solve everything. It just needs to be faithful, truthful, and grounded.',
          'Slow down enough to pray clearly and act wisely. You do not need a perfect plan right now. You need the next right step. Let that step be honest, calm, and aligned with what you already know is true.',
        ]);
    }
  }

  String _prayer(String subcategory) {
    switch (subcategory) {
      case 'addiction_relapse_thoughts':
        return _rotating('prayer_$subcategory', [
          'Lord, You see this battle before it becomes anything more, and I need Your help right now. The thoughts have come back, and I do not want to quietly drift toward what once had a grip on me. Strengthen my mind, steady my will, and help me resist before this grows stronger. Expose every lie that tries to make alcohol look harmless or comforting. Remind me what You have already brought me out of. Give me courage to be honest, wisdom to avoid what feeds this temptation, and strength to choose obedience over impulse. Keep me sober, alert, and close to You in this moment. Amen.',
          'Father, I bring this temptation to You honestly because I do not want to play with it in secret. You know the pull I feel, and You know the cost of going back. Guard my mind right now. Break the glamour of the old life and remind me clearly why I left it. Help me choose what is true over what feels familiar. Give me the strength to interrupt this thought, the humility to reach for help if I need it, and the wisdom to avoid every trigger that feeds this battle. Hold me steady, Lord, and do not let this thought become agreement. Amen.',
        ]);
      case 'addiction_active_relapse':
        return _rotating('prayer_$subcategory', [
          'God, I am bringing this to You honestly because I do not want to hide in shame after falling. You see exactly what happened, and I ask You for mercy, forgiveness, and strength to respond rightly right now. Cleanse what has been defiled, break the secrecy that tries to grow after failure, and keep this from becoming a deeper pattern. Help me tell the truth, cut off access to what feeds this, and step back into the light quickly. Do not let despair speak louder than Your grace. Restore what was shaken, strengthen what is weak, and help me stand again in truth. Amen.',
          'Lord, I confess this failure to You plainly. I cannot undo what happened, but I do not want to keep moving in the wrong direction. Have mercy on me, forgive me, and help me turn quickly instead of hiding behind shame. Break the power of secrecy, expose the lie that tells me there is no way back, and strengthen me to take the next right step immediately. Give me wisdom to remove what fed this relapse and courage to be honest where honesty is needed. Wash me, steady me, and keep this moment from becoming a bigger fall. Amen.',
        ]);
      case 'addiction_cravings':
        return _rotating('prayer_$subcategory', [
          'Father, this craving feels strong, and I need Your strength in a way that is immediate and real. My flesh is loud right now, but I ask You to remind me that this urge is not my master. Help me endure this wave without obeying it. Steady my thoughts, strengthen my self-control, and remove the false promise that relief is found in going backward. Give me wisdom to change my environment, honesty to name the battle, and power to keep saying no until the pressure passes. Be my refuge in this moment and keep me from surrendering to what once ruled me. Amen.',
          'Lord, You see how forcefully this craving is pressing on me, and I am asking for help before it carries me any further. Give me a sound mind right now. Help me interrupt the momentum, resist the lie of quick relief, and remember the damage that compromise always brings. Strengthen me to move away from what feeds this battle and toward what keeps me anchored in truth. Let Your presence be stronger than the urge, and let obedience come quicker than impulse. Hold me up while this passes, and do not let me bow to what is shouting at me. Amen.',
        ]);
      case 'addiction_fear_of_returning':
        return _rotating('prayer_$subcategory', [
          'Lord, I do not want to go back, and the fear of returning feels heavy on me. Thank You for making me aware that this battle is real, but do not let fear turn into despair. Make me watchful without making me hopeless. Strengthen my discernment, tighten my boundaries, and help me stay honest about where I am weak. Keep me alert, sober, and dependent on You instead of confident in myself. Show me where I have become careless and help me correct it quickly. Guard my steps, keep me in the light, and do not let my past become my future again. Amen.',
          'Father, I bring this fear to You because I know what it cost to come out of that old life, and I do not want to return to it. Help me walk carefully without living in constant dread. Give me wisdom where I need new guardrails, honesty where I have been loose, and courage to act before the pressure grows stronger. Remind me that I am not doomed to repeat the past. Keep my heart awake, my mind clear, and my spirit anchored in You. Lead me away from the path that leads backward and deeper into the freedom You have already begun in me. Amen.',
        ]);
      case 'addiction_shame_after_using':
      case 'shame_after_relapse':
        return _rotating('prayer_$subcategory', [
          'God, shame is pressing hard on me right now, and I do not want to hide under it. I bring my failure to You honestly and ask for mercy, cleansing, and the courage to come fully into the light. Break the voice that tells me to stay hidden, stay dirty, and stay far from You. Remind me that conviction leads me toward You, not away from You. Help me reject secrecy, receive Your correction, and move quickly toward truth instead of self-punishment. Wash what needs washing, restore what has been shaken, and let Your mercy be louder than my shame. Amen.',
          'Lord, I feel the heaviness of shame, and I know it will try to push me into silence and hiding if I let it. I refuse that path. I come to You honestly and ask You to cleanse me, forgive me, and restore what this failure has damaged. Do not let shame speak like it is the final authority over me. Give me humility to confess, courage to be truthful, and strength to reject every lie that tells me I am ruined beyond mercy. Draw me back into the light and teach me to respond to conviction without surrendering to condemnation. Amen.',
        ]);
      case 'grief_loss_of_pet':
      case 'grief_loss_of_loved_one':
      case 'grief_fresh_loss':
      case 'grief_anniversary_grief':
      case 'grief_with_regret':
        return _rotating('prayer_$subcategory', [
          'Lord, this grief is heavy, and I do not want to pretend otherwise before You. You see what has been lost, what is missing, and what my heart keeps feeling in waves. Draw near to me in this sorrow. Comfort me where I feel raw, tired, and tender. Help me carry what feels too heavy for me alone. Hold me in the memories, in the ache, and in the quiet moments when the loss feels especially sharp. Give me grace for today instead of forcing myself to be stronger than I am. Stay close to me in this mourning and let Your presence meet me here. Amen.',
          'Father, I bring this sorrow to You because You already know how deeply this loss has touched me. Some moments feel heavy without warning, and I need Your comfort in a way that is gentle and real. Be near to my broken heart. Help me not to run from grief or numb what needs to be carried honestly. If regret is mixed in, meet me there too with mercy and truth. Give me peace for the parts I cannot change and tenderness for the pain that is still fresh. Walk with me through this grief and do not let me carry it as though I am alone. Amen.',
        ]);
      case 'anxiety_panic_spiral':
      case 'anxiety_sleepless_worry':
      case 'anxiety_future_fear':
      case 'anxiety_health_anxiety':
      case 'anxiety_financial_anxiety':
        return _rotating('prayer_$subcategory', [
          'Father, my thoughts feel crowded and my peace feels thin right now, so I bring this anxiety to You honestly. Fear is trying to speak loudly, but I ask You to steady my mind and settle my heart. Help me separate what is true from what panic is inventing. Teach me to hand over what I cannot control instead of carrying it in circles. Give me a sound mind, a quieter spirit, and grace for the next step in front of me. Do not let fear become my guide. Let Your presence be stronger than this pressure and Your peace stronger than what my mind is trying to rehearse. Amen.',
          'Lord, anxiety is pressing on me, and I need You to meet me in this moment with calm and clarity. My mind wants to run ahead, replay worst-case outcomes, and carry things that are not mine to hold all at once. Help me slow down. Anchor me in what is true, not in what fear keeps projecting. Give me wisdom where action is needed and surrender where striving has taken over. Quiet what is loud inside me and remind me that You are still present, still strong, and still faithful here. Let Your peace guard my heart and mind right now. Amen.',
        ]);
      case 'anger_at_person':
      case 'anger_betrayal':
      case 'anger_resentment':
      case 'anger_at_self':
      case 'anger_at_god':
        return _rotating('prayer_$subcategory', [
          'God, You see the anger in me clearly, and I do not want it to lead me into sin. Something in me feels hurt, stirred, or deeply frustrated, and I bring that heat to You before it spills out in the wrong way. Slow me down. Keep my mouth from outrunning wisdom and my reaction from doing more damage than the wound itself. Help me be honest without becoming destructive. Search me where resentment or pride has taken root, and teach me how to respond with truth, restraint, and clarity. Do not let anger become my master. Rule my spirit, Lord, and guide what I do next. Amen.',
          'Father, anger is rising in me, and I need Your help before it turns into something reckless. You know what happened, what was said, and why my heart feels stirred. But I do not want this emotion to decide my words, my actions, or my tone. Give me self-control, humility, and discernment. Show me what is mine to release, what is mine to address, and what must be placed fully in Your hands. Guard me from bitterness, harsh speech, and flesh-led reaction. Let Your wisdom be stronger than my impulse and Your peace stronger than my frustration. Amen.',
        ]);
      case 'loneliness_feeling_unseen':
      case 'loneliness_isolation':
      case 'loneliness_abandonment':
      case 'loneliness_after_breakup':
      case 'loneliness_spiritual_loneliness':
        return _rotating('prayer_$subcategory', [
          'Lord, this loneliness feels heavy, and I bring it to You because I do not want to keep carrying it silently. You know the ache of feeling unseen, isolated, or left alone, and I ask You to meet me in that ache with real comfort. Remind me that I am not forgotten, not abandoned, and not invisible to You. Strengthen me against the lies loneliness tries to speak over my worth and my future. Help me resist deeper retreat and guide me toward whatever is healthy, honest, and grounding. Be near to me in the silence and let Your presence steady what feels so empty. Amen.',
          'Father, loneliness is pressing on my heart, and some part of me feels tired from carrying it. I ask You to come close to me in a way that is gentle and real. Where I feel unseen, remind me that You see me. Where I feel abandoned, remind me that You have not left me. Where I feel cut off, help me take wise steps toward truth and connection instead of deeper isolation. Guard my mind from the lies this ache tries to attach to my identity. Comfort me, steady me, and let Your nearness hold me through what feels empty. Amen.',
        ]);
      case 'shame_guilt_after_sin':
      case 'shame_self_condemnation':
      case 'shame_feeling_unworthy':
      case 'shame_regret_over_actions':
        return _rotating('prayer_$subcategory', [
          'Lord, I bring this guilt and shame to You because I do not want to stay trapped in self-condemnation. You already know what happened, what I regret, and what is weighing on my conscience. I ask You for forgiveness where I have sinned, cleansing where I feel stained, and truth where my mind is speaking too cruelly. Keep me from the pride of hiding and from the despair of believing grace is not for me. Teach me to respond with repentance, honesty, and trust instead of endless self-punishment. Restore what needs restoring and let Your mercy be stronger than my accusation. Amen.',
          'Father, my conscience feels heavy, and I need Your mercy and truth right now. I confess what needs to be confessed, and I ask You to forgive me, cleanse me, and renew what has been shaken in me. Do not let guilt turn into a deeper agreement with condemnation. Show me the difference between conviction that leads me back to You and shame that tries to keep me far from You. Help me walk honestly, receive Your correction, and believe that Your mercy is still real here. Make me clean in heart and steady in spirit again. Amen.',
        ]);
      case 'relationship_marriage_conflict':
      case 'relationship_family_tension':
      case 'relationship_friendship_hurt':
      case 'relationship_broken_trust':
      case 'relationship_unresolved_argument':
        return _rotating('prayer_$subcategory', [
          'God, You see the strain, hurt, and tension in this relationship, and I ask You to help me carry it with wisdom. Guard me from pride, harshness, impulsive words, and shutting down in the wrong way. Give me clarity about what is true, what needs to be said, and what needs to be surrendered to You. Help me pursue honesty without cruelty and peace without pretending the pain is not real. If I need humility, give it. If I need courage, give it. If I need restraint, give it. Lead me in what is healthy, faithful, and aligned with Your truth. Amen.',
          'Father, this relationship pain feels heavy, and I need Your help to respond in a way that does not add needless damage. You know the hurt, the confusion, the broken trust, or the unresolved tension. I ask You for wisdom before words, peace before reaction, and discernment about the next step. Keep me from saying what my flesh wants to say just because it is loud in the moment. Help me speak truthfully, listen carefully, and move with steadiness instead of emotional chaos. Guide this situation according to what is right, not just what feels immediate. Amen.',
        ]);
      case 'purpose_feeling_lost':
      case 'purpose_no_direction':
      case 'identity_confusion':
      case 'identity_low_self_worth':
      case 'purpose_questioning_purpose':
        return _rotating('prayer_$subcategory', [
          'Lord, I feel uncertain, and I need You to anchor me where my own understanding feels thin. You know the questions I have about direction, identity, value, and purpose. I ask You to quiet the panic of not knowing everything all at once. Remind me that my worth is not hanging on perfect clarity and that You are still able to lead me step by step. Show me what is mine to obey today. Guard me from comparing, striving, and trying to define myself by things that cannot hold me up. Give me peace in the process and confidence in Your faithfulness. Amen.',
          'Father, these questions about purpose and direction feel heavy on me, and I bring them to You because I do not want confusion to rule my heart. Meet me where I feel lost, uncertain, or small. Remind me that You have not misplaced me and that You are not finished leading me just because I do not see the whole path. Help me trust You in the next small step, obey what is clear, and let my identity rest more in You than in my own performance or answers. Give me steadiness, wisdom, and peace as I move forward. Amen.',
        ]);
      case 'temptation_sexual_temptation':
      case 'temptation_to_go_back':
      case 'temptation_to_give_up':
      case 'temptation_to_react_in_anger':
      case 'temptation_to_numb':
        return _rotating('prayer_$subcategory', [
          'Lord, temptation is pressing on me right now, and I need Your help before it gains more ground. Expose the lie inside what is pulling at me and remind me clearly that urgency is not authority. Strengthen my mind to reject what is false, my heart to desire what is clean, and my will to move away from what feeds compromise. Help me act quickly in obedience instead of lingering near what is trying to pull me in. Keep me watchful, honest, and close to You in this battle. Thank You that You are faithful even here. Give me strength to resist and wisdom to take the next right step. Amen.',
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
                  label: const Text('Speak'),
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
