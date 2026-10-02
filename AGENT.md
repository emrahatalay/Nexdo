# PROJE: ÖNCE NE, SONRA NE KADAR

Sen kıdemli bir macOS uygulama mühendisi, yazılım mimarı ve ürün geliştiricisisin.

Sıfırdan, production-quality seviyesinde, native macOS için profesyonel bir kişisel planlama ve odak uygulaması geliştireceksin.

Uygulamanın çalışma adı:

**Önce Ne, Sonra Ne Kadar**

Bu proje klasik bir todo uygulaması değildir.

Temel amacı:

> Kullanıcının bütün bekleyen işlerini güvenilir bir yerde toplaması, akşam bir sonraki günü gerçekçi biçimde planlaması, işleri belirli zaman kutularına yerleştirmesi ve ertesi gün yeniden karar vermeden sırayla başlayıp bitirmesini sağlamaktır.

Ana problem görev saklamak değil:

**Ertelemeyi azaltmak, işe başlamayı kolaylaştırmak ve planlanan işi bitirmektir.**

Bu nedenle ürünün temel döngüsü:

**Yakala → Karar Ver → Planla → Zamanla → Başla → Odaklan → Bitir/Dur → Değerlendir**

şeklindedir.

---

# 1. PLATFORM

Öncelikli platform:

**Native macOS**

Teknoloji:

- Swift
- SwiftUI
- SwiftData
- AppKit gerektiği noktalarda
- MenuBarExtra
- UserNotifications
- macOS native window management
- modern Swift concurrency
- Observation framework
- mümkün olduğu ölçüde Apple native framework'leri

Web tabanlı uygulama, Electron veya React Native kullanma.

Native macOS uygulaması geliştir.

Deployment target'ı güncel macOS sürümlerini ve Liquid Glass tasarım dilini destekleyecek şekilde belirle.

Kod yapısını ileride iCloud/CloudKit sync, iOS companion app ve Calendar entegrasyonu eklenebilecek şekilde tasarla.

Ancak MVP'yi gereksiz abstraction ve overengineering ile boğma.

---

# 2. TEMEL ÜRÜN FELSEFESİ

Bu uygulama kullanıcının önüne sürekli seçenek çıkarmamalıdır.

İki farklı çalışma modu vardır:

## Planning Mode

Kullanıcı karar verir.

- hangi işler önemli?
- hangileri yarın yapılacak?
- hangi sırayla?
- ne kadar süre ayrılacak?
- ne zaman başlanacak?
- ilk fiziksel hareket ne?

## Execution Mode

Kullanıcı karar vermez.

Uygulama sadece şunu söyler:

**Şimdi bunu yap.**

Ardından:

**Sonra bunu yap.**

En önemli UX prensibi:

> Planlama modunda seçenek çok olabilir. Çalışma modunda seçenek minimum olmalıdır.

Sabah kullanıcı tekrar öncelik belirlemek zorunda kalmamalıdır.

---

# 3. ANA NAVIGATION

Ana macOS uygulamasında sidebar kullan.

Bölümler:

1. Bugün
2. İş Havuzu
3. Akşam Planı
4. Odak
5. Rutinler
6. Geçmiş

Sidebar mümkün olduğunca native macOS NavigationSplitView yapısıyla oluşturulsun.

Liquid Glass materyalleri navigation ve floating controls üzerinde kullanılmalı.

Ana içerik alanını gereksiz cam kartlarla doldurma.

---

# 4. İŞ HAVUZU / INBOX

Bu alan kullanıcının bütün henüz planlanmamış işlerini saklar.

Yeni bir iş geldiğinde kullanıcı hızlı şekilde buraya ekleyebilmelidir.

Temel felsefe:

**Capture now. Decide later.**

Yeni görev oluştururken zorunlu olan tek bilgi:

`title`

Örneğin:

"Combat sistemindeki bugı düzelt"

Kullanıcı görev yakalarken şu alanları doldurmak zorunda bırakılmamalıdır:

- priority
- date
- Eisenhower quadrant
- duration
- tags
- project

Bunlar capture sırasında friction oluşturur.

Task ilk oluşturulduğunda:

`status = inbox`

olsun.

---

# 5. GLOBAL QUICK CAPTURE

macOS üzerinde uygulama açık olmasa veya arka planda olsa bile hızlı görev ekleme mekanizması tasarla.

Örneğin configurable shortcut:

`⌘ + Shift + Space`

Küçük floating Liquid Glass panel açılmalı.

İçerik:

"Ne yapman gerekiyor?"

[text field]

Enter → kaydet.

Görev Inbox'a gider.

Panel kapanır.

Capture mümkün olduğunca 2-3 saniye sürmelidir.

Shortcut kullanıcı tarafından Settings içinden değiştirilebilir olmalıdır.

---

# 6. TASK DATA MODEL

Task modeli en az aşağıdaki bilgileri desteklemelidir:

```swift
TaskItem

id: UUID
title: String
notes: String?
createdAt: Date
updatedAt: Date

status:
- inbox
- planned
- active
- completed
- stopped
- cancelled

eisenhowerQuadrant:
- doNow
- schedule
- delegate
- eliminate
- unset

estimatedDuration: TimeInterval?
actualDuration: TimeInterval

plannedDate: Date?
scheduledStart: Date?
scheduledEnd: Date?

sortOrder: Int

firstAction: String?

startedAt: Date?
completedAt: Date?

extensionCount: Int

postponeCount: Int

postponeReason: PostponeReason?

source:
- manual
- quickCapture
- recurring
- imported
```

Task modelini SwiftData ile persist et.

---

# 7. EISENHOWER MANTIĞI

Eisenhower Matrix uygulamanın kendisi değildir.

Bu yalnızca karar verme aracıdır.

Dört kategori:

1. Acil + Önemli → Yap
2. Acil Değil + Önemli → Planla
3. Acil + Önemli Değil → Devret
4. Acil Değil + Önemli Değil → Ele

Kullanıcıya sürekli 2x2 matrix gösterme.

Esas olarak Akşam Planı sırasında kullanılmalı.

Task değerlendirilirken kullanıcıya basit sorular sorulabilir:

**Bu iş önemli mi?**

Evet / Hayır

**Bu iş acil mi?**

Evet / Hayır

Sistem quadrant'ı otomatik belirlesin.

---

# 8. AKŞAM PLANI

Bu ekran ürünün en önemli ekranlarından biridir.

Amaç:

**Kullanıcının yarın sabah karar vermek zorunda kalmaması.**

Akşam kullanıcı Inbox'taki işleri değerlendirir.

Akış:

### STEP 1

Bekleyen işleri göster.

### STEP 2

Önem / aciliyet değerlendir.

### STEP 3

Yarın yapılacak işleri seç.

### STEP 4

Her işe timebox ver.

Önerilen preset'ler:

15 dk
25 dk
30 dk
45 dk
60 dk
90 dk

Custom duration da mümkün olsun.

### STEP 5

İlk hareketi belirle.

Örneğin:

Task:
"Combat sistemini geliştir."

First Action:

"Unity'yi aç → CombatScene → EnemyController.cs"

### STEP 6

Görevleri sırala.

Drag & drop destekle.

### STEP 7

Timeline'a yerleştir.

### STEP 8

Planı kilitle.

CTA:

**Yarını Hazırla**

---

# 9. DAILY CAPACITY

Bu özellik zorunludur.

Kullanıcı bir güne gerçekçi olmayan miktarda iş koymamalıdır.

DailyPlan modeli oluştur.

Örneğin:

```swift
DailyPlan

date
availableFocusMinutes
plannedTaskMinutes
routineMinutes
breakMinutes
bufferMinutes
isLocked
```

Akşam Planı ekranında sürekli göster:

**Kullanılabilir: 360 dk**

**Planlanan: 275 dk**

**Boşluk: 85 dk**

Progress indicator kullan.

Plan kapasiteyi geçerse UI açıkça uyarsın.

Örneğin:

"Yarın için 7 saat 20 dakika planladın ancak 6 saat kullanılabilir zaman belirledin."

Kullanıcı isterse override edebilir ancak uygulama bunu normal kabul etmemeli.

---

# 10. BUFFER TIME

Günü %100 doldurma.

Configurable buffer bırak.

Default örneğin:

%15

veya

30-60 dakika.

Bunun amacı beklenmeyen işler için alan bırakmaktır.

Timeline üzerinde buffer açık şekilde görünmelidir.

---

# 11. DAILY TIMELINE

Bugün ve Akşam Planı ekranlarında timeline olmalıdır.

Örneğin:

08:00
Sabah rutini

09:00
Combat sistemi
45 dakika

09:45
15 dk mola

10:00
Video senaryosu
50 dakika

10:50
Buffer

13:30
UI düzenleme
30 dakika

18:00
Yürüyüş

21:30
Yarınını planla

Timeline hem Task hem Routine gösterebilmelidir.

Drag & drop ile görev sıralaması yapılabilmelidir.

Çakışmalar algılanmalıdır.

---

# 12. BUGÜN EKRANI

Bu ekran sabah ana çalışma ekranıdır.

Amaç:

**Karar vermeyi ortadan kaldırmak.**

En üstte:

BUGÜN

Plan hazır.

Şimdi:

### Task title

Altında:

scheduled time

estimated duration

first action

Sonraki görev küçük şekilde gösterilmeli.

Örneğin:

**ŞİMDİ**

Combat sisteminin çekirdeğini tamamla

09:00 → 09:45

İlk hareket:

CombatScene'i aç → EnemyController.cs

[ BAŞLADIM ]

Altında:

**Sonraki**

Video senaryosu  
10:00 · 50 dk

---

# 13. FIRST ACTION

Ertelemeyi azaltmak için kritik özelliktir.

Her planlanan görev opsiyonel fakat güçlü şekilde teşvik edilen:

`firstAction`

alanına sahip olmalıdır.

Bu soyut hedef değil, fiziksel başlangıç hareketidir.

Kötü:

"Video üzerinde çalış."

İyi:

"Final Cut'ı aç ve project timeline'ını oluştur."

Kötü:

"Oyunu geliştir."

İyi:

"Unity → CombatScene → EnemyController.cs dosyasını aç."

Odak ekranında görev adından hemen sonra göster.

---

# 14. FOCUS MODE

Focus Mode son derece minimal olmalıdır.

Sidebar ve gereksiz UI dikkat dağıtmamalıdır.

Gösterilecekler:

Task title

First Action

Remaining time

Pause

Complete

Can't Start

Gerekirse Exit Focus.

Başka görevler gösterilmemelidir.

---

# 15. TIMEBOX ENGINE

Pomodoro uygulamanın temel modeli değildir.

Temel model:

**Timeboxing**

Pomodoro opsiyonel çalışma biçimidir.

Her planlanmış görevin estimatedDuration değeri olmalıdır.

Timer gerçek zamanlı çalışmalıdır.

App background'a geçtiğinde timer drift yaşamamalıdır.

Timer'ı yalnızca saniye azaltarak yönetme.

`startDate` üzerinden kalan süreyi hesapla.

App sleep/wake durumlarını doğru ele al.

State persistence yap.

App kapanıp tekrar açıldığında aktif timer doğru şekilde devam edebilmelidir.

---

# 16. TIMER STATE MACHINE

Timer logic'i View içinde yazma.

Ayrı domain/service katmanı oluştur.

Örneğin:

```swift
FocusSessionState

idle
running
paused
expired
completed
stopped
```

Geçişler deterministik olsun.

TimerManager / FocusSessionController gibi ayrı yapı kullan.

Unit test yaz.

---

# 17. TIMEBOX BİTİNCE

Sayaç 00:00 olduğunda otomatik olarak ekstra süre verme.

Modal / sheet aç:

**Zaman doldu.**

Şimdi bir karar ver.

Seçenekler:

### Bitti

Task completed olur.

actualDuration kaydedilir.

### Burada durdum

Task stopped olur.

Kalan kısmı tekrar planlamak mümkün olur.

### +15 dakika

Bir defalık extension.

`extensionCount += 1`

İkinci defa extension istenirse:

"Bu iş tahmin edilenden uzun sürüyor. Kalan kısmı yeniden planla."

göster.

Sınırsız timer extension verme.

---

# 18. ACTUAL DURATION

Gerçek çalışma süresini mutlaka kaydet.

Pause sürelerini actual focus duration'a dahil etme.

Örneğin:

Estimated:

45 dakika

Actual:

61 dakika

Bu veri gelecekte estimation learning için kullanılacak.

---

# 19. CAN'T START / ERTELEME

Focus başlamadan kullanıcı:

**Şimdi yapamıyorum**

seçeneğine basabilmeli.

Sonra neden sor:

- Enerjim yok
- İş çok büyük
- Ne yapacağım net değil
- Başka iş çıktı
- Ortam uygun değil
- Diğer

Kaydet:

```swift
Postponement

id
taskID
timestamp
reason
note?
```

Bu veri kullanıcının davranışını anlamak için kullanılacaktır.

Utandırıcı veya cezalandırıcı UI kullanma.

---

# 20. ROUTINES

Routine ile Task birbirinden ayrı domain entity olmalıdır.

Routine tekrar eden davranıştır.

Örneğin:

Kitap oku

Yürüyüş

Egzersiz

Akşam planlama

Meditasyon

Routine modeli:

```swift
Routine

id
title
estimatedDuration
timeOfDay
preferredStartTime

recurrenceRule

isActive

createdAt
```

Recurrence:

- everyDay
- weekdays
- selectedWeekdays
- weekly
- custom

RoutineCompletion:

```swift
id
routineID
date
completedAt
actualDuration?
```

Her gün Task kopyası oluşturma.

Routine kendi entity'si olarak kalmalıdır.

---

# 21. ROUTINES + CAPACITY

Rutinler günlük kapasiteden zaman tüketmelidir.

Örneğin:

Available:

6 saat

Tasks:

4 saat

Routines:

1 saat

Buffer:

30 dakika

Remaining:

30 dakika

Akşam planlama ekranında bunların hepsi hesaba katılmalıdır.

---

# 22. ROUTINE SCREEN

Rutin ekranında:

Bugünkü rutinler

Tüm rutinler

Weekly completion

streak

gösterilebilir.

Ancak gamification minimum tutulmalıdır.

Ana amaç streak kovalamak değil, düzen oluşturmaktır.

---

# 23. MENU BAR APP

macOS MenuBarExtra kullan.

Menü bar uygulamanın en önemli özelliklerinden biridir.

Normal durumda:

`◎ 45:00`

veya:

`◎ Combat · 37:42`

göster.

Tıklanınca Liquid Glass popover aç.

Popover:

Combat sisteminin çekirdeği

37:42

[ Pause ]

[ ✓ Bitir ]

[ … ]

Sonraki:

Video senaryosu  
50 dk

Kullanıcı ana pencereyi açmadan çalışma gününü yönetebilmelidir.

---

# 24. NOTIFICATIONS

Local notification kullan.

Örnekler:

"Combat sistemi için ayırdığın zaman başladı."

"45 dakikalık zaman kutun tamamlandı."

"21:30 — Yarını planlama zamanı."

Bildirim sayısını düşük tut.

Notification fatigue oluşturma.

---

# 25. HISTORY

History ekranı kullanıcının kendisini ölçmesi için değil, planlama yeteneğini geliştirmesi için kullanılmalıdır.

Göster:

Estimated vs Actual

Planned vs Completed

Stopped tasks

Postponements

Focus duration

Routine completion

Örneğin:

Combat AI

Tahmin: 45 dk

Gerçek: 61 dk

---

# 26. ESTIMATION LEARNING

Geçmiş verilerden basit insight üret.

Örneğin:

"Son 12 yazılım görevinde planladığın sürenin ortalama 1.28 katını kullandın."

Bu aşamada ağır ML sistemi kurmak zorunda değilsin.

Deterministic statistics yeterlidir.

Gelecekte AI layer eklenebilecek mimari oluştur.

---

# 27. GÜN SONU

Kısa bir review flow olsun.

Örneğin:

Bugün:

3 / 4 iş tamamlandı

Planlanan:
240 dk

Gerçek:
265 dk

Durdurulan:
1

Rutin:
3 / 4

Son soru:

"Bugünden yarına taşınması gereken bir şey var mı?"

Sonra Akşam Planı ekranına geç.

---

# 28. SETTINGS

Settings ekranı ekle.

Bölümler:

General

Focus

Planning

Routines

Notifications

Shortcuts

Appearance

Önemli seçenekler:

Default timebox

Extension duration

Daily available focus time

Default buffer

Planning reminder time

Quick Capture shortcut

Launch at login

Show Menu Bar item

Notifications

Appearance:
System / Light / Dark

---

# 29. LIQUID GLASS DESIGN

Uygulama macOS'un modern Liquid Glass tasarım diline çok yüksek uyum göstermelidir.

Ancak her şeyi cam yapma.

Liquid Glass özellikle:

- sidebar
- toolbar
- floating controls
- popovers
- menu bar
- sheets
- transient controls

üzerinde kullanılmalı.

Ana içerik yüzeylerinde okunabilirlik önceliklidir.

Native Apple materials tercih et.

Custom blur efektlerini yalnızca gerçekten gerekli olduğunda kullan.

System colors kullan.

Dark Mode eksiksiz desteklenmeli.

Reduce Transparency ve Reduce Motion accessibility ayarlarına saygı göster.

---

# 30. VISUAL LANGUAGE

Arayüz:

- profesyonel
- sakin
- minimalist
- premium
- odak artırıcı
- düşük cognitive load

olmalıdır.

Kaçın:

- aşırı gradient
- neon
- gereksiz renk
- çok fazla badge
- sürekli grafik
- yoğun dashboard görünümü
- çocukça gamification

Accent color minimum kullanılmalı.

Renk anlam taşımalıdır.

Typography native SF Pro sistemine dayanmalıdır.

Spacing tutarlı olmalıdır.

---

# 31. PRIORITY MODEL

P1 / P2 / P3 gibi ikinci bir priority sistemi ekleme.

Bu Eisenhower sistemiyle gereksiz şekilde çakışır.

Öncelik şunlardan çıkar:

Eisenhower classification

-

Daily order

Yani:

**Yarının sırası = gerçek priority.**

---

# 32. PROJECTS

Task'ların ileride Project ile ilişkilendirilebilmesini destekle.

Ancak Projects özelliğini ana deneyimin önüne koyma.

Basit model:

```swift
Project

id
name
isActive
createdAt
```

Task:

`projectID?`

MVP'de proje kullanımı opsiyonel olabilir.

---

# 33. DOMAIN ARCHITECTURE

Kod View dosyalarının içine yığılmamalıdır.

Katmanlı ve feature-oriented architecture kullan.

Önerilen yapı:

```text
App/
    FocusApp.swift
    AppEnvironment.swift

Domain/
    Models/
        TaskItem.swift
        Routine.swift
        RoutineCompletion.swift
        DailyPlan.swift
        FocusSession.swift
        Postponement.swift
        Project.swift

    Enums/
        TaskStatus.swift
        EisenhowerQuadrant.swift
        FocusSessionState.swift
        PostponeReason.swift

Features/
    Today/
        TodayView.swift
        TodayViewModel.swift

    Inbox/
        InboxView.swift
        InboxViewModel.swift

    Planning/
        PlanningView.swift
        PlanningViewModel.swift

    Focus/
        FocusView.swift
        FocusViewModel.swift

    Routines/
        RoutinesView.swift
        RoutinesViewModel.swift

    History/
        HistoryView.swift
        HistoryViewModel.swift

    Settings/
        SettingsView.swift

    QuickCapture/
        QuickCapturePanel.swift

    MenuBar/
        MenuBarView.swift

Services/
    FocusTimerService.swift
    PlanningService.swift
    CapacityService.swift
    NotificationService.swift
    RoutineScheduler.swift
    StatisticsService.swift

Persistence/
    PersistenceController.swift
    Repositories/

DesignSystem/
    Components/
    Typography/
    Materials/
    Layout/

Utilities/

Tests/
    DomainTests/
    ServiceTests/
    FeatureTests/
```

Dosya isimleri birebir böyle olmak zorunda değildir.

Ancak separation of concerns korunmalıdır.

---

# 34. REPOSITORY PATTERN

Persistence logic ViewModel içine dağılmamalıdır.

Gerekli yerlerde repository abstraction kullan.

Örneğin:

```swift
protocol TaskRepository {
    func fetchInbox() async throws -> [TaskItem]
    func save(_ task: TaskItem) async throws
    func delete(_ task: TaskItem) async throws
}
```

Ancak gereksiz protocol explosion yapma.

Test edilebilirlik veya persistence boundary olduğu yerlerde abstraction kullan.

---

# 35. SERVICES

Business logic View içinde olmamalıdır.

Örneğin:

Capacity calculation:

```swift
CapacityService
```

Planning:

```swift
PlanningService
```

Timer:

```swift
FocusTimerService
```

Statistics:

```swift
StatisticsService
```

Notification:

```swift
NotificationService
```

---

# 36. CAPACITY SERVICE

Örnek hesap:

```text
availableMinutes
- routineMinutes
- plannedTaskMinutes
- bufferMinutes
= remainingMinutes
```

Negatif değer oluşursa:

`overCapacity = true`

Planning UI bunu anında göstermelidir.

Unit test yaz.

---

# 37. PLANNING VALIDATION

Bir DailyPlan lock edilmeden önce kontrol et:

- en az bir task var mı?
- task duration belirlenmiş mi?
- sortOrder var mı?
- schedule conflict var mı?
- capacity aşılmış mı?
- active routine conflict var mı?

Hataları kullanıcıya anlaşılır biçimde göster.

---

# 38. DATA PERSISTENCE

Tüm önemli state persist edilmelidir.

Özellikle:

tasks

daily plans

routines

routine completions

focus sessions

timer state

postponements

settings

App restart olduğunda veri kaybolmamalıdır.

---

# 39. TIMER RECOVERY

Önemli edge case:

Kullanıcı timer çalışırken Mac'i sleep'e aldı.

Uygulama yeniden açıldığında:

wall clock üzerinden doğru kalan süreyi hesapla.

Aynı şekilde:

app terminate

app relaunch

system sleep

system wake

durumlarını ele al.

---

# 40. ACCESSIBILITY

VoiceOver labels ekle.

Keyboard navigation destekle.

Dynamic Type / accessibility text scaling mümkün olduğu ölçüde destekle.

Reduce Motion.

Reduce Transparency.

High Contrast.

Renk tek başına durum belirtmek için kullanılmamalıdır.

---

# 41. KEYBOARD-FIRST UX

Bu bir macOS productivity uygulamasıdır.

Keyboard-first tasarla.

Örneğin:

Quick Capture:
configurable global shortcut

Focus start:
⌘ + Return

Complete:
⌘ + Shift + Return

Pause:
Space veya uygun shortcut

Inbox:
⌘ + 1

Today:
⌘ + 2

Planning:
⌘ + 3

Shortcuts conflict yaratmayacak şekilde tasarlanmalıdır.

Menu commands oluştur.

---

# 42. EMPTY STATES

Her ekranın düzgün empty state'i olsun.

Örneğin Inbox boşsa:

**Her şey işlendi.**

"Yeni bir iş geldiğinde buraya bırak."

Planning boşsa:

"Yarın için henüz bir şey seçmedin."

Today plan yoksa:

"Bugün için plan hazırlanmadı."

CTA:

"Bugünü Planla"

---

# 43. ERROR HANDLING

Silent failure yapma.

Persistence error

Notification permission failure

shortcut registration failure

data migration failure

gibi durumlar kullanıcıya gerektiği ölçüde açıklanmalıdır.

Debug log ile kullanıcı-facing error ayrılmalıdır.

---

# 44. TESTING

Unit test özellikle şu alanlarda zorunlu:

FocusTimerService

CapacityService

PlanningService

Routine recurrence

Estimated vs actual calculation

Postponement statistics

DailyPlan validation

Timer state transitions

Extension limit

Sleep/wake timer recovery

---

# 45. PREVIEW / SAMPLE DATA

SwiftUI Preview için mock data oluştur.

Production database'e sample data yazma.

Preview'larda:

- empty state
- normal state
- over-capacity
- running timer
- expired timer
- dark mode

durumlarını göster.

---

# 46. PERFORMANCE

UI thread üzerinde ağır persistence veya statistics hesaplama yapma.

Swift concurrency kullan.

MainActor sınırlarını doğru belirle.

Timer saniyede gereksiz persistence write yapmamalıdır.

Session state yalnızca gerekli event'lerde persist edilmelidir.

---

# 47. MVP'DE YAPILMAMASI GEREKENLER

Şimdilik ekleme:

- sosyal özellikler
- leaderboard
- achievement sistemi
- karmaşık AI chatbot
- team collaboration
- kanban board
- onlarca priority seviyesi
- karmaşık tag sistemi
- reward coin sistemi
- aşırı analytics dashboard
- calendar replacement
- note-taking uygulaması

Ürünü Todoist/Notion klonuna dönüştürme.

---

# 48. GELECEKTE EKLENEBİLECEKLER

Architecture aşağıdakilere kapalı olmamalıdır:

- iCloud / CloudKit sync
- iOS companion
- Calendar integration
- Apple Shortcuts
- Siri / App Intents
- widgets
- AI duration estimation
- AI first-action suggestion
- AI evening planning assistant

Ancak bunları MVP'nin merkezine koyma.

---

# 49. EN ÖNEMLİ USER FLOW

Uygulamanın başarısını şu senaryoyla test et:

## Gün içinde

Kullanıcı yeni iş öğrenir.

Global shortcut.

"App Store görsellerini hazırla"

Enter.

Bitti.

---

## Akşam

21:30 notification:

"Yarını hazırlamak için 8 iş bekliyor."

Kullanıcı Planning ekranına gelir.

İşleri değerlendirir.

Yarın için:

Combat system — 60 min

Video script — 45 min

UI — 30 min

seçer.

Rutinler otomatik timeline'dadır.

Capacity:

Available: 360

Tasks: 135

Routines: 70

Buffer: 45

Remaining: 110

Kullanıcı sıralar.

First Action belirler.

"Yarını Hazırla"

---

## Sabah

Uygulamayı açar.

Dashboard gösterme.

Karar sordurma.

Göster:

**ŞİMDİ**

Combat system

09:00 → 10:00

First action:

Unity → CombatScene

[ BAŞLADIM ]

---

## Çalışma sırasında

Focus mode.

60:00

Timer başlar.

Menu bar:

`◎ Combat · 59:42`

---

## Süre sonunda

Modal:

**Zaman doldu.**

Bitti

Burada durdum

+15 dk

---

## İş bittiyse

actual duration kaydet.

Sıradaki işe geç:

**SONRAKİ**

Video script

[ BAŞLA ]

---

## Gün sonunda

Kısa review.

Ardından:

**Yarını Planla**

Döngü tekrar başlar.

---

# 50. ÜRÜNÜN BAŞARI KRİTERİ

Bu uygulamanın başarısı:

"Kaç görev ekledin?"

değildir.

Başarı:

**Planlanan işi zamanında başlatma oranı**

**Tamamlanan timebox oranı**

**Tahmin doğruluğu**

**Erteleme oranının zamanla azalması**

üzerinden düşünülmelidir.

---

# 51. UX KARAR FİLTRESİ

Yeni bir özellik eklemeden önce sor:

> Bu özellik kullanıcının ne yapacağını seçmesini, işe başlamasını veya işi bitirmesini kolaylaştırıyor mu?

Hayırsa büyük ihtimalle gerekli değildir.

İkinci soru:

> Bu özellik çalışma sırasında yeni karar yükü oluşturuyor mu?

Evetse sadeleştir.

---

# 52. KOD KALİTESİ

Kod production-quality olmalıdır.

Beklentiler:

- küçük ve anlaşılır component'ler
- güçlü type safety
- meaningful naming
- dependency injection
- testable business logic
- reusable design components
- minimal duplication
- documented non-obvious decisions
- no massive View files
- no massive ViewModels
- no god objects
- no force unwrap unless absolutely justified
- no business logic inside SwiftUI body
- no magic numbers
- no hardcoded strings scattered everywhere

Constants/design tokens oluştur.

---

# 53. IMPLEMENTATION STRATEGY

Projeyi tek seferde devasa kod dökümü şeklinde oluşturma.

Aşağıdaki sırayla ilerle:

### Phase 1 — Foundation

Project structure

SwiftData models

Enums

Repositories

App navigation

Design system

### Phase 2 — Capture

Inbox

Task creation

Quick Capture

Persistence

### Phase 3 — Planning

Eisenhower classification

Timebox selection

Capacity

DailyPlan

Timeline

Plan locking

### Phase 4 — Execution

Today

First Action

Focus Mode

Timer engine

Menu Bar

### Phase 5 — Completion

Actual duration

Complete

Stop

Extension

Postponement

### Phase 6 — Routines

Routine recurrence

Daily integration

Capacity integration

### Phase 7 — Review

History

Statistics

Daily review

Estimation insights

### Phase 8 — Polish

Notifications

Keyboard shortcuts

Settings

Accessibility

Animations

Liquid Glass refinement

Tests

---

# 54. HER PHASE SONUNDA

Her phase tamamlandığında:

1. build al
2. compiler error'larını çöz
3. warning'leri kontrol et
4. ilgili unit testleri çalıştır
5. UI flow'u kontrol et
6. mevcut çalışan feature'ları bozmadığını doğrula
7. ancak bundan sonra sonraki phase'e geç

Kırık kod bırakıp ilerleme.

Placeholder implementation'ları mümkün olduğunca bırakma.

---

# 55. TASARIM FELSEFESİ

Son ürün kullanıcıya şunu hissettirmelidir:

**"Bugün ne yapacağımı düşünmek zorunda değilim. Dün karar verdim. Şimdi sadece başlıyorum."**

Uygulamanın özü:

**Geleni yakala.**

↓

**Akşam karar ver.**

↓

**Gerçekçi süre ayır.**

↓

**Sabah düşünme.**

↓

**Başla.**

↓

**Tek işe odaklan.**

↓

**Süre bitince karar ver.**

↓

**Bitir veya yeniden planla.**

↓

**Sıradakine geç.**

Bu felsefeden uzaklaşma.

---

# 56. İLK GÖREVİN

Şimdi doğrudan rastgele kod yazmaya başlama.

Önce:

1. Bu specification'ı analiz et.
2. Domain modelini çıkar.
3. Uygulamanın state machine'lerini tanımla.
4. SwiftData ilişkilerini tasarla.
5. Feature/module yapısını çıkar.
6. Navigation architecture'ı belirle.
7. Timer architecture'ını açıkla.
8. DailyPlan ve capacity algoritmasını tanımla.
9. Routine recurrence yaklaşımını tanımla.
10. Riskli edge-case'leri listele.
11. Uygulamanın klasör/dosya ağacını çıkar.
12. Implementation planını phase'lere böl.

Bana kısa fakat teknik bir **Architecture & Implementation Plan** göster.

Ardından proje iskeletini oluşturmaya başla.

Her phase'i production-quality şekilde tamamla.

Kararsız kaldığında ürünün ana prensibine dön:

> Bu bir görev saklama uygulaması değil. Kullanıcının doğru işi, ayrılan süre içinde başlatıp bitirmesini sağlayan bir execution system.
