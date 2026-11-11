import 'package:flutter/material.dart';

class SdgGoal {
  final int number;
  final String shortTitle;
  final String fullTitle;
  final Color color;

  final String? everydayExplanation;
  final String? example;
  final String? actions;

  const SdgGoal({
    required this.number,
    required this.shortTitle,
    required this.fullTitle,
    required this.color,
    this.everydayExplanation,
    this.example,
    this.actions,
  });
}

const List<SdgGoal> sdgGoals = [
  SdgGoal(
    number: 1,
    shortTitle: 'No Poverty',
    fullTitle: 'End poverty in all its forms everywhere.',
    color: Color(0xFFE5243B),
    everydayExplanation:
        'No Poverty means everyone has enough money and support to meet basic needs like food, clothes, a safe place to live, and opportunities to study or work.',
    example:
        'In some communities, small loans help families start tiny businesses, like selling food or crafts, so they can earn their own income.',
    actions:
        '• Donate clothes, books or supplies to local shelters or charities.\n'
        '• Support community food banks or school fundraisers.\n'
        '• Learn about why poverty exists and talk about fair wages and support for families.',
  ),
  SdgGoal(
    number: 2,
    shortTitle: 'Zero Hunger',
    fullTitle:
        'End hunger, achieve food security and improved nutrition, and promote sustainable agriculture.',
    color: Color(0xFFDDA63A),
    everydayExplanation:
        'Zero Hunger means everyone has enough healthy food every day, and the way we grow food is kind to people, animals and the planet.',
    example:
        'Community gardens allow neighbours to grow fresh vegetables together and share them with families who need them most.',
    actions:
        '• Avoid wasting food: take only what you will eat.\n'
        '• Support or volunteer with food banks or soup kitchens.\n'
        '• Try buying local or seasonal food when possible.',
  ),
  SdgGoal(
    number: 3,
    shortTitle: 'Good Health and Well-being',
    fullTitle:
        'Ensure healthy lives and promote well-being for all at all ages.',
    color: Color(0xFF4C9F38),
    everydayExplanation:
        'Good Health means people can access doctors, medicine, clean air, safe spaces and support for mental health and happiness.',
    example:
        'Some schools create “well-being corners” where students can talk to a counsellor or teacher when they feel stressed or anxious.',
    actions:
        '• Move your body daily: walk, stretch or play a sport.\n'
        '• Talk openly about mental health with trusted adults.\n'
        '• Encourage friends to rest, drink water and seek help when needed.',
  ),
  SdgGoal(
    number: 4,
    shortTitle: 'Quality Education',
    fullTitle:
        'Ensure inclusive and equitable quality education and promote lifelong learning opportunities for all.',
    color: Color(0xFFC5192D),
    everydayExplanation:
        'Quality Education means every child and young person can go to school, learn in a safe space, and build skills for their future.',
    example:
        'In some countries, tablet libraries and radio lessons help students keep learning even when they can’t physically go to school.',
    actions:
        '• Help classmates who struggle with a subject if you can.\n'
        '• Take good care of school books and shared resources.\n'
        '• Join or start a school club that promotes learning or tutoring.',
  ),
  SdgGoal(
    number: 5,
    shortTitle: 'Gender Equality',
    fullTitle: 'Achieve gender equality and empower all women and girls.',
    color: Color(0xFFFF3A21),
    everydayExplanation:
        'Gender Equality means everyone gets the same rights, respect and opportunities, whatever their gender – at school, at home, at work and online.',
    example:
        'Some schools run coding clubs and sports teams that actively welcome girls, so more of them try subjects and activities they were once told weren\'t for them.',
    actions:
        '• Speak up when someone is treated unfairly or teased because of their gender.\n'
        '• Share chores at home fairly, whoever you are.\n'
        '• Encourage friends to try any subject, sport or career that interests them.',
  ),
  SdgGoal(
    number: 6,
    shortTitle: 'Clean Water and Sanitation',
    fullTitle:
        'Ensure availability and sustainable management of water and sanitation for all.',
    color: Color(0xFF26BDE2),
    everydayExplanation:
        'Clean Water and Sanitation means everyone can get safe water to drink and wash with, and has a clean, private toilet.',
    example:
        'In places without piped water, community wells and rainwater-collection tanks mean children spend less time fetching water and more time in school.',
    actions:
        '• Take shorter showers and turn off the tap while brushing your teeth.\n'
        '• Never pour oil, paint or chemicals down the sink or drain.\n'
        '• Report leaking taps and pipes at home or school so they get fixed.',
  ),
  SdgGoal(
    number: 7,
    shortTitle: 'Affordable and Clean Energy',
    fullTitle:
        'Ensure access to affordable, reliable, sustainable and modern energy for all.',
    color: Color(0xFFFCC30B),
    everydayExplanation:
        'Affordable and Clean Energy means everyone has electricity they can afford, made in ways that don\'t pollute the air or heat up the planet – like sun, wind and water power.',
    example:
        'Small solar panels let families in remote villages light their homes at night and charge phones without burning kerosene.',
    actions:
        '• Switch off lights and unplug chargers when you\'re not using them.\n'
        '• Dry clothes outside on a line instead of using a dryer when you can.\n'
        '• Ask your school or family about switching to renewable energy.',
  ),
  SdgGoal(
    number: 8,
    shortTitle: 'Decent Work and Economic Growth',
    fullTitle:
        'Promote sustained, inclusive and sustainable economic growth, full and productive employment and decent work for all.',
    color: Color(0xFFA21942),
    everydayExplanation:
        'Decent Work and Economic Growth means people can earn a fair wage in safe jobs, are treated with respect, and no one – especially children – is forced to work.',
    example:
        'Fair-trade schemes help farmers who grow crops like cocoa and coffee get a fairer price, so they can support their families and send their children to school.',
    actions:
        '• Look for fair-trade labels when you or your family shop.\n'
        '• Learn about your rights before you start a part-time job.\n'
        '• Support local small businesses in your community.',
  ),
  SdgGoal(
    number: 9,
    shortTitle: 'Industry, Innovation and Infrastructure',
    fullTitle:
        'Build resilient infrastructure, promote inclusive and sustainable industrialization and foster innovation.',
    color: Color(0xFFF36D2F),
    everydayExplanation:
        'Industry, Innovation and Infrastructure means building the roads, internet, bridges and factories people need – in ways that are strong, fair and kind to the environment.',
    example:
        'Mobile banking lets people without a nearby bank save money and pay bills safely using a basic phone.',
    actions:
        '• Fix and repair things before replacing them.\n'
        '• Get curious about science, technology and engineering – try a coding or building project.\n'
        '• Help someone who\'s less confident with technology get online safely.',
  ),
  SdgGoal(
    number: 10,
    shortTitle: 'Reduced Inequalities',
    fullTitle: 'Reduce inequality within and among countries.',
    color: Color(0xFFDD1367),
    everydayExplanation:
        'Reduced Inequalities means everyone gets a fair chance in life, whatever their background, income, disability, religion or where they come from.',
    example:
        'Many public buildings now add ramps, lifts and audio guides so people with disabilities can use them just like everyone else.',
    actions:
        '• Include classmates who are new or often left out.\n'
        '• Challenge jokes or comments that put people down for who they are.\n'
        '• Learn about the experiences of people whose lives are different from yours.',
  ),
  SdgGoal(
    number: 11,
    shortTitle: 'Sustainable Cities and Communities',
    fullTitle:
        'Make cities and human settlements inclusive, safe, resilient and sustainable.',
    color: Color(0xFFF89D29),
    everydayExplanation:
        'Sustainable Cities and Communities means towns and cities where everyone has a safe home, clean air, green spaces and easy ways to get around.',
    example:
        'Some cities have turned busy roads into bike lanes and parks, which cut pollution and give people more space to walk and play.',
    actions:
        '• Walk, cycle or take public transport for short trips.\n'
        '• Help look after local parks – pick up litter or join a clean-up.\n'
        '• Get to know your neighbours and support community events.',
  ),
  SdgGoal(
    number: 12,
    shortTitle: 'Responsible Consumption and Production',
    fullTitle: 'Ensure sustainable consumption and production patterns.',
    color: Color(0xFFBF8B2E),
    everydayExplanation:
        'Responsible Consumption and Production means using only what we need, wasting less, and choosing things made in ways that don\'t harm people or the planet.',
    example:
        'Repair cafés invite people to bring broken items like toasters and bikes so volunteers can help fix them instead of throwing them away.',
    actions:
        '• Carry a reusable bottle and bag.\n'
        '• Sort your rubbish into recycling, compost and landfill correctly.\n'
        '• Buy second-hand, swap or borrow before you buy something new.',
  ),
  SdgGoal(
    number: 13,
    shortTitle: 'Climate Action',
    fullTitle: 'Take urgent action to combat climate change and its impacts.',
    color: Color(0xFF3F7E44),
    everydayExplanation:
        'Climate Action means cutting the pollution that heats up the planet, and helping people stay safe from floods, heatwaves and storms that climate change makes worse.',
    example:
        'Young people around the world have organised school climate strikes and campaigns that pushed leaders to talk more seriously about climate change.',
    actions:
        '• Walk, cycle or use public transport when you can.\n'
        '• Eat more plant-based meals and waste less food.\n'
        '• Learn the facts about climate change and share them kindly with others.',
  ),
  SdgGoal(
    number: 14,
    shortTitle: 'Life Below Water',
    fullTitle:
        'Conserve and sustainably use the oceans, seas and marine resources.',
    color: Color(0xFF0A97D9),
    everydayExplanation:
        'Life Below Water means keeping oceans, seas and rivers clean and healthy, so fish, coral and other sea life can thrive.',
    example:
        'Protected marine areas, where fishing is limited, give fish populations and coral reefs time to recover and grow again.',
    actions:
        '• Avoid single-use plastics like straws, bottles and bags.\n'
        '• Never leave litter on beaches or near rivers – it often ends up in the sea.\n'
        '• Choose seafood from sustainable sources, if your family eats fish.',
  ),
  SdgGoal(
    number: 15,
    shortTitle: 'Life on Land',
    fullTitle:
        'Protect, restore and promote sustainable use of terrestrial ecosystems.',
    color: Color(0xFF56C02B),
    everydayExplanation:
        'Life on Land means protecting forests, animals, plants and soil so nature stays healthy and wildlife has places to live.',
    example:
        'Tree-planting projects in many countries are helping to bring back forests, which stop soil washing away and give animals a home.',
    actions:
        '• Plant flowers or trees, or create a small bug hotel.\n'
        '• Stick to paths in nature and leave plants and animals where they are.\n'
        '• Use both sides of paper and recycle it to save trees.',
  ),
  SdgGoal(
    number: 16,
    shortTitle: 'Peace, Justice and Strong Institutions',
    fullTitle:
        'Promote peaceful and inclusive societies, provide access to justice for all and build effective, accountable institutions.',
    color: Color(0xFF00689D),
    everydayExplanation:
        'Peace, Justice and Strong Institutions means everyone can live safely, be treated fairly by the law, and trust that leaders and organisations are honest.',
    example:
        'Student councils give young people a real voice in decisions at their school and teach how fair, democratic decisions are made.',
    actions:
        '• Solve disagreements by listening and talking calmly.\n'
        '• Stand up against bullying, online and offline.\n'
        '• Join your school council or a youth group to have your say.',
  ),
  SdgGoal(
    number: 17,
    shortTitle: 'Partnerships for the Goals',
    fullTitle:
        'Strengthen the means of implementation and revitalize the global partnership for sustainable development.',
    color: Color(0xFF19486A),
    everydayExplanation:
        'Partnerships for the Goals means countries, companies, charities and people working together, because no one can reach the goals alone.',
    example:
        'Global vaccine programmes bring together governments, scientists, charities and companies to get life-saving vaccines to children everywhere.',
    actions:
        '• Team up with friends or classmates on a project for one of the goals.\n'
        '• Share what you\'ve learned about the SDGs with your family.\n'
        '• Support organisations that work across borders to help people and the planet.',
  ),
];

SdgGoal? getSdgByNumber(int number) {
  try {
    return sdgGoals.firstWhere((g) => g.number == number);
  } catch (_) {
    return null;
  }
}
