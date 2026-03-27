# Release Runbook

This runbook documents the current Tryzeon mobile release flow for iOS and Android.

## Overview

The release process is split into two phases:

- `beta`: build a release binary and upload it to the testing channel
- `release`: promote an already-validated testing build to the production channel

Current triggers:

- iOS beta: GitHub Actions `Beta Build - iOS`
- Android beta: GitHub Actions `Beta Build - Android`
- iOS release: push a git tag like `v1.2.0`
- Android release: push a git tag like `v1.2.0`

Versioning rules:

- Beta workflows take a semantic version like `1.2.0`
- Release workflows read the version from the git tag `vX.Y.Z`
- Beta builds auto-increment build numbers
- Release workflows do not create new binaries; they promote existing builds

## Beta Flow

### iOS beta

Workflow: `.github/workflows/beta_ios.yml`

Trigger:

- Run the workflow manually from GitHub Actions
- Enter `version`, for example `1.2.0`
- Or run `scripts/release-beta.sh 1.2.0 --ios`

Behavior:

- Builds an App Store distribution binary
- Uses the next TestFlight build number for that App Store Connect app
- Uploads the build to TestFlight
- Generates beta release notes from recent git commit subjects

Fastlane lane:

- `ios/fastlane/Fastfile` -> `beta`

### Android beta

Workflow: `.github/workflows/beta_android.yml`

Trigger:

- Run the workflow manually from GitHub Actions
- Enter `version`, for example `1.2.0`
- Or run `scripts/release-beta.sh 1.2.0 --android`

Behavior:

- Builds a release AAB
- Uses the next global Play Store `versionCode`
- Uploads the build to the `internal` testing track
- Generates Play internal release notes from recent git commit subjects

Fastlane lane:

- `android/fastlane/Fastfile` -> `beta`

## Release Flow

### iOS release

Workflow: `.github/workflows/release_ios.yml`

Trigger:

- Push a tag like `v1.2.0`

Behavior:

- Reads `1.2.0` from the tag
- Looks up the latest TestFlight build for version `1.2.0`
- Promotes that existing build to the App Store release flow
- Submits the build for review and enables automatic release after approval

Fastlane lane:

- `ios/fastlane/Fastfile` -> `release`

Important:

- The release workflow does not build a new binary
- The latest TestFlight build for the tagged version must already exist

### Android release

Workflow: `.github/workflows/release_android.yml`

Trigger:

- Push a tag like `v1.2.0`

Behavior:

- Reads `1.2.0` from the tag
- Checks the `internal` track release name
- Fails if there is no internal candidate
- Fails if there are multiple internal candidates
- Fails if the internal candidate version does not match the tag version
- Promotes the existing `internal` release to `production`

Fastlane lane:

- `android/fastlane/Fastfile` -> `release`

Important:

- The release workflow does not build a new AAB
- The `internal` track should contain only the candidate intended for production

## Operating Procedure

### Prepare a beta build

1. Decide the version number for the current release train, for example `1.2.0`.
2. Run `Beta Build - iOS` and enter `1.2.0`.
3. Run `Beta Build - Android` and enter `1.2.0`.
   You can also trigger both with:

```bash
scripts/release-beta.sh 1.2.0
```

4. Wait for TestFlight and Play internal uploads to complete.
5. Validate both builds.

### Promote to production

1. Confirm the validated iOS and Android candidates both belong to the intended version, for example `1.2.0`.
2. Ensure the Android `internal` track contains only that candidate release.
3. Push a release tag:

```bash
git tag v1.2.0
git push origin v1.2.0
```

4. Wait for the iOS and Android release workflows to finish.

## Failure Modes

### iOS release fails because no TestFlight build exists

Cause:

- No uploaded TestFlight build exists for the tagged version

Fix:

- Run the iOS beta workflow for that same version first

### Android release fails because version does not match the tag

Cause:

- The `internal` track candidate is not the same version as the tag

Fix:

- Upload the correct Android beta build for the tagged version
- Remove or replace stale internal candidates if needed

### Android release fails because multiple internal candidates exist

Cause:

- More than one active release name is visible in the `internal` track

Fix:

- Keep only one production candidate in the `internal` track before tagging

## Conventions

- Use semantic versions for release trains: `1.2.0`, `1.2.1`, `1.3.0`
- Use tags in the format `vX.Y.Z`
- Do not tag a release before both platform beta builds are validated
- Do not upload new beta builds for the same version after deciding which build will be promoted

## Files

- `.github/workflows/beta_ios.yml`
- `.github/workflows/beta_android.yml`
- `.github/workflows/release_ios.yml`
- `.github/workflows/release_android.yml`
- `ios/fastlane/Fastfile`
- `android/fastlane/Fastfile`
- `scripts/release-beta.sh`
