// Synthetic nonempty SQLite serialized by unmodified build13 GameStore/core.
// Source: 236cea0479837d415094a784f47b6d3928c3366c; no device/SDK data.
// Reproduction: tools/validation/fixtures/README.md. Not a shipping asset.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const legacy13FixtureSha256 =
    'a5cbb36efe5b6eee47cfc59785a550006df563fb8f76d52b7b62af3dd7364c9f';

Uint8List legacy13FixtureBytes() => Uint8List.fromList(
  gzip.decode(
    base64Decode(
      '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'
      'AAAABA8/svafN0gwAAAgA=',
    ),
  ),
);
