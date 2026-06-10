/// Navigation surface handed to every Training Finance screen.
///
/// The prototype drives navigation with a tab root + an in-shell push stack
/// (the bottom bar stays visible on pushed screens, except "Add"). [TFNav]
/// abstracts those four operations so screens stay decoupled from the shell.
abstract class TFNav {
  /// Switch to a root tab, clearing the push stack.
  void tab(String name);

  /// Push a screen onto the in-shell stack.
  void push(String screen, [Map<String, Object?> params]);

  /// Pop the top pushed screen.
  void back();

  /// Clear the whole push stack.
  void reset();
}

/// Identifiers for pushed (non-tab) screens.
abstract final class TFScreens {
  static const program = 'program';
  static const participants = 'participants';
  static const participant = 'participant';
  static const txList = 'txlist';
  static const txDetail = 'txdetail';
  static const budgets = 'budgets';
  static const receipts = 'receipts';
  static const pnl = 'pnl';
  static const add = 'add';
}

/// Identifiers for root tabs.
abstract final class TFTabs {
  static const dashboard = 'dashboard';
  static const programs = 'programs';
  static const reports = 'reports';
  static const more = 'more';
}
