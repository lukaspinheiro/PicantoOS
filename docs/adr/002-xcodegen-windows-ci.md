# ADR-002: XcodeGen + GitHub Actions (`macos-latest`) for Windows Development

- **Status:** Accepted
- **Context:** Primary development happens on Windows without a local Mac. Manually editing Xcode `.pbxproj` files on Windows is error-prone and hard to maintain.
- **Decision:** Define the iOS app in `ios/project.yml` using **XcodeGen**, isolate OBD-II logic in a pure Swift Package (`PicantoOBDKit`), and generate/build the `.xcodeproj` in GitHub Actions (`macos-latest`).
- **Consequences:** Clean, diffable iOS project configuration and automated Swift unit tests + iOS Simulator builds on every push.
