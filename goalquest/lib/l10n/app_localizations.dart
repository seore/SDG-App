import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMissions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get navMissions;

  /// No description provided for @navPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navPlay;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to login'**
  String get goToLogin;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @sdgLabel.
  ///
  /// In en, this message translates to:
  /// **'SDG {number} · {title}'**
  String sdgLabel(int number, String title);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @showFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get showFewer;

  /// No description provided for @showAllCount.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String showAllCount(int count);

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Pick up where you left off.'**
  String get welcomeBack;

  /// No description provided for @joinTagline.
  ///
  /// In en, this message translates to:
  /// **'Small actions, global impact. Join in.'**
  String get joinTagline;

  /// No description provided for @newHereCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreateAccount;

  /// No description provided for @haveAccountLogIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccountLogIn;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above first.'**
  String get enterEmailFirst;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @agreePrivacyFirst.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the privacy policy to continue.'**
  String get agreePrivacyFirst;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Choose a username (2+ characters)'**
  String get usernameTooShort;

  /// No description provided for @usernameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under 24 characters'**
  String get usernameTooLong;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterBirthYear.
  ///
  /// In en, this message translates to:
  /// **'Enter the year you were born'**
  String get enterBirthYear;

  /// No description provided for @birthYear.
  ///
  /// In en, this message translates to:
  /// **'Year of birth'**
  String get birthYear;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHelper;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get privacyPolicyLink;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @obEyebrow1.
  ///
  /// In en, this message translates to:
  /// **'WELCOME'**
  String get obEyebrow1;

  /// No description provided for @obTitle1.
  ///
  /// In en, this message translates to:
  /// **'Small actions.\nGlobal impact.'**
  String get obTitle1;

  /// No description provided for @obBody1.
  ///
  /// In en, this message translates to:
  /// **'The UN set 17 Sustainable Development Goals for a fairer, greener world. Your everyday choices help reach them.'**
  String get obBody1;

  /// No description provided for @obEyebrow2.
  ///
  /// In en, this message translates to:
  /// **'DAILY MISSIONS'**
  String get obEyebrow2;

  /// No description provided for @obTitle2.
  ///
  /// In en, this message translates to:
  /// **'Five quick actions,\nevery day.'**
  String get obTitle2;

  /// No description provided for @obBody2.
  ///
  /// In en, this message translates to:
  /// **'Unplug for an hour, take a shorter shower, walk instead of drive. Each mission takes minutes and earns XP.'**
  String get obBody2;

  /// No description provided for @obEyebrow3.
  ///
  /// In en, this message translates to:
  /// **'YOUR IMPACT'**
  String get obEyebrow3;

  /// No description provided for @obTitle3.
  ///
  /// In en, this message translates to:
  /// **'Watch your impact\ngrow.'**
  String get obTitle3;

  /// No description provided for @obBody3.
  ///
  /// In en, this message translates to:
  /// **'Level up, keep your streak alive, and see your actions on a live map alongside people around the world.'**
  String get obBody3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @startFirstMission.
  ///
  /// In en, this message translates to:
  /// **'Start your first mission'**
  String get startFirstMission;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearning;

  /// No description provided for @yourWorld.
  ///
  /// In en, this message translates to:
  /// **'Your world'**
  String get yourWorld;

  /// No description provided for @yourWorldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grows with every goal star you earn'**
  String get yourWorldSubtitle;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @openYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Open your profile'**
  String get openYourProfile;

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'LVL'**
  String get levelShort;

  /// No description provided for @impactXp.
  ///
  /// In en, this message translates to:
  /// **'Impact XP'**
  String get impactXp;

  /// No description provided for @xpToLevel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to level {level}'**
  String xpToLevel(int xp, int level);

  /// No description provided for @viewImpact.
  ///
  /// In en, this message translates to:
  /// **'View impact'**
  String get viewImpact;

  /// No description provided for @completedOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} completed'**
  String completedOf(int done, int total);

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @learnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lessons on all 17 goals'**
  String get learnSubtitle;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @communitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stories from others'**
  String get communitySubtitle;

  /// No description provided for @yourImpact.
  ///
  /// In en, this message translates to:
  /// **'Your impact'**
  String get yourImpact;

  /// No description provided for @yourImpactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Progress over time'**
  String get yourImpactSubtitle;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @rewardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock frames by playing'**
  String get rewardsSubtitle;

  /// No description provided for @loginToStart.
  ///
  /// In en, this message translates to:
  /// **'Log in or sign up to start earning XP and tracking your SDG impact.'**
  String get loginToStart;

  /// No description provided for @teamChallenge.
  ///
  /// In en, this message translates to:
  /// **'Team challenge'**
  String get teamChallenge;

  /// No description provided for @allTeams.
  ///
  /// In en, this message translates to:
  /// **'All teams'**
  String get allTeams;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @teamUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Team up with your class'**
  String get teamUpTitle;

  /// No description provided for @teamUpBody.
  ///
  /// In en, this message translates to:
  /// **'Set a weekly target and reach it together.'**
  String get teamUpBody;

  /// No description provided for @consentResent.
  ///
  /// In en, this message translates to:
  /// **'Sent again. Ask your parent to check their email.'**
  String get consentResent;

  /// No description provided for @waitingForParent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a parent to approve'**
  String get waitingForParent;

  /// No description provided for @waitingForParentBody.
  ///
  /// In en, this message translates to:
  /// **'You can learn and play now. Sharing stories, photos, the map and teams unlock once a parent approves.'**
  String get waitingForParentBody;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend the email'**
  String get resendEmail;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @todaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new set of missions every day'**
  String get todaySubtitle;

  /// No description provided for @allMissionsComplete.
  ///
  /// In en, this message translates to:
  /// **'All missions complete'**
  String get allMissionsComplete;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily progress'**
  String get dailyProgress;

  /// No description provided for @missionsDoneForToday.
  ///
  /// In en, this message translates to:
  /// **'Great work. New missions arrive tomorrow.'**
  String get missionsDoneForToday;

  /// No description provided for @missionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Complete small real-world actions to earn XP.'**
  String get missionsIntro;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  /// No description provided for @missionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mission complete'**
  String get missionComplete;

  /// No description provided for @missionXp.
  ///
  /// In en, this message translates to:
  /// **'Mission XP'**
  String get missionXp;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @streakBonus.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak bonus'**
  String streakBonus(int days);

  /// No description provided for @levelUpReached.
  ///
  /// In en, this message translates to:
  /// **'Level up — you reached level {level}'**
  String levelUpReached(int level);

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelN(int level);

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQuestion;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in at any time.'**
  String get signOutBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @earnedOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} earned'**
  String earnedOf(int earned, int total);

  /// No description provided for @goalMastery.
  ///
  /// In en, this message translates to:
  /// **'Goal mastery'**
  String get goalMastery;

  /// No description provided for @goalMasterySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{stars} of {max} stars · lesson, quiz and action for each goal'**
  String goalMasterySubtitle(int stars, int max);

  /// No description provided for @focusSdgs.
  ///
  /// In en, this message translates to:
  /// **'Focus SDGs'**
  String get focusSdgs;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @impactDashboard.
  ///
  /// In en, this message translates to:
  /// **'Impact dashboard'**
  String get impactDashboard;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'Lessons and missions are in English for now.'**
  String get languageNote;

  /// No description provided for @noQuizzesYet.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get noQuizzesYet;

  /// No description provided for @quizAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String quizAttempts(int count);

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @xpToNext.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to next'**
  String xpToNext(int xp);

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get totalEarned;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @daysInARow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day in a row} other{days in a row}}'**
  String daysInARow(int count);

  /// No description provided for @quizAverage.
  ///
  /// In en, this message translates to:
  /// **'Quiz average'**
  String get quizAverage;

  /// No description provided for @levelRank.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {rank}'**
  String levelRank(int level, String rank);

  /// No description provided for @rankGlobalLeader.
  ///
  /// In en, this message translates to:
  /// **'Global Leader'**
  String get rankGlobalLeader;

  /// No description provided for @rankChangemaker.
  ///
  /// In en, this message translates to:
  /// **'Changemaker'**
  String get rankChangemaker;

  /// No description provided for @rankAdvocate.
  ///
  /// In en, this message translates to:
  /// **'Advocate'**
  String get rankAdvocate;

  /// No description provided for @rankExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get rankExplorer;

  /// No description provided for @rankNewcomer.
  ///
  /// In en, this message translates to:
  /// **'Newcomer'**
  String get rankNewcomer;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @focusPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 3 goals you care about. Your daily missions will include them.'**
  String get focusPrompt;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @editFocusGoals.
  ///
  /// In en, this message translates to:
  /// **'Edit focus goals'**
  String get editFocusGoals;

  /// No description provided for @yourFocusGoals.
  ///
  /// In en, this message translates to:
  /// **'Your focus goals'**
  String get yourFocusGoals;

  /// No description provided for @focusChooseUpTo.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {max}. Up to 2 of your daily missions will come from these.'**
  String focusChooseUpTo(int max);

  /// No description provided for @selectedOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} selected'**
  String selectedOf(int count, int max);

  /// No description provided for @noProfileYet.
  ///
  /// In en, this message translates to:
  /// **'No profile yet'**
  String get noProfileYet;

  /// No description provided for @noProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Log in or sign up to see your SDG stats.'**
  String get noProfileBody;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, XP, missions, quiz and game history, stories, photos and team memberships. It cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deleting;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersOn.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time} · streak nudge at 8 pm'**
  String remindersOn(String time);

  /// No description provided for @remindersOff.
  ///
  /// In en, this message translates to:
  /// **'Daily mission reminder and streak nudge'**
  String get remindersOff;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for this app. Turn them on in your phone settings.'**
  String get notificationsBlocked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
