// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navMissions => 'Missions';

  @override
  String get navPlay => 'Play';

  @override
  String get navMap => 'Map';

  @override
  String get navProfile => 'Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get goToLogin => 'Go to login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get explorer => 'Explorer';

  @override
  String sdgLabel(int number, String title) {
    return 'SDG $number · $title';
  }

  @override
  String get loading => 'Loading…';

  @override
  String get sending => 'Sending…';

  @override
  String get saving => 'Saving…';

  @override
  String get save => 'Save';

  @override
  String get showFewer => 'Show fewer';

  @override
  String showAllCount(int count) {
    return 'Show all $count';
  }

  @override
  String get authGenericError => 'Something went wrong. Please try again.';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get welcomeBack => 'Welcome back. Pick up where you left off.';

  @override
  String get joinTagline => 'Small actions, global impact. Join in.';

  @override
  String get newHereCreateAccount => 'New here? Create an account';

  @override
  String get haveAccountLogIn => 'Already have an account? Log in';

  @override
  String get logIn => 'Log in';

  @override
  String get signUp => 'Sign up';

  @override
  String get enterEmailFirst => 'Enter your email above first.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get agreePrivacyFirst =>
      'Please agree to the privacy policy to continue.';

  @override
  String get usernameTooShort => 'Choose a username (2+ characters)';

  @override
  String get usernameTooLong => 'Keep it under 24 characters';

  @override
  String get username => 'Username';

  @override
  String get enterBirthYear => 'Enter the year you were born';

  @override
  String get birthYear => 'Year of birth';

  @override
  String get passwordHelper => 'At least 6 characters';

  @override
  String get iAgreeToThe => 'I agree to the ';

  @override
  String get privacyPolicyLink => 'privacy policy';

  @override
  String get createAccount => 'Create account';

  @override
  String get obEyebrow1 => 'WELCOME';

  @override
  String get obTitle1 => 'Small actions.\nGlobal impact.';

  @override
  String get obBody1 =>
      'The UN set 17 Sustainable Development Goals for a fairer, greener world. Your everyday choices help reach them.';

  @override
  String get obEyebrow2 => 'DAILY MISSIONS';

  @override
  String get obTitle2 => 'Five quick actions,\nevery day.';

  @override
  String get obBody2 =>
      'Unplug for an hour, take a shorter shower, walk instead of drive. Each mission takes minutes and earns XP.';

  @override
  String get obEyebrow3 => 'YOUR IMPACT';

  @override
  String get obTitle3 => 'Watch your impact\ngrow.';

  @override
  String get obBody3 =>
      'Level up, keep your streak alive, and see your actions on a live map alongside people around the world.';

  @override
  String get skip => 'Skip';

  @override
  String get startFirstMission => 'Start your first mission';

  @override
  String get continueLearning => 'Continue learning';

  @override
  String get yourWorld => 'Your world';

  @override
  String get yourWorldSubtitle => 'Grows with every goal star you earn';

  @override
  String get explore => 'Explore';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get openYourProfile => 'Open your profile';

  @override
  String get levelShort => 'LVL';

  @override
  String get impactXp => 'Impact XP';

  @override
  String xpToLevel(int xp, int level) {
    return '$xp XP to level $level';
  }

  @override
  String get viewImpact => 'View impact';

  @override
  String completedOf(int done, int total) {
    return '$done of $total completed';
  }

  @override
  String get viewAll => 'View all';

  @override
  String get learn => 'Learn';

  @override
  String get learnSubtitle => 'Lessons on all 17 goals';

  @override
  String get community => 'Community';

  @override
  String get communitySubtitle => 'Stories from others';

  @override
  String get yourImpact => 'Your impact';

  @override
  String get yourImpactSubtitle => 'Progress over time';

  @override
  String get rewards => 'Rewards';

  @override
  String get rewardsSubtitle => 'Unlock frames by playing';

  @override
  String get loginToStart =>
      'Log in or sign up to start earning XP and tracking your SDG impact.';

  @override
  String get teamChallenge => 'Team challenge';

  @override
  String get allTeams => 'All teams';

  @override
  String get manage => 'Manage';

  @override
  String get teamUpTitle => 'Team up with your class';

  @override
  String get teamUpBody => 'Set a weekly target and reach it together.';

  @override
  String get consentResent =>
      'Sent again. Ask your parent to check their email.';

  @override
  String get waitingForParent => 'Waiting for a parent to approve';

  @override
  String get waitingForParentBody =>
      'You can learn and play now. Sharing stories, photos, the map and teams unlock once a parent approves.';

  @override
  String get resendEmail => 'Resend the email';

  @override
  String get today => 'Today';

  @override
  String get todaySubtitle => 'A new set of missions every day';

  @override
  String get allMissionsComplete => 'All missions complete';

  @override
  String get dailyProgress => 'Daily progress';

  @override
  String get missionsDoneForToday =>
      'Great work. New missions arrive tomorrow.';

  @override
  String get missionsIntro => 'Complete small real-world actions to earn XP.';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get missionComplete => 'Mission complete';

  @override
  String get missionXp => 'Mission XP';

  @override
  String get dismiss => 'Dismiss';

  @override
  String streakBonus(int days) {
    return '$days-day streak bonus';
  }

  @override
  String levelUpReached(int level) {
    return 'Level up — you reached level $level';
  }

  @override
  String levelN(int level) {
    return 'Level $level';
  }

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get signOutBody => 'You can sign back in at any time.';

  @override
  String get signOut => 'Sign out';

  @override
  String get achievements => 'Achievements';

  @override
  String earnedOf(int earned, int total) {
    return '$earned of $total earned';
  }

  @override
  String get goalMastery => 'Goal mastery';

  @override
  String goalMasterySubtitle(int stars, int max) {
    return '$stars of $max stars · lesson, quiz and action for each goal';
  }

  @override
  String get focusSdgs => 'Focus SDGs';

  @override
  String get account => 'Account';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get impactDashboard => 'Impact dashboard';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageNote => 'Lessons and missions are in English for now.';

  @override
  String get noQuizzesYet => 'No quizzes yet';

  @override
  String quizAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get level => 'Level';

  @override
  String xpToNext(int xp) {
    return '$xp XP to next';
  }

  @override
  String get totalEarned => 'Total earned';

  @override
  String get streak => 'Streak';

  @override
  String daysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days in a row',
      one: 'day in a row',
    );
    return '$_temp0';
  }

  @override
  String get quizAverage => 'Quiz average';

  @override
  String levelRank(int level, String rank) {
    return 'Level $level · $rank';
  }

  @override
  String get rankGlobalLeader => 'Global Leader';

  @override
  String get rankChangemaker => 'Changemaker';

  @override
  String get rankAdvocate => 'Advocate';

  @override
  String get rankExplorer => 'Explorer';

  @override
  String get rankNewcomer => 'Newcomer';

  @override
  String get earned => 'Earned';

  @override
  String get focusPrompt =>
      'Pick up to 3 goals you care about. Your daily missions will include them.';

  @override
  String get choose => 'Choose';

  @override
  String get editFocusGoals => 'Edit focus goals';

  @override
  String get yourFocusGoals => 'Your focus goals';

  @override
  String focusChooseUpTo(int max) {
    return 'Choose up to $max. Up to 2 of your daily missions will come from these.';
  }

  @override
  String selectedOf(int count, int max) {
    return '$count of $max selected';
  }

  @override
  String get noProfileYet => 'No profile yet';

  @override
  String get noProfileBody => 'Log in or sign up to see your SDG stats.';

  @override
  String get deleteAccountQuestion => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile, XP, missions, quiz and game history, stories, photos and team memberships. It cannot be undone.';

  @override
  String get deleting => 'Deleting…';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get reminders => 'Reminders';

  @override
  String remindersOn(String time) {
    return 'Daily at $time · streak nudge at 8 pm';
  }

  @override
  String get remindersOff => 'Daily mission reminder and streak nudge';

  @override
  String get notificationsBlocked =>
      'Notifications are turned off for this app. Turn them on in your phone settings.';
}
