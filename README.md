# MyDictate

Локальная диктовка для Mac с Apple Silicon. Голос распознаётся на самом Mac:
текст и аудио не отправляются в облачный API.

## Использование

Нужны macOS 14+, Mac с M1 или новее и три разрешения macOS:

- Microphone — записывать голос;
- Accessibility — вернуть готовый текст в поле ввода;
- Input Monitoring — видеть глобальную горячую клавишу.

По умолчанию правый `Command` запускает и завершает диктовку без Enter.
`Option + правый Command` завершает запись, вставляет текст и нажимает Enter.
`Shift + правый Command` завершает запись, сохраняет текст в буфер обмена и
ничего не вставляет. После любой успешной диктовки текст остаётся в буфере.
Настройки горячих клавиш доступны через шестерёнку.

В главной панели можно сразу выбрать модель:

- Whisper Small — компактная модель;
- Whisper Medium — баланс скорости и качества;
- Whisper Large V3 Turbo — максимум качества для русской речи и технических слов;
- Parakeet TDT v3 — самый быстрый вариант.

## Сохранённые диктовки и вставка

Перед вставкой каждая успешная расшифровка сохраняется в
`~/Library/Application Support/MyDictate/Saved Dictations/Transcripts`.
Карточка «Сохранённые диктовки» открывает компактный список: можно открыть
полный текст, скопировать его или показать исходный файл в Finder.

В обычных режимах MyDictate вставляет текст в поле, где находится курсор в
момент завершения распознавания. Если поле оказалось не тем, результат можно
сразу вставить из системного буфера обмена или открыть в сохранённых
диктовках.

## Тестовая сборка без установки

```bash
./scripts/build-app.sh ./dist/MyDictate.app
open ./dist/MyDictate.app
```

Не запускайте одновременно тестовую копию из `dist` и установленную копию из
`/Applications`: у них одна фоновая служба и один набор системных разрешений.

## Обновления из GitHub

В приложении есть кнопка обновления. Она проверяет только релизы репозитория
`Ilyaevst/MyDictate`, скачивает `MyDictate-X.Y.Z.zip`, сверяет SHA-256 из
`update.json`, проверяет bundle и подпись, затем заменяет приложение и открывает
его снова. История, настройки и модели остаются на месте.

Чтобы подготовить новый релиз:

```bash
./scripts/prepare-github-release.sh
git add update.json
git commit -m "Release vX.Y.Z"
git push
gh release create vX.Y.Z dist/MyDictate-X.Y.Z.zip --title "MyDictate vX.Y.Z" --generate-notes
```

Репозиторий должен быть публичным: приложение скачивает обновление без
GitHub-аккаунта и без сохранённого токена. Для первой публикации нужен
публичный репозиторий `Ilyaevst/MyDictate` и Release `v1.0.1`.

## Сборка и проверка

```bash
./scripts/check.sh
swift run -c debug --package-path swift Parakey --self-test all
./scripts/build-app.sh ./dist/MyDictate.app
codesign --verify --deep --strict ./dist/MyDictate.app
```

## Данные и удаление

- тексты, журналы, настройки: `~/Library/Application Support/MyDictate`;
- модель: `~/Library/Application Support/FluidAudio/Models`;
- фоновой процесс: `~/Library/LaunchAgents/com.local.mydictate.agent.plist`.

См. также [PRIVACY.md](PRIVACY.md) и [LICENSE](LICENSE).
