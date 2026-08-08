from pathlib import Path
import os
import re
import shutil

root = Path(__file__).resolve().parents[1]
app_gradle = root / "android" / "app" / "build.gradle.kts"
manifest_source = root / "tool" / "AndroidManifest.template.xml"
manifest_target = root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"

if not app_gradle.exists():
    raise SystemExit("Run `flutter create . --platforms=android` first.")

text = app_gradle.read_text()

if "import java.util.Properties" not in text:
    text = "import java.util.Properties\n\n" + text

text = re.sub(r"compileSdk\s*=\s*flutter\.compileSdkVersion", "compileSdk = 36", text)
text = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24", text)

if "multiDexEnabled = true" not in text:
    text = text.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled = true", 1)

if "isCoreLibraryDesugaringEnabled = true" not in text:
    replacement = """compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }"""
    text = re.sub(r"compileOptions\s*\{.*?\}", replacement, text, flags=re.S)

if "coreLibraryDesugaring(\"com.android.tools:desugar_jdk_libs:2.1.4\")" not in text:
    if "dependencies {" in text:
        text = text.replace(
            "dependencies {",
            'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")',
            1,
        )
    else:
        text += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'

# Flutter's generated release build uses the debug signing key. Keep that as a
# local fallback, but use a protected properties file for permanent release
# signing so passwords never need to persist in the CI job environment.
if 'create("skinflowRelease")' not in text:
    signing_block = """signingConfigs {
        val skinflowSigningPropertiesPath = System.getenv("SKINFLOW_SIGNING_PROPERTIES_PATH")
        if (!skinflowSigningPropertiesPath.isNullOrBlank()) {
            val skinflowSigningProperties = Properties().apply {
                file(skinflowSigningPropertiesPath).inputStream().use { input ->
                    load(input)
                }
            }
            create("skinflowRelease") {
                storeFile = file(skinflowSigningProperties.getProperty("storeFile"))
                storePassword = skinflowSigningProperties.getProperty("storePassword")
                keyAlias = skinflowSigningProperties.getProperty("keyAlias")
                keyPassword = skinflowSigningProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {"""
    text = text.replace("buildTypes {", signing_block, 1)

release_signing = """signingConfig = if (System.getenv("SKINFLOW_SIGNING_PROPERTIES_PATH").isNullOrBlank()) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("skinflowRelease")
            }"""
text = text.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    release_signing,
    1,
)

app_gradle.write_text(text)
manifest_target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(manifest_source, manifest_target)
print(f"Patched {app_gradle}")
print(f"Installed {manifest_target}")
if os.getenv("SKINFLOW_SIGNING_PROPERTIES_PATH"):
    print("SkinFlow permanent release signing enabled")
else:
    print("SkinFlow permanent release signing not configured; using local fallback key")
