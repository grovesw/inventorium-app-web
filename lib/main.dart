import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'item_creator.dart'; // Assuming this exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InventoryItem.initializeItems();
  await Character.initializeCharacters();
  runApp(const InventoriumApp());
}

class InventoriumApp extends StatelessWidget {
  const InventoriumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventorium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blueGrey[800],
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventorium')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CharactersScreen())),
              child: const Text('Characters'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageItemsScreen())),
              child: const Text('Manage Items'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemCreatorScreen())),
              child: const Text('Create Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryItem {
  double x;
  double y;
  double angle;
  final String name;
  final String imagePath;
  final int gridWidth;
  final int gridHeight;
  final List<List<bool>> gridLayout;
  bool isDragging;
  bool isOverlapping;

  InventoryItem({
    required this.x,
    required this.y,
    this.angle = 0.0,
    required this.name,
    required this.imagePath,
    required this.gridWidth,
    required this.gridHeight,
    required this.gridLayout,
    this.isDragging = false,
    this.isOverlapping = false,
  });

  double get width => gridWidth * 18.0;
  double get height => gridHeight * 18.0;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'angle': angle,
        'name': name,
        'imagePath': imagePath,
        'gridWidth': gridWidth,
        'gridHeight': gridHeight,
        'gridLayout': gridLayout.map((row) => row.map((cell) => cell ? 1 : 0).toList()).toList(),
        'isDragging': isDragging,
        'isOverlapping': isOverlapping,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        x: json['x']?.toDouble() ?? 0.0,
        y: json['y']?.toDouble() ?? 0.0,
        angle: json['angle']?.toDouble() ?? 0.0,
        name: json['name'] ?? 'unnamed',
        imagePath: json['imagePath'] ?? 'assets/images/long_sword.png',
        gridWidth: json['gridWidth'] ?? 3,
        gridHeight: json['gridHeight'] ?? 10,
        gridLayout: (json['gridLayout'] as List<dynamic>)
            .map((row) => (row as List<dynamic>).map((cell) => cell == 1).toList())
            .toList(),
        isDragging: json['isDragging'] ?? false,
        isOverlapping: json['isOverlapping'] ?? false,
      );

  static List<InventoryItem> _predefinedItems = [];

  static Future<void> initializeItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('inventory_items');
    if (itemsJson != null) {
      final List<dynamic> itemsList = jsonDecode(itemsJson);
      _predefinedItems = itemsList.map((item) => InventoryItem.fromJson(item)).toList();
    } else {
      _predefinedItems = [
        InventoryItem(
          x: 0.0,
          y: 0.0,
          name: "sword",
          imagePath: 'assets/images/long_sword.png',
          gridWidth: 3,
          gridHeight: 10,
          gridLayout: List.generate(10, (y) => List.generate(3, (x) => y < 10 && (x == 1 || (y == 2 && x != 1)))),
        ),
        InventoryItem(
          x: 0.0,
          y: 0.0,
          name: "book",
          imagePath: 'assets/images/book.png',
          gridWidth: 3,
          gridHeight: 4,
          gridLayout: List.generate(4, (_) => List.filled(3, true)),
        ),
        InventoryItem(
          x: 0.0,
          y: 0.0,
          name: "shield",
          imagePath: 'assets/images/book.png',
          gridWidth: 4,
          gridHeight: 4,
          gridLayout: List.generate(4, (_) => List.filled(4, true)),
        ),
      ];
      await saveItems();
    }
  }

  static Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(_predefinedItems.map((item) => item.toJson()).toList());
    await prefs.setString('inventory_items', itemsJson);
  }

  static List<InventoryItem> getPredefinedItems() => List.from(_predefinedItems);

  static void addPredefinedItem(InventoryItem item) {
    _predefinedItems.add(item);
    saveItems();
  }

  static void removePredefinedItem(String name) {
    _predefinedItems.removeWhere((item) => item.name == name);
    saveItems();
  }
}

class Character {
  final String name;
  final int str;
  List<InventoryItem> inventory;

  Character({required this.name, required this.str, required this.inventory});

  Map<String, dynamic> toJson() => {
        'name': name,
        'str': str,
        'inventory': inventory.map((item) => item.toJson()).toList(),
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        name: json['name'] ?? 'Unnamed',
        str: json['str'] ?? 10,
        inventory: (json['inventory'] as List<dynamic>)
            .map((item) => InventoryItem.fromJson(item))
            .toList(),
      );

  static List<Character> _characters = [];

  static Future<void> initializeCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final charactersJson = prefs.getString('characters');
    if (charactersJson != null) {
      final List<dynamic> charactersList = jsonDecode(charactersJson);
      _characters = charactersList.map((char) => Character.fromJson(char)).toList();
    }
  }

  static Future<void> saveCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final charactersJson = jsonEncode(_characters.map((char) => char.toJson()).toList());
    await prefs.setString('characters', charactersJson);
  }

  static List<Character> getCharacters() => List.from(_characters);

  static void addCharacter(Character character) {
    _characters.add(character);
    saveCharacters();
  }
}

class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final characters = Character.getCharacters();
    return Scaffold(
      appBar: AppBar(title: const Text('Characters')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index];
                return ListTile(
                  title: Text(character.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('STR: ${character.str}', style: const TextStyle(color: Colors.grey)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CharacterInventoryScreen(character: character),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCharacterScreen()),
              ),
              child: const Text('Create New Character'),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateCharacterScreen extends StatefulWidget {
  const CreateCharacterScreen({super.key});

  @override
  State<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends State<CreateCharacterScreen> {
  final _nameController = TextEditingController();
  final _strController = TextEditingController();

  void _saveCharacter() {
    final name = _nameController.text.trim();
    final strText = _strController.text.trim();
    if (name.isEmpty || strText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and STR score')),
      );
      return;
    }
    final str = int.tryParse(strText);
    if (str == null || str < 1 || str > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('STR must be a number between 1 and 30')),
      );
      return;
    }
    Character.addCharacter(Character(name: name, str: str, inventory: []));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Character')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Character Name',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _strController,
              decoration: const InputDecoration(
                labelText: 'STR Score (1-30)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCharacter,
              child: const Text('Save Character'),
            ),
          ],
        ),
      ),
    );
  }
}

class CharacterInventoryScreen extends StatefulWidget {
  final Character character;

  const CharacterInventoryScreen({super.key, required this.character});

  @override
  State<CharacterInventoryScreen> createState() => _CharacterInventoryScreenState();
}

class _CharacterInventoryScreenState extends State<CharacterInventoryScreen> {
  late List<InventoryItem> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.character.inventory);
  }

  Future<void> _saveInventory() async {
    widget.character.inventory = items;
    await Character.saveCharacters();
  }

  static const double _gridX = 0.0;
  static const double _gridY = 0.0;
  double get _gridWidth => 540.0; // 30 cells * 18.0
  double get _gridHeight => widget.character.str * 2 * 18.0; // STR * 2 cells * 18.0
  static const double _cellSize = 18.0;

  List<Rect> _getGreyBlocks(InventoryItem item) {
    List<Rect> blocks = [];
    final bool hasOddDimension = (item.gridWidth % 2 != 0) || (item.gridHeight % 2 != 0);
    double baseX = item.x;
    double baseY = item.y;

    final double centerX = baseX + item.width / 2;
    final double centerY = baseY + item.height / 2;

    for (int y = 0; y < item.gridHeight; y++) {
      for (int x = 0; x < item.gridWidth; x++) {
        if (item.gridLayout[y][x]) {
          double relX = x * _cellSize;
          double relY = y * _cellSize;
          double offsetX = relX - item.width / 2;
          double offsetY = relY - item.height / 2;
          double rotatedX = offsetX * math.cos(item.angle) - offsetY * math.sin(item.angle);
          double rotatedY = offsetX * math.sin(item.angle) + offsetY * math.cos(item.angle);
          double blockX = centerX + rotatedX;
          double blockY = centerY + rotatedY;

          if (hasOddDimension) {
            if (item.angle == 0) {
              // 0° Vertical: No change
            } else if (item.angle == math.pi / 2) {
              blockX -= 1 * _cellSize; // -18.0 for 90° odd-dimension
            } else if (item.angle == math.pi) {
              blockX -= _cellSize; // -18.0 for 180° odd-dimension
              blockY -= _cellSize; // -18.0 for 180° odd-dimension
            } else if (item.angle == 3 * math.pi / 2) {
              blockX += 0 * _cellSize; // 0.0 for 270° odd-dimension
              blockY -= _cellSize; // -18.0 for 270° odd-dimension
            }
          } else {
            if (item.angle == 0) {
              // 0°: No offset, align with grid
            } else if (item.angle == math.pi / 2) {
              blockX -= _cellSize; // -18.0 for 90° even-dimension
            } else if (item.angle == math.pi) {
              blockX -= _cellSize; // -18.0 for 180° even-dimension
              blockY -= _cellSize; // -18.0 for 180° even-dimension
            } else if (item.angle == 3 * math.pi / 2) {
              blockY -= _cellSize; // -18.0 for 270° even-dimension
            }
          }
          blocks.add(Rect.fromLTWH(blockX, blockY, _cellSize, _cellSize));
        }
      }
    }
    return blocks;
  }

  bool _checkOverlap(InventoryItem item1, InventoryItem item2) {
    final blocks1 = _getGreyBlocks(item1);
    final blocks2 = _getGreyBlocks(item2);
    for (var block1 in blocks1) {
      for (var block2 in blocks2) {
        if (block1.overlaps(block2)) return true;
      }
    }
    return false;
  }

  Rect _getItemBounds(InventoryItem item) {
    final blocks = _getGreyBlocks(item);
    if (blocks.isEmpty) {
      return Rect.fromLTWH(item.x, item.y, item.width, item.height);
    }
    double left = blocks.map((b) => b.left).reduce(math.min);
    double top = blocks.map((b) => b.top).reduce(math.min);
    double right = blocks.map((b) => b.right).reduce(math.max);
    double bottom = blocks.map((b) => b.bottom).reduce(math.max);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _snapToGrid(InventoryItem droppedItem, double x, double y) {
    final int cellX = ((x - _gridX) / _cellSize).round();
    final int cellY = ((y - _gridY) / _cellSize).round();
    double snappedX = (cellX * _cellSize) + _gridX;
    double snappedY = (cellY * _cellSize) + _gridY;

    final bool hasOddDimension = (droppedItem.gridWidth % 2 != 0) || (droppedItem.gridHeight % 2 != 0);
    if (hasOddDimension && (droppedItem.angle == math.pi / 2 || droppedItem.angle == 3 * math.pi / 2)) {
      snappedX -= _cellSize / 2; // -9.0
      snappedY -= _cellSize / 2; // -9.0
    }

    double oldX = droppedItem.x;
    double oldY = droppedItem.y;
    droppedItem.x = snappedX;
    droppedItem.y = snappedY;
    final bounds = _getItemBounds(droppedItem);

    double minX = _gridX;
    if (hasOddDimension) {
      if (droppedItem.angle == math.pi / 2) {
        minX = _gridX; // Changed from -18.0 to 0.0 to stop at left edge
      } else if (droppedItem.angle == 3 * math.pi / 2) {
        minX = _gridX; // 0.0
      }
    }

    if (bounds.left < minX) snappedX += (minX - bounds.left);
    if (bounds.top < _gridY) snappedY += (_gridY - bounds.top);
    if (bounds.right > _gridX + _gridWidth) snappedX -= (bounds.right - (_gridX + _gridWidth));
    if (bounds.bottom > _gridY + _gridHeight) snappedY -= (bounds.bottom - (_gridY + _gridHeight));

    setState(() {
      droppedItem.x = snappedX;
      droppedItem.y = snappedY;

      for (var item in items) {
        item.isOverlapping = false;
      }

      for (int i = 0; i < items.length; i++) {
        for (int j = i + 1; j < items.length; j++) {
          if (_checkOverlap(items[i], items[j])) {
            items[i].isOverlapping = true;
            items[j].isOverlapping = true;
          }
        }
      }

      _saveInventory();
    });
  }

  void _updatePosition(DragUpdateDetails details, InventoryItem item) {
    setState(() {
      double newX = item.x + details.delta.dx;
      double newY = item.y + details.delta.dy;

      double oldX = item.x;
      double oldY = item.y;
      item.x = newX;
      item.y = newY;
      final bounds = _getItemBounds(item);

      final bool hasOddDimension = (item.gridWidth % 2 != 0) || (item.gridHeight % 2 != 0);
      double minX = _gridX;
      if (hasOddDimension) {
        if (item.angle == math.pi / 2) {
          minX = _gridX; // Changed from -18.0 to 0.0 to stop at left edge
        } else if (item.angle == 3 * math.pi / 2) {
          minX = _gridX; // 0.0
        }
      }

      if (bounds.left < minX) newX += (minX - bounds.left);
      if (bounds.top < _gridY) newY += (_gridY - bounds.top);
      if (bounds.right > _gridX + _gridWidth) newX -= (bounds.right - (_gridX + _gridWidth));
      if (bounds.bottom > _gridY + _gridHeight) newY -= (bounds.bottom - (_gridY + _gridHeight));

      item.x = newX;
      item.y = newY;
    });
  }

  void _rotateItem(InventoryItem item) {
    setState(() {
      item.angle = (item.angle + math.pi / 2) % (2 * math.pi);
      final bounds = _getItemBounds(item);

      if (bounds.left < _gridX) item.x += (_gridX - bounds.left);
      if (bounds.top < _gridY) item.y += (_gridY - bounds.top);
      if (bounds.right > _gridX + _gridWidth) item.x -= (bounds.right - (_gridX + _gridWidth));
      if (bounds.bottom > _gridY + _gridHeight) item.y -= (bounds.bottom - (_gridY + _gridHeight));

      _snapToGrid(item, item.x, item.y);
    });
  }

  void _addItem(InventoryItem newItem) {
    setState(() {
      items.add(InventoryItem(
        x: 0.0,
        y: 0.0,
        name: newItem.name,
        imagePath: newItem.imagePath,
        gridWidth: newItem.gridWidth,
        gridHeight: newItem.gridHeight,
        gridLayout: newItem.gridLayout.map((row) => List<bool>.from(row)).toList(),
      ));
      _snapToGrid(items.last, items.last.x, items.last.y);
    });
  }

  void _removeItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.name.capitalize()),
                onTap: () {
                  setState(() {
                    items.removeAt(index);
                    for (var item in items) {
                      item.isOverlapping = false;
                    }
                    for (int i = 0; i < items.length; i++) {
                      for (int j = i + 1; j < items.length; j++) {
                        if (_checkOverlap(items[i], items[j])) {
                          items[i].isOverlapping = true;
                          items[j].isOverlapping = true;
                        }
                      }
                    }
                    _saveInventory();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final predefinedItems = InventoryItem.getPredefinedItems();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: predefinedItems.length,
            itemBuilder: (context, index) {
              final item = predefinedItems[index];
              return ListTile(
                title: Text(item.name.capitalize()),
                onTap: () {
                  _addItem(item);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
      ),
    );
  }

  Widget _buildGreyBlocks(InventoryItem item) {
    final double blockSize = _cellSize;
    List<Widget> blocks = [];
    final Color blockColor = item.isOverlapping && !item.isDragging
        ? Colors.red.withOpacity(0.5)
        : Colors.grey.withOpacity(0.5);

    for (int y = 0; y < item.gridHeight; y++) {
      for (int x = 0; x < item.gridWidth; x++) {
        if (item.gridLayout[y][x]) {
          blocks.add(Positioned(
            left: x * blockSize,
            top: y * blockSize,
            child: Container(width: blockSize, height: blockSize, color: blockColor),
          ));
        }
      }
    }
    return SizedBox(width: item.width, height: item.height, child: Stack(children: blocks));
  }

  int _calculateMovementSpeed() {
    const int baseSpeed = 30;
    bool anyOverlapping = false;
    bool anyInRed = false;
    bool anyInYellow = false;

    for (var item in items) {
      final blocks = _getGreyBlocks(item);
      for (var block in blocks) {
        if (block.left >= 360.0) { // Red zone (20-29)
          anyInRed = true;
        } else if (block.left >= 180.0) { // Yellow zone (10-19)
          anyInYellow = true;
        }
      }
    }

    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        if (_checkOverlap(items[i], items[j])) {
          anyOverlapping = true;
        }
      }
    }

    if (anyOverlapping) return 0;
    if (anyInRed) return baseSpeed - 20;
    if (anyInYellow) return baseSpeed - 10;
    return baseSpeed;
  }

  @override
  Widget build(BuildContext context) {
    const double bufferLeftRight = 80.0;
    const double textBoxWidth = 180.0;
    const double textBoxHeight = 72.0;
    const double smallBoxWidth = 36.0;
    const double smallBoxHeight = 36.0;

    final movementSpeed = _calculateMovementSpeed();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.character.name}'s Inventory"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Movement Speed: $movementSpeed',
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.blueGrey[800],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: bufferLeftRight, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    SizedBox(height: 100.0),
                    SizedBox(height: _gridHeight - (widget.character.str * smallBoxHeight)),
                    ...List.generate(widget.character.str, (index) {
                      final number = widget.character.str - index;
                      return Container(
                        width: smallBoxWidth,
                        height: smallBoxHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$number',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                    Container(
                      width: smallBoxWidth,
                      height: textBoxHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('^', style: TextStyle(color: Colors.white, fontSize: 12)),
                          Text('STR', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(height: 100.0),
                    SizedBox(
                      width: _gridWidth,
                      height: _gridHeight,
                      child: Stack(
                        children: [
                          Positioned(
                            left: _gridX,
                            top: _gridY,
                            child: CustomPaint(
                              size: Size(_gridWidth, _gridHeight),
                              painter: GridPainter(cellsTall: widget.character.str * 2),
                            ),
                          ),
                          ...items.map((item) => Positioned(
                                left: item.x,
                                top: item.y,
                                child: GestureDetector(
                                  onPanStart: (_) {
                                    setState(() => item.isDragging = true);
                                  },
                                  onPanUpdate: (details) => _updatePosition(details, item),
                                  onPanEnd: (_) {
                                    setState(() {
                                      item.isDragging = false;
                                      _snapToGrid(item, item.x, item.y);
                                    });
                                  },
                                  onDoubleTap: () => _rotateItem(item),
                                  child: Transform.rotate(
                                    angle: item.angle,
                                    child: Stack(
                                      children: [
                                        _buildGreyBlocks(item),
                                        Container(
                                          width: item.width,
                                          height: item.height,
                                          decoration: BoxDecoration(
                                            border: item.isDragging ? Border.all(color: Colors.yellow, width: 2) : null,
                                          ),
                                          child: Image.asset(item.imagePath, fit: BoxFit.contain),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: textBoxWidth,
                          height: textBoxHeight,
                          decoration: BoxDecoration(
                            color: Colors.green[300]!.withOpacity(0.6),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Not Encumbered',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: textBoxWidth,
                          height: textBoxHeight,
                          decoration: BoxDecoration(
                            color: Colors.yellow[300]!.withOpacity(0.6),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Encumbered\n-10 Move Speed',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: textBoxWidth,
                          height: textBoxHeight,
                          decoration: BoxDecoration(
                            color: Colors.red[300]!.withOpacity(0.6),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Heavily Encumbered',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '-20 Move Speed\nDisadv. Dex/Str/Con, Atk Rolls',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'removeFab',
            onPressed: () => _removeItemDialog(context),
            child: const Icon(Icons.remove),
            tooltip: 'Remove Item',
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'addFab',
            onPressed: () => _showAddItemDialog(context),
            child: const Icon(Icons.add),
            tooltip: 'Add Item',
          ),
        ],
      ),
    );
  }
}

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  void _deleteItem(BuildContext context, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $itemName?'),
        content: const Text('This will permanently remove the item from the app. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                InventoryItem.removePredefinedItem(itemName);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$itemName deleted permanently')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final predefinedItems = InventoryItem.getPredefinedItems();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Items')),
      body: ListView.builder(
        itemCount: predefinedItems.length,
        itemBuilder: (context, index) {
          final item = predefinedItems[index];
          return ListTile(
            title: Text(item.name.capitalize()),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(context, item.name),
            ),
          );
        },
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final int cellsTall;

  GridPainter({required this.cellsTall});

  @override
  void paint(Canvas canvas, Size size) {
    const int cellsWide = 30;
    final double cellSize = size.width / cellsWide;
    final double sectionWidth = cellSize * 10;

    final greenPaint = Paint()..color = Colors.green[300]!.withOpacity(0.6);
    final yellowPaint = Paint()..color = Colors.yellow[300]!.withOpacity(0.6);
    final redPaint = Paint()..color = Colors.red[300]!.withOpacity(0.6);

    canvas.drawRect(Rect.fromLTWH(0, 0, sectionWidth, size.height), greenPaint);
    canvas.drawRect(Rect.fromLTWH(sectionWidth, 0, sectionWidth, size.height), yellowPaint);
    canvas.drawRect(Rect.fromLTWH(2 * sectionWidth, 0, sectionWidth, size.height), redPaint);

    final blackPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final greyPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= cellsWide; i++) {
      if (i % 2 == 1) {
        final x = i * cellSize;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), greyPaint);
      }
    }
    for (int i = 0; i <= cellsTall; i++) {
      final indexFromBottom = cellsTall - i;
      if (indexFromBottom % 2 == 1) {
        final y = i * cellSize;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), greyPaint);
      }
    }
    for (int i = 0; i <= cellsWide; i++) {
      if (i % 2 == 0) {
        final x = i * cellSize;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), blackPaint);
      }
    }
    for (int i = 0; i <= cellsTall; i++) {
      final indexFromBottom = cellsTall - i;
      if (indexFromBottom % 2 == 0) {
        final y = i * cellSize;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), blackPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}// this version is working both with edge detection and with collision detection it should basically be ready for item additions . i might want to add the weight indicator on the item creation just to make sure i get the numbers right 