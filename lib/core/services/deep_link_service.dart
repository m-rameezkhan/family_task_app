import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks;

  DeepLinkService({
    AppLinks? appLinks,
  }) : _appLinks = appLinks ?? AppLinks();

  Stream<Uri> get uriStream => _appLinks.uriLinkStream;

  Future<Uri?> getInitialLink() {
    return _appLinks.getInitialLink();
  }
}