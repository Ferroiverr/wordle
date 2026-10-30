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

    // ===== МОБИЛЬНЫЕ РАЗМЕРЫ =====
    // Квадратики делаем заметно меньше
    final double tileSize = isMobile
        ? (size.width * 0.118).clamp(42.0, 52.0)
        : 62.0;

    // Клавиши делаем крупнее и удобнее
    final double availableWidth = size.width - 10;
    final double keyWidth = isMobile
        ? availableWidth / 10.6          // крупнее, чем раньше
        : 43.0;

    final double keyHeight = isMobile ? 52.0 : 54.0;   // выше = удобнее попадать
    final double specialKeyWidth = isMobile ? keyWidth * 1.65 : 72.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WORDLE RU',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: isMobile ? 1.5 : 4,
            fontSize: isMobile ? 20 : 28,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isMobile ? 44 : 56,
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
              const SizedBox(height: 4),

              // Игровое поле (компактное на мобильном)
              Expanded(
                flex: isMobile ? 5 : 6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (row) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 1.8 : 4,
                        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 17,
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
                  left: isMobile ? 3 : 8,
                  right: isMobile ? 3 : 8,
                  bottom: isMobile ? 8 : 16,
                  top: 4,
                ),
                child: _buildKeyboard(
                  keyWidth,
                  keyHeight,
                  specialKeyWidth,
                  isMobile,
                ),
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
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(
    double keyWidth,
    double keyHeight,
    double specialKeyWidth,
    bool isMobile,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1 ряд
        _buildKeyRow(
          keyboardRows[0].split(''),
          keyWidth,
          keyHeight,
          isMobile,
        ),
        SizedBox(height: isMobile ? 6 : 7),

        // 2 ряд
        _buildKeyRow(
          keyboardRows[1].split(''),
          keyWidth,
          keyHeight,
          isMobile,
        ),
        SizedBox(height: isMobile ? 6 : 7),

        // 3 ряд
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _key('Ввод', specialKeyWidth, keyHeight, isMobile, isSpecial: true),
            ...keyboardRows[2].split('').map(
                  (l) => _key(l, keyWidth, keyHeight, isMobile),
                ),
            _key('⌫', specialKeyWidth, keyHeight, isMobile, isSpecial: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(
    List<String> letters,
    double keyWidth,
    double keyHeight,
    bool isMobile,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters
          .map((l) => _key(l, keyWidth, keyHeight, isMobile))
          .toList(),
    );
  }

  Widget _key(
    String letter,
    double width,
    double height,
    bool isMobile, {
    bool isSpecial = false,
  }) {
    final color = keyColors[letter] ?? const Color(0xFF818384);

    return GestureDetector(
      onTap: () => _onKeyTap(letter),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 2.0 : 3.0,
        ),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isMobile ? 8 : 5), // более круглые на мобильном
          boxShadow: isMobile
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            letter.toUpperCase(),
            style: TextStyle(
              fontSize: isSpecial
                  ? (isMobile ? 12.5 : 13.5)
                  : (isMobile ? 16.5 : 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}