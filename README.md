# BIST Hisse Takip Uygulaması

Bu uygulama, Borsa İstanbul (BIST) verilerini çeken, MongoDB veritabanında saklayan ve hisse senetlerinin grafiklerini gösteren bir Ruby Sinatra web uygulamasıdır. Yükselen ve düşen hisseleri takip edebilir, teknik analiz grafiklerini görüntüleyebilirsiniz.

## Özellikler

- BIST hisse verilerini otomatik olarak çekme
- MongoDB veritabanında veri saklama
- Hisse fiyat grafikleri
- Yükselen ve düşen hisseleri listeleme
- Destek ve direnç seviyeleri
- Hareketli ortalamalar
- Yükselen ve düşen kanal analizleri

## Gereksinimler

- Ruby 2.7 veya üzeri
- MongoDB 4.0 veya üzeri
- Bundler gem'i

## Kurulum

1. Repoyu klonlayın:

```bash
git clone https://github.com/kullanici/bist-hisse-takip.git
cd bist-hisse-takip
```

2. Gerekli gem'leri yükleyin:

```bash
bundle install
```

3. MongoDB'nin çalıştığından emin olun:

```bash
# MongoDB'yi başlatmak için (macOS)
brew services start mongodb-community

# veya Linux için
sudo systemctl start mongod
```

4. Uygulamayı başlatın:

```bash
ruby app.rb
```

5. Tarayıcınızda `http://localhost:4567` adresine gidin.

## Kullanım

- Ana sayfa: Tüm hisselerin genel görünümü
- Yükselenler: Değer kazanan hisselerin listesi ve grafiği
- Düşenler: Değer kaybeden hisselerin listesi ve grafiği
- Hisse Detayı: Belirli bir hissenin detaylı analizi ve grafikleri
- Verileri Güncelle: BIST verilerini manuel olarak güncelleme

## Veri Kaynağı

Uygulama, Borsa İstanbul verilerini KAP (Kamuyu Aydınlatma Platformu) web sitesinden çekmektedir. Veriler 15 dakika gecikmeli olabilir ve yalnızca bilgi amaçlıdır.

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen bir pull request göndermeden önce bir issue açın.

## İletişim

Sorularınız veya önerileriniz için bir issue açabilir veya e-posta gönderebilirsiniz.