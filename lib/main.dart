import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() => runApp(FinanceAIApp());

class FinanceAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Финансовый Наставник',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent.shade700),
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFF7F8FA),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class Goal {
  String title;
  double target;
  double saved;
  Goal(this.title, this.target, this.saved);
}

class _Message {
  final String sender; // 'child' или 'bot'
  final String text;
  _Message({required this.sender, required this.text});
}

class Transaction {
  final String type;
  final String title;
  final double amount;
  final DateTime date;

  Transaction(
      {required this.type,
        required this.title,
        required this.amount,
        required this.date});
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double balance = 0.0;
  final List<Goal> goals = [];
  final List<_Message> messages = [];
  final List<Transaction> transactions = [];

  int spendCount = 0; // для отслеживания количества расходов
  bool goalCreated = false; // чтобы совет не повторялся

  void addRecord(String type, String title, double amount) {
    if (amount <= 0 || title.trim().isEmpty) return;

    setState(() {
      final transaction = Transaction(
          type: type, title: title, amount: amount, date: DateTime.now());
      transactions.add(transaction);
      messages.add(_Message(
          sender: 'child', text: '$type: $title - ${amount.toStringAsFixed(2)}₽'));

      if (type == "Доход") {
        balance += amount;
      } else {
        balance -= amount;
        spendCount++;
      }

      messages.add(_Message(
          sender: 'bot', text: generateAIResponseForRecord(type, title, amount)));

      // Автоматические советы от бота по прогрессу:
      if (spendCount >= 3) {
        messages.add(_Message(
            sender: 'bot',
            text:
            'Ты уже записал 3 расхода! Отлично ведёшь учет. Совет: попробуй планировать траты заранее.'));
        spendCount = 0; // сбросить счетчик, чтобы не спамить
      }

      if (goals.isNotEmpty) {
        for (var goal in goals) {
          double progress = goal.saved / goal.target;
          if (progress >= 0.5 && progress < 1.0) {
            messages.add(_Message(
                sender: 'bot',
                text:
                'Ты достиг ${ (progress*100).toStringAsFixed(0)}% цели "${goal.title}". Молодец! Подумай, как ускорить накопления.'));
          } else if (progress >= 1.0) {
            messages.add(_Message(
                sender: 'bot',
                text:
                'Цель "${goal.title}" достигнута! Поздравляю! Можно ставить новую цель.'));
          }
        }
      }
    });
  }

  String generateAIResponseForRecord(String type, String title, double amount) {
    if (type == "Доход") {
      return "Отлично! Ты получил ${amount.toStringAsFixed(0)}₽ за '$title'. Молодец, продолжай в том же духе! 💰";
    } else {
      if (title.toLowerCase().contains("игра") ||
          title.toLowerCase().contains("шоколад")) {
        return "Ты потратил ${amount.toStringAsFixed(0)}₽ на '$title'. А может в следующий раз отложить немного на мечту? 😊";
      } else {
        return "Ты потратил ${amount.toStringAsFixed(0)}₽ на '$title'. Всё под контролем? 👍";
      }
    }
  }

  void addGoal(String title, double target) {
    if (title.trim().isEmpty || target <= 0) return;
    setState(() {
      goals.add(Goal(title, target, 0));
      if (!goalCreated) {
        messages.add(_Message(
            sender: 'bot',
            text:
            'Новая цель "$title" создана. Разбей её на маленькие шаги и двигайся к мечте!'));
        goalCreated = true;
      }
    });
  }

  void updateGoal(int index, double amount, bool isAdd) {
    if (amount <= 0) return;
    setState(() {
      if (isAdd && balance >= amount) {
        goals[index].saved += amount;
        balance -= amount;
      } else if (!isAdd && goals[index].saved >= amount) {
        goals[index].saved -= amount;
        balance += amount;
      }
    });
  }

  Map<String, double> getSummary() {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      if (tx.type == "Доход") totalIncome += tx.amount;
      if (tx.type == "Расход") totalExpense += tx.amount;
    }
    return {
      "Доход": totalIncome,
      "Расход": totalExpense,
      "Итого": totalIncome - totalExpense,
    };
  }

  // Кнопка с идеями на миллион
  void addMillionIdea() {
    final ideas = [
      'Создай онлайн-курс на тему финансовой грамотности.',
      'Начни продавать свои хобби-изделия в интернете.',
      'Изучи инвестирование и начни с малого.',
      'Попробуй создать мобильное приложение для финансов.',
      'Подумай о создании блога с полезными советами по деньгам.',
    ];
    final idea = (ideas..shuffle()).first;
    setState(() {
      messages.add(_Message(sender: 'bot', text: 'Идея на миллион: $idea'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = getSummary();

    return Scaffold(
      appBar: AppBar(title: Text('Финансовый дневник')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              color: Colors.greenAccent.shade700, size: 40),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Текущий баланс',
                                  style: TextStyle(color: Colors.grey[700])),
                              SizedBox(height: 4),
                              Text('${balance.toStringAsFixed(2)} ₽',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Анализ расходов и доходов',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Доход: ${summary["Доход"]?.toStringAsFixed(2)} ₽'),
                          Text('Расход: ${summary["Расход"]?.toStringAsFixed(2)} ₽'),
                          Divider(),
                          Text('Итог: ${summary["Итого"]?.toStringAsFixed(2)} ₽',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _operationButton(
                          "Доход", Icons.add_circle, Colors.green.shade700),
                      _operationButton(
                          "Расход", Icons.remove_circle, Colors.red.shade700),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Цели накоплений',
                      style: Theme.of(context).textTheme.titleMedium),
                  ...List.generate(goals.length,
                          (index) => _goalCard(index, goals[index])),
                  Center(
                    child: TextButton.icon(
                      icon: Icon(Icons.flag),
                      label: Text('Добавить цель'),
                      onPressed: _showGoalDialog,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.lightbulb),
                      label: Text('Идеи на миллион'),
                      onPressed: addMillionIdea,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          Container(
            height: 240,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg.sender == 'child';
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                      isUser ? Colors.greenAccent.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text, style: TextStyle(fontSize: 15)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationButton(String type, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () => _showRecordDialog(type),
      icon: Icon(icon, color: Colors.white),
      label: Text(type, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _goalCard(int index, Goal goal) {
    double progress = (goal.saved / goal.target).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: Colors.greenAccent.shade700,
              minHeight: 10,
            ),
            SizedBox(height: 4),
            Text(
                'Накоплено: ${goal.saved.toStringAsFixed(2)} / ${goal.target.toStringAsFixed(2)} ₽'),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => _showUpdateGoalDialog(index, true),
                    child: Text('Добавить')),
                TextButton(
                    onPressed: () => _showUpdateGoalDialog(index, false),
                    child: Text('Убрать')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordDialog(String type) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type: Введите детали'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Сумма (₽)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0;
              if (title.isNotEmpty && amount > 0) {
                addRecord(type, title, amount);
                Navigator.pop(context);
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog() {
    final goalTitleController = TextEditingController();
    final goalTargetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить цель'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: goalTitleController,
              decoration: InputDecoration(labelText: 'Название цели'),
            ),
            TextField(
              controller: goalTargetController,
              decoration: InputDecoration(labelText: 'Сумма цели (₽)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена')),
          ElevatedButton(
              onPressed: () {
                final title = goalTitleController.text.trim();
                final target = double.tryParse(goalTargetController.text) ?? 0;
                if (title.isNotEmpty && target > 0) {
                  addGoal(title, target);
                  Navigator.pop(context);
                }
              },
              child: Text('Создать')),
        ],
      ),
    );
  }

  void _showUpdateGoalDialog(int index, bool isAdd) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isAdd ? 'Добавить' : 'Убрать'} средства из "${goals[index].title}"'),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(labelText: 'Сумма (₽)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена')),
          ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  updateGoal(index, amount, isAdd);
                  Navigator.pop(context);
                }
              },
              child: Text('Сохранить')),
        ],
      ),
    );
  }
}
