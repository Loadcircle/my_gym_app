import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

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
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'GymVault'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get registerSubtitle;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLink;

  /// No description provided for @recoverPassword.
  ///
  /// In en, this message translates to:
  /// **'Recover Password'**
  String get recoverPassword;

  /// No description provided for @recoverPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password'**
  String get recoverPasswordSubtitle;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get sendLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get emailSent;

  /// No description provided for @emailSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a recovery link to:'**
  String get emailSentMessage;

  /// No description provided for @emailSentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and follow the email instructions to reset your password.'**
  String get emailSentInstructions;

  /// No description provided for @didNotReceiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Try again'**
  String get didNotReceiveEmail;

  /// No description provided for @legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept the '**
  String get legalPrefix;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @legalMiddle.
  ///
  /// In en, this message translates to:
  /// **' and the '**
  String get legalMiddle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @searchExercise.
  ///
  /// In en, this message translates to:
  /// **'Search exercise...'**
  String get searchExercise;

  /// No description provided for @myExercises.
  ///
  /// In en, this message translates to:
  /// **'My exercises'**
  String get myExercises;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @noExercises.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have exercises'**
  String get noExercises;

  /// No description provided for @createFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'Create your first custom exercise'**
  String get createFirstExercise;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noCustomExercisesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have exercises matching \"{query}\"'**
  String noCustomExercisesMatchSearch(String query);

  /// No description provided for @noFilteredExercisesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'There are no \"{filter}\" exercises matching \"{query}\"'**
  String noFilteredExercisesMatchSearch(String filter, String query);

  /// No description provided for @noExercisesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'There are no exercises matching \"{query}\"'**
  String noExercisesMatchSearch(String query);

  /// No description provided for @noExercisesInGroup.
  ///
  /// In en, this message translates to:
  /// **'There are no exercises'**
  String get noExercisesInGroup;

  /// No description provided for @selectAnotherMuscleGroup.
  ///
  /// In en, this message translates to:
  /// **'Select another muscle group'**
  String get selectAnotherMuscleGroup;

  /// No description provided for @notTheRightOne.
  ///
  /// In en, this message translates to:
  /// **'Not the right one?'**
  String get notTheRightOne;

  /// No description provided for @createOneForYou.
  ///
  /// In en, this message translates to:
  /// **'You can create one just for you'**
  String get createOneForYou;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @errorLoadingExercises.
  ///
  /// In en, this message translates to:
  /// **'Error loading exercises'**
  String get errorLoadingExercises;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorLoadingExercise.
  ///
  /// In en, this message translates to:
  /// **'Error loading exercise'**
  String get errorLoadingExercise;

  /// No description provided for @exerciseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found'**
  String get exerciseNotFound;

  /// No description provided for @routine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get routine;

  /// No description provided for @hideExerciseDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide exercise details'**
  String get hideExerciseDetails;

  /// No description provided for @showExerciseDetails.
  ///
  /// In en, this message translates to:
  /// **'Show exercise details'**
  String get showExerciseDetails;

  /// No description provided for @tapToHide.
  ///
  /// In en, this message translates to:
  /// **'Tap to hide'**
  String get tapToHide;

  /// No description provided for @descriptionVideoInstructions.
  ///
  /// In en, this message translates to:
  /// **'Description, video and instructions'**
  String get descriptionVideoInstructions;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @newExercise.
  ///
  /// In en, this message translates to:
  /// **'New Exercise'**
  String get newExercise;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @optionalTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Optional - Tap to select'**
  String get optionalTapToSelect;

  /// No description provided for @muscleGroup.
  ///
  /// In en, this message translates to:
  /// **'Muscle group'**
  String get muscleGroup;

  /// No description provided for @selectMuscleGroup.
  ///
  /// In en, this message translates to:
  /// **'Select the main muscle group'**
  String get selectMuscleGroup;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exerciseName;

  /// No description provided for @exerciseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Exercise or machine name'**
  String get exerciseNameHint;

  /// No description provided for @exerciseNameExample.
  ///
  /// In en, this message translates to:
  /// **'E.g: Incline dumbbell press'**
  String get exerciseNameExample;

  /// No description provided for @personalNotes.
  ///
  /// In en, this message translates to:
  /// **'Personal notes'**
  String get personalNotes;

  /// No description provided for @personalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Instructions or notes for you (optional)'**
  String get personalNotesHint;

  /// No description provided for @personalNotesExample.
  ///
  /// In en, this message translates to:
  /// **'E.g: Lower slowly, push up explosively.\nKeep elbows at 45 degrees.'**
  String get personalNotesExample;

  /// No description provided for @createExercise.
  ///
  /// In en, this message translates to:
  /// **'Create exercise'**
  String get createExercise;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select image'**
  String get selectImage;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @errorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String errorSelectingImage(String error);

  /// No description provided for @mustSignInToCreateExercises.
  ///
  /// In en, this message translates to:
  /// **'You must sign in to create exercises'**
  String get mustSignInToCreateExercises;

  /// No description provided for @errorUploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error uploading the image. Try again.'**
  String get errorUploadingImage;

  /// No description provided for @exerciseCreated.
  ///
  /// In en, this message translates to:
  /// **'Exercise \"{name}\" created'**
  String exerciseCreated(String name);

  /// No description provided for @errorCreatingExercise.
  ///
  /// In en, this message translates to:
  /// **'Error creating the exercise'**
  String get errorCreatingExercise;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get nameMinLength;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get nameTooLong;

  /// No description provided for @editExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit Exercise'**
  String get editExercise;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get changeImage;

  /// No description provided for @mustSignInToEditExercises.
  ///
  /// In en, this message translates to:
  /// **'You must sign in to edit exercises'**
  String get mustSignInToEditExercises;

  /// No description provided for @exerciseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Exercise \"{name}\" updated'**
  String exerciseUpdated(String name);

  /// No description provided for @errorUpdatingExercise.
  ///
  /// In en, this message translates to:
  /// **'Error updating the exercise'**
  String get errorUpdatingExercise;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get pendingReview;

  /// No description provided for @approvedAsGlobal.
  ///
  /// In en, this message translates to:
  /// **'Approved as global'**
  String get approvedAsGlobal;

  /// No description provided for @proposalRejected.
  ///
  /// In en, this message translates to:
  /// **'Proposal rejected'**
  String get proposalRejected;

  /// No description provided for @hideNotes.
  ///
  /// In en, this message translates to:
  /// **'Hide notes'**
  String get hideNotes;

  /// No description provided for @showNotes.
  ///
  /// In en, this message translates to:
  /// **'Show notes'**
  String get showNotes;

  /// No description provided for @personalInstructions.
  ///
  /// In en, this message translates to:
  /// **'Personal instructions'**
  String get personalInstructions;

  /// No description provided for @deleteExercise.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get deleteExercise;

  /// No description provided for @deleteExerciseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?\n\nThis action cannot be undone.'**
  String deleteExerciseConfirm(String name);

  /// No description provided for @exerciseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Exercise \"{name}\" deleted'**
  String exerciseDeleted(String name);

  /// No description provided for @errorDeletingExercise.
  ///
  /// In en, this message translates to:
  /// **'Error deleting the exercise'**
  String get errorDeletingExercise;

  /// No description provided for @recordSets.
  ///
  /// In en, this message translates to:
  /// **'Record sets'**
  String get recordSets;

  /// No description provided for @quickRecord.
  ///
  /// In en, this message translates to:
  /// **'Quick record'**
  String get quickRecord;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enterWeight;

  /// No description provided for @invalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Invalid weight'**
  String get invalidWeight;

  /// No description provided for @savedRecord.
  ///
  /// In en, this message translates to:
  /// **'Saved: {weight} kg x {sets} sets x {reps} reps'**
  String savedRecord(String weight, String sets, String reps);

  /// No description provided for @completeAllSets.
  ///
  /// In en, this message translates to:
  /// **'Fill in weight and reps on all sets'**
  String get completeAllSets;

  /// No description provided for @savedAdvancedRecord.
  ///
  /// In en, this message translates to:
  /// **'Saved: {weight} kg ({count} sets)'**
  String savedAdvancedRecord(String weight, String count);

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @advancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Max: {weight} kg | Sets: {count}'**
  String advancedSummary(String weight, String count);

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSet;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routines;

  /// No description provided for @deleteRoutine.
  ///
  /// In en, this message translates to:
  /// **'Delete Routine'**
  String get deleteRoutine;

  /// No description provided for @deleteRoutineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This action cannot be undone.'**
  String deleteRoutineConfirm(String name);

  /// No description provided for @routineDeleted.
  ///
  /// In en, this message translates to:
  /// **'Routine deleted'**
  String get routineDeleted;

  /// No description provided for @errorDeletingRoutine.
  ///
  /// In en, this message translates to:
  /// **'Error deleting routine'**
  String get errorDeletingRoutine;

  /// No description provided for @renameRoutine.
  ///
  /// In en, this message translates to:
  /// **'Rename Routine'**
  String get renameRoutine;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @routineNameExample.
  ///
  /// In en, this message translates to:
  /// **'E.g: Push, Pull, Legs...'**
  String get routineNameExample;

  /// No description provided for @errorRenamingRoutine.
  ///
  /// In en, this message translates to:
  /// **'Error renaming routine'**
  String get errorRenamingRoutine;

  /// No description provided for @noRoutinesYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have routines yet'**
  String get noRoutinesYet;

  /// No description provided for @createFirstRoutine.
  ///
  /// In en, this message translates to:
  /// **'Create your first routine to organize your workouts'**
  String get createFirstRoutine;

  /// No description provided for @createRoutine.
  ///
  /// In en, this message translates to:
  /// **'Create Routine'**
  String get createRoutine;

  /// No description provided for @errorLoadingRoutines.
  ///
  /// In en, this message translates to:
  /// **'Error loading routines'**
  String get errorLoadingRoutines;

  /// No description provided for @noExercisesCount.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercisesCount;

  /// No description provided for @oneExercise.
  ///
  /// In en, this message translates to:
  /// **'1 exercise'**
  String get oneExercise;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String exerciseCount(int count);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get newRoutine;

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineName;

  /// No description provided for @routineNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: Push, Pull, Legs, Full Body...'**
  String get routineNameHint;

  /// No description provided for @enterRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the routine'**
  String get enterRoutineName;

  /// No description provided for @routineNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get routineNameMinLength;

  /// No description provided for @willBeAddedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Will be added automatically:'**
  String get willBeAddedAutomatically;

  /// No description provided for @canAddMoreExercisesLater.
  ///
  /// In en, this message translates to:
  /// **'You can add more exercises later'**
  String get canAddMoreExercisesLater;

  /// No description provided for @canAddExercisesLater.
  ///
  /// In en, this message translates to:
  /// **'You can add exercises to your routine later'**
  String get canAddExercisesLater;

  /// No description provided for @exerciseAddedToRoutine.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" added to routine'**
  String exerciseAddedToRoutine(String name);

  /// No description provided for @errorCreatingRoutine.
  ///
  /// In en, this message translates to:
  /// **'Error creating routine'**
  String get errorCreatingRoutine;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get todayProgress;

  /// No description provided for @exercisesProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} exercises'**
  String exercisesProgress(String completed, String total);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @completeRoutine.
  ///
  /// In en, this message translates to:
  /// **'Complete Routine ({completed}/{total})'**
  String completeRoutine(String completed, String total);

  /// No description provided for @routineCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} completed'**
  String routineCompleted(String name);

  /// No description provided for @routineMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as completed'**
  String routineMarkedCompleted(String name);

  /// No description provided for @noExercisesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added exercises yet'**
  String get noExercisesAddedYet;

  /// No description provided for @addExercisesToBuildRoutine.
  ///
  /// In en, this message translates to:
  /// **'Add exercises to build your routine'**
  String get addExercisesToBuildRoutine;

  /// No description provided for @addExercises.
  ///
  /// In en, this message translates to:
  /// **'Add Exercises'**
  String get addExercises;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// No description provided for @routineNotFound.
  ///
  /// In en, this message translates to:
  /// **'Routine not found'**
  String get routineNotFound;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @removeFromRoutine.
  ///
  /// In en, this message translates to:
  /// **'Remove from routine'**
  String get removeFromRoutine;

  /// No description provided for @removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise'**
  String get removeExercise;

  /// No description provided for @removeExerciseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from the routine?'**
  String removeExerciseConfirm(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @errorRemovingExercise.
  ///
  /// In en, this message translates to:
  /// **'Error removing exercise'**
  String get errorRemovingExercise;

  /// No description provided for @routineNameExampleShort.
  ///
  /// In en, this message translates to:
  /// **'E.g: Push Day'**
  String get routineNameExampleShort;

  /// No description provided for @deleteRoutineConfirmFull.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?\n\nThis action cannot be undone.'**
  String deleteRoutineConfirmFull(String name);

  /// No description provided for @searchExercisePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search exercise...'**
  String get searchExercisePlaceholder;

  /// No description provided for @addCount.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String addCount(int count);

  /// No description provided for @exerciseAdded.
  ///
  /// In en, this message translates to:
  /// **'Exercise added'**
  String get exerciseAdded;

  /// No description provided for @exercisesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises added'**
  String exercisesAdded(int count);

  /// No description provided for @errorAdding.
  ///
  /// In en, this message translates to:
  /// **'Error adding'**
  String get errorAdding;

  /// No description provided for @alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get alreadyAdded;

  /// No description provided for @addToRoutine.
  ///
  /// In en, this message translates to:
  /// **'Add to Routine'**
  String get addToRoutine;

  /// No description provided for @errorLoadingRoutinesSheet.
  ///
  /// In en, this message translates to:
  /// **'Error loading routines'**
  String get errorLoadingRoutinesSheet;

  /// No description provided for @noRoutinesSheet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have routines'**
  String get noRoutinesSheet;

  /// No description provided for @createRoutineToOrganize.
  ///
  /// In en, this message translates to:
  /// **'Create a routine to organize your exercises'**
  String get createRoutineToOrganize;

  /// No description provided for @createNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'Create new routine'**
  String get createNewRoutine;

  /// No description provided for @addedToRoutine.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{name}\"'**
  String addedToRoutine(String name);

  /// No description provided for @exerciseAlreadyInRoutine.
  ///
  /// In en, this message translates to:
  /// **'Exercise is already in the routine'**
  String get exerciseAlreadyInRoutine;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @editDate.
  ///
  /// In en, this message translates to:
  /// **'Edit - {date}'**
  String editDate(String date);

  /// No description provided for @addExerciseButton.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExerciseButton;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @noRecordsThisDay.
  ///
  /// In en, this message translates to:
  /// **'No records this day'**
  String get noRecordsThisDay;

  /// No description provided for @addExerciseWithButton.
  ///
  /// In en, this message translates to:
  /// **'Add an exercise with the button below'**
  String get addExerciseWithButton;

  /// No description provided for @completedRoutines.
  ///
  /// In en, this message translates to:
  /// **'Completed routines'**
  String get completedRoutines;

  /// No description provided for @registeredExercises.
  ///
  /// In en, this message translates to:
  /// **'Registered exercises'**
  String get registeredExercises;

  /// No description provided for @unknownExercise.
  ///
  /// In en, this message translates to:
  /// **'Unknown exercise'**
  String get unknownExercise;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get deleteRecord;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the record of \"{name}\" ({weight} kg)?'**
  String deleteRecordConfirm(String name, String weight);

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'\n\nThis action cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No description provided for @errorDeleting.
  ///
  /// In en, this message translates to:
  /// **'Error deleting'**
  String get errorDeleting;

  /// No description provided for @deleteCompletedRoutine.
  ///
  /// In en, this message translates to:
  /// **'Delete completed routine'**
  String get deleteCompletedRoutine;

  /// No description provided for @deleteCompletedRoutineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the record of \"{name}\"?'**
  String deleteCompletedRoutineConfirm(String name);

  /// No description provided for @addDate.
  ///
  /// In en, this message translates to:
  /// **'Add - {date}'**
  String addDate(String date);

  /// No description provided for @exercisesTab.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesTab;

  /// No description provided for @routinesTab.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routinesTab;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get noExercisesFound;

  /// No description provided for @addOneExercise.
  ///
  /// In en, this message translates to:
  /// **'Add 1 exercise'**
  String get addOneExercise;

  /// No description provided for @addMultipleExercises.
  ///
  /// In en, this message translates to:
  /// **'Add {count} exercises'**
  String addMultipleExercises(int count);

  /// No description provided for @exerciseNameAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String exerciseNameAdded(String name);

  /// No description provided for @countExercisesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises added'**
  String countExercisesAdded(int count);

  /// No description provided for @errorAddingExercises.
  ///
  /// In en, this message translates to:
  /// **'Error adding'**
  String get errorAddingExercises;

  /// No description provided for @noRoutinesAvailable.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have routines'**
  String get noRoutinesAvailable;

  /// No description provided for @createRoutineFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a routine first'**
  String get createRoutineFirst;

  /// No description provided for @routineAddedWithExercises.
  ///
  /// In en, this message translates to:
  /// **'{name} added ({count} exercises)'**
  String routineAddedWithExercises(String name, int count);

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @exerciseCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exerciseCountLabel(int count);

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(String error);

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @recordFirstWorkout.
  ///
  /// In en, this message translates to:
  /// **'Record your first workout'**
  String get recordFirstWorkout;

  /// No description provided for @goToExercises.
  ///
  /// In en, this message translates to:
  /// **'Go to exercises'**
  String get goToExercises;

  /// No description provided for @noWorkoutsRecorded.
  ///
  /// In en, this message translates to:
  /// **'You didn\'t record any workout'**
  String get noWorkoutsRecorded;

  /// No description provided for @editDay.
  ///
  /// In en, this message translates to:
  /// **'Edit day'**
  String get editDay;

  /// No description provided for @routineLabel.
  ///
  /// In en, this message translates to:
  /// **'routine'**
  String get routineLabel;

  /// No description provided for @exerciseLabel.
  ///
  /// In en, this message translates to:
  /// **'exercise'**
  String get exerciseLabel;

  /// No description provided for @exercisesCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} exercises'**
  String exercisesCompletedCount(String completed, String total);

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @hundredPercent.
  ///
  /// In en, this message translates to:
  /// **'100%'**
  String get hundredPercent;

  /// No description provided for @completionPercentage.
  ///
  /// In en, this message translates to:
  /// **'{percentage}%'**
  String completionPercentage(String percentage);

  /// No description provided for @detailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get detailed;

  /// No description provided for @setsTimesReps.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets x {reps} reps'**
  String setsTimesReps(String sets, String reps);

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String weightKg(String weight);

  /// No description provided for @lastWorkout.
  ///
  /// In en, this message translates to:
  /// **'Last workout'**
  String get lastWorkout;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @activityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 activity} other{{count} activities}}'**
  String activityCount(int count);

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(String error);

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: John'**
  String get firstNameHint;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: Smith'**
  String get lastNameHint;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ageHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: 25'**
  String get ageHint;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @heightHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: 175'**
  String get heightHint;

  /// No description provided for @cm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cm;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @weightHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: 70.5'**
  String get weightHint;

  /// No description provided for @sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sex;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecified;

  /// No description provided for @allFieldsOptional.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional. Your information is saved securely.'**
  String get allFieldsOptional;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSavingProfile(String error);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An email with instructions will be sent'**
  String get changePasswordSubtitle;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes your account and data'**
  String get deleteAccountSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version {version}{buildSuffix}'**
  String versionInfo(String version, String buildSuffix);

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Record your workouts, exercises and progress at the gym.'**
  String get appDescription;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 GymVault'**
  String get copyright;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'A link to change your password will be sent to:\n\n{email}'**
  String changePasswordMessage(String email);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @emailSentTo.
  ///
  /// In en, this message translates to:
  /// **'Email sent to {email}'**
  String emailSentTo(String email);

  /// No description provided for @errorSendingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error sending email: {error}'**
  String errorSendingEmail(String error);

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTitle;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @errorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String errorSigningOut(String error);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'By deleting your account, all personal and workout data will be deleted.\n\nThis action cannot be undone.'**
  String get deleteAccountMessage;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @deleteAccountFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently?'**
  String get deleteAccountFinalTitle;

  /// No description provided for @deleteAccountFinalMessage.
  ///
  /// In en, this message translates to:
  /// **'All your exercises, routines, weight records and personal data will be deleted.'**
  String get deleteAccountFinalMessage;

  /// No description provided for @deleteDefinitely.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteDefinitely;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deletingAccount;

  /// No description provided for @couldNotGetEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not get account email'**
  String get couldNotGetEmail;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @weightEvolution.
  ///
  /// In en, this message translates to:
  /// **'Weight Evolution'**
  String get weightEvolution;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @positivePercentage.
  ///
  /// In en, this message translates to:
  /// **'+{percentage}%'**
  String positivePercentage(String percentage);

  /// No description provided for @negativePercentage.
  ///
  /// In en, this message translates to:
  /// **'-{percentage}%'**
  String negativePercentage(String percentage);

  /// No description provided for @sinceDate.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String sinceDate(String date);

  /// No description provided for @weightRepsTooltip.
  ///
  /// In en, this message translates to:
  /// **'{weight}kg x {reps} reps'**
  String weightRepsTooltip(String weight, String reps);

  /// No description provided for @weightAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'{weight}kg'**
  String weightAxisLabel(String weight);

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {length} characters'**
  String validationPasswordMinLength(int length);

  /// No description provided for @validationConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get validationConfirmPassword;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validationNameRequired;

  /// No description provided for @validationNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get validationNameMinLength;

  /// No description provided for @validationFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String validationFieldRequired(String fieldName);

  /// No description provided for @validationWeightRequired.
  ///
  /// In en, this message translates to:
  /// **'Weight is required'**
  String get validationWeightRequired;

  /// No description provided for @validationEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationEnterValidNumber;

  /// No description provided for @validationWeightNegative.
  ///
  /// In en, this message translates to:
  /// **'Weight cannot be negative'**
  String get validationWeightNegative;

  /// No description provided for @validationWeightMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum weight is {max} kg'**
  String validationWeightMax(String max);

  /// No description provided for @validationEnterInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get validationEnterInteger;

  /// No description provided for @validationMinSets.
  ///
  /// In en, this message translates to:
  /// **'Minimum 1 set'**
  String get validationMinSets;

  /// No description provided for @validationMaxSets.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} sets'**
  String validationMaxSets(int max);

  /// No description provided for @validationMinReps.
  ///
  /// In en, this message translates to:
  /// **'Minimum 1 rep'**
  String get validationMinReps;

  /// No description provided for @validationMaxReps.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} reps'**
  String validationMaxReps(int max);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @routineCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 routine} other{{count} routines}}'**
  String routineCountBadge(int count);

  /// No description provided for @generalProgress.
  ///
  /// In en, this message translates to:
  /// **'General Progress'**
  String get generalProgress;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @workoutDays.
  ///
  /// In en, this message translates to:
  /// **'Workout days'**
  String get workoutDays;

  /// No description provided for @totalVolume.
  ///
  /// In en, this message translates to:
  /// **'Total volume'**
  String get totalVolume;

  /// No description provided for @dominantMuscle.
  ///
  /// In en, this message translates to:
  /// **'Dominant muscle'**
  String get dominantMuscle;

  /// No description provided for @bestProgress.
  ///
  /// In en, this message translates to:
  /// **'Best progress'**
  String get bestProgress;

  /// No description provided for @muscleDistribution.
  ///
  /// In en, this message translates to:
  /// **'Muscle Distribution'**
  String get muscleDistribution;

  /// No description provided for @topMuscles.
  ///
  /// In en, this message translates to:
  /// **'Top muscles'**
  String get topMuscles;

  /// No description provided for @forgottenMusclesWarning.
  ///
  /// In en, this message translates to:
  /// **'Muscles with low work: {muscles}'**
  String forgottenMusclesWarning(String muscles);

  /// No description provided for @noProgressData.
  ///
  /// In en, this message translates to:
  /// **'No progress data'**
  String get noProgressData;

  /// No description provided for @noProgressDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record your workouts to see your progress'**
  String get noProgressDataSubtitle;

  /// No description provided for @errorLoadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Error loading progress'**
  String get errorLoadingProgress;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get last30Days;

  /// No description provided for @last90Days.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get last90Days;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get last6Months;

  /// No description provided for @last12Months.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get last12Months;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @volumeKg.
  ///
  /// In en, this message translates to:
  /// **'{volume} kg'**
  String volumeKg(String volume);

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} d'**
  String days(String count);

  /// No description provided for @workoutDaysTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unique days you trained in this period'**
  String get workoutDaysTooltip;

  /// No description provided for @totalVolumeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Total weight x reps x sets of all exercises'**
  String get totalVolumeTooltip;

  /// No description provided for @dominantMuscleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Muscle group with the highest volume'**
  String get dominantMuscleTooltip;

  /// No description provided for @bestProgressTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exercise with the greatest weight increase'**
  String get bestProgressTooltip;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @setsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// No description provided for @tapChartHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a section for details'**
  String get tapChartHint;
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

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
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
