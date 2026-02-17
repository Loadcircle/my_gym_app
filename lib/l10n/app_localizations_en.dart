// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GymVault';

  @override
  String get welcome => 'Welcome';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign Up';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registerSubtitle => 'Sign up to get started';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Your name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get register => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signInLink => 'Sign In';

  @override
  String get recoverPassword => 'Recover Password';

  @override
  String get recoverPasswordSubtitle =>
      'Enter your email and we\'ll send you a link to reset your password';

  @override
  String get sendLink => 'Send Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get emailSent => 'Email Sent';

  @override
  String get emailSentMessage => 'We\'ve sent a recovery link to:';

  @override
  String get emailSentInstructions =>
      'Check your inbox and follow the email instructions to reset your password.';

  @override
  String get didNotReceiveEmail => 'Didn\'t receive the email? Try again';

  @override
  String get legalPrefix => 'By continuing, you accept the ';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get legalMiddle => ' and the ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get exercises => 'Exercises';

  @override
  String get menu => 'Menu';

  @override
  String get searchExercise => 'Search exercise...';

  @override
  String get myExercises => 'My exercises';

  @override
  String get personal => 'Personal';

  @override
  String get noExercises => 'You don\'t have exercises';

  @override
  String get createFirstExercise => 'Create your first custom exercise';

  @override
  String get noResults => 'No results';

  @override
  String noCustomExercisesMatchSearch(String query) {
    return 'You don\'t have exercises matching \"$query\"';
  }

  @override
  String noFilteredExercisesMatchSearch(String filter, String query) {
    return 'There are no \"$filter\" exercises matching \"$query\"';
  }

  @override
  String noExercisesMatchSearch(String query) {
    return 'There are no exercises matching \"$query\"';
  }

  @override
  String get noExercisesInGroup => 'There are no exercises';

  @override
  String get selectAnotherMuscleGroup => 'Select another muscle group';

  @override
  String get notTheRightOne => 'Not the right one?';

  @override
  String get createOneForYou => 'You can create one just for you';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get errorLoadingExercises => 'Error loading exercises';

  @override
  String get retry => 'Retry';

  @override
  String get errorLoadingExercise => 'Error loading exercise';

  @override
  String get exerciseNotFound => 'Exercise not found';

  @override
  String get routine => 'Routine';

  @override
  String get hideExerciseDetails => 'Hide exercise details';

  @override
  String get showExerciseDetails => 'Show exercise details';

  @override
  String get tapToHide => 'Tap to hide';

  @override
  String get descriptionVideoInstructions =>
      'Description, video and instructions';

  @override
  String get instructions => 'Instructions';

  @override
  String get newExercise => 'New Exercise';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get optionalTapToSelect => 'Optional - Tap to select';

  @override
  String get muscleGroup => 'Muscle group';

  @override
  String get selectMuscleGroup => 'Select the main muscle group';

  @override
  String get exerciseName => 'Exercise name';

  @override
  String get exerciseNameHint => 'Exercise or machine name';

  @override
  String get exerciseNameExample => 'E.g: Incline dumbbell press';

  @override
  String get personalNotes => 'Personal notes';

  @override
  String get personalNotesHint => 'Instructions or notes for you (optional)';

  @override
  String get personalNotesExample =>
      'E.g: Lower slowly, push up explosively.\nKeep elbows at 45 degrees.';

  @override
  String get createExercise => 'Create exercise';

  @override
  String get cancel => 'Cancel';

  @override
  String get selectImage => 'Select image';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removeImage => 'Remove image';

  @override
  String errorSelectingImage(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get mustSignInToCreateExercises =>
      'You must sign in to create exercises';

  @override
  String get errorUploadingImage => 'Error uploading the image. Try again.';

  @override
  String exerciseCreated(String name) {
    return 'Exercise \"$name\" created';
  }

  @override
  String get errorCreatingExercise => 'Error creating the exercise';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get nameMinLength => 'Name must be at least 3 characters';

  @override
  String get nameTooLong => 'Name is too long';

  @override
  String get editExercise => 'Edit Exercise';

  @override
  String get error => 'Error';

  @override
  String get notFound => 'Not found';

  @override
  String get changeImage => 'Change image';

  @override
  String get mustSignInToEditExercises => 'You must sign in to edit exercises';

  @override
  String exerciseUpdated(String name) {
    return 'Exercise \"$name\" updated';
  }

  @override
  String get errorUpdatingExercise => 'Error updating the exercise';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get pendingReview => 'Pending review';

  @override
  String get approvedAsGlobal => 'Approved as global';

  @override
  String get proposalRejected => 'Proposal rejected';

  @override
  String get hideNotes => 'Hide notes';

  @override
  String get showNotes => 'Show notes';

  @override
  String get personalInstructions => 'Personal instructions';

  @override
  String get deleteExercise => 'Delete exercise';

  @override
  String deleteExerciseConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?\n\nThis action cannot be undone.';
  }

  @override
  String exerciseDeleted(String name) {
    return 'Exercise \"$name\" deleted';
  }

  @override
  String get errorDeletingExercise => 'Error deleting the exercise';

  @override
  String get recordSets => 'Record sets';

  @override
  String get quickRecord => 'Quick record';

  @override
  String get save => 'Save';

  @override
  String get enterWeight => 'Enter weight';

  @override
  String get invalidWeight => 'Invalid weight';

  @override
  String savedRecord(String weight, String sets, String reps) {
    return 'Saved: $weight kg x $sets sets x $reps reps';
  }

  @override
  String get completeAllSets => 'Fill in weight and reps on all sets';

  @override
  String savedAdvancedRecord(String weight, String count) {
    return 'Saved: $weight kg ($count sets)';
  }

  @override
  String get sets => 'Sets';

  @override
  String get reps => 'Reps';

  @override
  String get kg => 'kg';

  @override
  String advancedSummary(String weight, String count) {
    return 'Max: $weight kg | Sets: $count';
  }

  @override
  String get addSet => 'Add set';

  @override
  String get routines => 'Routines';

  @override
  String get deleteRoutine => 'Delete Routine';

  @override
  String deleteRoutineConfirm(String name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get routineDeleted => 'Routine deleted';

  @override
  String get errorDeletingRoutine => 'Error deleting routine';

  @override
  String get renameRoutine => 'Rename Routine';

  @override
  String get nameLabel => 'Name';

  @override
  String get routineNameExample => 'E.g: Push, Pull, Legs...';

  @override
  String get errorRenamingRoutine => 'Error renaming routine';

  @override
  String get noRoutinesYet => 'You don\'t have routines yet';

  @override
  String get createFirstRoutine =>
      'Create your first routine to organize your workouts';

  @override
  String get createRoutine => 'Create Routine';

  @override
  String get errorLoadingRoutines => 'Error loading routines';

  @override
  String get noExercisesCount => 'No exercises';

  @override
  String get oneExercise => '1 exercise';

  @override
  String exerciseCount(int count) {
    return '$count exercises';
  }

  @override
  String get rename => 'Rename';

  @override
  String get newRoutine => 'New Routine';

  @override
  String get routineName => 'Routine name';

  @override
  String get routineNameHint => 'E.g: Push, Pull, Legs, Full Body...';

  @override
  String get enterRoutineName => 'Enter a name for the routine';

  @override
  String get routineNameMinLength => 'Name must be at least 2 characters';

  @override
  String get willBeAddedAutomatically => 'Will be added automatically:';

  @override
  String get canAddMoreExercisesLater => 'You can add more exercises later';

  @override
  String get canAddExercisesLater =>
      'You can add exercises to your routine later';

  @override
  String exerciseAddedToRoutine(String name) {
    return '\"$name\" added to routine';
  }

  @override
  String get errorCreatingRoutine => 'Error creating routine';

  @override
  String get loading => 'Loading...';

  @override
  String get todayProgress => 'Today\'s progress';

  @override
  String exercisesProgress(String completed, String total) {
    return '$completed/$total exercises';
  }

  @override
  String get completed => 'Completed';

  @override
  String get markAsCompleted => 'Mark as Completed';

  @override
  String completeRoutine(String completed, String total) {
    return 'Complete Routine ($completed/$total)';
  }

  @override
  String routineCompleted(String name) {
    return '$name completed';
  }

  @override
  String routineMarkedCompleted(String name) {
    return '$name marked as completed';
  }

  @override
  String get noExercisesAddedYet => 'You haven\'t added exercises yet';

  @override
  String get addExercisesToBuildRoutine =>
      'Add exercises to build your routine';

  @override
  String get addExercises => 'Add Exercises';

  @override
  String get errorLoading => 'Error loading';

  @override
  String get routineNotFound => 'Routine not found';

  @override
  String get back => 'Back';

  @override
  String get today => 'Today';

  @override
  String get removeFromRoutine => 'Remove from routine';

  @override
  String get removeExercise => 'Remove Exercise';

  @override
  String removeExerciseConfirm(String name) {
    return 'Remove \"$name\" from the routine?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get errorRemovingExercise => 'Error removing exercise';

  @override
  String get routineNameExampleShort => 'E.g: Push Day';

  @override
  String deleteRoutineConfirmFull(String name) {
    return 'Are you sure you want to delete \"$name\"?\n\nThis action cannot be undone.';
  }

  @override
  String get searchExercisePlaceholder => 'Search exercise...';

  @override
  String addCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get exerciseAdded => 'Exercise added';

  @override
  String exercisesAdded(int count) {
    return '$count exercises added';
  }

  @override
  String get errorAdding => 'Error adding';

  @override
  String get alreadyAdded => 'Already added';

  @override
  String get addToRoutine => 'Add to Routine';

  @override
  String get errorLoadingRoutinesSheet => 'Error loading routines';

  @override
  String get noRoutinesSheet => 'You don\'t have routines';

  @override
  String get createRoutineToOrganize =>
      'Create a routine to organize your exercises';

  @override
  String get createNewRoutine => 'Create new routine';

  @override
  String addedToRoutine(String name) {
    return 'Added to \"$name\"';
  }

  @override
  String get exerciseAlreadyInRoutine => 'Exercise is already in the routine';

  @override
  String get history => 'History';

  @override
  String get errorLoadingHistory => 'Error loading history';

  @override
  String editDate(String date) {
    return 'Edit - $date';
  }

  @override
  String get addExerciseButton => 'Add exercise';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noRecordsThisDay => 'No records this day';

  @override
  String get addExerciseWithButton => 'Add an exercise with the button below';

  @override
  String get completedRoutines => 'Completed routines';

  @override
  String get registeredExercises => 'Registered exercises';

  @override
  String get unknownExercise => 'Unknown exercise';

  @override
  String get deleteRecord => 'Delete record';

  @override
  String deleteRecordConfirm(String name, String weight) {
    return 'Delete the record of \"$name\" ($weight kg)?';
  }

  @override
  String get cannotBeUndone => '\n\nThis action cannot be undone.';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get errorDeleting => 'Error deleting';

  @override
  String get deleteCompletedRoutine => 'Delete completed routine';

  @override
  String deleteCompletedRoutineConfirm(String name) {
    return 'Delete the record of \"$name\"?';
  }

  @override
  String addDate(String date) {
    return 'Add - $date';
  }

  @override
  String get exercisesTab => 'Exercises';

  @override
  String get routinesTab => 'Routines';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get addOneExercise => 'Add 1 exercise';

  @override
  String addMultipleExercises(int count) {
    return 'Add $count exercises';
  }

  @override
  String exerciseNameAdded(String name) {
    return '$name added';
  }

  @override
  String countExercisesAdded(int count) {
    return '$count exercises added';
  }

  @override
  String get errorAddingExercises => 'Error adding';

  @override
  String get noRoutinesAvailable => 'You don\'t have routines';

  @override
  String get createRoutineFirst => 'Create a routine first';

  @override
  String routineAddedWithExercises(String name, int count) {
    return '$name added ($count exercises)';
  }

  @override
  String get custom => 'Custom';

  @override
  String exerciseCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get noRecords => 'No records';

  @override
  String get recordFirstWorkout => 'Record your first workout';

  @override
  String get goToExercises => 'Go to exercises';

  @override
  String get noWorkoutsRecorded => 'You didn\'t record any workout';

  @override
  String get editDay => 'Edit day';

  @override
  String get routineLabel => 'routine';

  @override
  String get exerciseLabel => 'exercise';

  @override
  String exercisesCompletedCount(String completed, String total) {
    return '$completed/$total exercises';
  }

  @override
  String get auto => 'Auto';

  @override
  String get manual => 'Manual';

  @override
  String get hundredPercent => '100%';

  @override
  String completionPercentage(String percentage) {
    return '$percentage%';
  }

  @override
  String get detailed => 'Detailed';

  @override
  String setsTimesReps(String sets, String reps) {
    return '$sets sets x $reps reps';
  }

  @override
  String weightKg(String weight) {
    return '$weight kg';
  }

  @override
  String get lastWorkout => 'Last workout';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0';
  }

  @override
  String get myProfile => 'My Profile';

  @override
  String errorLoadingProfile(String error) {
    return 'Error loading profile: $error';
  }

  @override
  String get firstName => 'First name';

  @override
  String get firstNameHint => 'E.g: John';

  @override
  String get lastName => 'Last name';

  @override
  String get lastNameHint => 'E.g: Smith';

  @override
  String get age => 'Age';

  @override
  String get ageHint => 'E.g: 25';

  @override
  String get years => 'years';

  @override
  String get height => 'Height';

  @override
  String get heightHint => 'E.g: 175';

  @override
  String get cm => 'cm';

  @override
  String get weight => 'Weight';

  @override
  String get weightHint => 'E.g: 70.5';

  @override
  String get sex => 'Sex';

  @override
  String get unspecified => 'Unspecified';

  @override
  String get allFieldsOptional =>
      'All fields are optional. Your information is saved securely.';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String errorSavingProfile(String error) {
    return 'Error saving: $error';
  }

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle =>
      'An email with instructions will be sent';

  @override
  String get session => 'Session';

  @override
  String get signOut => 'Sign out';

  @override
  String get legal => 'Legal';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently deletes your account and data';

  @override
  String get about => 'About';

  @override
  String versionInfo(String version, String buildSuffix) {
    return 'Version $version$buildSuffix';
  }

  @override
  String get appDescription =>
      'Record your workouts, exercises and progress at the gym.';

  @override
  String get copyright => '© 2026 GymVault';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String changePasswordMessage(String email) {
    return 'A link to change your password will be sent to:\n\n$email';
  }

  @override
  String get send => 'Send';

  @override
  String emailSentTo(String email) {
    return 'Email sent to $email';
  }

  @override
  String errorSendingEmail(String error) {
    return 'Error sending email: $error';
  }

  @override
  String get signOutTitle => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String errorSigningOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountMessage =>
      'By deleting your account, all personal and workout data will be deleted.\n\nThis action cannot be undone.';

  @override
  String get continueAction => 'Continue';

  @override
  String get deleteAccountFinalTitle => 'Delete account permanently?';

  @override
  String get deleteAccountFinalMessage =>
      'All your exercises, routines, weight records and personal data will be deleted.';

  @override
  String get deleteDefinitely => 'Delete permanently';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get deletingAccount => 'Deleting account...';

  @override
  String get couldNotGetEmail => 'Could not get account email';

  @override
  String get user => 'User';

  @override
  String get configuration => 'Configuration';

  @override
  String get weightEvolution => 'Weight Evolution';

  @override
  String get stable => 'Stable';

  @override
  String positivePercentage(String percentage) {
    return '+$percentage%';
  }

  @override
  String negativePercentage(String percentage) {
    return '-$percentage%';
  }

  @override
  String sinceDate(String date) {
    return 'since $date';
  }

  @override
  String weightRepsTooltip(String weight, String reps) {
    return '${weight}kg x $reps reps';
  }

  @override
  String weightAxisLabel(String weight) {
    return '${weight}kg';
  }

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String validationPasswordMinLength(int length) {
    return 'Password must be at least $length characters';
  }

  @override
  String get validationConfirmPassword => 'Confirm your password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get validationNameRequired => 'Name is required';

  @override
  String get validationNameMinLength => 'Name must be at least 2 characters';

  @override
  String validationFieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  @override
  String get validationWeightRequired => 'Weight is required';

  @override
  String get validationEnterValidNumber => 'Enter a valid number';

  @override
  String get validationWeightNegative => 'Weight cannot be negative';

  @override
  String validationWeightMax(String max) {
    return 'Maximum weight is $max kg';
  }

  @override
  String get validationEnterInteger => 'Enter a whole number';

  @override
  String get validationMinSets => 'Minimum 1 set';

  @override
  String validationMaxSets(int max) {
    return 'Maximum $max sets';
  }

  @override
  String get validationMinReps => 'Minimum 1 rep';

  @override
  String validationMaxReps(int max) {
    return 'Maximum $max reps';
  }

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get selectLanguage => 'Select language';

  @override
  String routineCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routines',
      one: '1 routine',
    );
    return '$_temp0';
  }

  @override
  String get generalProgress => 'General Progress';

  @override
  String get summary => 'Summary';

  @override
  String get workoutDays => 'Workout days';

  @override
  String get totalVolume => 'Total volume';

  @override
  String get dominantMuscle => 'Dominant muscle';

  @override
  String get bestProgress => 'Best progress';

  @override
  String get muscleDistribution => 'Muscle Distribution';

  @override
  String get topMuscles => 'Top muscles';

  @override
  String forgottenMusclesWarning(String muscles) {
    return 'Muscles with low work: $muscles';
  }

  @override
  String get noProgressData => 'No progress data';

  @override
  String get noProgressDataSubtitle =>
      'Record your workouts to see your progress';

  @override
  String get errorLoadingProgress => 'Error loading progress';

  @override
  String get last30Days => '30 days';

  @override
  String get last90Days => '90 days';

  @override
  String get last6Months => '6 months';

  @override
  String get last12Months => '12 months';

  @override
  String get allTime => 'All time';

  @override
  String volumeKg(String volume) {
    return '$volume kg';
  }

  @override
  String days(String count) {
    return '$count d';
  }

  @override
  String get workoutDaysTooltip => 'Unique days you trained in this period';

  @override
  String get totalVolumeTooltip =>
      'Total weight x reps x sets of all exercises';

  @override
  String get dominantMuscleTooltip => 'Muscle group with the highest volume';

  @override
  String get bestProgressTooltip =>
      'Exercise with the greatest weight increase';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Sets';

  @override
  String get tapChartHint => 'Tap a section for details';

  @override
  String get bestMuscleProgress => 'Best muscle progress';

  @override
  String get detailedProgress => 'Detailed Progress';

  @override
  String get byMuscleGroup => 'By muscle group';

  @override
  String get byExercise => 'By exercise';

  @override
  String get currentVolume => 'Current';

  @override
  String get previousVolume => 'Previous';

  @override
  String get newLabel => 'New';

  @override
  String get noProgressYet => 'Not enough data to compare progress';

  @override
  String get minRecordsHint => 'Exercises with 3+ workouts';

  @override
  String yourProgressInPeriod(String period) {
    return 'Your progress in the last $period';
  }

  @override
  String get yourProgressAllTime => 'Your all-time progress';

  @override
  String get tapForDetails => 'Tap for details';

  @override
  String get bestMuscleProgressTooltip =>
      'Muscle group with the greatest volume increase';

  @override
  String get vsLastPeriod => 'vs last period';

  @override
  String progressPercentage(String percentage) {
    return '+$percentage%';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Reminders, progress, and more';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get reminders => 'Reminders';

  @override
  String get trainingReminders => 'Training reminders';

  @override
  String get trainingRemindersDesc => 'Reminds you at your usual workout time';

  @override
  String get incompleteSessionReminder => 'Incomplete session';

  @override
  String get incompleteSessionDesc => 'Reminds you to finish your routine';

  @override
  String get progressSection => 'Progress';

  @override
  String get progressMilestones => 'Progress milestones';

  @override
  String get progressMilestonesDesc => 'Celebrates your improvements';

  @override
  String get news => 'News';

  @override
  String get gymvaultUpdates => 'GymVault updates';

  @override
  String get gymvaultUpdatesDesc => 'News and announcements';

  @override
  String get doNotDisturb => 'Do Not Disturb';

  @override
  String get dndDescription => 'No notifications during this time';

  @override
  String get dndFrom => 'From';

  @override
  String get dndTo => 'To';

  @override
  String get notifTrainingTitle => 'Ready to train?';

  @override
  String get notifTrainingBody => 'Your usual workout time is here. Let\'s go!';

  @override
  String get notifIncompleteTitle => 'Finish your session?';

  @override
  String get notifIncompleteBody =>
      'You logged exercises earlier. Want to complete your routine?';

  @override
  String notifMilestoneTitle(String muscleGroup) {
    return '$muscleGroup is growing!';
  }

  @override
  String notifMilestoneBody(String muscleGroup, String percentage) {
    return 'Your $muscleGroup volume improved $percentage% this month. Keep it up!';
  }

  @override
  String get notifPermissionRequired =>
      'Notification permission is required to send reminders';
}
