"""Native pre-engine launch contract; independent of Flutter/SDK execution."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / 'app/android/app/src/main/res'
BLUE = (130, 223, 241)


class StartupNativeTest(unittest.TestCase):
    def test_ios_launch_and_engine_container_have_same_opaque_blue(self):
        for name in ['LaunchScreen', 'Main']:
            with self.subTest(storyboard=name):
                xml = ET.parse(ROOT / f'app/ios/Runner/Base.lproj/{name}.storyboard')
                color = xml.find('.//view/color[@key="backgroundColor"]')
                rgb = tuple(round(float(color.get(k, color.get('white', '0'))) * 255)
                            for k in ['red', 'green', 'blue'])
                self.assertEqual(rgb, BLUE)
                self.assertEqual(color.get('alpha'), '1')

    def test_legacy_normal_day_and_night_never_use_system_surface_color(self):
        for folder in ['values', 'values-night']:
            xml = ET.parse(RES / folder / 'styles.xml')
            self.assertEqual(xml.findtext("style[@name='NormalTheme']/item[@name='android:windowBackground']"),
                             '@color/startup_background')
            self.assertEqual(xml.findtext("style[@name='LaunchTheme']/item[@name='android:windowBackground']"),
                             '@drawable/launch_background')
        for folder in ['drawable', 'drawable-v21']:
            xml = ET.parse(RES / folder / 'launch_background.xml')
            self.assertEqual(xml.find('item').get('{http://schemas.android.com/apk/res/android}drawable'),
                             '@color/startup_background')

    def test_android_12_light_and_night_explicitly_brand_system_splash(self):
        for folder in ['values-v31', 'values-night-v31']:
            path = RES / folder / 'styles.xml'
            self.assertTrue(path.exists(), f'{folder} must cover Android12 system splash')
            xml = ET.parse(path)
            self.assertEqual(xml.findtext("style[@name='LaunchTheme']/item[@name='android:windowSplashScreenBackground']"),
                             '@color/startup_background')
            self.assertEqual(xml.findtext("style[@name='LaunchTheme']/item[@name='android:windowSplashScreenAnimatedIcon']"),
                             '@drawable/startup_icon')

    def test_native_wordmark_is_not_empty_or_clipped_by_android_icon_mask(self):
        for scale in [1, 2, 3]:
            suffix = '' if scale == 1 else f'@{scale}x'
            im = Image.open(ROOT / f'app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png')
            self.assertEqual(im.width, 176 * scale)
            self.assertTrue(im.convert('RGBA').getchannel('A').getbbox())
        for folder, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
            path = RES / f'drawable-{folder}/startup_icon.png'
            self.assertTrue(path.exists())
            im = Image.open(path).convert('RGBA')
            self.assertEqual(im.size, (round(288 * scale), round(288 * scale)))
            alpha = im.getchannel('A')
            bounds = alpha.getbbox()
            self.assertIsNotNone(bounds)
            cx = cy = im.width / 2
            for x, y in [(bounds[0], bounds[1]), (bounds[2], bounds[3])]:
                self.assertLessEqual((x-cx)**2 + (y-cy)**2, (96 * scale)**2)


if __name__ == '__main__':
    unittest.main()
