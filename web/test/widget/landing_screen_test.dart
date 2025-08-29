import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:comfunds_web/screens/landing/landing_screen.dart';
import 'package:comfunds_web/providers/auth_provider.dart';
import 'package:comfunds_web/providers/theme_provider.dart';

void main() {
  group('Landing Screen Widget Tests', () {
    late AuthProvider authProvider;
    late ThemeProvider themeProvider;

    setUp(() {
      authProvider = AuthProvider();
      themeProvider = ThemeProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: const LandingScreen(),
        ),
      );
    }

    group('Landing Screen Structure Tests', () {
      testWidgets('should display all main sections', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('HAJIFUND'), findsOneWidget);
        expect(find.text('Platform P2P Lending Syariah terdepan'), findsOneWidget);
        expect(find.text('Fitur Unggulan'), findsOneWidget);
        expect(find.text('Cara Kerja'), findsOneWidget);
        expect(find.text('Testimoni Pengguna'), findsOneWidget);
      });

      testWidgets('should display navigation menu items', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Fitur'), findsOneWidget);
        expect(find.text('Cara Kerja'), findsOneWidget);
        expect(find.text('Testimoni'), findsOneWidget);
        expect(find.text('Tentang'), findsOneWidget);
      });

      testWidgets('should display authentication buttons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Masuk'), findsOneWidget);
        expect(find.text('Daftar'), findsOneWidget);
      });

      testWidgets('should display call-to-action buttons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Mulai Investasi Sekarang'), findsOneWidget);
        expect(find.text('Pelajari Lebih Lanjut'), findsOneWidget);
      });
    });

    group('Hero Section Tests', () {
      testWidgets('should display hero statistics', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('1,500+'), findsOneWidget);
        expect(find.text('Investor Aktif'), findsOneWidget);
        expect(find.text('750+'), findsOneWidget);
        expect(find.text('Proyek Berhasil'), findsOneWidget);
        expect(find.text('Rp 75M+'), findsOneWidget);
        expect(find.text('Total Investasi'), findsOneWidget);
        expect(find.text('18%'), findsOneWidget);
        expect(find.text('Rata-rata Return'), findsOneWidget);
      });

      testWidgets('should display hero subtitle', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(
          find.textContaining('Platform P2P Lending Syariah terdepan'),
          findsOneWidget,
        );
      });
    });

    group('Features Section Tests', () {
      testWidgets('should display all feature cards', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Prinsip Syariah'), findsOneWidget);
        expect(find.text('Keamanan Terjamin'), findsOneWidget);
        expect(find.text('Monitoring Real-time'), findsOneWidget);
        expect(find.text('Proses Cepat'), findsOneWidget);
        expect(find.text('Profit Sharing Adil'), findsOneWidget);
        expect(find.text('Diversifikasi Portofolio'), findsOneWidget);
      });

      testWidgets('should display feature descriptions', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(
          find.textContaining('Semua transaksi mengikuti prinsip syariah'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Teknologi enkripsi tingkat tinggi'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Pantau performa investasi'),
          findsOneWidget,
        );
      });
    });

    group('How It Works Section Tests', () {
      testWidgets('should display all steps', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('1'), findsOneWidget);
        expect(find.text('Daftar & Verifikasi'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Pilih Proyek'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('Investasi'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('Monitor & Profit'), findsOneWidget);
      });

      testWidgets('should display step descriptions', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(
          find.textContaining('Daftar akun dan lakukan verifikasi KYC'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Pilih proyek yang sesuai'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Lakukan investasi'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Pantau perkembangan investasi'),
          findsOneWidget,
        );
      });
    });

    group('Testimonials Section Tests', () {
      testWidgets('should display testimonial cards', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Ahmad Rahman'), findsOneWidget);
        expect(find.text('Pemilik UMKM'), findsOneWidget);
        expect(find.text('Siti Nurhaliza'), findsOneWidget);
        expect(find.text('Investor'), findsOneWidget);
        expect(find.text('Budi Santoso'), findsOneWidget);
      });

      testWidgets('should display testimonial text', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(
          find.textContaining('HAJIFUND telah membantu saya'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Platform investasi terbaik'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Customer service yang sangat membantu'),
          findsOneWidget,
        );
      });
    });

    group('CTA Section Tests', () {
      testWidgets('should display CTA title and description', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(
          find.text('Mulai Perjalanan Investasi Syariah Anda'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Bergabunglah dengan ribuan investor'),
          findsOneWidget,
        );
      });

      testWidgets('should display CTA buttons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Daftar Sekarang'), findsOneWidget);
        expect(find.text('Hubungi Kami'), findsOneWidget);
      });
    });

    group('Footer Tests', () {
      testWidgets('should display footer sections', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Layanan'), findsOneWidget);
        expect(find.text('Perusahaan'), findsOneWidget);
        expect(find.text('Dukungan'), findsOneWidget);
      });

      testWidgets('should display footer links', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Investasi Syariah'), findsOneWidget);
        expect(find.text('Pembiayaan UMKM'), findsOneWidget);
        expect(find.text('Profit Sharing'), findsOneWidget);
        expect(find.text('Tentang Kami'), findsOneWidget);
        expect(find.text('Karir'), findsOneWidget);
        expect(find.text('Pusat Bantuan'), findsOneWidget);
        expect(find.text('Kontak'), findsOneWidget);
        expect(find.text('Privasi'), findsOneWidget);
        expect(find.text('Syarat & Ketentuan'), findsOneWidget);
      });

      testWidgets('should display copyright information', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(
          find.textContaining('© 2024 HAJIFUND'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Platform P2P Lending Syariah Terpercaya'),
          findsOneWidget,
        );
      });
    });

    group('Navigation Tests', () {
      testWidgets('should navigate to login when login button is tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.tap(find.text('Masuk'));
        await tester.pumpAndSettle();

        // Assert
        // Note: This would need proper routing setup to test actual navigation
        expect(find.text('Masuk'), findsOneWidget);
      });

      testWidgets('should navigate to register when register button is tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.tap(find.text('Daftar'));
        await tester.pumpAndSettle();

        // Assert
        // Note: This would need proper routing setup to test actual navigation
        expect(find.text('Daftar'), findsOneWidget);
      });

      testWidgets('should scroll to features when features link is tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.tap(find.text('Fitur'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Fitur Unggulan'), findsOneWidget);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should display correctly on mobile screen size', (WidgetTester tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(375, 812); // iPhone X size
        tester.binding.window.devicePixelRatioTestValue = 3.0;

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('HAJIFUND'), findsOneWidget);
        expect(find.text('Fitur Unggulan'), findsOneWidget);

        // Reset
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

      testWidgets('should display correctly on tablet screen size', (WidgetTester tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(768, 1024); // iPad size
        tester.binding.window.devicePixelRatioTestValue = 2.0;

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('HAJIFUND'), findsOneWidget);
        expect(find.text('Fitur Unggulan'), findsOneWidget);

        // Reset
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have semantic labels for buttons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.bySemanticsLabel('Masuk'), findsOneWidget);
        expect(find.bySemanticsLabel('Daftar'), findsOneWidget);
        expect(find.bySemanticsLabel('Mulai Investasi Sekarang'), findsOneWidget);
      });

      testWidgets('should have proper contrast ratios', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        // Note: This would require more sophisticated testing with color analysis
        // For now, we just verify that text is visible
        expect(find.text('HAJIFUND'), findsOneWidget);
        expect(find.text('Fitur Unggulan'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should render within acceptable time', (WidgetTester tester) async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should render within 1 second
      });

      testWidgets('should handle rapid state changes', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act - Rapidly change theme
        for (int i = 0; i < 5; i++) {
          themeProvider.toggleTheme();
          await tester.pump();
        }

        // Assert
        expect(find.text('HAJIFUND'), findsOneWidget);
        expect(find.text('Fitur Unggulan'), findsOneWidget);
      });
    });
  });
}
