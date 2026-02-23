// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'GymVault';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get loginSubtitle => 'Inicia sesion para continuar';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'tu@email.com';

  @override
  String get password => 'Contrasena';

  @override
  String get forgotPassword => 'Olvidaste tu contrasena?';

  @override
  String get signIn => 'Iniciar Sesion';

  @override
  String get orContinueWith => 'o continua con';

  @override
  String get noAccount => 'No tienes cuenta? ';

  @override
  String get signUp => 'Registrate';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get registerSubtitle => 'Registrate para empezar';

  @override
  String get name => 'Nombre';

  @override
  String get nameHint => 'Tu nombre';

  @override
  String get confirmPassword => 'Confirmar Contrasena';

  @override
  String get register => 'Registrarse';

  @override
  String get alreadyHaveAccount => 'Ya tienes cuenta? ';

  @override
  String get signInLink => 'Inicia Sesion';

  @override
  String get recoverPassword => 'Recuperar Contrasena';

  @override
  String get recoverPasswordSubtitle =>
      'Ingresa tu email y te enviaremos un enlace para restablecer tu contrasena';

  @override
  String get sendLink => 'Enviar Enlace';

  @override
  String get backToLogin => 'Volver al Login';

  @override
  String get emailSent => 'Email Enviado';

  @override
  String get emailSentMessage => 'Hemos enviado un enlace de recuperacion a:';

  @override
  String get emailSentInstructions =>
      'Revisa tu bandeja de entrada y sigue las instrucciones del email para restablecer tu contrasena.';

  @override
  String get didNotReceiveEmail => 'No recibiste el email? Intentar de nuevo';

  @override
  String get legalPrefix => 'Al continuar, aceptas los ';

  @override
  String get termsAndConditions => 'Terminos y Condiciones';

  @override
  String get legalMiddle => ' y la ';

  @override
  String get privacyPolicy => 'Politica de Privacidad';

  @override
  String get exercises => 'Ejercicios';

  @override
  String get menu => 'Menu';

  @override
  String get searchExercise => 'Buscar ejercicio...';

  @override
  String get myExercises => 'Mis ejercicios';

  @override
  String get personal => 'Personal';

  @override
  String get noExercises => 'No tienes ejercicios';

  @override
  String get createFirstExercise => 'Crea tu primer ejercicio personalizado';

  @override
  String get noResults => 'Sin resultados';

  @override
  String noCustomExercisesMatchSearch(String query) {
    return 'No tienes ejercicios que coincidan con \"$query\"';
  }

  @override
  String noFilteredExercisesMatchSearch(String filter, String query) {
    return 'No hay ejercicios de \"$filter\" que coincidan con \"$query\"';
  }

  @override
  String noExercisesMatchSearch(String query) {
    return 'No hay ejercicios que coincidan con \"$query\"';
  }

  @override
  String get noExercisesInGroup => 'No hay ejercicios';

  @override
  String get selectAnotherMuscleGroup => 'Selecciona otro grupo muscular';

  @override
  String get notTheRightOne => 'No es ninguno de estos?';

  @override
  String get createOneForYou => 'Puedes crear uno solo para ti';

  @override
  String get addExercise => 'Agregar ejercicio';

  @override
  String get errorLoadingExercises => 'Error al cargar ejercicios';

  @override
  String get retry => 'Reintentar';

  @override
  String get errorLoadingExercise => 'Error al cargar ejercicio';

  @override
  String get exerciseNotFound => 'Ejercicio no encontrado';

  @override
  String get routine => 'Rutina';

  @override
  String get hideExerciseDetails => 'Ocultar detalles del ejercicio';

  @override
  String get showExerciseDetails => 'Ver detalles del ejercicio';

  @override
  String get tapToHide => 'Toca para ocultar';

  @override
  String get descriptionVideoInstructions =>
      'Descripcion, video e instrucciones';

  @override
  String get instructions => 'Instrucciones';

  @override
  String get newExercise => 'Nuevo Ejercicio';

  @override
  String get addPhoto => 'Agregar foto';

  @override
  String get optionalTapToSelect => 'Opcional - Toca para seleccionar';

  @override
  String get muscleGroup => 'Grupo muscular';

  @override
  String get selectMuscleGroup => 'Selecciona el grupo muscular principal';

  @override
  String get exerciseName => 'Nombre del ejercicio';

  @override
  String get exerciseNameHint => 'Nombre del ejercicio o maquina';

  @override
  String get exerciseNameExample => 'Ej: Press inclinado con mancuernas';

  @override
  String get personalNotes => 'Notas personales';

  @override
  String get personalNotesHint => 'Instrucciones o notas para ti (opcional)';

  @override
  String get personalNotesExample =>
      'Ej: Bajar lento, subir explosivo.\nMantener codos a 45 grados.';

  @override
  String get createExercise => 'Crear ejercicio';

  @override
  String get cancel => 'Cancelar';

  @override
  String get selectImage => 'Seleccionar imagen';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get chooseFromGallery => 'Elegir de galeria';

  @override
  String get removeImage => 'Eliminar imagen';

  @override
  String errorSelectingImage(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String get mustSignInToCreateExercises =>
      'Debes iniciar sesion para crear ejercicios';

  @override
  String get errorUploadingImage =>
      'Error al subir la imagen. Intenta de nuevo.';

  @override
  String exerciseCreated(String name) {
    return 'Ejercicio \"$name\" creado';
  }

  @override
  String get errorCreatingExercise => 'Error al crear el ejercicio';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get nameIsRequired => 'El nombre es obligatorio';

  @override
  String get nameMinLength => 'El nombre debe tener al menos 3 caracteres';

  @override
  String get nameTooLong => 'El nombre es muy largo';

  @override
  String get editExercise => 'Editar Ejercicio';

  @override
  String get error => 'Error';

  @override
  String get notFound => 'No encontrado';

  @override
  String get changeImage => 'Cambiar imagen';

  @override
  String get mustSignInToEditExercises =>
      'Debes iniciar sesion para editar ejercicios';

  @override
  String exerciseUpdated(String name) {
    return 'Ejercicio \"$name\" actualizado';
  }

  @override
  String get errorUpdatingExercise => 'Error al actualizar el ejercicio';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get pendingReview => 'Pendiente de revision';

  @override
  String get approvedAsGlobal => 'Aprobado como global';

  @override
  String get proposalRejected => 'Propuesta rechazada';

  @override
  String get hideNotes => 'Ocultar notas';

  @override
  String get showNotes => 'Ver notas';

  @override
  String get personalInstructions => 'Instrucciones personales';

  @override
  String get deleteExercise => 'Eliminar ejercicio';

  @override
  String deleteExerciseConfirm(String name) {
    return 'Estas seguro que deseas eliminar \"$name\"?\n\nEsta accion no se puede deshacer.';
  }

  @override
  String exerciseDeleted(String name) {
    return 'Ejercicio \"$name\" eliminado';
  }

  @override
  String get errorDeletingExercise => 'Error al eliminar el ejercicio';

  @override
  String get recordSets => 'Registrar series';

  @override
  String get quickRecord => 'Registro rapido';

  @override
  String get save => 'Guardar';

  @override
  String get enterWeight => 'Ingresa el peso';

  @override
  String get invalidWeight => 'Peso invalido';

  @override
  String savedRecord(String weight, String sets, String reps) {
    return 'Guardado: $weight kg x $sets series x $reps reps';
  }

  @override
  String get completeAllSets => 'Completa peso y reps en todas las series';

  @override
  String savedAdvancedRecord(String weight, String count) {
    return 'Guardado: $weight kg ($count series)';
  }

  @override
  String get sets => 'Series';

  @override
  String get reps => 'Reps';

  @override
  String get kg => 'kg';

  @override
  String advancedSummary(String weight, String count) {
    return 'Max: $weight kg | Series: $count';
  }

  @override
  String get addSet => 'Agregar serie';

  @override
  String get routines => 'Rutinas';

  @override
  String get deleteRoutine => 'Eliminar Rutina';

  @override
  String deleteRoutineConfirm(String name) {
    return 'Eliminar \"$name\"? Esta accion no se puede deshacer.';
  }

  @override
  String get routineDeleted => 'Rutina eliminada';

  @override
  String get errorDeletingRoutine => 'Error al eliminar rutina';

  @override
  String get renameRoutine => 'Renombrar Rutina';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get routineNameExample => 'Ej: Push, Pull, Legs...';

  @override
  String get errorRenamingRoutine => 'Error al renombrar rutina';

  @override
  String get noRoutinesYet => 'Aun no tienes rutinas';

  @override
  String get createFirstRoutine =>
      'Crea tu primera rutina para organizar tus entrenamientos';

  @override
  String get createRoutine => 'Crear Rutina';

  @override
  String get errorLoadingRoutines => 'Error al cargar rutinas';

  @override
  String get noExercisesCount => 'Sin ejercicios';

  @override
  String get oneExercise => '1 ejercicio';

  @override
  String exerciseCount(int count) {
    return '$count ejercicios';
  }

  @override
  String get rename => 'Renombrar';

  @override
  String get newRoutine => 'Nueva Rutina';

  @override
  String get routineName => 'Nombre de la rutina';

  @override
  String get routineNameHint => 'Ej: Push, Pull, Legs, Full Body...';

  @override
  String get enterRoutineName => 'Ingresa un nombre para la rutina';

  @override
  String get routineNameMinLength =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get willBeAddedAutomatically => 'Se agregara automaticamente:';

  @override
  String get canAddMoreExercisesLater =>
      'Despues podras agregar mas ejercicios';

  @override
  String get canAddExercisesLater =>
      'Despues podras agregar ejercicios a tu rutina';

  @override
  String exerciseAddedToRoutine(String name) {
    return '\"$name\" agregado a la rutina';
  }

  @override
  String get errorCreatingRoutine => 'Error al crear rutina';

  @override
  String get loading => 'Cargando...';

  @override
  String get todayProgress => 'Progreso de hoy';

  @override
  String exercisesProgress(String completed, String total) {
    return '$completed/$total ejercicios';
  }

  @override
  String get completed => 'Completada';

  @override
  String get markAsCompleted => 'Marcar como Completada';

  @override
  String completeRoutine(String completed, String total) {
    return 'Completar Rutina ($completed/$total)';
  }

  @override
  String routineCompleted(String name) {
    return '$name completada';
  }

  @override
  String routineMarkedCompleted(String name) {
    return '$name marcada como completada';
  }

  @override
  String get noExercisesAddedYet => 'Aun no agregaste ejercicios';

  @override
  String get addExercisesToBuildRoutine =>
      'Agrega ejercicios para armar tu rutina';

  @override
  String get addExercises => 'Agregar Ejercicios';

  @override
  String get errorLoading => 'Error al cargar';

  @override
  String get routineNotFound => 'Rutina no encontrada';

  @override
  String get back => 'Volver';

  @override
  String get today => 'Hoy';

  @override
  String get removeFromRoutine => 'Quitar de la rutina';

  @override
  String get removeExercise => 'Quitar Ejercicio';

  @override
  String removeExerciseConfirm(String name) {
    return 'Quitar \"$name\" de la rutina?';
  }

  @override
  String get remove => 'Quitar';

  @override
  String get errorRemovingExercise => 'Error al quitar ejercicio';

  @override
  String get routineNameExampleShort => 'Ej: Push Day';

  @override
  String deleteRoutineConfirmFull(String name) {
    return 'Estas seguro de eliminar \"$name\"?\n\nEsta accion no se puede deshacer.';
  }

  @override
  String get searchExercisePlaceholder => 'Buscar ejercicio...';

  @override
  String addCount(int count) {
    return 'Agregar ($count)';
  }

  @override
  String get exerciseAdded => 'Ejercicio agregado';

  @override
  String exercisesAdded(int count) {
    return '$count ejercicios agregados';
  }

  @override
  String get errorAdding => 'Error al agregar';

  @override
  String get alreadyAdded => 'Ya agregado';

  @override
  String get addToRoutine => 'Agregar a Rutina';

  @override
  String get errorLoadingRoutinesSheet => 'Error al cargar rutinas';

  @override
  String get noRoutinesSheet => 'No tienes rutinas';

  @override
  String get createRoutineToOrganize =>
      'Crea una rutina para organizar tus ejercicios';

  @override
  String get createNewRoutine => 'Crear nueva rutina';

  @override
  String addedToRoutine(String name) {
    return 'Agregado a \"$name\"';
  }

  @override
  String get exerciseAlreadyInRoutine => 'El ejercicio ya esta en la rutina';

  @override
  String get history => 'Historial';

  @override
  String get errorLoadingHistory => 'Error al cargar historial';

  @override
  String editDate(String date) {
    return 'Editar - $date';
  }

  @override
  String get addExerciseButton => 'Agregar ejercicio';

  @override
  String get yesterday => 'Ayer';

  @override
  String get noRecordsThisDay => 'No hay registros este dia';

  @override
  String get addExerciseWithButton =>
      'Agrega un ejercicio con el boton de abajo';

  @override
  String get completedRoutines => 'Rutinas completadas';

  @override
  String get registeredExercises => 'Ejercicios registrados';

  @override
  String get unknownExercise => 'Ejercicio desconocido';

  @override
  String get deleteRecord => 'Eliminar registro';

  @override
  String deleteRecordConfirm(String name, String weight) {
    return 'Eliminar el registro de \"$name\" ($weight kg)?';
  }

  @override
  String get cannotBeUndone => '\n\nEsta accion no se puede deshacer.';

  @override
  String get recordDeleted => 'Registro eliminado';

  @override
  String get errorDeleting => 'Error al eliminar';

  @override
  String get deleteCompletedRoutine => 'Eliminar rutina completada';

  @override
  String deleteCompletedRoutineConfirm(String name) {
    return 'Eliminar el registro de \"$name\"?';
  }

  @override
  String addDate(String date) {
    return 'Agregar - $date';
  }

  @override
  String get exercisesTab => 'Ejercicios';

  @override
  String get routinesTab => 'Rutinas';

  @override
  String get noExercisesFound => 'No se encontraron ejercicios';

  @override
  String get addOneExercise => 'Agregar 1 ejercicio';

  @override
  String addMultipleExercises(int count) {
    return 'Agregar $count ejercicios';
  }

  @override
  String exerciseNameAdded(String name) {
    return '$name agregado';
  }

  @override
  String countExercisesAdded(int count) {
    return '$count ejercicios agregados';
  }

  @override
  String get errorAddingExercises => 'Error al agregar';

  @override
  String get noRoutinesAvailable => 'No tienes rutinas';

  @override
  String get createRoutineFirst => 'Crea una rutina primero';

  @override
  String routineAddedWithExercises(String name, int count) {
    return '$name agregada ($count ejercicios)';
  }

  @override
  String get custom => 'Custom';

  @override
  String exerciseCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '1 ejercicio',
    );
    return '$_temp0';
  }

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get noRecords => 'Sin registros';

  @override
  String get recordFirstWorkout => 'Registra tu primer entrenamiento';

  @override
  String get goToExercises => 'Ir a ejercicios';

  @override
  String get noWorkoutsRecorded => 'No registraste ningun entrenamiento';

  @override
  String get editDay => 'Editar dia';

  @override
  String get routineLabel => 'rutina';

  @override
  String get exerciseLabel => 'ejercicio';

  @override
  String exercisesCompletedCount(String completed, String total) {
    return '$completed/$total ejercicios';
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
  String get detailed => 'Detallado';

  @override
  String setsTimesReps(String sets, String reps) {
    return '$sets series x $reps reps';
  }

  @override
  String weightKg(String weight) {
    return '$weight kg';
  }

  @override
  String get lastWorkout => 'Ultimo entrenamiento';

  @override
  String daysAgo(int count) {
    return 'Hace $count dias';
  }

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actividades',
      one: '1 actividad',
    );
    return '$_temp0';
  }

  @override
  String get myProfile => 'Mi Perfil';

  @override
  String errorLoadingProfile(String error) {
    return 'Error al cargar perfil: $error';
  }

  @override
  String get firstName => 'Nombre';

  @override
  String get firstNameHint => 'Ej: Juan';

  @override
  String get lastName => 'Apellido';

  @override
  String get lastNameHint => 'Ej: Perez';

  @override
  String get age => 'Edad';

  @override
  String get ageHint => 'Ej: 25';

  @override
  String get years => 'anos';

  @override
  String get height => 'Altura';

  @override
  String get heightHint => 'Ej: 175';

  @override
  String get cm => 'cm';

  @override
  String get weight => 'Peso';

  @override
  String get weightHint => 'Ej: 70.5';

  @override
  String get sex => 'Sexo';

  @override
  String get unspecified => 'Sin especificar';

  @override
  String get allFieldsOptional =>
      'Todos los campos son opcionales. Tu informacion se guarda de forma segura.';

  @override
  String get profileSaved => 'Perfil guardado';

  @override
  String errorSavingProfile(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get settings => 'Configuracion';

  @override
  String get account => 'Cuenta';

  @override
  String get changePassword => 'Cambiar contrasena';

  @override
  String get changePasswordSubtitle => 'Se enviara un email con instrucciones';

  @override
  String get session => 'Sesion';

  @override
  String get signOut => 'Cerrar sesion';

  @override
  String get legal => 'Legal';

  @override
  String get dangerZone => 'Zona de peligro';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle =>
      'Elimina permanentemente tu cuenta y datos';

  @override
  String get about => 'Acerca de';

  @override
  String versionInfo(String version, String buildSuffix) {
    return 'Version $version$buildSuffix';
  }

  @override
  String get appDescription =>
      'Registra tus entrenamientos, ejercicios y progreso en el gimnasio.';

  @override
  String get copyright => '© 2026 GymVault';

  @override
  String get changePasswordTitle => 'Cambiar Contrasena';

  @override
  String changePasswordMessage(String email) {
    return 'Se enviara un enlace para cambiar tu contrasena a:\n\n$email';
  }

  @override
  String get send => 'Enviar';

  @override
  String emailSentTo(String email) {
    return 'Email enviado a $email';
  }

  @override
  String errorSendingEmail(String error) {
    return 'Error al enviar email: $error';
  }

  @override
  String get signOutTitle => 'Cerrar Sesion';

  @override
  String get signOutConfirm => 'Estas seguro que deseas cerrar sesion?';

  @override
  String errorSigningOut(String error) {
    return 'Error al cerrar sesion: $error';
  }

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountMessage =>
      'Al eliminar la cuenta, se eliminan todos los datos personales y de entrenamiento asociados.\n\nEsta accion no se puede deshacer.';

  @override
  String get continueAction => 'Continuar';

  @override
  String get deleteAccountFinalTitle => 'Eliminar cuenta definitivamente?';

  @override
  String get deleteAccountFinalMessage =>
      'Se eliminaran todos tus ejercicios, rutinas, registros de peso y datos personales.';

  @override
  String get deleteDefinitely => 'Eliminar definitivamente';

  @override
  String get accountDeleted => 'Cuenta eliminada';

  @override
  String get deletingAccount => 'Eliminando cuenta...';

  @override
  String get couldNotGetEmail => 'No se pudo obtener el email de la cuenta';

  @override
  String get user => 'Usuario';

  @override
  String get configuration => 'Configuracion';

  @override
  String get weightEvolution => 'Evolucion de Peso';

  @override
  String get stable => 'Estable';

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
    return 'desde $date';
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
  String get pageNotFound => 'Pagina no encontrada';

  @override
  String get goToHome => 'Ir al Inicio';

  @override
  String get validationEmailRequired => 'El email es requerido';

  @override
  String get validationEmailInvalid => 'Ingresa un email valido';

  @override
  String get validationPasswordRequired => 'La contrasena es requerida';

  @override
  String validationPasswordMinLength(int length) {
    return 'La contrasena debe tener al menos $length caracteres';
  }

  @override
  String get validationConfirmPassword => 'Confirma tu contrasena';

  @override
  String get validationPasswordsDoNotMatch => 'Las contrasenas no coinciden';

  @override
  String get validationNameRequired => 'El nombre es requerido';

  @override
  String get validationNameMinLength =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String validationFieldRequired(String fieldName) {
    return '$fieldName es requerido';
  }

  @override
  String get validationWeightRequired => 'El peso es requerido';

  @override
  String get validationEnterValidNumber => 'Ingresa un numero valido';

  @override
  String get validationWeightNegative => 'El peso no puede ser negativo';

  @override
  String validationWeightMax(String max) {
    return 'El peso maximo es $max kg';
  }

  @override
  String get validationEnterInteger => 'Ingresa un numero entero';

  @override
  String get validationMinSets => 'Minimo 1 serie';

  @override
  String validationMaxSets(int max) {
    return 'Maximo $max series';
  }

  @override
  String get validationMinReps => 'Minimo 1 repeticion';

  @override
  String validationMaxReps(int max) {
    return 'Maximo $max repeticiones';
  }

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Ingles';

  @override
  String get spanish => 'Espanol';

  @override
  String get portuguese => 'Portugues';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String routineCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rutinas',
      one: '1 rutina',
    );
    return '$_temp0';
  }

  @override
  String get generalProgress => 'Progreso General';

  @override
  String get summary => 'Resumen';

  @override
  String get workoutDays => 'Dias de entreno';

  @override
  String get totalVolume => 'Volumen total';

  @override
  String get dominantMuscle => 'Musculo dominante';

  @override
  String get bestProgress => 'Mejor progreso';

  @override
  String get muscleDistribution => 'Distribucion Muscular';

  @override
  String get topMuscles => 'Musculos principales';

  @override
  String forgottenMusclesWarning(String muscles) {
    return 'Musculos con poco trabajo: $muscles';
  }

  @override
  String get noProgressData => 'Sin datos de progreso';

  @override
  String get noProgressDataSubtitle =>
      'Registra tus entrenamientos para ver tu progreso';

  @override
  String get errorLoadingProgress => 'Error al cargar progreso';

  @override
  String get last30Days => '30 dias';

  @override
  String get last90Days => '90 dias';

  @override
  String get last6Months => '6 meses';

  @override
  String get last12Months => '12 meses';

  @override
  String get allTime => 'Todo';

  @override
  String volumeKg(String volume) {
    return '$volume kg';
  }

  @override
  String days(String count) {
    return '$count d';
  }

  @override
  String get workoutDaysTooltip =>
      'Dias unicos de entrenamiento en este periodo';

  @override
  String get totalVolumeTooltip =>
      'Peso total x reps x series de todos los ejercicios';

  @override
  String get dominantMuscleTooltip =>
      'Grupo muscular con mayor volumen acumulado';

  @override
  String get bestProgressTooltip => 'Ejercicio con mayor aumento de peso';

  @override
  String get volumeLabel => 'Volumen';

  @override
  String get setsLabel => 'Series';

  @override
  String get tapChartHint => 'Toca una seccion para ver detalles';

  @override
  String get bestMuscleProgress => 'Mejor progreso muscular';

  @override
  String get detailedProgress => 'Progreso Detallado';

  @override
  String get byMuscleGroup => 'Por grupo muscular';

  @override
  String get byExercise => 'Por ejercicio';

  @override
  String get currentVolume => 'Actual';

  @override
  String get previousVolume => 'Anterior';

  @override
  String get newLabel => 'Nuevo';

  @override
  String get noProgressYet => 'No hay suficientes datos para comparar progreso';

  @override
  String get minRecordsHint => 'Ejercicios con 3+ entrenamientos';

  @override
  String yourProgressInPeriod(String period) {
    return 'Tu progreso en los ultimos $period';
  }

  @override
  String get yourProgressAllTime => 'Tu progreso total';

  @override
  String get tapForDetails => 'Toca para ver detalles';

  @override
  String get bestMuscleProgressTooltip =>
      'Grupo muscular con mayor aumento de volumen';

  @override
  String get vsLastPeriod => 'vs periodo anterior';

  @override
  String progressPercentage(String percentage) {
    return '+$percentage%';
  }

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationsSubtitle => 'Recordatorios, progreso y mas';

  @override
  String get enableNotifications => 'Activar notificaciones';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get trainingReminders => 'Recordatorio de entrenamiento';

  @override
  String get trainingRemindersDesc =>
      'Te avisa en tu hora habitual de entrenamiento';

  @override
  String get incompleteSessionReminder => 'Sesion incompleta';

  @override
  String get incompleteSessionDesc => 'Te recuerda completar tu rutina';

  @override
  String get progressSection => 'Progreso';

  @override
  String get progressMilestones => 'Hitos de progreso';

  @override
  String get progressMilestonesDesc => 'Celebra tus mejoras';

  @override
  String get news => 'Noticias';

  @override
  String get gymvaultUpdates => 'Actualizaciones GymVault';

  @override
  String get gymvaultUpdatesDesc => 'Novedades y anuncios';

  @override
  String get doNotDisturb => 'No molestar';

  @override
  String get dndDescription => 'Sin notificaciones durante este horario';

  @override
  String get dndFrom => 'Desde';

  @override
  String get dndTo => 'Hasta';

  @override
  String get notifTrainingTitle => 'Entrenamos hoy?';

  @override
  String get notifTrainingBody => 'Es tu hora habitual de entrenar. Vamos!';

  @override
  String get notifIncompleteTitle => 'Terminas tu sesion?';

  @override
  String get notifIncompleteBody =>
      'Registraste ejercicios antes. Quieres completar tu rutina?';

  @override
  String notifMilestoneTitle(String muscleGroup) {
    return '$muscleGroup esta creciendo!';
  }

  @override
  String notifMilestoneBody(String muscleGroup, String percentage) {
    return 'Tu volumen de $muscleGroup mejoro $percentage% este mes. Sigue asi!';
  }

  @override
  String get notifPermissionRequired =>
      'Se necesita permiso de notificaciones para enviar recordatorios';

  @override
  String get unsavedSetsTitle => 'Cambios sin guardar';

  @override
  String get unsavedSetsBody =>
      'Tienes cambios sin guardar en tus series. Si sales, se perderán.';

  @override
  String get leave => 'Salir';

  @override
  String get timerTitle => 'Descanso';

  @override
  String get timerStart => 'Iniciar';

  @override
  String get timerPause => 'Pausar';

  @override
  String get timerResume => 'Reanudar';

  @override
  String get timerStop => 'Detener';

  @override
  String get timerReset => 'Reiniciar';

  @override
  String get timerCustom => 'Personalizado';

  @override
  String get timerFinishedTitle => '¡Tiempo!';

  @override
  String get timerFinishedBody => 'Tu descanso terminó';

  @override
  String timerNotifBody(String remaining) {
    return '$remaining restante';
  }
}
