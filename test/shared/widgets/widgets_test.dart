import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miro_app/shared/widgets/choice_card.dart';
import 'package:miro_app/shared/widgets/miro_button.dart';
import 'package:miro_app/shared/widgets/miro_controls.dart';
import 'package:miro_app/shared/widgets/miro_text_field.dart';
import 'package:miro_app/shared/widgets/radio_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../helpers/golden.dart';

Future<void> _pump(WidgetTester tester, Widget child) => pumpGolden(
      tester,
      Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

void main() {
  group('MiroButton', () {
    testWidgets('ketuk memanggil onPressed, label kapital', (tester) async {
      var taps = 0;
      await _pump(tester, MiroButton(label: 'Lanjut', onPressed: () => taps++));
      expect(find.text('LANJUT'), findsOneWidget);
      await tester.tap(find.text('LANJUT'));
      expect(taps, 1);
    });

    testWidgets('nonaktif tidak bisa ditekan', (tester) async {
      await _pump(tester, const MiroButton(label: 'Lanjut', onPressed: null));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lanjut')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
    });

    testWidgets('loading menolak ketukan (cegah aksi ganda, QA §5)', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        MiroButton(label: 'Simpan', onPressed: () => taps++, loading: true),
      );
      expect(find.text('SIMPAN'), findsNothing);
      await tester.tap(find.byType(MiroButton));
      expect(taps, 0);
    });

    testWidgets('target sentuh minimal 44', (tester) async {
      await _pump(
        tester,
        MiroButton(
          label: 'Kecil',
          onPressed: () {},
          size: MiroButtonSize.s,
          expand: false,
        ),
      );
      final size = tester.getSize(find.byType(MiroButton));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('Pilihan', () {
    testWidgets('ChoiceCard diumumkan sebagai pilihan terpilih', (
      tester,
    ) async {
      await _pump(
        tester,
        ChoiceCard(
          title: 'Orang Tua',
          icon: PhosphorIconsFill.usersThree,
          selected: true,
          onTap: () {},
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Orang Tua')),
        isSemantics(isSelected: true, label: 'Orang Tua'),
      );
    });

    testWidgets('RadioCard memanggil onTap', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        RadioCard(title: 'Nara', selected: false, onTap: () => tapped = true),
      );
      await tester.tap(find.text('Nara'));
      expect(tapped, isTrue);
    });
  });

  group('Kontrol', () {
    testWidgets('MiroSwitch membalik nilai', (tester) async {
      bool? got;
      await _pump(
        tester,
        MiroSwitch(value: false, label: 'Getar', onChanged: (v) => got = v),
      );
      await tester.tap(find.byType(MiroSwitch));
      expect(got, isTrue);
    });

    testWidgets('MiroStepper tidak melewati batas', (tester) async {
      final values = <int>[];
      await _pump(
        tester,
        MiroStepper(
          value: 1,
          min: 1,
          max: 2,
          decrementLabel: 'Kurangi',
          incrementLabel: 'Tambah',
          onChanged: values.add,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Kurangi'));
      await tester.tap(find.bySemanticsLabel('Tambah'));
      expect(values, [2]); // − di batas bawah diabaikan.
    });

    testWidgets('MiroTextField: error tampil, tombol mata membuka sandi', (
      tester,
    ) async {
      await _pump(
        tester,
        const MiroTextField(
          label: 'Kata sandi',
          obscure: true,
          error: 'Minimal 8 karakter',
        ),
      );
      expect(find.text('Minimal 8 karakter'), findsOneWidget);
      TextField field() => tester.widget<TextField>(find.byType(TextField));
      expect(field().obscureText, isTrue);
      await tester.tap(find.bySemanticsLabel('Tampilkan kata sandi'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });
  });
}
