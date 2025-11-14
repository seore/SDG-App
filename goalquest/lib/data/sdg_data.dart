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
  ),
  SdgGoal(
    number: 6,
    shortTitle: 'Clean Water and Sanitation',
    fullTitle:
        'Ensure availability and sustainable management of water and sanitation for all.',
    color: Color(0xFF26BDE2),
  ),
  SdgGoal(
    number: 7,
    shortTitle: 'Affordable and Clean Energy',
    fullTitle:
        'Ensure access to affordable, reliable, sustainable and modern energy for all.',
    color: Color(0xFFFCC30B),
  ),
  SdgGoal(
    number: 8,
    shortTitle: 'Decent Work and Economic Growth',
    fullTitle:
        'Promote sustained, inclusive and sustainable economic growth, full and productive employment and decent work for all.',
    color: Color(0xFFA21942),
  ),
  SdgGoal(
    number: 9,
    shortTitle: 'Industry, Innovation and Infrastructure',
    fullTitle:
        'Build resilient infrastructure, promote inclusive and sustainable industrialization and foster innovation.',
    color: Color(0xFFF36D2F),
  ),
  SdgGoal(
    number: 10,
    shortTitle: 'Reduced Inequalities',
    fullTitle: 'Reduce inequality within and among countries.',
    color: Color(0xFFDD1367),
  ),
  SdgGoal(
    number: 11,
    shortTitle: 'Sustainable Cities and Communities',
    fullTitle:
        'Make cities and human settlements inclusive, safe, resilient and sustainable.',
    color: Color(0xFFF89D29),
  ),
  SdgGoal(
    number: 12,
    shortTitle: 'Responsible Consumption and Production',
    fullTitle: 'Ensure sustainable consumption and production patterns.',
    color: Color(0xFFBF8B2E),
  ),
  SdgGoal(
    number: 13,
    shortTitle: 'Climate Action',
    fullTitle:
        'Take urgent action to combat climate change and its impacts.',
    color: Color(0xFF3F7E44),
  ),
  SdgGoal(
    number: 14,
    shortTitle: 'Life Below Water',
    fullTitle:
        'Conserve and sustainably use the oceans, seas and marine resources.',
    color: Color(0xFF0A97D9),
  ),
  SdgGoal(
    number: 15,
    shortTitle: 'Life on Land',
    fullTitle:
        'Protect, restore and promote sustainable use of terrestrial ecosystems.',
    color: Color(0xFF56C02B),
  ),
  SdgGoal(
    number: 16,
    shortTitle: 'Peace, Justice and Strong Institutions',
    fullTitle:
        'Promote peaceful and inclusive societies, provide access to justice for all and build effective, accountable institutions.',
    color: Color(0xFF00689D),
  ),
  SdgGoal(
    number: 17,
    shortTitle: 'Partnerships for the Goals',
    fullTitle:
        'Strengthen the means of implementation and revitalize the global partnership for sustainable development.',
    color: Color(0xFF19486A),
  ),
];

SdgGoal? getSdgByNumber(int number) {
  try {
    return sdgGoals.firstWhere((g) => g.number == number);
  } catch (_) {
    return null;
  }
}
