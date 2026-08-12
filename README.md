# Finance+ — Setup Guide

A Flutter app (Supabase backend) that walks a user through a daily finance
review, budgeting, recording income/expenses, and tracking savings goals.

---

## 1. Add the files to your Flutter project

Copy the contents of this folder into your existing project so you end up with:

```
your_project/
├─ pubspec.yaml                 # merge the dependencies below into yours
└─ lib/
   ├─ main.dart
   ├─ config/supabase_config.dart
   ├─ theme/app_theme.dart
   ├─ utils/format.dart
   ├─ models/models.dart
   ├─ services/auth_service.dart
   ├─ services/data_service.dart
   ├─ widgets/common.dart
   └─ screens/
      ├─ welcome_screen.dart        (Image 1)
      ├─ review_screen.dart         (Image 2)
      ├─ budget_screen.dart         (Image 3)
      ├─ record_screen.dart         (Image 4)
      ├─ create_goal_screen.dart    (Image 5)
      ├─ goals_screen.dart          (Image 6)
      ├─ home_shell.dart            (bottom nav)
      ├─ profile_screen.dart
      └─ auth/
         ├─ login_screen.dart
         └─ register_screen.dart
```

Add these dependencies (already in the included `pubspec.yaml`) and run
`flutter pub get`:

```yaml
supabase_flutter: ^2.5.6
fl_chart: ^0.69.0
intl: ^0.19.0
```

---

## 2. Create the Supabase project

1. Go to https://supabase.com → **New project**. Pick a name and a strong
   database password, choose the region closest to you, and create it.
2. When it finishes provisioning, open **SQL Editor → New query**, paste the
   entire contents of `supabase_schema.sql`, and click **Run**. This creates
   the `profiles`, `budgets`, `transactions`, and `goals` tables, turns on
   Row Level Security, and adds the signup trigger that auto-creates a profile.

---

## 3. Connect the app to Supabase

In the Supabase dashboard go to **Project Settings → API** and copy:

- **Project URL**
- **anon public** key

Paste them into `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://xxxxxxxx.supabase.co';
  static const String anonKey = 'eyJhbGciOi...';
}
```

The anon key is meant to live in the client — it only works together with the
Row Level Security policies. **Never** put the `service_role` key in the app.

---

## 4. Auth settings (important for testing)

By default Supabase requires **email confirmation**. For quick local testing:

- **Authentication → Providers → Email** → turn **Confirm email** OFF.

With it off, registering logs the user straight in. With it on, the user must
click the link in their email before they can log in (the register screen shows
a hint for this case). Re-enable it before going to production.

---

## 5. Run it

```bash
flutter pub get
flutter run
```

Register an account → you land on the **Welcome / Digital Manager** screen →
tap **START** → you're on the **Review** dashboard. Tick the declaration box to
unlock the rest of the bottom navigation, then use **Budget**, **Record**,
**Goals**, and **Profile**.

---

## How the pieces map to your mockups

| Screen | File | Notes |
|---|---|---|
| Image 1 – Digital Manager start | `welcome_screen.dart` | START routes to the review tab |
| Image 2 – Review dashboard | `review_screen.dart` | totals, donut, goal bars, declaration that locks the nav |
| Image 3 – Budget setup | `budget_screen.dart` | income auto-splits Needs 50 / Savings 20 / Debt 20 / Tithes 10; "Set" accumulates |
| Image 4 – Record | `record_screen.dart` | Expenses/Income tabs with the category dropdowns you specified |
| Image 5 – Create goal | `create_goal_screen.dart` | Career / Emergency / Business / Travel |
| Image 6 – Goals summary | `goals_screen.dart` | tap a goal circle to add an amount |

---

## Things you'll likely want to refine next

- **Category mismatch across screens.** Your budget uses *Tithes*, but expenses
  use *Wants*. Right now the donut shows the expense breakdown (Needs/Wants/
  Debt/Savings). Decide on one consistent set and update `budget_screen.dart`,
  `record_screen.dart`, and `AppColors.category` in `app_theme.dart`.
- **Persisting "reviewed today."** The nav-lock currently resets each app
  launch (session-only). To enforce a true once-per-day review, add a
  `reviews` table and check the latest row's date on startup.
- **Budgets vs. actual spend.** You can compare `transactions` totals per
  category against the `budgets` thresholds to warn when a category is over.
