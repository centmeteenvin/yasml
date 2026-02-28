import 'package:yasml/src/world/world.dart';

/// A base class for all plugins that can be added to the world
///
/// A Plugin is a way to extend the functionality of the world. E.g. you can use it to create an http client for the world:
/// ```dart
/// class HttpClientPlugin implements WorldPlugin {
///   late final HttpClient client;
///   @override
///   void onInit(World world) {
///     client = HttpClient();
///   }
///   @override
///   Future<void> onDispose() async {
///     client.close();
///   }
/// }
/// ```
/// You can then access it using [World.pluginByType] and use the client to make http requests:
/// ```dart
/// base class MyQuery extends Query<String> {
///   @override
///   Future<String> fetch(World world) async {
///     final httpClient = world.pluginByType<HttpClientPlugin>().client;
///     if (httpClient == null) {
///       throw Exception('HttpClientPlugin is not available');
///     }
///     final request = await httpClient.getUrl(Uri.parse('https://example.com'));
///     final response = await request.close();
///
///    final responseBody = await response.transform(utf8.decoder).join();
///    return responseBody;
/// }
/// ```
///
/// We suggest to create an extension method on World to make it easier to access the plugin:
/// ```dart
/// extension HttpClientPluginExtension on World {
///   HttpClientPlugin get httpClientPlugin {
///    final plugin = pluginByType<HttpClientPlugin>();
///   if (plugin == null) {
///     throw Exception('HttpClientPlugin is not available');
///   }
///   return plugin!;
/// }
/// ```
/// The above becomes:
/// ```dart
/// base class MyQuery extends Query<String> {
///   @override
///   Future<String> fetch(World world) async {
///     final httpClient = world.httpClientPlugin.client;
///     final request = await httpClient.getUrl(Uri.parse('https://example.com'));
///     final response = await request.close();
///    final responseBody = await response.transform(utf8.decoder).join();
///     return responseBody;
/// }/// ```
///
abstract interface class WorldPlugin {
  /// A method that is called when the plugin is added to the world. It can be used to initialize any resources
  void onInit(World world);

  /// A method that is called when the plugin is removed from the world. It can be used to clean up any resources
  Future<void> onDispose();
}
