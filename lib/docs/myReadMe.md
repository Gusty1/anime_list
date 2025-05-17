# 我的說明

首次創建專案記得先去android studio開啟android目錄，讓他跑gradle，要一段時間
如果要發佈到play商店專案名稱不要用`com.example`  
上傳google play他會建議需要有一個zip，就把`D:\GitHub\anime_list\build\app\intermediates\merged_native_libs\release\mergeReleaseNativeLibs\out\lib`這邊的檔案把打包成`symbols.zip`即可

## keystore

由於keystore要自己保管，紀錄一下某些重要資訊，打包記得放到對應的目錄

- password: abc...
- alias: al

## 匯出APK

有點麻煩，請看[官方文件](https://docs.flutter.dev/deployment/android '官方文件')，網路上很多都是舊的，都不能用
因為我的專案debug和release都一樣，所以我只設定release

```terminal
flutter build apk --release
flutter build aab --release
```

`AndroidManifest.xml`也有一些設定要改，尤其是網路的定，要注意一下

build.gradle.kts範例，由於網路都是錯的，所以紀錄一下

```kts
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.gusty.anime_list"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.gusty.anime_list"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            ndk {
                debugSymbolLevel =  "SYMBOL_TABLE"
            }
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

```

## 特殊指令

- flutter pub cache repair: 有時候找不到問題可以試試

有些工具需要用到指令，也都要在`pubspec.yaml`做設定

- flutter_native_splash: 設定應用程式啟動時的原生閃屏

  ```terminal
  flutter pub run flutter_native_splash:create
  ```

- flutter_launcher_icons: 設定應用程式在手機桌面上顯示的啟動圖標

  ```terminal
  flutter pub run flutter_launcher_icons
  ```
