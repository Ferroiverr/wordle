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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (gameOver || isLoading) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.backspace) {
      _onKeyTap('⌫');
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter) {
      _onKeyTap('Ввод');
      return KeyEventResult.handled;
    }

    final character = event.character?.toLowerCase();
    if (character != null && RegExp(r'^[а-яё]$').hasMatch(character)) {
      _onKeyTap(character);
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

    if (!dictionary.contains(guess)) {
      setState(() => message = 'Такого слова нет в словаре!');
      return;
    }

    List<Color> rowColors = List.filled(5, const Color(0xFF3A3A3C));
    List<bool> used = List.filled(5, false);

    for (int i = 0; i < 5; i++) {
      if (guess[i] == secretWord[i]) {
        rowColors[i] = const Color(0xFF538D4E);
        used[i] = true;
        keyColors[guess[i]] = const Color(0xFF538D4E);
      }
    }

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

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final padding = MediaQuery.of(context).padding;

    // Адаптивные размеры плиток
    final double tileSize = isMobile
        ? ((size.width - 28) / 5.6).clamp(46.0, 58.0)
        : 62.0;

    // ===== Клавиатура — более компактная =====
    final double availableWidth = size.width - 8; // почти без отступов
    final double keyWidth = isMobile
        ? (availableWidth / 11.8)   // было 12.5 — теперь плотнее
        : 42.0;

    final double keyHeight = isMobile ? 44.0 : 52.0;
    final double specialKeyWidth = isMobile ? keyWidth * 1.55 : 70.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WORDLE RU',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: isMobile ? 2 : 4,
            fontSize: isMobile ? 20 : 28,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isMobile ? 46 : 56,
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
              const SizedBox(height: 2),

              // Игровое поле
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (row) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 2.0 : 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (col) {
                            return _buildTile(row, col, tileSize);
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Сообщение
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: message.contains('нет в словаре')
                          ? Colors.orange
                          : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Клавиатура
              Padding(
                padding: EdgeInsets.only(
                  left: 2,
                  right: 2,
                  bottom: isMobile ? 6 : 14,
                ),
                child: _buildKeyboard(keyWidth, keyHeight, specialKeyWidth, isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int row, int col, double size) {
    final letter = board[row][col];
    final color = colors[row][col];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(2),
      width: size,
      height: size,
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
          style: TextStyle(
            fontSize: size * 0.47,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(double keyWidth, double keyHeight, double specialKeyWidth, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1 ряд
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: keyboardRows[0]
              .split('')
              .map((l) => _key(l, keyWidth, keyHeight, isMobile))
              .toList(),
        ),
        SizedBox(height: isMobile ? 4 : 6),

        // 2 ряд
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: keyboardRows[1]
              .split('')
              .map((l) => _key(l, keyWidth, keyHeight, isMobile))
              .toList(),
        ),
        SizedBox(height: isMobile ? 4 : 6),

        // 3 ряд
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _key('Ввод', specialKeyWidth, keyHeight, isMobile),
            ...keyboardRows[2]
                .split('')
                .map((l) => _key(l, keyWidth, keyHeight, isMobile)),
            _key('⌫', specialKeyWidth, keyHeight, isMobile),
          ],
        ),
      ],
    );
  }

  Widget _key(String letter, double width, double height, bool isMobile) {
    final color = keyColors[letter] ?? const Color(0xFF818384);

    return GestureDetector(
      onTap: () => _onKeyTap(letter),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 1.3 : 2.5),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            letter.toUpperCase(),
            style: TextStyle(
              fontSize: letter.length > 1
                  ? (isMobile ? 10.5 : 13)
                  : (isMobile ? 13.5 : 16),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}