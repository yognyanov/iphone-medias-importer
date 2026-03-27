# Mimari ve Teknik Kararlar

## 1. Teknoloji Secimi

Bu proje icin en uygun secim `Swift + SwiftUI` oldu.

Gerekceler:

- macOS ile birinci sinif uyum saglar.
- `ImageCaptureCore` ve `AppKit` kopruleriyle resmi Apple cihaz erisim modeline rahat baglanir.
- `ObservableObject` ve `@Published` ile MVVM akisi sade kalir.
- Uzun vadede `AppKit` kadar guclu ama MVP icin daha hizli gelistirme sunar.

`AppKit` tamamen terk edilmedi. Dosya secici gibi macOS'e ozgu alanlarda hedefli olarak kullanildi.

## 2. Proje Mimarisi

Katmanlar:

- `Views`: SwiftUI ekranlari
- `ViewModels`: ekran durumu ve kullanici aksiyonlari
- `Services`: cihaz algilama, tarama, planlama, kopyalama, loglama
- `Models`: UI ve is akisinin veri modelleri
- `Utilities`: formatlama yardimcilari

Akis:

1. `DeviceBrowserService` iPhone'u algilar.
2. `MediaScannerService` cihaz oturumu acar ve `mediaFiles` listesini okur.
3. `MediaDateResolver` ve `MediaTypeResolver` medya kayitlarini normalize eder.
4. `ImportPlanner` yil/ay klasor yapisini ve duplicate stratejisini uygular.
5. `TransferCoordinator` asenkron indirme islemini yurutur.
6. `AppViewModel` UI durumunu anlik gunceller.

## 3. Klasorleme ve Tarih Bazli Ayirma Algoritmasi

Tarih onceligi:

1. `exifCreationDate`
2. `creationDate`
3. `fileCreationDate`
4. `modificationDate`
5. `fileModificationDate`
6. import zamani

Yol olusturma:

1. Medya turunu uzantidan belirle.
2. Ana klasoru sec:
   `Fotograflar` veya `Videolar`
3. Tarihten yil ve ayi al.
4. Ay klasorunu `01_Ocak`, `02_Subat` formatinda olustur.
5. Son yolu `AnaKlasor/Yil/Ay` seklinde kur.

Duplicate stratejisi:

- Once hedefte ayni isimli dosya var mi bak.
- Varsa isim, boyut ve tarih esitligini kontrol et.
- Hedef klasorde `.iphone-media-importer-manifest.json` ile onceki import imzalari saklanir.
- Kaynak fingerprint varsa oncelikle onu kullan.
- Gercek duplicate ise atla.
- Sadece isim cakismasi varsa `_1`, `_2` gibi guvenli yeniden adlandirma uygula.

## 4. iPhone Algilama ve Medya Erisim Stratejisi

Secilen gercekci strateji `ImageCaptureCore` tabanlidir.

Neden:

- Apple'in resmi medya cihaz erisim modelidir.
- iPhone, macOS tarafinda medya kaynagi gibi gorundugunde bu framework ile kataloglanabilir.
- `ICDeviceBrowser` USB cihazlarini izler.
- `ICCameraDevice` cihaz oturumu acmayi saglar.
- `ICCameraFile` metadata ve indirme API'lerini sunar.

Sinirlar:

- Uygulama iPhone dosya sistemine genel amacli erisim beklememelidir.
- Erisim medya import modeliyle sinirlidir.
- Kullanici cihaz kilidini acmali ve guven onayini vermelidir.

## 5. UI Ekran Plani

Ana ekran:

- cihaz durumu
- hedef klasor secimi
- aktarim gecmisi
- tara butonu
- kopyalamayi baslat butonu

Tarama sonrasi:

- toplam fotograf
- toplam video
- toplam boyut
- hedef klasor ozeti

Kopyalama:

- ilerleme cubugu
- anlik dosya
- kopyalanan sayi
- kalan sayi
- tahmini kalan sure
- duraklat/devam et/iptal

Tamamlandi:

- toplam kopyalanan veri
- fotograf sayisi
- video sayisi
- atlanan sayi
- hata sayisi
- toplam sure
- hata logunu ac
- hedef klasoru ac

Gecmis:

- son transfer raporlarini listeler
- cihaz/hedef klasor bazli arama sunar
- tamamlanan ve iptal edilen aktarimlari filtreler
- tekil rapor silme ve toplu temizleme sunar

Ayarlar:

- aktarim bitince hedef klasoru otomatik acma
- JSON rapor kaydini acma/kapatma
- hata logu kaydini acma/kapatma
- gecmis kartinin baslangic gorunum sayisi

## 6. Ornek Proje Klasor Yapisi

```text
iPhoneMediaImporter/
  Package.swift
  README.md
  Docs/
    Architecture.md
  Sources/
    iPhoneMediaImporterApp/
      App/
      Models/
      Services/
      Utilities/
      ViewModels/
      Views/
```

## 7. MVP Sinirlari

Bu ilk surum su alanlara odaklandi:

- tek cihaz algilama
- medya tarama
- filtreleme
- hedef klasor secimi
- tarih bazli ayirma
- duplicate onleme icin temel metadata kontrolu
- kalici manifest ile tekrar import onleme
- asenkron kopyalama
- ilerleme ve ozet rapor
- demo mod ile cihazsiz UI testi

Sonraki adimlarda eklenebilir:

- gercek fingerprint/hash tabanli indeks veritabani
- yeniden baslatilabilir import gecmisi
- daha gelismis cihaz durum mesajlari
- otomatik silme icin ayri ve ekstra guvenli bir akıs

## 8. Hata Yonetimi ve Loglama

- Kullaniciya kisa ve net hata mesaji gosterilir.
- Sistem olaylari `OSLog` ile loglanir.
- Dosya bazli hatalar `TransferErrorRecord` olarak toplanir.
- Islem sonunda hata varsa JSON log dosyasi uretilir.
- Her aktarim sonunda hedef klasorde kalici bir JSON transfer raporu uretilir.
- Cihaz baglantisi kopyalama sirasinda koparsa islem iptal edilir ve kullaniciya net uyari verilir.

## 9. Sandbox ve Izin Modeli

- Hedef klasor mutlaka kullanici tarafindan secilir.
- Bu secim security-scoped bookmark olarak saklanir.
- Sandboxed dagitimda `user-selected read/write` entitlement'i gerekir.
- iPhone erisimi icin ayri bir dosya sistemi izni yerine cihaz guven/onay akisi belirleyicidir.
