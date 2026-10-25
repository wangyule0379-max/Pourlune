import 'package:flutter/painting.dart';

/// Warm neutral knit derived from the existing cuff's luminance. Texture,
/// highlights and shadows survive; this is applied only to the knitted rim.
const neutralKnitColorFilter = ColorFilter.matrix([
  .15,
  .2933,
  .0567,
  0,
  132,
  .15,
  .2933,
  .0567,
  0,
  126,
  .15,
  .2933,
  .0567,
  0,
  115,
  0,
  0,
  0,
  1,
  0,
]);
