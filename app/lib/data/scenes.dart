const sceneIds = ['color_studio', 'garden_nook', 'seaside_corner'];
String sceneForLevel(int level) => sceneIds[(level - 1) ~/ 20];
String sceneTitle(String id) =>
    const {
      'color_studio': 'Color Studio',
      'garden_nook': 'Garden Nook',
      'seaside_corner': 'Seaside Corner',
    }[id] ??
    id;
