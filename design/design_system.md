---
name: "Kovetz — Web Design System"
description: "Calm, warm, offline-first web design system for the Kovetz (Kovetz) JW Library backup merger and note exporter."
---

## Overview

Kovetz (Kovetz) — независимый, бесплатный и спокойный инструмент для тех, кто изучает Библию с приложением JW Library на нескольких устройствах. Веб-сайт и документация передают ощущение тихого рабочего стола: тёплые каменные нейтральные оттенки, много воздуха, скруглённые карточки (16px–24px) и один глубокий лесной зелёный акцент (`#376754`). Дизайн одинаково понятен пожилым пользователям (крупный читаемый шрифт, чёткий контраст, пошаговые иллюстрации) и продвинутым пользователям Obsidian. Поддерживаются светлая и тёмная темы без резкого чисто-белого или чисто-чёрного фона.

## Colors

Палитра строится на одном глубоком зелёном цвете (`#376754`) в паре с тёплыми каменными нейтралями (`#F7F7F3` в светлой теме, `#121513` в тёмной). Статусные оттенки (`success`, `warning`, `error`) используются строго для обратной связи, предупреждений и статусов.

```yaml
colors:
  brand-green: "#376754"
  success: "#2E6F4E"
  on-success: "#FFFFFF"
  success-container: "#D3EFE0"
  on-success-container: "#0E3B25"
  warning: "#8C5A1B"
  on-warning: "#FFFFFF"
  warning-container: "#F7E5CC"
  on-warning-container: "#472A06"
  light:
    primary: "#376754"
    on-primary: "#FFFFFF"
    primary-container: "#D3E7DC"
    on-primary-container: "#112E22"
    secondary: "#506259"
    on-secondary: "#FFFFFF"
    secondary-container: "#E1F6EA"
    on-secondary-container: "#1E332A"
    tertiary: "#693837"
    on-tertiary: "#FFFFFF"
    tertiary-container: "#FFEDEB"
    on-tertiary-container: "#350F0F"
    error: "#BA1A1A"
    on-error: "#FFFFFF"
    error-container: "#FFDAD6"
    on-error-container: "#410002"
    background: "#F7F7F3"
    on-background: "#191C1B"
    surface: "#F7F7F3"
    surface-dim: "#E2E3DE"
    surface-bright: "#FCFDF9"
    surface-container-lowest: "#FFFFFF"
    surface-container-low: "#F1F2ED"
    surface-container: "#EBECE7"
    surface-container-high: "#E4E6E0"
    surface-container-highest: "#DDDFD9"
    on-surface: "#191C1B"
    surface-variant: "#DCE5DE"
    on-surface-variant: "#454D48"
    outline: "#717974"
    outline-variant: "#C8D0CA"
    inverse-surface: "#2E312F"
    inverse-on-surface: "#F0F1EE"
    inverse-primary: "#9FD1BA"
  dark:
    primary: "#9FD1BA"
    on-primary: "#003828"
    primary-container: "#1E4F3D"
    on-primary-container: "#C8FCE3"
    secondary: "#B7CBC0"
    on-secondary: "#22342C"
    secondary-container: "#384B42"
    on-secondary-container: "#E1F6EA"
    tertiary: "#FBB5B2"
    on-tertiary: "#4F2322"
    tertiary-container: "#6A3937"
    on-tertiary-container: "#FFEDEB"
    error: "#FFB4AB"
    on-error: "#690005"
    error-container: "#93000A"
    on-error-container: "#FFDAD6"
    background: "#121513"
    on-background: "#E4E6E2"
    surface: "#121513"
    surface-dim: "#0E110F"
    surface-bright: "#343835"
    surface-container-lowest: "#0C0F0D"
    surface-container-low: "#191D1A"
    surface-container: "#1F2421"
    surface-container-high: "#292E2B"
    surface-container-highest: "#333835"
    on-surface: "#E4E6E2"
    surface-variant: "#3B443F"
    on-surface-variant: "#BFC8C2"
    outline: "#8A938D"
    outline-variant: "#3D4640"
    inverse-surface: "#E4E6E2"
    inverse-on-surface: "#2E312F"
    inverse-primary: "#376754"
```

## Typography

**Manrope** используется для всех заголовков, основного текста и элементов управления благодаря тёплой геометрии и отличной читаемости кириллицы (минимальный основной текст — 18px на лендинге). **Playfair Display** применяется точечно для книжного превью PDF-экспорта. **Spline Sans Mono** используется для имён файлов, версий, контрольных сумм и структуры папок Obsidian.

```yaml
typography:
  display-lg:
    fontFamily: "Manrope"
    fontSize: 44px
    fontWeight: 700
    lineHeight: 52px
    letterSpacing: -0.8px
  display-lg-mobile:
    fontFamily: "Manrope"
    fontSize: 30px
    fontWeight: 700
    lineHeight: 38px
    letterSpacing: -0.5px
  headline-lg:
    fontFamily: "Manrope"
    fontSize: 32px
    fontWeight: 700
    lineHeight: 40px
    letterSpacing: -0.4px
  headline-md:
    fontFamily: "Manrope"
    fontSize: 24px
    fontWeight: 700
    lineHeight: 32px
    letterSpacing: -0.2px
  title-lg:
    fontFamily: "Manrope"
    fontSize: 20px
    fontWeight: 600
    lineHeight: 28px
    letterSpacing: 0px
  title-md:
    fontFamily: "Manrope"
    fontSize: 18px
    fontWeight: 600
    lineHeight: 26px
    letterSpacing: 0px
  body-lg:
    fontFamily: "Manrope"
    fontSize: 18px
    fontWeight: 400
    lineHeight: 28px
    letterSpacing: 0px
  body-md:
    fontFamily: "Manrope"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 24px
    letterSpacing: 0px
  body-sm:
    fontFamily: "Manrope"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 20px
    letterSpacing: 0.1px
  label-lg:
    fontFamily: "Manrope"
    fontSize: 15px
    fontWeight: 600
    lineHeight: 20px
    letterSpacing: 0.1px
  label-md:
    fontFamily: "Manrope"
    fontSize: 13px
    fontWeight: 600
    lineHeight: 18px
    letterSpacing: 0.2px
  label-sm:
    fontFamily: "Manrope"
    fontSize: 12px
    fontWeight: 600
    lineHeight: 16px
    letterSpacing: 0.2px
  editorial-title:
    fontFamily: "Playfair Display"
    fontSize: 22px
    fontWeight: 700
    lineHeight: 28px
    letterSpacing: -0.2px
  editorial-body:
    fontFamily: "Playfair Display"
    fontSize: 15px
    fontWeight: 400
    lineHeight: 22px
    letterSpacing: 0px
  mono-sm:
    fontFamily: "Spline Sans Mono"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 18px
    letterSpacing: 0px
```

## Layout & Spacing

Веб-макет строится на центрированном контейнере `max-w-6xl` (до `1200px`) с 12-колоночной сеткой на десктопе (`1280px`) и одноколоночным потоком на мобильных экранах (`390px`). Между секциями сохраняется щедрый вертикальный ритм (`section: 64px`–`96px`).

```yaml
spacing:
  gutter-xs: 4px
  gutter-sm: 8px
  gutter-md: 12px
  gutter-lg: 16px
  gutter-xl: 24px
  section: 64px
  page-margin: 24px
```

## Elevation & Depth

Иерархия строится через тональные слои поверхности (`surface` → `surface-container-low` → `surface-container-lowest`) и мягкие рассеянные тени (`0 4px 20px rgba(25, 28, 27, 0.04)`), без тяжёлых рамок и неонового свечения. На карточках покоя используется деликатная обводка `1px` `outline-variant` с низкой непрозрачностью.

## Shapes

Дружелюбные скругления подчёркивают тактильность интерфейса: `16px` (`md`) для стандартных карточек и инпутов, `20px`–`24px` (`lg`, `xl`) для ключевых блоков и макетов устройств, и `9999px` (`full`) для кнопок-пилюль и бейджей.

```yaml
rounded:
  sm: 8px
  DEFAULT: 12px
  md: 16px
  lg: 20px
  xl: 24px
  full: 9999px
```

## Motion & Micro-interaction

Движение спокойное, неспешное и строго функциональное. Нажатия кнопок и переключение тем/аккордеона откликаются за `120ms`, раскрытие секций и переходы вкладок — за `240ms`.

```yaml
motion:
  state-change:
    duration: 120ms
    delay: 0ms
    timingFunction: ease-out
  surface-enter:
    duration: 240ms
    delay: 0ms
    timingFunction: cubic-bezier(0.2, 0, 0, 1)
  surface-exit:
    duration: 180ms
    delay: 0ms
    timingFunction: cubic-bezier(0.3, 0, 1, 1)
```

## Voice & Content Strategy

- **Тон:** Тёплый, спокойный, доверительный, простым человеческим языком без технического жаргона.
- **Регистр:** Sentence case (с заглавной только первое слово).
- **Терминология:** Резервная копия (`.jwlibrary`), заметки, выделения, закладки, теги, отчёт.
- **Приватность:** Подчёркивается локальная работа без интернета и рекламы.
- **Ограничения (Do's & Don'ts):** Не использовать логотипы и торговые марки JW Library; не использовать фиолетово-синие градиенты и стоковые фото; использовать только предоставленные скриншоты и векторные иллюстрации.

## Components

Component implementations live as individual HTML sticker sheet files in
`components/`. Each file contains the canonical, styled HTML components with
`<!-- COMPONENT: name -->` comment markers. Read each file before use.

- **Accordion** → `@components/accordion.html`: `accordion-single`, `accordion-group`
- **Button** → `@components/button.html`: `button-primary`, `button-icon`, `button-with-icon`
- **Card** → `@components/card.html`: `card-elevated`, `card-action`, `card-interactive`, `card-interactive-2`
- **Chip** → `@components/chip.html`: `chip-action`, `chip-input`, `chip-with-icon`
- **Typography** → `@components/typography.html`: `typography-display`, `typography-body`, `typography-label`
