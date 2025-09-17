import 'package:flutter/material.dart';
import '../vision_bord/premium_them_vision_board.dart';
import '../vision_bord/post_it_theme_vision_board.dart';
import '../vision_bord/coffee_hues_theme_vision_board.dart';
import '../vision_bord/winter_warmth_theme_vision_board.dart';
import '../vision_bord/box_them_vision_board.dart';
import '../vision_bord/ruby_reds_theme_vision_board.dart';
import 'vision_board_category_picker.dart';

class VisionBoardThemePickerPage extends StatelessWidget {
  static const routeName = '/visionboard/theme-picker';

  const VisionBoardThemePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ThemeItem>[
      _ThemeItem('Premium Vision Board', Icons.star, () => const PremiumThemeVisionBoard()),
      _ThemeItem('PostIt Vision Board', Icons.sticky_note_2, () => const PostItThemeVisionBoard()),
      _ThemeItem('Coffee Hues Vision Board', Icons.coffee, () => const CoffeeHuesThemeVisionBoard()),
      _ThemeItem('Winter Warmth Vision Board', Icons.ac_unit, () => const WinterWarmthThemeVisionBoard()),
      _ThemeItem('Box Vision Board', Icons.view_module, () => const VisionBoardDetailsPage(title: 'Box Them Vision Board')),
      _ThemeItem('Ruby Reds Vision Board', Icons.favorite, () => const RubyRedsThemeVisionBoard()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Select Vision Board Theme')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Icon(item.icon, color: Colors.blue),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // After selecting theme screen, send the user to category picker
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => item.builder()),
              ).then((_) {
                Navigator.of(context).pushNamed(VisionBoardCategoryPickerPage.routeName);
              });
            },
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: items.length,
      ),
    );
  }
}

class _ThemeItem {
  final String title;
  final IconData icon;
  final Widget Function() builder;
  _ThemeItem(this.title, this.icon, this.builder);
}


