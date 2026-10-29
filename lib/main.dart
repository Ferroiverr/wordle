import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const WordleApp());
}

class WordleApp extends StatelessWidget {
  const WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordle RU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121213),
        fontFamily: 'Roboto',
      ),
      home: const WordleGame(),
    );
  }
}

class WordleGame extends StatefulWidget {
  const WordleGame({super.key});

  @override
  State<WordleGame> createState() => _WordleGameState();
}

class _WordleGameState extends State<WordleGame> {
  List<String> dictionary = [];
  late String secretWord;
  List<List<String>> board = List.generate(6, (_) => List.filled(5, ''));
  List<List<Color>> colors = List.generate(6, (_) => List.filled(5, Colors.transparent));
  int currentRow = 0;
  int currentCol = 0;
  bool gameOver = false;
  bool isLoading = true;
  String message = '';

  final List<String> keyboardRows = [
    'йцукенгшщзхъ',
    'фывапролджэ',
    'ячсмитьбю',
  ];

  Map<String, Color> keyColors = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDictionary() async {
    try {
      final String data = await rootBundle.loadString('assets/words.txt');
      final List<String> words = data
          .split('\n')
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.length == 5 && RegExp(r'^[а-яё]+$').hasMatch(w))
          .toList();

      setState(() {
        dictionary = words;
        isLoading = false;
      });

      _newGame();
    } catch (e) {
      setState(() {
        message = 'Ошибка загрузки словаря';
        isLoading = false;
      });
    }
  }

  void _newGame() {
    if (dictionary.isEmpty) return;

    secretWord = dictionary[Random().nextInt(dictionary.length)];
    board = List.generate(6, (_) => List.filled(5, ''));
    colors = List.generate(6, (_) => List.filled(5, Colors.transparent));
    currentRow = 0;
    currentCol = 0;
    gameOver = false;
    message = '';
    keyColors.clear();
    setState(() {});
  }

  void _onKeyTap(String letter) {
    if (gameOver || isLoading) return;

    if (letter == '⌫') {
      if (currentCol > 0) {
        currentCol--;
        board[currentRow][currentCol] = '';
        setState(() {});
      }
      return;
    }

    if (letter == 'Ввод') {
      _submitGuess();
      return;
    }

    if (currentCol < 5) {
      board[currentRow][currentCol] = letter;
      currentCol++;
      setState(() {});
    }
  }

  // Обработка физической клавиатуры
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (gameOver || isLoading) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Backspace
    if (key == LogicalKeyboardKey.backspace) {
      _onKeyTap('⌫');
      return KeyEventResult.handled;
    }

    // Enter
    if (key == LogicalKeyboardKey.enter) {
      _onKeyTap('Ввод');
      return KeyEventResult.handled;
    }

    // Русские и английские буквы
    String? letter;

    // Русская раскладка
    const russianKeys = {
      'KeyQ': 'й', 'KeyW': 'ц', 'KeyE': 'у', 'KeyR': 'к', 'KeyT': 'е',
      'KeyY': 'н', 'KeyU': 'г', 'KeyI': 'ш', 'KeyO': 'щ', 'KeyP': 'з',
      'BracketLeft': 'х', 'BracketRight': 'ъ',
      'KeyA': 'ф', 'KeyS': 'ы', 'KeyD': 'в', 'KeyF': 'а', 'KeyG': 'п',
      'KeyH': 'р', 'KeyJ': 'о', 'KeyK': 'л', 'KeyL': 'д', 'Semicolon': 'ж',
      'Quote': 'э',
      'KeyZ': 'я', 'KeyX': 'ч', 'KeyC': 'с', 'KeyV': 'м', 'KeyB': 'и',
      'KeyN': 'т', 'KeyM': 'ь', 'Comma': 'б', 'Period': 'ю',
    };

    if (russianKeys.containsKey(key.keyLabel) || russianKeys.containsKey(key.debugName)) {
      letter = russianKeys[key.debugName] ?? russianKeys[key.keyLabel];
    }

    // Если нажали русскую букву напрямую (когда раскладка русская)
    final character = event.character?.toLowerCase();
    if (character != null && RegExp(r'^[а-яё]$').hasMatch(character)) {
      letter = character;
    }

    if (letter != null) {
      _onKeyTap(letter);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _submitGuess() {
    if (currentCol < 5) {
      setState(() => message = 'Введи 5 букв!');
      return;
    }

    String guess = board[currentRow].join();

    // ===== ПРОВЕРКА СЛОВА =====
    if (!dictionary.contains(guess)) {
      setState(() => message = 'Такого слова нет в словаре!');
      return;
    }
    // =========================

    List<Color> rowColors = List.filled(5, const Color(0xFF3A3A3C));
    List<bool> used = List.filled(5, false);

    // Зелёные
    for (int i = 0; i < 5; i++) {
      if (guess[i] == secretWord[i]) {
        rowColors[i] = const Color(0xFF538D4E);
        used[i] = true;
        keyColors[guess[i]] = const Color(0xFF538D4E);
      }
    }

    // Жёлтые
    for (int i = 0; i < 5; i++) {
      if (rowColors[i] == const Color(0xFF538D4E)) continue;
      for (int j = 0; j < 5; j++) {
        if (!used[j] && guess[i] == secretWord[j]) {
          rowColors[i] = const Color(0xFFB59F3B);
          used[j] = true;
          if (keyColors[guess[i]] != const Color(0xFF538D4E)) {
            keyColors[guess[i]] = const Color(0xFFB59F3B);
          }
          break;
        }
      }
      if (rowColors[i] == const Color(0xFF3A3A3C)) {
        keyColors[guess[i]] = const Color(0xFF3A3A3C);
      }
    }

    colors[currentRow] = rowColors;

    if (guess == secretWord) {
      gameOver = true;
      message = 'Победа! Слово: $secretWord';
    } else if (currentRow == 5) {
      gameOver = true;
      message = 'Поражение. Слово было: $secretWord';
    } else {
      currentRow++;
      currentCol = 0;
      message = '';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WORDLE RU',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _newGame,
            tooltip: 'Новая игра',
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (col) {
                            return _buildTile(row, col);
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: message.contains('нет в словаре')
                          ? Colors.orange
                          : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              _buildKeyboard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int row, int col) {
    final letter = board[row][col];
    final color = colors[row][col];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(3),
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color == Colors.transparent ? Colors.transparent : color,
        border: Border.all(
          color: letter.isEmpty
              ? const Color(0xFF3A3A3C)
              : color == Colors.transparent
                  ? const Color(0xFF565758)
                  : color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: keyboardRows[0].split('').map((l) => _key(l)).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: keyboardRows[1].split('').map((l) => _key(l)).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _key('Ввод', width: 70),
            ...keyboardRows[2].split('').map((l) => _key(l)),
            _key('⌫', width: 70),
          ],
        ),
      ],
    );
  }

  Widget _key(String letter, {double width = 38}) {
    final color = keyColors[letter] ?? const Color(0xFF818384);

    return GestureDetector(
      onTap: () => _onKeyTap(letter),
      child: Container(
        margin: const EdgeInsets.all(3),
        width: width,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            letter.toUpperCase(),
            style: TextStyle(
              fontSize: letter.length > 1 ? 13 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}