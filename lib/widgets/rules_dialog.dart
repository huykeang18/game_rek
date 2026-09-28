import 'package:flutter/material.dart';
import '../models/move.dart';

class RulesDialog extends StatelessWidget {
  final List<RekMove> moveHistory;

  const RulesDialog({super.key, required this.moveHistory});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 440,
          height: 520,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cambodian Rek (ល្បែងរែក)',
                    style: TextStyle(
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
              const TabBar(
                indicatorColor: Color(0xFFFFD54F),
                labelColor: Color(0xFFFFD54F),
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(icon: Icon(Icons.menu_book), text: 'Rules & Guide'),
                  Tab(icon: Icon(Icons.history), text: 'Move Log'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRulesTab(),
                    _buildMoveLogTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('1. Board & Objective'),
          _buildBodyText(
            '• Played on an 8×8 board between Teal (Top) and Lime Green (Bottom).\n'
            '• Each player controls 1 King (crowned) and 15 Men (plain).\n'
            '• Objective: Capture the opposing player\'s King or eliminate all opposing pieces!',
          ),
          const SizedBox(height: 12),
          _buildSectionTitle('2. Movement (Rook-like)'),
          _buildBodyText(
            '• All pieces (both King and Men) move orthogonally (up, down, left, right) '
            'any number of unoccupied squares, exactly like a Chess Rook.\n'
            '• Pieces cannot jump over other pieces.',
          ),
          const SizedBox(height: 12),
          _buildSectionTitle('3. The "Rek" (Shoulder Pole) Capture'),
          _buildBodyText(
            '• "Rek" in Khmer means carrying baskets balanced on a shoulder pole.\n'
            '• When you move your piece directly between two adjacent enemy pieces along a straight line '
            '(Horizontal: Enemy - You - Enemy, or Vertical: Enemy - You - Enemy), '
            'you "Rek" and capture both enemy pieces!\n'
            '• If your move simultaneously sandwiches both horizontally and vertically, you capture all 4 pieces!',
          ),
          const SizedBox(height: 12),
          _buildSectionTitle('4. Surrounding Capture (Khat)'),
          _buildBodyText(
            '• Any enemy piece or group completely surrounded with zero legal orthogonal moves '
            'is trapped and removed from the board.',
          ),
          const SizedBox(height: 12),
          _buildSectionTitle('5. Interface & Editor'),
          _buildBodyText(
            '• Use Piece Selectors to customize the board.\n'
            '• Tap "Erase" to remove pieces or "Erase all" to clear.\n'
            '• Tap "Rotate Baord" to flip the board view.\n'
            '• Tap "Play" to start real game play with move highlights and AI!',
          ),
        ],
      ),
    );
  }

  Widget _buildMoveLogTab() {
    if (moveHistory.isEmpty) {
      return const Center(
        child: Text(
          'No moves played yet in this session.\nTap "Play" to begin playing!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: moveHistory.length,
      separatorBuilder: (_, index) => const Divider(color: Colors.white24, height: 1),
      itemBuilder: (context, index) {
        final move = moveHistory[index];
        final moveNum = index + 1;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: move.piece.player.name == 'teal'
                ? const Color(0xFF00897B)
                : const Color(0xFF7CB342),
            child: Text(
              '$moveNum',
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            move.description,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          trailing: move.hasCapture
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${move.totalCaptures} Rek',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFD54F),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}
