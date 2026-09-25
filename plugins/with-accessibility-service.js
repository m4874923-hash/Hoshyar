const { withAndroidManifest, withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const serviceClassName = 'HoshyarAccessibilityService';

function withServiceManifest(config) {
  return withAndroidManifest(config, (modConfig) => {
    const manifest = modConfig.modResults.manifest;
    const application = manifest.application?.[0];
    if (!application) return modConfig;
    const packageName = modConfig.android?.package ?? 'com.hoshyar.app';
    const serviceName = `${packageName}.${serviceClassName}`;
    const services = application.service ?? [];
    const existing = services.find((service) => service.$?.['android:name'] === serviceName);
    if (!existing) {
      services.push({
        $: {
          'android:name': serviceName,
          'android:exported': 'true',
          'android:label': 'Hoshyar accessibility service',
          'android:permission': 'android.permission.BIND_ACCESSIBILITY_SERVICE',
        },
        'intent-filter': [{ action: [{ $: { 'android:name': 'android.accessibilityservice.AccessibilityService' } }] }],
        'meta-data': [{ $: { 'android:name': 'android.accessibilityservice', 'android:resource': '@xml/hoshyar_accessibility_service' } }],
      });
    }
    application.service = services;
    return modConfig;
  });
}

function withServiceSource(config) {
  return withDangerousMod(config, ['android', async (modConfig) => {
    const packageName = modConfig.android?.package ?? 'com.hoshyar.app';
    const packagePath = packageName.split('.').join(path.sep);
    const javaDirectory = path.join(modConfig.modRequest.platformProjectRoot, 'app', 'src', 'main', 'java', packagePath);
    const resourceDirectory = path.join(modConfig.modRequest.platformProjectRoot, 'app', 'src', 'main', 'res', 'xml');
    fs.mkdirSync(javaDirectory, { recursive: true });
    fs.mkdirSync(resourceDirectory, { recursive: true });
    fs.writeFileSync(path.join(javaDirectory, `${serviceClassName}.kt`), `package ${packageName}

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class ${serviceClassName} : AccessibilityService() {
  override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    // Observe-only until the user explicitly enables the service.
  }

  override fun onInterrupt() = Unit
}
`);
    fs.writeFileSync(path.join(resourceDirectory, 'hoshyar_accessibility_service.xml'), '<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android" android:accessibilityEventTypes="typeAllMask" android:accessibilityFeedbackType="feedbackGeneric" android:notificationTimeout="100" android:canRetrieveWindowContent="false" />');
    return modConfig;
  }]);
}

module.exports = function withAccessibilityService(config) {
  return withServiceSource(withServiceManifest(config));
};
