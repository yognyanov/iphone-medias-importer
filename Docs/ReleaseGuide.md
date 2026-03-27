# Release Guide

Bu proje Xcode icinde dogrudan calisir; dis dagitim icin ise `Developer ID Application` imzasi ve notarization gerekir.

## Hazirlik

1. `Config/SigningOverrides.xcconfig.example` dosyasini `Config/SigningOverrides.xcconfig` olarak kopyalayin.
2. Kendi bundle identifier ve Team ID degerlerinizi yazin.
3. Xcode icinde ayni Apple Developer hesabiyla oturum acin.
4. Keychain icinde bir `notarytool` profili saklayin:

```text
xcrun notarytool store-credentials "iPhoneMediaImporterNotary"
```

## Otomatik Release Akisi

Repo icindeki script:

```text
./Scripts/release_build.sh
```

Beklenen environment degiskenleri:

- `NOTARY_PROFILE`
- `DEVELOPMENT_TEAM`
- `PRODUCT_BUNDLE_IDENTIFIER`

Opsiyonel degiskenler:

- `SCHEME`
- `ARCHIVE_PATH`
- `EXPORT_PATH`
- `SKIP_NOTARIZATION=1`

## Uretilen Ciktilar

Script varsayilan olarak su klasoru doldurur:

```text
build/release/
```

Burada sunlar olusur:

- `.xcarchive`
- export edilmis `.app`
- notarization icin `.zip`

## Canli Cihaz Dagrim Notlari

- Uygulama sandbox icinde hedef klasor icin user-selected read/write yetkisi kullanir.
- iPhone erisimi icin kullanici cihaz kilidini acmali ve gerekirse `Bu Mac'e Guven` onayi vermelidir.
- Kilitli veya erisim kisitli Apple cihazlari uygulama icinde net hata durumu olarak gosterilir.

