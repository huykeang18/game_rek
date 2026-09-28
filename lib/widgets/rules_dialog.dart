import 'package:flutter/material.dart';
import '../models/move.dart';
import '../services/language_service.dart';

class RulesDialog extends StatelessWidget {
  final List<RekMove> moveHistory;

  const RulesDialog({super.key, required this.moveHistory});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = screenSize.width * 0.92 > 520 ? 520.0 : screenSize.width * 0.92;
    final dialogHeight = screenSize.height * 0.88 > 580 ? 580.0 : screenSize.height * 0.88;

    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) {
          final lang = LanguageService.instance;
          final isKhmer = lang.isKhmer;

          return Dialog(
            backgroundColor: const Color(0xFF263238),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            ),
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Dialog Title & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book, color: Color(0xFFFFD54F), size: 22),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isKhmer ? 'ល្បែងរែក (Cambodian Rek)' : 'Cambodian Rek (ល្បែងរែក)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: isKhmer ? 'បិទ' : 'Close',
                      ),
                    ],
                  ),

                  // Tab Bar
                  TabBar(
                    indicatorColor: const Color(0xFFFFD54F),
                    labelColor: const Color(0xFFFFD54F),
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.menu_book),
                        text: isKhmer ? 'ច្បាប់លេង & ការណែនាំ' : 'Rules & Guide',
                      ),
                      Tab(
                        icon: const Icon(Icons.history),
                        text: isKhmer ? 'កំណត់ត្រាក្បាច់ដើរ' : 'Move Log',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRulesTab(isKhmer),
                        _buildMoveLogTab(isKhmer),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRulesTab(bool isKhmer) {
    if (isKhmer) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('១. ក្តារអុក & គោលដៅនៃការលេង'),
            _buildBodyText(
              '• លេងនៅលើក្តារក្រឡា ៨×៨ រវាងពណ៌បៃតងចាស់ (ខាងលើ) និងពណ៌បៃតងខ្ចី (ខាងក្រោម)។\n'
              '• អ្នកលេងម្នាក់ៗមានកូនអុកសរុប ១៦ គ្រាប់ រួមមាន ស្តេច ១ អង្គ (មានមកុដ) និងកូនទ័ពធម្មតា ១៥ គ្រាប់។\n'
              '• គោលបំណងចម្បង៖ ស៊ីស្តេចរបស់គូប្រកួត ឬស៊ីកូនអុកគូប្រកួតទាំងអស់ឱ្យអស់ពីក្តារដើម្បីទទួលបានជ័យជម្នះ!',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('២. របៀបដើរកូនអុក (ដើរដូចទូកក្នុងអុក)'),
            _buildBodyText(
              '• កូនអុកទាំងអស់ (ទាំងស្តេច និងកូនទ័ព) ដើរផ្លូវត្រង់ (ឡើងលើ ចុះក្រោម ទៅឆ្វេង ទៅស្តាំ) ដោយរំលងក្រឡាទទេបានច្រើនក្រឡាតាមចិត្ត ដូចទូកក្នុងអុកចត្រង្គដែរ។\n'
              '• កូនអុកមិនអាចដើររំលង ឬផ្លោះពីលើកូនអុកដទៃទៀតបានឡើយ។',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('៣. ក្បាច់ស៊ីរែក (The "Rek" Shoulder-Pole Capture)'),
            _buildBodyText(
              '• ពាក្យថា «រែក» គឺសំដៅលើទំនៀមខ្មែរក្នុងការប្រើអង្រែកដាក់លើស្មា ដោយមានកញ្ជើ ឬល្អីនៅសងខាងយ៉ាងមានលំនឹង។\n'
              '• នៅពេលអ្នកដើរកូនអុករបស់អ្នកចូលចន្លោះកណ្តាលរវាងកូនអុកសត្រូវ ២ គ្រាប់ដែលនៅជាប់គ្នាជាខ្សែបន្ទាត់ត្រង់ '
              '(ខ្សែផ្តេក៖ សត្រូវ - យើង - សត្រូវ ឬខ្សែបញ្ឈរ៖ សត្រូវ - យើង - សត្រូវ) អ្នកនឹង «រែក» ហើយស៊ីកូនអុកសត្រូវទាំង ២ គ្រាប់នោះភ្លាមៗ!\n'
              '• ប្រសិនបើក្បាច់ដើររបស់អ្នកអាចរែកបានទាំងខ្សែផ្តេក និងខ្សែបញ្ឈរក្នុងពេលតែមួយ អ្នកនឹងអាចស៊ីកូនអុកសត្រូវរហូតដល់ ៤ គ្រាប់ក្នុងពេលតែមួយ!',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('៤. ក្បាច់ព័ទ្ធស៊ី (ខាត់)'),
            _buildBodyText(
              '• កូនអុក ឬក្រុមនៃកូនអុករបស់សត្រូវណាដែលត្រូវបានឡោមព័ទ្ធជុំជិតដោយគ្មានក្រឡាទំនេរណាមួយអាចដើរបាន ត្រូវបានចាត់ទុកថាជាប់អន្ទាក់ (ខាត់) ហើយត្រូវដកចេញពីក្តារ។',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('៥. ផ្ទាំងបញ្ជា និងឧបករណ៍រៀបចំក្តារ'),
            _buildBodyText(
              '• ប្រើប្រអប់ជ្រើសរើសកូនអុកខាងលើ និងខាងក្រោមក្តារ ដើម្បីរៀបចំកូនអុកលើក្តារតាមការចង់បាន។\n'
              '• ចុច «លុប» ដើម្បីលុបកូនអុកម្តងមួយ ឬ «លុបទាំងអស់» ដើម្បីសម្អាតក្តារទាំងមូល។\n'
              '• ចុច «បង្វិលក្តារ» ដើម្បីបង្វិលមុំមើលក្តារអុក ១៨០ ដឺក្រេ។\n'
              '• ចុច «លេង» ដើម្បីចាប់ផ្តើមលេងការប្រកួតពិតប្រាកដជាមួយ AI ដ៏ឆ្លាតវៃ ឬលេង២នាក់នៅលើឧបករណ៍តែមួយ!',
            ),
          ],
        ),
      );
    }

    // English version
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
          const SizedBox(height: 14),

          _buildSectionTitle('2. Movement (Rook-like)'),
          _buildBodyText(
            '• All pieces (both King and Men) move orthogonally (up, down, left, right) '
            'any number of unoccupied squares, exactly like a Chess Rook.\n'
            '• Pieces cannot jump over other pieces.',
          ),
          const SizedBox(height: 14),

          _buildSectionTitle('3. The "Rek" (Shoulder Pole) Capture'),
          _buildBodyText(
            '• "Rek" in Khmer means carrying baskets balanced on a shoulder pole.\n'
            '• When you move your piece directly between two adjacent enemy pieces along a straight line '
            '(Horizontal: Enemy - You - Enemy, or Vertical: Enemy - You - Enemy), '
            'you "Rek" and capture both enemy pieces!\n'
            '• If your move simultaneously sandwiches both horizontally and vertically, you capture all 4 pieces!',
          ),
          const SizedBox(height: 14),

          _buildSectionTitle('4. Surrounding Capture (Khat)'),
          _buildBodyText(
            '• Any enemy piece or group completely surrounded with zero legal orthogonal moves '
            'is trapped and removed from the board.',
          ),
          const SizedBox(height: 14),

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

  Widget _buildMoveLogTab(bool isKhmer) {
    if (moveHistory.isEmpty) {
      return Center(
        child: Text(
          isKhmer
              ? 'មិនទាន់មានក្បាច់ដើរនៅក្នុងការប្រកួតនេះនៅឡើយទេ។\nសូមចុច «លេង» ដើម្បីចាប់ផ្តើម!'
              : 'No moves played yet in this session.\nTap "Play" to begin playing!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
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
                    isKhmer
                        ? '+${move.totalCaptures} រែក'
                        : '+${move.totalCaptures} Rek',
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
          height: 1.45,
        ),
      ),
    );
  }
}
