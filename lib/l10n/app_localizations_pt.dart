// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'VIA LIVRE';

  @override
  String get mapScreen => 'Mapa';

  @override
  String get createReport => 'Reportar Problema';

  @override
  String get reportForm => 'Relatar Problema na Estrada';

  @override
  String get issueType => 'Tipo de Problema';

  @override
  String get description => 'Descrição (Opcional)';

  @override
  String get submit => 'Enviar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get accident => 'Acidente';

  @override
  String get construction => 'Obra';

  @override
  String get flood => 'Enchente';

  @override
  String get treeFallen => 'Árvore Caída';

  @override
  String get protest => 'Protesto';

  @override
  String get other => 'Outro';

  @override
  String get stillPresent => 'Ainda Presente';

  @override
  String get noLongerPresent => 'Não Mais Presente';

  @override
  String get gettingLocation => 'Obtendo sua localização...';

  @override
  String get locationError =>
      'Falha ao obter localização. Por favor, habilite os serviços de localização.';

  @override
  String get reportCreated => 'Relatório criado com sucesso';

  @override
  String get reportError =>
      'Falha ao criar relatório. Por favor, tente novamente.';

  @override
  String get loading => 'Carregando...';

  @override
  String get selectIssueType => 'Por favor, selecione um tipo de problema';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglês';

  @override
  String get portuguese => 'Português';

  @override
  String confirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmações',
      one: '1 confirmação',
      zero: 'Nenhuma confirmação',
    );
    return '$_temp0';
  }

  @override
  String dismissals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispensas',
      one: '1 dispensa',
      zero: 'Nenhuma dispensa',
    );
    return '$_temp0';
  }

  @override
  String get location => 'Localização';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get additionalDetailsOptional => 'Detalhes adicionais (opcional)';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get failedToLoadReports => 'Falha ao carregar relatórios';

  @override
  String get failedToVote => 'Falha ao votar. Por favor, tente novamente.';

  @override
  String get error => 'Erro';

  @override
  String reportedAgo(String time) {
    return 'há $time';
  }

  @override
  String get justNow => 'Agora mesmo';

  @override
  String minutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get updateLocation => 'Atualizar Localização';

  @override
  String get locationCaptured => 'Localização capturada';

  @override
  String get about => 'Sobre';

  @override
  String get appTagline => 'Relatórios de condições das estradas em tempo real';

  @override
  String get aboutTitle => 'Sobre o VIA LIVRE';

  @override
  String get aboutDescription =>
      'VIA LIVRE é uma plataforma colaborativa que ajuda motoristas a se manterem informados sobre condições das estradas em tempo real. Relate e visualize problemas nas estradas como acidentes, obras, enchentes e mais para ajudar outros motoristas a navegarem com segurança.';

  @override
  String get howItWorksTitle => 'Como Funciona';

  @override
  String get howItWorksDescription =>
      '1. Visualize relatórios em tempo real no mapa\n2. Relate problemas nas estradas que você encontrar\n3. Confirme ou descarte relatórios para ajudar a manter as informações precisas';

  @override
  String get featuresTitle => 'Recursos';

  @override
  String get featureRealTimeMap => 'Mapa em Tempo Real';

  @override
  String get featureRealTimeMapDesc =>
      'Veja relatórios de estradas atualizados em tempo real em um mapa interativo';

  @override
  String get featureReportIssues => 'Relatar Problemas';

  @override
  String get featureReportIssuesDesc =>
      'Relate rapidamente acidentes, obras, enchentes e outros problemas nas estradas';

  @override
  String get featureCommunityVerified => 'Verificado pela Comunidade';

  @override
  String get featureCommunityVerifiedDesc =>
      'Relatórios são verificados pela comunidade através de confirmações e dispensas';

  @override
  String get featureTimeLimited => 'Relatórios com Tempo Limitado';

  @override
  String get featureTimeLimitedDesc =>
      'Todos os relatórios expiram após 2 horas para garantir que apenas informações atuais sejam mostradas';

  @override
  String get importantNotice => 'Aviso Importante';

  @override
  String get reportExpiryTitle => 'Expiração de Relatórios';

  @override
  String get reportExpiryDescription =>
      'Todos os relatórios expiram automaticamente 2 horas após a criação para garantir que você veja apenas informações atuais e relevantes.';

  @override
  String get appVersion => 'Versão 1.0.0';

  @override
  String get madeWithLove => 'Feito com ❤️ para estradas mais seguras';

  @override
  String get filterReports => 'Filtrar Relatórios';

  @override
  String get noDetailsAvailable =>
      'Nenhum detalhe adicional disponível para este relatório.';

  @override
  String selectLocationOnMap(int maxDistance) {
    return 'Toque no mapa para selecionar a localização do relatório (máximo $maxDistance km da sua localização atual)';
  }

  @override
  String get pleaseSelectLocation =>
      'Por favor, toque no mapa para selecionar a localização do relatório';

  @override
  String locationTooFar(int maxDistance) {
    return 'A localização selecionada deve estar dentro de $maxDistance km da sua localização atual';
  }

  @override
  String locationDistanceWarning(String distance, int maxDistance) {
    return 'A localização está a $distance km de distância. Por favor, selecione uma localização dentro de $maxDistance km.';
  }

  @override
  String get distance => 'Distância';
}
