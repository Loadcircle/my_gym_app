// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'GymVault';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get loginSubtitle => 'Faca login para continuar';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'voce@email.com';

  @override
  String get password => 'Senha';

  @override
  String get forgotPassword => 'Esqueceu sua senha?';

  @override
  String get signIn => 'Entrar';

  @override
  String get orContinueWith => 'ou continue com';

  @override
  String get noAccount => 'Nao tem conta? ';

  @override
  String get signUp => 'Cadastre-se';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get registerSubtitle => 'Cadastre-se para comecar';

  @override
  String get name => 'Nome';

  @override
  String get nameHint => 'Seu nome';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get register => 'Cadastrar';

  @override
  String get alreadyHaveAccount => 'Ja tem conta? ';

  @override
  String get signInLink => 'Entrar';

  @override
  String get recoverPassword => 'Recuperar Senha';

  @override
  String get recoverPasswordSubtitle =>
      'Digite seu email e enviaremos um link para redefinir sua senha';

  @override
  String get sendLink => 'Enviar Link';

  @override
  String get backToLogin => 'Voltar ao Login';

  @override
  String get emailSent => 'Email Enviado';

  @override
  String get emailSentMessage => 'Enviamos um link de recuperacao para:';

  @override
  String get emailSentInstructions =>
      'Verifique sua caixa de entrada e siga as instrucoes do email para redefinir sua senha.';

  @override
  String get didNotReceiveEmail => 'Nao recebeu o email? Tentar novamente';

  @override
  String get legalPrefix => 'Ao continuar, voce aceita os ';

  @override
  String get termsAndConditions => 'Termos e Condicoes';

  @override
  String get legalMiddle => ' e a ';

  @override
  String get privacyPolicy => 'Politica de Privacidade';

  @override
  String get exercises => 'Exercicios';

  @override
  String get menu => 'Menu';

  @override
  String get searchExercise => 'Buscar exercicio...';

  @override
  String get myExercises => 'Meus exercicios';

  @override
  String get personal => 'Pessoal';

  @override
  String get noExercises => 'Voce nao tem exercicios';

  @override
  String get createFirstExercise => 'Crie seu primeiro exercicio personalizado';

  @override
  String get noResults => 'Sem resultados';

  @override
  String noCustomExercisesMatchSearch(String query) {
    return 'Voce nao tem exercicios que correspondam a \"$query\"';
  }

  @override
  String noFilteredExercisesMatchSearch(String filter, String query) {
    return 'Nao ha exercicios de \"$filter\" que correspondam a \"$query\"';
  }

  @override
  String noExercisesMatchSearch(String query) {
    return 'Nao ha exercicios que correspondam a \"$query\"';
  }

  @override
  String get noExercisesInGroup => 'Nao ha exercicios';

  @override
  String get selectAnotherMuscleGroup => 'Selecione outro grupo muscular';

  @override
  String get notTheRightOne => 'Nao e nenhum desses?';

  @override
  String get createOneForYou => 'Voce pode criar um so para voce';

  @override
  String get addExercise => 'Adicionar exercicio';

  @override
  String get errorLoadingExercises => 'Erro ao carregar exercicios';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get errorLoadingExercise => 'Erro ao carregar exercicio';

  @override
  String get exerciseNotFound => 'Exercicio nao encontrado';

  @override
  String get routine => 'Rotina';

  @override
  String get hideExerciseDetails => 'Ocultar detalhes do exercicio';

  @override
  String get showExerciseDetails => 'Ver detalhes do exercicio';

  @override
  String get tapToHide => 'Toque para ocultar';

  @override
  String get descriptionVideoInstructions => 'Descricao, video e instrucoes';

  @override
  String get instructions => 'Instrucoes';

  @override
  String get newExercise => 'Novo Exercicio';

  @override
  String get addPhoto => 'Adicionar foto';

  @override
  String get optionalTapToSelect => 'Opcional - Toque para selecionar';

  @override
  String get muscleGroup => 'Grupo muscular';

  @override
  String get selectMuscleGroup => 'Selecione o grupo muscular principal';

  @override
  String get exerciseName => 'Nome do exercicio';

  @override
  String get exerciseNameHint => 'Nome do exercicio ou maquina';

  @override
  String get exerciseNameExample => 'Ex: Supino inclinado com halteres';

  @override
  String get personalNotes => 'Notas pessoais';

  @override
  String get personalNotesHint => 'Instrucoes ou notas para voce (opcional)';

  @override
  String get personalNotesExample =>
      'Ex: Descer devagar, subir explosivo.\nManter cotovelos a 45 graus.';

  @override
  String get createExercise => 'Criar exercicio';

  @override
  String get cancel => 'Cancelar';

  @override
  String get selectImage => 'Selecionar imagem';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get chooseFromGallery => 'Escolher da galeria';

  @override
  String get removeImage => 'Remover imagem';

  @override
  String errorSelectingImage(String error) {
    return 'Erro ao selecionar imagem: $error';
  }

  @override
  String get mustSignInToCreateExercises =>
      'Voce precisa fazer login para criar exercicios';

  @override
  String get errorUploadingImage => 'Erro ao enviar a imagem. Tente novamente.';

  @override
  String exerciseCreated(String name) {
    return 'Exercicio \"$name\" criado';
  }

  @override
  String get errorCreatingExercise => 'Erro ao criar o exercicio';

  @override
  String errorGeneric(String error) {
    return 'Erro: $error';
  }

  @override
  String get nameIsRequired => 'O nome e obrigatorio';

  @override
  String get nameMinLength => 'O nome deve ter pelo menos 3 caracteres';

  @override
  String get nameTooLong => 'O nome e muito longo';

  @override
  String get editExercise => 'Editar Exercicio';

  @override
  String get error => 'Erro';

  @override
  String get notFound => 'Nao encontrado';

  @override
  String get changeImage => 'Alterar imagem';

  @override
  String get mustSignInToEditExercises =>
      'Voce precisa fazer login para editar exercicios';

  @override
  String exerciseUpdated(String name) {
    return 'Exercicio \"$name\" atualizado';
  }

  @override
  String get errorUpdatingExercise => 'Erro ao atualizar o exercicio';

  @override
  String get saveChanges => 'Salvar alteracoes';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get pendingReview => 'Pendente de revisao';

  @override
  String get approvedAsGlobal => 'Aprovado como global';

  @override
  String get proposalRejected => 'Proposta rejeitada';

  @override
  String get hideNotes => 'Ocultar notas';

  @override
  String get showNotes => 'Ver notas';

  @override
  String get personalInstructions => 'Instrucoes pessoais';

  @override
  String get deleteExercise => 'Excluir exercicio';

  @override
  String deleteExerciseConfirm(String name) {
    return 'Tem certeza que deseja excluir \"$name\"?\n\nEsta acao nao pode ser desfeita.';
  }

  @override
  String exerciseDeleted(String name) {
    return 'Exercicio \"$name\" excluido';
  }

  @override
  String get errorDeletingExercise => 'Erro ao excluir o exercicio';

  @override
  String get recordSets => 'Registrar series';

  @override
  String get quickRecord => 'Registro rapido';

  @override
  String get save => 'Salvar';

  @override
  String get enterWeight => 'Digite o peso';

  @override
  String get invalidWeight => 'Peso invalido';

  @override
  String savedRecord(String weight, String sets, String reps) {
    return 'Salvo: $weight kg x $sets series x $reps reps';
  }

  @override
  String get completeAllSets => 'Preencha peso e reps em todas as series';

  @override
  String savedAdvancedRecord(String weight, String count) {
    return 'Salvo: $weight kg ($count series)';
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
  String get addSet => 'Adicionar serie';

  @override
  String get routines => 'Rotinas';

  @override
  String get deleteRoutine => 'Excluir Rotina';

  @override
  String deleteRoutineConfirm(String name) {
    return 'Excluir \"$name\"? Esta acao nao pode ser desfeita.';
  }

  @override
  String get routineDeleted => 'Rotina excluida';

  @override
  String get errorDeletingRoutine => 'Erro ao excluir rotina';

  @override
  String get renameRoutine => 'Renomear Rotina';

  @override
  String get nameLabel => 'Nome';

  @override
  String get routineNameExample => 'Ex: Push, Pull, Pernas...';

  @override
  String get errorRenamingRoutine => 'Erro ao renomear rotina';

  @override
  String get noRoutinesYet => 'Voce ainda nao tem rotinas';

  @override
  String get createFirstRoutine =>
      'Crie sua primeira rotina para organizar seus treinos';

  @override
  String get createRoutine => 'Criar Rotina';

  @override
  String get errorLoadingRoutines => 'Erro ao carregar rotinas';

  @override
  String get noExercisesCount => 'Sem exercicios';

  @override
  String get oneExercise => '1 exercicio';

  @override
  String exerciseCount(int count) {
    return '$count exercicios';
  }

  @override
  String get rename => 'Renomear';

  @override
  String get newRoutine => 'Nova Rotina';

  @override
  String get routineName => 'Nome da rotina';

  @override
  String get routineNameHint => 'Ex: Push, Pull, Pernas, Full Body...';

  @override
  String get enterRoutineName => 'Digite um nome para a rotina';

  @override
  String get routineNameMinLength => 'O nome deve ter pelo menos 2 caracteres';

  @override
  String get willBeAddedAutomatically => 'Sera adicionado automaticamente:';

  @override
  String get canAddMoreExercisesLater =>
      'Depois voce pode adicionar mais exercicios';

  @override
  String get canAddExercisesLater =>
      'Depois voce pode adicionar exercicios a sua rotina';

  @override
  String exerciseAddedToRoutine(String name) {
    return '\"$name\" adicionado a rotina';
  }

  @override
  String get errorCreatingRoutine => 'Erro ao criar rotina';

  @override
  String get loading => 'Carregando...';

  @override
  String get todayProgress => 'Progresso de hoje';

  @override
  String exercisesProgress(String completed, String total) {
    return '$completed/$total exercicios';
  }

  @override
  String get completed => 'Completa';

  @override
  String get markAsCompleted => 'Marcar como Completa';

  @override
  String completeRoutine(String completed, String total) {
    return 'Completar Rotina ($completed/$total)';
  }

  @override
  String routineCompleted(String name) {
    return '$name completa';
  }

  @override
  String routineMarkedCompleted(String name) {
    return '$name marcada como completa';
  }

  @override
  String get noExercisesAddedYet => 'Voce ainda nao adicionou exercicios';

  @override
  String get addExercisesToBuildRoutine =>
      'Adicione exercicios para montar sua rotina';

  @override
  String get addExercises => 'Adicionar Exercicios';

  @override
  String get errorLoading => 'Erro ao carregar';

  @override
  String get routineNotFound => 'Rotina nao encontrada';

  @override
  String get back => 'Voltar';

  @override
  String get today => 'Hoje';

  @override
  String get removeFromRoutine => 'Remover da rotina';

  @override
  String get removeExercise => 'Remover Exercicio';

  @override
  String removeExerciseConfirm(String name) {
    return 'Remover \"$name\" da rotina?';
  }

  @override
  String get remove => 'Remover';

  @override
  String get errorRemovingExercise => 'Erro ao remover exercicio';

  @override
  String get routineNameExampleShort => 'Ex: Push Day';

  @override
  String deleteRoutineConfirmFull(String name) {
    return 'Tem certeza que deseja excluir \"$name\"?\n\nEsta acao nao pode ser desfeita.';
  }

  @override
  String get searchExercisePlaceholder => 'Buscar exercicio...';

  @override
  String addCount(int count) {
    return 'Adicionar ($count)';
  }

  @override
  String get exerciseAdded => 'Exercicio adicionado';

  @override
  String exercisesAdded(int count) {
    return '$count exercicios adicionados';
  }

  @override
  String get errorAdding => 'Erro ao adicionar';

  @override
  String get alreadyAdded => 'Ja adicionado';

  @override
  String get addToRoutine => 'Adicionar a Rotina';

  @override
  String get errorLoadingRoutinesSheet => 'Erro ao carregar rotinas';

  @override
  String get noRoutinesSheet => 'Voce nao tem rotinas';

  @override
  String get createRoutineToOrganize =>
      'Crie uma rotina para organizar seus exercicios';

  @override
  String get createNewRoutine => 'Criar nova rotina';

  @override
  String addedToRoutine(String name) {
    return 'Adicionado a \"$name\"';
  }

  @override
  String get exerciseAlreadyInRoutine => 'O exercicio ja esta na rotina';

  @override
  String get history => 'Historico';

  @override
  String get errorLoadingHistory => 'Erro ao carregar historico';

  @override
  String editDate(String date) {
    return 'Editar - $date';
  }

  @override
  String get addExerciseButton => 'Adicionar exercicio';

  @override
  String get yesterday => 'Ontem';

  @override
  String get noRecordsThisDay => 'Sem registros neste dia';

  @override
  String get addExerciseWithButton =>
      'Adicione um exercicio com o botao abaixo';

  @override
  String get completedRoutines => 'Rotinas completas';

  @override
  String get registeredExercises => 'Exercicios registrados';

  @override
  String get unknownExercise => 'Exercicio desconhecido';

  @override
  String get deleteRecord => 'Excluir registro';

  @override
  String deleteRecordConfirm(String name, String weight) {
    return 'Excluir o registro de \"$name\" ($weight kg)?';
  }

  @override
  String get cannotBeUndone => '\n\nEsta acao nao pode ser desfeita.';

  @override
  String get recordDeleted => 'Registro excluido';

  @override
  String get errorDeleting => 'Erro ao excluir';

  @override
  String get deleteCompletedRoutine => 'Excluir rotina completa';

  @override
  String deleteCompletedRoutineConfirm(String name) {
    return 'Excluir o registro de \"$name\"?';
  }

  @override
  String addDate(String date) {
    return 'Adicionar - $date';
  }

  @override
  String get exercisesTab => 'Exercicios';

  @override
  String get routinesTab => 'Rotinas';

  @override
  String get noExercisesFound => 'Nenhum exercicio encontrado';

  @override
  String get addOneExercise => 'Adicionar 1 exercicio';

  @override
  String addMultipleExercises(int count) {
    return 'Adicionar $count exercicios';
  }

  @override
  String exerciseNameAdded(String name) {
    return '$name adicionado';
  }

  @override
  String countExercisesAdded(int count) {
    return '$count exercicios adicionados';
  }

  @override
  String get errorAddingExercises => 'Erro ao adicionar';

  @override
  String get noRoutinesAvailable => 'Voce nao tem rotinas';

  @override
  String get createRoutineFirst => 'Crie uma rotina primeiro';

  @override
  String routineAddedWithExercises(String name, int count) {
    return '$name adicionada ($count exercicios)';
  }

  @override
  String get custom => 'Personalizado';

  @override
  String exerciseCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercicios',
      one: '1 exercicio',
    );
    return '$_temp0';
  }

  @override
  String errorMessage(String error) {
    return 'Erro: $error';
  }

  @override
  String get noRecords => 'Sem registros';

  @override
  String get recordFirstWorkout => 'Registre seu primeiro treino';

  @override
  String get goToExercises => 'Ir para exercicios';

  @override
  String get noWorkoutsRecorded => 'Voce nao registrou nenhum treino';

  @override
  String get editDay => 'Editar dia';

  @override
  String get routineLabel => 'rotina';

  @override
  String get exerciseLabel => 'exercicio';

  @override
  String exercisesCompletedCount(String completed, String total) {
    return '$completed/$total exercicios';
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
  String get detailed => 'Detalhado';

  @override
  String setsTimesReps(String sets, String reps) {
    return '$sets series x $reps reps';
  }

  @override
  String weightKg(String weight) {
    return '$weight kg';
  }

  @override
  String get lastWorkout => 'Ultimo treino';

  @override
  String daysAgo(int count) {
    return 'Ha $count dias';
  }

  @override
  String activityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atividades',
      one: '1 atividade',
    );
    return '$_temp0';
  }

  @override
  String get myProfile => 'Meu Perfil';

  @override
  String errorLoadingProfile(String error) {
    return 'Erro ao carregar perfil: $error';
  }

  @override
  String get firstName => 'Nome';

  @override
  String get firstNameHint => 'Ex: Joao';

  @override
  String get lastName => 'Sobrenome';

  @override
  String get lastNameHint => 'Ex: Silva';

  @override
  String get age => 'Idade';

  @override
  String get ageHint => 'Ex: 25';

  @override
  String get years => 'anos';

  @override
  String get height => 'Altura';

  @override
  String get heightHint => 'Ex: 175';

  @override
  String get cm => 'cm';

  @override
  String get weight => 'Peso';

  @override
  String get weightHint => 'Ex: 70.5';

  @override
  String get sex => 'Sexo';

  @override
  String get unspecified => 'Nao especificado';

  @override
  String get allFieldsOptional =>
      'Todos os campos sao opcionais. Suas informacoes sao salvas com seguranca.';

  @override
  String get profileSaved => 'Perfil salvo';

  @override
  String errorSavingProfile(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get settings => 'Configuracoes';

  @override
  String get account => 'Conta';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String get changePasswordSubtitle => 'Um email com instrucoes sera enviado';

  @override
  String get session => 'Sessao';

  @override
  String get signOut => 'Sair';

  @override
  String get legal => 'Legal';

  @override
  String get dangerZone => 'Zona de perigo';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountSubtitle =>
      'Exclui permanentemente sua conta e dados';

  @override
  String get about => 'Sobre';

  @override
  String versionInfo(String version, String buildSuffix) {
    return 'Versao $version$buildSuffix';
  }

  @override
  String get appDescription =>
      'Registre seus treinos, exercicios e progresso na academia.';

  @override
  String get copyright => '© 2026 GymVault';

  @override
  String get changePasswordTitle => 'Alterar Senha';

  @override
  String changePasswordMessage(String email) {
    return 'Um link para alterar sua senha sera enviado para:\n\n$email';
  }

  @override
  String get send => 'Enviar';

  @override
  String emailSentTo(String email) {
    return 'Email enviado para $email';
  }

  @override
  String errorSendingEmail(String error) {
    return 'Erro ao enviar email: $error';
  }

  @override
  String get signOutTitle => 'Sair';

  @override
  String get signOutConfirm => 'Tem certeza que deseja sair?';

  @override
  String errorSigningOut(String error) {
    return 'Erro ao sair: $error';
  }

  @override
  String get deleteAccountTitle => 'Excluir conta';

  @override
  String get deleteAccountMessage =>
      'Ao excluir a conta, todos os dados pessoais e de treino serao excluidos.\n\nEsta acao nao pode ser desfeita.';

  @override
  String get continueAction => 'Continuar';

  @override
  String get deleteAccountFinalTitle => 'Excluir conta definitivamente?';

  @override
  String get deleteAccountFinalMessage =>
      'Todos os seus exercicios, rotinas, registros de peso e dados pessoais serao excluidos.';

  @override
  String get deleteDefinitely => 'Excluir definitivamente';

  @override
  String get accountDeleted => 'Conta excluida';

  @override
  String get deletingAccount => 'Excluindo conta...';

  @override
  String get couldNotGetEmail => 'Nao foi possivel obter o email da conta';

  @override
  String get user => 'Usuario';

  @override
  String get configuration => 'Configuracoes';

  @override
  String get weightEvolution => 'Evolucao de Peso';

  @override
  String get stable => 'Estavel';

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
  String get pageNotFound => 'Pagina nao encontrada';

  @override
  String get goToHome => 'Ir ao Inicio';

  @override
  String get validationEmailRequired => 'O email e obrigatorio';

  @override
  String get validationEmailInvalid => 'Digite um email valido';

  @override
  String get validationPasswordRequired => 'A senha e obrigatoria';

  @override
  String validationPasswordMinLength(int length) {
    return 'A senha deve ter pelo menos $length caracteres';
  }

  @override
  String get validationConfirmPassword => 'Confirme sua senha';

  @override
  String get validationPasswordsDoNotMatch => 'As senhas nao correspondem';

  @override
  String get validationNameRequired => 'O nome e obrigatorio';

  @override
  String get validationNameMinLength =>
      'O nome deve ter pelo menos 2 caracteres';

  @override
  String validationFieldRequired(String fieldName) {
    return '$fieldName e obrigatorio';
  }

  @override
  String get validationWeightRequired => 'O peso e obrigatorio';

  @override
  String get validationEnterValidNumber => 'Digite um numero valido';

  @override
  String get validationWeightNegative => 'O peso nao pode ser negativo';

  @override
  String validationWeightMax(String max) {
    return 'O peso maximo e $max kg';
  }

  @override
  String get validationEnterInteger => 'Digite um numero inteiro';

  @override
  String get validationMinSets => 'Minimo 1 serie';

  @override
  String validationMaxSets(int max) {
    return 'Maximo $max series';
  }

  @override
  String get validationMinReps => 'Minimo 1 repeticao';

  @override
  String validationMaxReps(int max) {
    return 'Maximo $max repeticoes';
  }

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Ingles';

  @override
  String get spanish => 'Espanhol';

  @override
  String get portuguese => 'Portugues';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String routineCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rotinas',
      one: '1 rotina',
    );
    return '$_temp0';
  }

  @override
  String get generalProgress => 'Progresso Geral';

  @override
  String get summary => 'Resumo';

  @override
  String get workoutDays => 'Dias de treino';

  @override
  String get totalVolume => 'Volume total';

  @override
  String get dominantMuscle => 'Musculo dominante';

  @override
  String get bestProgress => 'Melhor progresso';

  @override
  String get muscleDistribution => 'Distribuicao Muscular';

  @override
  String get topMuscles => 'Musculos principais';

  @override
  String forgottenMusclesWarning(String muscles) {
    return 'Musculos com pouco trabalho: $muscles';
  }

  @override
  String get noProgressData => 'Sem dados de progresso';

  @override
  String get noProgressDataSubtitle =>
      'Registre seus treinos para ver seu progresso';

  @override
  String get errorLoadingProgress => 'Erro ao carregar progresso';

  @override
  String get last30Days => '30 dias';

  @override
  String get last90Days => '90 dias';

  @override
  String get last6Months => '6 meses';

  @override
  String get last12Months => '12 meses';

  @override
  String get allTime => 'Tudo';

  @override
  String volumeKg(String volume) {
    return '$volume kg';
  }

  @override
  String days(String count) {
    return '$count d';
  }

  @override
  String get workoutDaysTooltip => 'Dias unicos de treino neste periodo';

  @override
  String get totalVolumeTooltip =>
      'Peso total x reps x series de todos os exercicios';

  @override
  String get dominantMuscleTooltip =>
      'Grupo muscular com maior volume acumulado';

  @override
  String get bestProgressTooltip => 'Exercicio com maior aumento de peso';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Series';

  @override
  String get tapChartHint => 'Toque uma secao para ver detalhes';

  @override
  String get bestMuscleProgress => 'Melhor progresso muscular';

  @override
  String get detailedProgress => 'Progresso Detalhado';

  @override
  String get byMuscleGroup => 'Por grupo muscular';

  @override
  String get byExercise => 'Por exercicio';

  @override
  String get currentVolume => 'Atual';

  @override
  String get previousVolume => 'Anterior';

  @override
  String get newLabel => 'Novo';

  @override
  String get noProgressYet => 'Dados insuficientes para comparar progresso';

  @override
  String get minRecordsHint => 'Exercicios com 3+ treinos';

  @override
  String yourProgressInPeriod(String period) {
    return 'Seu progresso nos ultimos $period';
  }

  @override
  String get yourProgressAllTime => 'Seu progresso total';

  @override
  String get tapForDetails => 'Toque para ver detalhes';

  @override
  String get bestMuscleProgressTooltip =>
      'Grupo muscular com maior aumento de volume';

  @override
  String get vsLastPeriod => 'vs periodo anterior';

  @override
  String progressPercentage(String percentage) {
    return '+$percentage%';
  }

  @override
  String get notifications => 'Notificacoes';

  @override
  String get notificationsSubtitle => 'Lembretes, progresso e mais';

  @override
  String get enableNotifications => 'Ativar notificacoes';

  @override
  String get reminders => 'Lembretes';

  @override
  String get trainingReminders => 'Lembrete de treino';

  @override
  String get trainingRemindersDesc => 'Avisa no seu horario habitual de treino';

  @override
  String get incompleteSessionReminder => 'Sessao incompleta';

  @override
  String get incompleteSessionDesc => 'Lembra de completar sua rotina';

  @override
  String get progressSection => 'Progresso';

  @override
  String get progressMilestones => 'Marcos de progresso';

  @override
  String get progressMilestonesDesc => 'Celebra suas melhorias';

  @override
  String get news => 'Novidades';

  @override
  String get gymvaultUpdates => 'Atualizacoes GymVault';

  @override
  String get gymvaultUpdatesDesc => 'Novidades e anuncios';

  @override
  String get doNotDisturb => 'Nao perturbe';

  @override
  String get dndDescription => 'Sem notificacoes durante este horario';

  @override
  String get dndFrom => 'De';

  @override
  String get dndTo => 'Ate';

  @override
  String get notifTrainingTitle => 'Vamos treinar?';

  @override
  String get notifTrainingBody =>
      'Seu horario habitual de treino chegou. Vamos!';

  @override
  String get notifIncompleteTitle => 'Terminar sua sessao?';

  @override
  String get notifIncompleteBody =>
      'Voce registrou exercicios antes. Quer completar sua rotina?';

  @override
  String notifMilestoneTitle(String muscleGroup) {
    return '$muscleGroup esta crescendo!';
  }

  @override
  String notifMilestoneBody(String muscleGroup, String percentage) {
    return 'Seu volume de $muscleGroup melhorou $percentage% este mes. Continue assim!';
  }

  @override
  String get notifPermissionRequired =>
      'Permissao de notificacoes necessaria para enviar lembretes';

  @override
  String get unsavedSetsTitle => 'Alterações não salvas';

  @override
  String get unsavedSetsBody =>
      'Você tem alterações não salvas nas suas séries. Se sair, elas serão perdidas.';

  @override
  String get leave => 'Sair';

  @override
  String get timerTitle => 'Descanso';

  @override
  String get timerStart => 'Iniciar';

  @override
  String get timerPause => 'Pausar';

  @override
  String get timerResume => 'Retomar';

  @override
  String get timerStop => 'Parar';

  @override
  String get timerReset => 'Reiniciar';

  @override
  String get timerCustom => 'Personalizado';

  @override
  String get timerFinishedTitle => 'Tempo!';

  @override
  String get timerFinishedBody => 'Descanso terminado';

  @override
  String timerNotifBody(String remaining) {
    return '$remaining restante';
  }
}
