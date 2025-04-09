import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'main.dart';

class ItemCreatorScreen extends StatefulWidget {
  const ItemCreatorScreen({super.key});

  @override
  State<ItemCreatorScreen> createState() => _ItemCreatorScreenState();
}

class _ItemCreatorScreenState extends State<ItemCreatorScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedImagePath = 'assets/images/long_sword.png';
  int _gridWidth = 3;
  int _gridHeight = 10;
  late List<List<bool>> _gridLayout;

  @override
  void initState() {
    super.initState();
    _gridLayout = List.generate(_gridHeight, (_) => List.filled(_gridWidth, true));
    _nameController.addListener(_updateImage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateImage() {
    final input = _nameController.text.toLowerCase().trim();
    if (input.isEmpty) {
      setState(() => _selectedImagePath = 'assets/images/long_sword.png');
      return;
    }
    setState(() => _selectedImagePath = 'assets/images/${input.replaceAll(' ', '_')}.png');
  }

  void _updateGridSize() {
    setState(() {
      _gridLayout = List.generate(
        _gridHeight,
        (_) => List.filled(_gridWidth, true),
      );
    });
  }

  void _toggleGridCell(int x, int y) {
    setState(() {
      _gridLayout[y][x] = !_gridLayout[y][x];
    });
  }

  double _calculateWeight() {
    int selectedCells = 0;
    for (var row in _gridLayout) {
      for (var cell in row) {
        if (cell) selectedCells++;
      }
    }
    return selectedCells * 0.25; // Each cell is 1/4 lb
  }

  void _saveItem() {
    final newItem = InventoryItem(
      x: 0.0,
      y: 0.0,
      name: _nameController.text.isEmpty ? 'unnamed' : _nameController.text,
      imagePath: _selectedImagePath,
      gridWidth: _gridWidth,
      gridHeight: _gridHeight,
      gridLayout: _gridLayout.map((row) => List<bool>.from(row)).toList(),
    );
    InventoryItem.addPredefinedItem(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const double gridCellSize = 10.0; // Half of typical 20-24px size for better fit
    final currentWeight = _calculateWeight();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Current Weight: ${currentWeight.toStringAsFixed(2)} lbs',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                _selectedImagePath,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Image not found', style: TextStyle(color: Colors.red));
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Grid Width'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _gridWidth = int.tryParse(value) ?? 3;
                        _gridWidth = _gridWidth.clamp(1, 30);
                        _updateGridSize();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Grid Height'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _gridHeight = int.tryParse(value) ?? 10;
                        _gridHeight = _gridHeight.clamp(1, 30);
                        _updateGridSize();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridWidth,
                childAspectRatio: 1.0,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: _gridWidth * _gridHeight,
              itemBuilder: (context, index) {
                final x = index % _gridWidth;
                final y = index ~/ _gridWidth;
                return GestureDetector(
                  onTap: () => _toggleGridCell(x, y),
                  child: Container(
                    width: gridCellSize,
                    height: gridCellSize,
                    decoration: BoxDecoration(
                      color: _gridLayout[y][x] ? Colors.grey : Colors.transparent,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveItem,
                child: const Text('Save Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}