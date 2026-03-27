# iPhone Media Importer

macOS icin iPhone baglandiginda fotograf ve videolari tarayip secilen hedef klasore duzenli sekilde aktaran SwiftUI tabanli MVP.

## Teknoloji Secimi

- `Swift + SwiftUI`: Apple ekosistemiyle en uyumlu, modern ve uzun vadede surdurulebilir secim.
- `ImageCaptureCore`: iPhone'u macOS tarafinda resmi olarak medya kaynagi gibi gorup taramak ve indirmek icin uygun framework.
- `OSLog`: dusuk maliyetli ve sistemle uyumlu loglama.
- `MVVM + service layer`: UI, is kurallari ve cihaz erisimini ayirmak icin sade ama gelistirilebilir yapi.

`AppKit` yerine `SwiftUI` secildi cunku bu uygulamanin ihtiyaci agir custom pencere yonetimi degil; hizli gelistirme, net veri akisi ve modern macOS arayuzu. Dosya secici gibi noktalarda gereken yerde `AppKit` koprusu kullaniliyor.

## Gercekci Cihaz Erisim Stratejisi

- USB ile bagli cihazlari `ICDeviceBrowser` ile izleriz.
- Yalnizca `ICCameraDevice` olarak gorunen, `productKind` degeri `iPhone` veya benzeri olan cihazlari kabul ederiz.
- Medya listesini `mediaFiles` uzerinden aliriz.
- Indirme icin `ICCameraFile.requestDownloadWithOptions` kullaniriz.
- Hedef klasor kullanici tarafindan secilir, secim security-scoped bookmark olarak saklanir.

Not: iPhone'a erisim icin kullanicinin cihaz kilidini acmasi ve gerekirse "Trust This Mac" onayini vermesi gerekir. Sandboxed dagitimda kullanici-secili klasor erisimi icin `com.apple.security.files.user-selected.read-write` entitlement'i eklenmelidir.

## Tarih ve Klasorleme Kurali

Tarih belirleme onceligi:

1. `exifCreationDate`
2. `creationDate`
3. `fileCreationDate`
4. `modificationDate`
5. `fileModificationDate`
6. Import zamani

Hedef yol ornegi:

```text
Fotoograflar/2025/03_Mart
Videolar/2025/01_Ocak
```

## MVP Ozeti

- Cihaz otomatik algilanir
- Hedef klasor secilir
- Medya taranir
- Fotograf/video filtrelenir
- Tarihe gore klasorlenir
- Kopyalama ilerlemesi, kalan oge ve tahmini sure gosterilir
- Duraklat, devam ettir, iptal desteklenir
- Ozet rapor ve hata logu uretilir
- Hedef klasorde kalici JSON transfer raporu uretilir
- Son aktarim raporlari uygulama icinde "Gecmis" bolumunde listelenir
- Gecmis bolumu arama, filtreleme ve daha fazla goster akisini destekler
- Demo mod ile gercek cihaz olmadan arayuz akisi test edilebilir

## Klasor Yapisi

```text
Sources/iPhoneMediaImporterApp/
  App/
  Models/
  Services/
  Utilities/
  ViewModels/
  Views/
```

## Xcode ile Calistirma

1. Xcode acin.
2. Bu klasordeki `iPhoneMediaImporter.xcodeproj` dosyasini acin.
3. Sol ustte `iPhoneMediaImporter` shared scheme'ini secin.
4. Run edin. Testler icin Product > Test kullanin.

Not: Projede `Config/Info.plist`, `Config/AppSandbox.entitlements`, `Config/Debug.xcconfig` ve `Config/Release.xcconfig` zaten bagli gelir.
Not: CLI tarafinda `xcodebuild` kullanmak icin tam Xcode kurulu olmali ve aktif developer directory onun uzerine alinmali.

Ornek:

```text
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Release, Signing ve Notarization

Disaridan dagitim icin repo icinde hazir bir release script'i bulunur:

```text
./Scripts/release_build.sh
```

Oncesinde:

1. `Config/SigningOverrides.xcconfig.example` dosyasini `Config/SigningOverrides.xcconfig` olarak kopyalayin.
2. Kendi `DEVELOPMENT_TEAM`, `PRODUCT_BUNDLE_IDENTIFIER` ve imzalama kimligi degerlerinizi girin.
3. Bir notarytool profili olusturun:

```text
xcrun notarytool store-credentials "iPhoneMediaImporterNotary"
```

4. Script'i su degiskenlerle calistirin:

```text
NOTARY_PROFILE=iPhoneMediaImporterNotary \
DEVELOPMENT_TEAM=TEAMID1234 \
PRODUCT_BUNDLE_IDENTIFIER=com.sirketiniz.iPhoneMediaImporter \
./Scripts/release_build.sh
```

Script su adimlari otomatik yapar:

- `Release` archive alir
- `developer-id` export uretir
- `.app` paketini zip'ler
- `notarytool submit --wait` ile notarization gonderir
- `stapler` ile notary ticket'i uygular
- `spctl` ile son dogrulamayi yapar

Daha ayrintili dagitim notlari icin [ReleaseGuide.md](/Users/yuliyanognyanov/Documents/iphoneBackup/Docs/ReleaseGuide.md) dosyasina bakin.

## Demo Mod

Gercek cihaz bagli degilken ekran akislarini test etmek icin run environment variable ekleyin:

```text
IPHONE_IMPORTER_DEMO=1
```

Bu modda ornek medya listesi uretilir ve indirme yerine sahte bir zamanlanmis aktarim calisir.
Xcode icinde bunun icin hazir `iPhoneMediaImporter Demo` shared scheme'i de eklendi.

## Testler

Paket icinde cekirdek is kurallari icin unit testler de bulunur:

```text
swift test
```

Bu ortamda `swift test` komutu yerel toolchain/SDK uyumsuzlugu nedeniyle dogrulanamadi; ancak testler cihaz gerektirmeyen saf servisler icin yazildi.

## Son Eklenenler

- Ayarlar bolumu ile rapor/log kaydi ve aktarim sonrasi klasor acma davranisi yonetilir.
- Gecmis raporlari tek tek silinebilir veya topluca temizlenebilir.
- Gecmis karti arama, filtreleme ve daha fazla goster akisini destekler.
- Gecmis raporlari CSV olarak disa aktarilabilir.
- Secili rapor icin uygulama icinde detay ozeti gosterilir.
- Hedef klasor secimi sifirlanabilir.
- Xcode proje ayarlari test import ve Debug derleme icin biraz daha sertlestirildi.
- Cihaz delegate akisi guclendirildi; kilitli veya guven verilmeyen iPhone durumlari daha net yakalaniyor.
- Release build, Developer ID export ve notarization icin hazir script ve config iskeleti eklendi.

## Resmi Kaynaklar

- Apple ImageCaptureCore genel cerceve: <https://developer.apple.com/documentation/imagecapturecore>
- `ICDeviceBrowser`: <https://developer.apple.com/documentation/imagecapturecore/icdevicebrowser>
- `ICCameraDevice`: <https://developer.apple.com/documentation/imagecapturecore/iccameradevice>
- `ICCameraFile`: <https://developer.apple.com/documentation/imagecapturecore/iccamerafile>
- Security-scoped bookmarklar: <https://developer.apple.com/documentation/foundation/nsurl/bookmarkdata(options:includingresourcevaluesforkeys:relativeto:)>
