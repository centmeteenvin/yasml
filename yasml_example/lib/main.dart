import 'package:flutter/material.dart';
import 'package:yasml/yasml.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePageView());
  }
}

int count = 0;
final counterQuery = SynchronousQuery(fetch: () => count);

Mutation updateCounter(int newValue) => Mutation((manager) {
  count = newValue;
  manager.invalidate(counterQuery);
});

final homePageViewModel = SynchronousViewModelManager<int>((composer) {
  final count = composer.watch(counterQuery);
  return count;
});

class HomePageView extends ViewWidget<int> {
  const HomePageView({super.key});

  @override
  ViewModelManager<int> get viewModel => homePageViewModel;

  @override
  Widget build(BuildContext context, int viewModel) {
    return Scaffold(body: Center(child: Text(viewModel.toString())));
  }
}
