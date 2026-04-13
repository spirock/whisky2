# Whisky 2

> Fork de Whisky con builds automatizados de Wine para macOS

## Acerca de

Whisky 2 es un fork de [Whisky](https://github.com/IsaacMarovitz/Whisky) que descarga Wine automáticamente desde [wine-macos-automated](https://github.com/spirock/wine-macos-automated).

## Características

- **Wine automatizado**: Descarga builds semanales con parches de Proton automáticamente
- **Apple Silicon**: Soporte para Mac con chips M1/M2/M3
- **Game Porting Toolkit**: Compatible con la instalación manual de GPTK
- **Actualizaciones automáticas**: Descarga Wine actualizado desde releases

## Descarga e Instalación

1. Descarga la última release desde la [página de releases](../../releases)
2. Extrae el archivo `.app`
3. Copia a tu carpeta de Aplicaciones
4. Al abrir la app, Wine se descargará automáticamente

## Game Porting Toolkit

Este proyecto **no incluye** Apple Game Porting Toolkit debido a restricciones de licencia.

Para usar D3DMetal:

1. Descarga Game Porting Toolkit de [Apple Developer](https://developer.apple.com/games/game-porting-toolkit/)
2. Monta el DMG
3. Copia `D3DMetal.framework` a tu carpeta de Whisky:
```bash
cp -r "/Volumes/Game Porting Toolkit/D3DMetal.framework" ~/Library/Application\ Support/com.isaacmarovitz.Whisky/Libraries/
```

## Builds de Wine

Los builds de Wine se generan automáticamente en [wine-macos-automated](https://github.com/spirock/wine-macos-automated) mediante GitHub Actions cada semana.

| Build | Descripción | Arquitectura |
|-------|-------------|--------------|
| wine-proton-x86_64 | Proton patches | Intel |
| wine-proton-arm64 | Proton patches | Apple Silicon |

## Compilación

```bash
xcodebuild -project Whisky.xcodeproj -scheme Whisky -configuration Release build
```

## Requisitos

- macOS 14.0 (Sonoma) o posterior
- Xcode 15+

## Licencia

- **Whisky App**: [GPL v3](LICENSE) (heredado de Whisky)
- **Wine**: [LGPL 2.1](https://www.winehq.org/site/legal)
- **Proton patches**: [BSD-3-Clause](https://github.com/ValveSoftware/Proton/blob/ge_proton/LICENSE)

## Créditos

- [Whisky](https://github.com/IsaacMarovitz/Whisky) - Proyecto original
- [Wine Project](https://www.winehq.org/) - Implementación core de Wine
- [Valve Software](https://github.com/ValveSoftware/Proton) - Parches de Proton
- [GloriousEggroll](https://github.com/GloriousEggroll/proton-ge-custom) - GE-Proton

## Soporte

Para soporte técnico y consultoría, contacta a través de:
- [Patreon](https://patreon.com/whisky2)
- [Ko-fi](https://ko-fi.com/whisky2)
