// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navMissions => 'Missions';

  @override
  String get navPlay => 'Jouer';

  @override
  String get navMap => 'Carte';

  @override
  String get navProfile => 'Profil';

  @override
  String get cancel => 'Annuler';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get goToLogin => 'Aller à la connexion';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get explorer => 'Explorateur';

  @override
  String sdgLabel(int number, String title) {
    return 'ODD $number · $title';
  }

  @override
  String get loading => 'Chargement…';

  @override
  String get sending => 'Envoi…';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get save => 'Enregistrer';

  @override
  String get showFewer => 'Afficher moins';

  @override
  String showAllCount(int count) {
    return 'Tout afficher ($count)';
  }

  @override
  String get authGenericError => 'Une erreur s\'est produite. Réessaie.';

  @override
  String get enterEmail => 'Saisis ton e-mail';

  @override
  String get enterValidEmail => 'Saisis un e-mail valide';

  @override
  String get passwordTooShort => 'Utilise au moins 6 caractères';

  @override
  String get welcomeBack => 'Re-bonjour ! Reprends là où tu en étais.';

  @override
  String get joinTagline => 'Petites actions, impact mondial. Rejoins-nous !';

  @override
  String get newHereCreateAccount => 'Première visite ? Crée un compte';

  @override
  String get haveAccountLogIn => 'Tu as déjà un compte ? Connecte-toi';

  @override
  String get logIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get enterEmailFirst => 'Saisis d\'abord ton e-mail ci-dessus.';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get agreePrivacyFirst =>
      'Accepte la politique de confidentialité pour continuer.';

  @override
  String get usernameTooShort =>
      'Choisis un nom d\'utilisateur (2 caractères ou plus)';

  @override
  String get usernameTooLong => '24 caractères maximum';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get enterBirthYear => 'Saisis ton année de naissance';

  @override
  String get birthYear => 'Année de naissance';

  @override
  String get passwordHelper => 'Au moins 6 caractères';

  @override
  String get iAgreeToThe => 'J\'accepte la ';

  @override
  String get privacyPolicyLink => 'politique de confidentialité';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get obEyebrow1 => 'BIENVENUE';

  @override
  String get obTitle1 => 'Petites actions.\nImpact mondial.';

  @override
  String get obBody1 =>
      'L\'ONU a fixé 17 Objectifs de développement durable pour un monde plus juste et plus vert. Tes choix quotidiens aident à les atteindre.';

  @override
  String get obEyebrow2 => 'MISSIONS DU JOUR';

  @override
  String get obTitle2 => 'Cinq actions rapides,\nchaque jour.';

  @override
  String get obBody2 =>
      'Débranche une heure, prends une douche plus courte, marche au lieu de prendre la voiture. Chaque mission prend quelques minutes et rapporte des XP.';

  @override
  String get obEyebrow3 => 'TON IMPACT';

  @override
  String get obTitle3 => 'Regarde ton impact\ngrandir.';

  @override
  String get obBody3 =>
      'Monte de niveau, garde ta série et vois tes actions sur une carte en direct, avec des gens du monde entier.';

  @override
  String get skip => 'Passer';

  @override
  String get startFirstMission => 'Commence ta première mission';

  @override
  String get continueLearning => 'Continue d\'apprendre';

  @override
  String get yourWorld => 'Ton monde';

  @override
  String get yourWorldSubtitle =>
      'Grandit avec chaque étoile d\'objectif que tu gagnes';

  @override
  String get explore => 'Explorer';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get openYourProfile => 'Ouvrir ton profil';

  @override
  String get levelShort => 'NIV';

  @override
  String get impactXp => 'XP d\'impact';

  @override
  String xpToLevel(int xp, int level) {
    return '$xp XP avant le niveau $level';
  }

  @override
  String get viewImpact => 'Voir l\'impact';

  @override
  String completedOf(int done, int total) {
    return '$done sur $total terminées';
  }

  @override
  String get viewAll => 'Tout voir';

  @override
  String get learn => 'Apprendre';

  @override
  String get learnSubtitle => 'Leçons sur les 17 objectifs';

  @override
  String get community => 'Communauté';

  @override
  String get communitySubtitle => 'Histoires des autres';

  @override
  String get yourImpact => 'Ton impact';

  @override
  String get yourImpactSubtitle => 'Tes progrès au fil du temps';

  @override
  String get rewards => 'Récompenses';

  @override
  String get rewardsSubtitle => 'Débloque des cadres en jouant';

  @override
  String get loginToStart =>
      'Connecte-toi ou inscris-toi pour gagner des XP et suivre ton impact sur les ODD.';

  @override
  String get teamChallenge => 'Défi d\'équipe';

  @override
  String get allTeams => 'Toutes les équipes';

  @override
  String get manage => 'Gérer';

  @override
  String get teamUpTitle => 'Fais équipe avec ta classe';

  @override
  String get teamUpBody => 'Un objectif hebdomadaire à atteindre ensemble.';

  @override
  String get consentResent =>
      'Renvoyé. Demande à ton parent de vérifier ses e-mails.';

  @override
  String get waitingForParent => 'En attente de l\'accord d\'un parent';

  @override
  String get waitingForParentBody =>
      'Tu peux déjà apprendre et jouer. Le partage d\'histoires et de photos, la carte et les équipes se débloquent quand un parent aura donné son accord.';

  @override
  String get resendEmail => 'Renvoyer l\'e-mail';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get todaySubtitle => 'De nouvelles missions chaque jour';

  @override
  String get allMissionsComplete => 'Toutes les missions sont terminées';

  @override
  String get dailyProgress => 'Progression du jour';

  @override
  String get missionsDoneForToday =>
      'Bravo ! De nouvelles missions arrivent demain.';

  @override
  String get missionsIntro =>
      'Réalise de petites actions concrètes pour gagner des XP.';

  @override
  String get statusCompleted => 'Terminée';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusNotStarted => 'Pas commencée';

  @override
  String get missionComplete => 'Mission terminée';

  @override
  String get missionXp => 'XP de la mission';

  @override
  String get dismiss => 'Fermer';

  @override
  String streakBonus(int days) {
    return 'Bonus de série de $days jours';
  }

  @override
  String levelUpReached(int level) {
    return 'Niveau supérieur : tu as atteint le niveau $level';
  }

  @override
  String levelN(int level) {
    return 'Niveau $level';
  }

  @override
  String get signOutQuestion => 'Se déconnecter ?';

  @override
  String get signOutBody => 'Tu peux te reconnecter à tout moment.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get achievements => 'Succès';

  @override
  String earnedOf(int earned, int total) {
    return '$earned sur $total obtenus';
  }

  @override
  String get goalMastery => 'Maîtrise des objectifs';

  @override
  String goalMasterySubtitle(int stars, int max) {
    return '$stars sur $max étoiles · leçon, quiz et action pour chaque objectif';
  }

  @override
  String get focusSdgs => 'Tes ODD prioritaires';

  @override
  String get account => 'Compte';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get impactDashboard => 'Tableau de bord d\'impact';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Langue de l\'appareil';

  @override
  String get languageNote =>
      'Pour l\'instant, les leçons et missions sont en anglais.';

  @override
  String get noQuizzesYet => 'Aucun quiz pour l\'instant';

  @override
  String quizAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentatives',
      one: '1 tentative',
    );
    return '$_temp0';
  }

  @override
  String get level => 'Niveau';

  @override
  String xpToNext(int xp) {
    return '$xp XP avant le suivant';
  }

  @override
  String get totalEarned => 'Total gagné';

  @override
  String get streak => 'Série';

  @override
  String daysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours d\'affilée',
      one: 'jour d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String get quizAverage => 'Moyenne aux quiz';

  @override
  String levelRank(int level, String rank) {
    return 'Niveau $level · $rank';
  }

  @override
  String get rankGlobalLeader => 'Leader mondial';

  @override
  String get rankChangemaker => 'Acteur du changement';

  @override
  String get rankAdvocate => 'Porte-parole';

  @override
  String get rankExplorer => 'Explorateur';

  @override
  String get rankNewcomer => 'Débutant';

  @override
  String get earned => 'Obtenu';

  @override
  String get focusPrompt =>
      'Choisis jusqu\'à 3 objectifs qui te tiennent à cœur. Tes missions du jour les incluront.';

  @override
  String get choose => 'Choisir';

  @override
  String get editFocusGoals => 'Modifier les objectifs prioritaires';

  @override
  String get yourFocusGoals => 'Tes objectifs prioritaires';

  @override
  String focusChooseUpTo(int max) {
    return 'Choisis-en jusqu\'à $max. Jusqu\'à 2 de tes missions du jour en viendront.';
  }

  @override
  String selectedOf(int count, int max) {
    return '$count sur $max sélectionnés';
  }

  @override
  String get noProfileYet => 'Pas encore de profil';

  @override
  String get noProfileBody =>
      'Connecte-toi ou inscris-toi pour voir tes statistiques ODD.';

  @override
  String get deleteAccountQuestion => 'Supprimer ton compte ?';

  @override
  String get deleteAccountBody =>
      'Cela supprime définitivement ton profil, tes XP, missions, historique de quiz et de jeux, histoires, photos et équipes. C\'est irréversible.';

  @override
  String get deleting => 'Suppression…';

  @override
  String get deleteForever => 'Supprimer définitivement';

  @override
  String get reminders => 'Rappels';

  @override
  String remindersOn(String time) {
    return 'Chaque jour à $time · rappel de série à 20 h';
  }

  @override
  String get remindersOff => 'Rappel des missions du jour et de ta série';

  @override
  String get notificationsBlocked =>
      'Les notifications sont désactivées pour cette appli. Active-les dans les réglages de ton téléphone.';
}
