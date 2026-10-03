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
            _buildSectionTitle('១. ក្បាច់ស៊ីរែក (1. The Rule of "Rek" - Capturing)'),
            _buildBodyText(
              '• យន្តការស៊ីរែក (Capturing Mechanism)៖ អ្នកលេងអាច «រែក» ស៊ីកូនអុករបស់គូប្រកួតបាន លុះត្រាតែដើរកូនអុករបស់ខ្លួនចូលចំកណ្តាលរវាងកូនអុកសត្រូវ ២ គ្រាប់ដែលនៅជាប់គ្នាជាបន្ទាត់ត្រង់ (ខ្សែផ្តេក ឬខ្សែបញ្ឈរ)។\n'
              '• នៅពេលរែកបាន កូនអុកសត្រូវទាំង ២ គ្រាប់នោះនឹងត្រូវដកចេញពីក្តារភ្លាមៗ (រូបរាងដូចមនុស្សកំពុងរែកអង្រែកដែលមានបន្ទុកស្មើគ្នានៅសងខាងស្មា)។\n'
              '• ប្រសិនបើដើរចូលចំកណ្តាលរវាងខ្សែផ្តេកផង និងខ្សែបញ្ឈរផង នោះអាចរែកស៊ីបានទាំង ៤ គ្រាប់ក្នុងពេលតែមួយ!',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('២. ច្បាប់ហៅ (2. The Rule of "Call" - Setting Traps & Forcing a Capture)'),
            _buildBodyText(
              '• ការដាក់អន្ទាក់ (Baiting)៖ ជាយុទ្ធសាស្ត្រដែលអ្នកលេងដើរកូនអុករបស់ខ្លួនដើម្បីដាក់អន្ទាក់ ដោយចេតនាបើកផ្លូវឱ្យគូប្រកួតដើរចូលដើម្បីស៊ី (រែក/ខាត់) កូនអុករបស់ខ្លួន។\n'
              '• ប៊ូតុងហៅ និងកាតព្វកិច្ចស៊ី (Strict Obligation by Button Call)៖ អ្នកលេងត្រូវតែស៊ីរែកដាច់ខាត លុះត្រាតែគូប្រកួតបានចុចប៊ូតុង «ហៅ» (Call)។ ប្រសិនបើគូប្រកួតមិនបានចុចប៊ូតុងហៅទេ នោះអ្នកលេងអាចសម្រេចចិត្តដោយសេរីថាតើចង់ស៊ីរែក ឬចង់ដើរក្រឡាធម្មតាផ្សេងទៀត!\n'
              '• ប្រសិនបើមានអន្ទាក់ «ហៅ» (Call) ច្រើនក្នុងពេលតែមួយ អ្នកលេងដែលត្រូវបង្ខំឱ្យស៊ី អាចជ្រើសរើសស៊ីអន្ទាក់ណាមួយដែលផ្តល់ការខាតបង់តិចបំផុត។',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('៣. ក្បាច់ស៊ីខាត់ (3. The Rule of "Khat" - Surrounding Capture)'),
            _buildBodyText(
              '• ការឡោមព័ទ្ធចាប់ស៊ី (Surrounding Capture)៖ កូនអុក ឬក្រុមនៃកូនអុករបស់សត្រូវណាដែលត្រូវបានឡោមព័ទ្ធជុំជិតទាំងស្រុង ដោយគ្មានក្រឡាទំនេរស្របច្បាប់ណាមួយអាចដើរបាន (Zero legal orthogonal moves) ត្រូវបានចាត់ទុកថាជាប់អន្ទាក់ (ខាត់) ហើយត្រូវដកចេញពីក្តារភ្លាមៗ។\n'
              '• ច្បាប់ខាត់នេះអនុវត្តទាំងលើជម្រើសលេងរែក (Rek) និងជម្រើសលេងហៅ (Call)។\n'
              '• ប្រសិនបើការដើរមួយបង្កើតបានទាំងការស៊ីរែកផង និងស៊ីខាត់ផង នោះកូនអុកសត្រូវទាំងអស់ដែលត្រូវរែក និងត្រូវខាត់ នឹងត្រូវដកចេញពីក្តារក្នុងពេលតែមួយ!',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('៤. ច្បាប់ដើរទូទៅ (4. General Movement Rules)'),
            _buildBodyText(
              '• កូនអុកនីមួយៗអាចរត់ជាខ្សែបន្ទាត់ត្រង់ (ទៅមុខ ថយក្រោយ ទៅឆ្វេង ឬទៅស្តាំ ដូចទូកក្នុងអុក) បានច្រើនក្រឡារហូតដល់ទល់នឹងឧបសគ្គ (កូនអុកផ្សេងទៀត ឬជាយនៃក្តារ)។\n'
              '• កូនអុកមិនអាចដើរបញ្ឆិត (អង្កត់ទ្រូង) ឬលោតរំលងកូនអុកដទៃបានឡើយ។\n'
              '• កូនអុកពិសេស «មេ» (Me - King/Commander) ស្ថិតនៅមួយកន្លែងមិនអាចដើរបានឡើយ (Fixed King)។ អ្នកលេងត្រូវការពារមេរបស់ខ្លួន និងស្វែងរកឱកាសចាប់ស៊ីមេរបស់គូប្រកួត។',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('៥. លក្ខខណ្ឌឈ្នះ និងចាញ់ (5. Winning & Losing Conditions)'),
            _buildBodyText(
              '• អ្នកឈ្នះ គឺជាអ្នកលេងដែលស៊ីកូនអុករបស់គូប្រកួតទាំងអស់ឱ្យអស់ពីក្តារ ឬឡោមព័ទ្ធចាប់ស៊ី «មេ» (Me) របស់គូប្រកួតបានសម្រេច។\n'
              '• អ្នកលេងក៏ត្រូវចាញ់ផងដែរ ប្រសិនបើត្រូវបានគូប្រកួតឡោមព័ទ្ធជិតទាំងស្រុង (ខាត់/Stalemate) ដោយគ្មានក្រឡាស្របច្បាប់ណាមួយអាចដើរបាន។',
            ),
            const SizedBox(height: 14),

            _buildSectionTitle('៦. ផ្ទាំងបញ្ជា និងឧបករណ៍រៀបចំក្តារ (Controls & Editor)'),
            _buildBodyText(
              '• ប្រើប្រអប់ជ្រើសរើសកូនអុកដើម្បីរៀបចំក្តារដោយសេរី។\n'
              '• ចុច «លុប» ឬ «លុបទាំងអស់» ដើម្បីសម្អាតក្តារ។\n'
              '• ចុច «បង្វិលក្តារ» ដើម្បីបង្វិលមុំមើល ១៨០ ដឺក្រេ។\n'
              '• ចុច «លេង» ដើម្បីចាប់ផ្តើមលេងការប្រកួតពិតប្រាកដជាមួយ AI ឬលេង២នាក់!',
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
          _buildSectionTitle('1. The Rule of "Rek" (Capturing)'),
          _buildBodyText(
            '• Capturing Mechanism: A player can "Rek" (capture) the opponent\'s pieces only when they move one of their own pieces to land exactly in the middle between two of the opponent\'s pieces (in a straight horizontal or vertical line).\n'
            '• Once captured, both of the opponent\'s pieces are removed from the board (this visually resembles a person carrying a balanced load on both ends of a shoulder pole).\n'
            '• If a move simultaneously sandwiches between two opponent pieces horizontally and two vertically, all 4 pieces are captured!',
          ),
          const SizedBox(height: 14),

          _buildSectionTitle('2. The Rule of "Call" (Setting Traps & Forcing a Capture)'),
          _buildBodyText(
            '• Baiting: A strategy where a player moves their piece to set a trap, opening a path to bait the opponent into capturing their piece.\n'
            '• Call Button & Strict Obligation: A player is strictly obligated to Rek ONLY when the opponent calls them by clicking the "Call" button! If the opponent does NOT click the Call button, the player can freely decide whether they want to Rek or make another legal move.\n'
            '• If there are multiple "Call" traps set at the same time, the player forced to capture may choose which one to take based on which will result in the least loss.',
          ),
          const SizedBox(height: 14),

          _buildSectionTitle('3. Surrounding Capture (Khat)'),
          _buildBodyText(
            '• Surrounding Capture (Khat): Any enemy piece or group completely surrounded with zero legal orthogonal moves is trapped and removed from the board.\n'
            '• This rule applies to both "Rek" and "Call" game modes.\n'
            '• If a single move simultaneously executes both a Rek sandwich capture and traps an enemy group with Khat, all captured and trapped pieces are removed from the board together!',
          ),
          const SizedBox(height: 14),

          _buildSectionTitle('4. General Movement Rules'),
          _buildBodyText(
            '• Standard pieces can move in straight orthogonal lines: forward, backward, left, or right (like a Rook in chess) across any number of empty squares until obstructed by another piece or the board edge.\n'
            '• Pieces cannot move diagonally and cannot jump over other pieces.\n'
            '• The King ("Me" / Commander) is fixed in one place and cannot move. Players must guard their own King while maneuvering their pieces to capture the opponent\'s stationary King.',
          ),
          const SizedBox(height: 14),

          _buildSectionTitle('5. Winning and Losing Conditions'),
          _buildBodyText(
            '• The winner is the player who captures all of the opponent\'s pieces or successfully traps and captures the opponent\'s "Me".\n'
            '• A player also loses if they are completely blocked in (stalemate) by the opponent and have no valid moves left.',
          ),
          const SizedBox(height: 14),

          _buildSectionTitle('6. Interface & Editor Controls'),
          _buildBodyText(
            '• Use Piece Selectors to customize your board setup.\n'
            '• Tap "Erase" to remove pieces or "Erase all" to clear the board.\n'
            '• Tap "Rotate Baord" to flip the board view 180 degrees.\n'
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
                        ? '+${move.totalCaptures} ${move.surroundCaptures.isNotEmpty && move.rekCaptures.isEmpty ? "ខាត់" : "រែក"}'
                        : '+${move.totalCaptures} ${move.surroundCaptures.isNotEmpty && move.rekCaptures.isEmpty ? "Khat" : "Rek"}',
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
