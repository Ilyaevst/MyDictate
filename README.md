# SuperDictate

Быстрая локальная диктовка для Mac: нажал **правый Command**, сказал текст,
нажал ещё раз — текст появился в активном поле. Аудио и расшифровка не
отправляются в облако.

## Установка

Нужен Mac с Apple Silicon (`M1` или новее) и macOS 14+.

1. Откройте **Terminal**.
2. Вставьте команду и нажмите Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/shlgd/SuperDictate/main/install.sh | bash
```

3. В открывшемся SuperDictate выдайте три разрешения: **Microphone**,
   **Accessibility** и **Input Monitoring**.

При первом запуске приложение один раз скачает локальную модель распознавания
речи (около 600 МБ). После этого интернет для диктовки не нужен.

Если на Mac ещё нет инструментов Apple для сборки, установщик откроет их
стандартную установку. После её окончания запустите ту же команду ещё раз.

## Использование

- **Правый Command** — начать или закончить диктовку.
- **Правый Shift + правый Command** — открыть или закрыть быструю историю.
- **Правый Option + правый Command** — альтернативное завершение; поведение
  Enter настраивается в панели SuperDictate.
- Откройте `SuperDictate` из Applications, чтобы проверить службу, разрешения
  и изменить цвета.

Панель настроек можно полностью закрыть: отдельная фоновая служба продолжит
работать и сама запустится после входа в macOS.

## Что делает установщик

Установщик скачивает этот репозиторий, собирает приложение локально через
официальный Swift toolchain, помещает `SuperDictate.app` в `/Applications` и
открывает его. Код, который выполняется, находится в [install.sh](install.sh)
и [scripts/build-app.sh](scripts/build-app.sh).

Сейчас публичная сборка подписывается локально на вашем Mac. Это позволяет не
обходить Gatekeeper командой `xattr`, но после обновления macOS иногда может
повторно запросить системные разрешения. Полностью нотарифицированная сборка
потребует сертификат Apple Developer ID.

## Приватность

- Распознавание выполняется локально моделью Parakeet TDT через FluidAudio.
- Аудио не загружается на сервер и не хранится после штатной транскрибации.
- История и настройки лежат только в `~/Library/Application Support/SuperDictate`.
- Аналитики, аккаунтов и телеметрии нет.

Подробнее: [PRIVACY.md](PRIVACY.md).

## Сборка вручную

```bash
git clone https://github.com/shlgd/SuperDictate.git
cd SuperDictate
./scripts/build-app.sh ./dist/SuperDictate.app
open ./dist/SuperDictate.app
```

## Удаление

```bash
curl -fsSL https://raw.githubusercontent.com/shlgd/SuperDictate/main/uninstall.sh | bash
```

Локальная история и модель при обычном удалении сохраняются, чтобы их нельзя
было потерять случайно.

## Происхождение и лицензия

SuperDictate основан на открытом проекте
[Parakey](https://github.com/rcourtman/parakey) Richard Courtman. Исходный и
изменённый код распространяется по лицензии MIT. См. [LICENSE](LICENSE) и
[NOTICE.md](NOTICE.md).

