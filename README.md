# Most

Клиент для подключения к собственным серверам. Пользователь вводит код доступа — приложение
само забирает настройки с сервера подписки и дальше обновляет их без участия человека.

Собирается для Android; iOS — следующим этапом (код общий, Flutter).

---

## Основано на Hiddify

Это форк [hiddify/hiddify-app](https://github.com/hiddify/hiddify-app).
Лицензия — [Hiddify Extended GNU GPL v3](LICENSE.md), она же распространяется на этот форк.
Спасибо команде Hiddify за исходный проект.

Ядро (`hiddify-core`, на базе sing-box) не пересобирается: подтягивается готовым артефактом
из релизов [hiddify/hiddify-core](https://github.com/hiddify/hiddify-core).

## Чем этот форк отличается от апстрима

| Область | Изменение |
|---------|-----------|
| Название и идентификаторы | приложение называется `Most`, `applicationId` — `ru.most.app`, добавлена deep-link схема `most://` |
| Первый запуск | вводный экран апстрима (выбор региона + условия использования) заменён экраном **ввода кода доступа**: код превращается в адрес подписки, профиль добавляется автоматически |
| Телеметрия | Sentry удалён полностью — пакеты, инициализация, обработчики, переключатель в настройках |
| Сторонние конфиги | убран блок «бесплатных» профилей, который загружался с GitHub Hiddify |
| Ссылки | убраны ссылки на сайт, Telegram, условия и политику Hiddify; в «О программе» оставлена ссылка на апстрим (атрибуция) |
| Языки | оставлены русский и английский |
| Платформы | удалены Windows, Linux, macOS, Web (проект только мобильный) |
| Обновления | проверка обновлений отключена до появления собственных релизов |

Функциональность ядра (протоколы, маршрутизация, per-app proxy, WARP, Psiphon) не тронута.

## Сборка

Требуется Flutter **3.38.5**, JDK 17, Android SDK 36 (+ NDK 28.2.13676358).
На Windows нужен включённый режим разработчика — Flutter создаёт симлинки.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run slang
mkdir -p android/app/libs
curl -L https://github.com/hiddify/hiddify-core/releases/download/v4.1.0/hiddify-lib-android.tar.gz | tar xz -C android/app/libs
flutter build apk --release
```

## Сервер подписки

Приложение обращается по адресу `<subscriptionBaseUrl>/sub/<код>` (см. `lib/core/model/constants.dart`)
и ожидает стандартный ответ подписки: base64-список `vless://`-ссылок и заголовки
`Profile-Title`, `Profile-Update-Interval`, `Subscription-Userinfo`.

Серверная часть в этом репозитории не публикуется.
