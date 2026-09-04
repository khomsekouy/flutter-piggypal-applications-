import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/features/account/presentation/view/delete_account_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_in_page.dart';
import 'package:flutter_piggypal_app/features/more/presentation/view/more_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/training_finance_app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

/// One test per file on purpose: `AppRouter.router` is a `static final`, so its
/// location survives for the life of the isolate and a second `pumpAppToHome`
/// would start from wherever the first one finished.
void main() {
  testWidgets('deleting the account leaves the module for sign-in', (
    tester,
  ) async {
    await tester.pumpAppToHome();

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountPage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'supersecret');
    await tester.pump();
    await tester.ensureVisible(find.text('Delete My Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete My Account'));
    await tester.pumpAndSettle();

    // Unlike sign-out, this path emits `loading` on the way out. A watcher
    // that reads the status before it as "was signed in" sees `loading`
    // instead of `authenticated` and never fires — leaving the user inside a
    // module backed by an account that no longer exists, where every request
    // is a 401 nobody asked for.
    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(TrainingFinanceApp), findsNothing);
    expect(find.byType(MorePage), findsNothing);
  });
}
