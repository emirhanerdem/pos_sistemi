import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    (
      'NFC ile ödeme nasıl alınır?',
      'Cüzdanım ekranından Hızlı Ödeme\'yi seçin, müşterinizin kartını '
          'telefonunuzun arka kısmına yaklaştırın. Cihazınız NFC '
          'desteklemiyorsa "Elle Girin" seçeneğiyle kart bilgilerini manuel '
          'girebilirsiniz.',
    ),
    (
      'Bir işlemi nasıl iptal ederim?',
      'İşlem Detayları ekranında ilgili işlemi sola kaydırın ya da işleme '
          'dokunup detay sayfasındaki "İptal Et" butonunu kullanın.',
    ),
    (
      'İade talebi ne kadar sürede sonuçlanır?',
      'İade talepleri banka POS altyapınıza bağlı olarak genellikle 1-3 iş '
          'günü içinde işleme alınır.',
    ),
    (
      'Şifremi unuttum, ne yapmalıyım?',
      'Giriş ekranındaki "Şifremi Unuttum" bağlantısına dokunup kayıtlı '
          'e-posta adresinizi girerek sıfırlama talebinde bulunabilirsiniz.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Yardım')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Sıkça Sorulan Sorular',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._faq.map(
            (item) => Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.support_agent, color: context.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sorununuz çözülmediyse destek@zanhapay.com adresinden '
                    'bize ulaşabilirsiniz.',
                    style: TextStyle(color: palette.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
