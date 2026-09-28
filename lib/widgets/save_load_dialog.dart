import 'package:flutter/material.dart';
import '../logic/storage_service.dart';

class SaveLoadDialog extends StatefulWidget {
  final bool isSaveMode;
  final SavedGameState currentState;
  final Function(SavedGameState state) onLoad;

  const SaveLoadDialog({
    super.key,
    required this.isSaveMode,
    required this.currentState,
    required this.onLoad,
  });

  @override
  State<SaveLoadDialog> createState() => _SaveLoadDialogState();
}

class _SaveLoadDialogState extends State<SaveLoadDialog> {
  final TextEditingController _nameController = TextEditingController();
  List<SavedGameState> _saves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        'Rek Match ${DateTime.now().month}/${DateTime.now().day} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    _loadSavesList();
  }

  Future<void> _loadSavesList() async {
    setState(() => _isLoading = true);
    final list = await StorageService.getAllSavedGames();
    setState(() {
      _saves = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = screenSize.width * 0.92 > 480 ? 480.0 : screenSize.width * 0.92;
    final dialogHeight = screenSize.height * 0.88 > 520 ? 520.0 : screenSize.height * 0.88;

    return Dialog(
      backgroundColor: const Color(0xFF263238),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isSaveMode ? 'Save Game' : 'Load Game',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (widget.isSaveMode) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Save Name',
                  labelStyle: const TextStyle(color: Color(0xFFFFD54F)),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Current Board'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final newSave = SavedGameState(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim().isEmpty
                          ? 'Untitled Rek Game'
                          : _nameController.text.trim(),
                      timestamp: DateTime.now(),
                      board: widget.currentState.board,
                      currentTurn: widget.currentState.currentTurn,
                      isPlayMode: widget.currentState.isPlayMode,
                    );
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    await StorageService.saveGame(newSave);
                    await StorageService.quickSave(newSave);
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Game saved successfully!'),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24),
            ],
            const Text(
              'Saved Games',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _saves.isEmpty
                      ? const Center(
                          child: Text(
                            'No saved games found.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _saves.length,
                          separatorBuilder: (_, index) =>
                              const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            final save = _saves[index];
                            final timeStr =
                                '${save.timestamp.year}-${save.timestamp.month.toString().padLeft(2, '0')}-${save.timestamp.day.toString().padLeft(2, '0')} ${save.timestamp.hour.toString().padLeft(2, '0')}:${save.timestamp.minute.toString().padLeft(2, '0')}';
                            return ListTile(
                              dense: true,
                              title: Text(
                                save.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '$timeStr • Turn: ${save.currentTurn.name.toUpperCase()}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.file_upload_outlined,
                                      color: Color(0xFF81C784),
                                    ),
                                    onPressed: () {
                                      widget.onLoad(save);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      await StorageService.deleteSave(save.id);
                                      _loadSavesList();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
