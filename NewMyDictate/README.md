# New MyDictate

Полностью отдельная экспериментальная версия MyDictate.

## Изоляция

- bundle ID: `com.local.newmydictate.dev`;
- настройки: отдельный домен `UserDefaults`;
- данные: `~/Library/Application Support/New MyDictate Dev`;
- приложение: `NewMyDictate/dist/New MyDictate.app`;
- текущий MyDictate и его папка `MyDictate Content` не читаются и не изменяются.

## Сборка и запуск

```bash
./NewMyDictate/build-app.sh
open "NewMyDictate/dist/New MyDictate.app"
```

Первая версия является нативной продуктовой оболочкой: обзор, история, словарь,
режимы, настройки, onboarding, светлая/тёмная темы и плеер истории. Подключение
рабочего движка диктовки выполняется отдельным следующим этапом после утверждения
интерфейса.
