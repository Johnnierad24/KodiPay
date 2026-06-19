// ignore_for_file: constant_identifier_names
//
// Central icon mapping for KodiPay.
//
// Every icon used in the app resolves through this class to a Phosphor icon
// (regular weight) for a cohesive, modern look. Field names intentionally
// mirror the original Material `Icons.*` names so call sites read naturally and
// the icon set can be retuned (weight, specific glyph) from this one place.
//
// All values are `const`, so `const Icon(AppIcons.x)` keeps working.

import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppIcons {
  AppIcons._();

  // Navigation & chrome
  static const menu_rounded = PhosphorIconsRegular.list;
  static const logout_rounded = PhosphorIconsRegular.signOut;
  static const exit_to_app_rounded = PhosphorIconsRegular.signOut;
  static const arrow_back_ios_new_rounded = PhosphorIconsRegular.arrowLeft;
  static const chevron_right_rounded = PhosphorIconsRegular.caretRight;
  static const dashboard_rounded = PhosphorIconsRegular.squaresFour;
  static const grid_view_rounded = PhosphorIconsRegular.dotsNine;
  static const settings_outlined = PhosphorIconsRegular.gear;
  static const help_outline_rounded = PhosphorIconsRegular.question;
  static const open_in_new_rounded = PhosphorIconsRegular.arrowSquareOut;
  static const power_settings_new_rounded = PhosphorIconsRegular.power;
  static const swap_horiz_rounded = PhosphorIconsRegular.arrowsLeftRight;

  // People
  static const person_outline_rounded = PhosphorIconsRegular.user;
  static const person_add_alt_1_rounded = PhosphorIconsRegular.userPlus;
  static const person_remove_outlined = PhosphorIconsRegular.userMinus;
  static const groups_2_outlined = PhosphorIconsRegular.usersThree;
  static const engineering_outlined = PhosphorIconsRegular.userGear;
  static const support_agent_rounded = PhosphorIconsRegular.headset;

  // Property & rooms
  static const home_rounded = PhosphorIconsRegular.house;
  static const add_home_rounded = PhosphorIconsRegular.house;
  static const home_work_outlined = PhosphorIconsRegular.buildings;
  static const business_rounded = PhosphorIconsRegular.buildings;
  static const apartment_rounded = PhosphorIconsRegular.buildingApartment;
  static const meeting_room_outlined = PhosphorIconsRegular.door;

  // Money & payments
  static const account_balance_wallet_outlined = PhosphorIconsRegular.wallet;
  static const account_balance_wallet_rounded = PhosphorIconsRegular.wallet;
  static const payments_outlined = PhosphorIconsRegular.money;
  static const money_off_outlined = PhosphorIconsRegular.prohibit;
  static const receipt_long_outlined = PhosphorIconsRegular.receipt;
  static const balance_outlined = PhosphorIconsRegular.scales;
  static const gavel_outlined = PhosphorIconsRegular.gavel;

  // Maintenance
  static const handyman_rounded = PhosphorIconsRegular.wrench;
  static const handyman_outlined = PhosphorIconsRegular.wrench;
  static const build_outlined = PhosphorIconsRegular.wrench;
  static const build_circle_outlined = PhosphorIconsRegular.wrench;
  static const health_and_safety_outlined = PhosphorIconsRegular.shieldCheck;

  // Documents & files
  static const description_outlined = PhosphorIconsRegular.fileText;
  static const assignment_outlined = PhosphorIconsRegular.clipboardText;
  static const handshake_outlined = PhosphorIconsRegular.handshake;
  static const folder_open_rounded = PhosphorIconsRegular.folderOpen;
  static const folder_copy_outlined = PhosphorIconsRegular.folders;
  static const upload_file_outlined = PhosphorIconsRegular.fileArrowUp;
  static const note_add_outlined = PhosphorIconsRegular.filePlus;
  static const attach_file_rounded = PhosphorIconsRegular.paperclip;
  static const cloud_upload_outlined = PhosphorIconsRegular.cloudArrowUp;
  static const picture_as_pdf_outlined = PhosphorIconsRegular.filePdf;
  static const picture_as_pdf_rounded = PhosphorIconsRegular.filePdf;
  static const table_chart_outlined = PhosphorIconsRegular.table;
  static const save_outlined = PhosphorIconsRegular.floppyDisk;
  static const save_rounded = PhosphorIconsRegular.floppyDisk;
  static const download_rounded = PhosphorIconsRegular.downloadSimple;
  static const ios_share_rounded = PhosphorIconsRegular.shareNetwork;
  static const copy_rounded = PhosphorIconsRegular.copy;
  static const copy_all_outlined = PhosphorIconsRegular.copy;
  static const edit_outlined = PhosphorIconsRegular.pencilSimple;
  static const delete_outline_rounded = PhosphorIconsRegular.trash;

  // Communication
  static const email_outlined = PhosphorIconsRegular.envelopeSimple;
  static const email_rounded = PhosphorIconsRegular.envelopeSimple;
  static const mail_outline_rounded = PhosphorIconsRegular.envelopeSimple;
  static const phone_outlined = PhosphorIconsRegular.phone;
  static const phone_rounded = PhosphorIconsRegular.phone;
  static const call_outlined = PhosphorIconsRegular.phone;
  static const sms_outlined = PhosphorIconsRegular.chatText;
  static const chat_bubble_outline_rounded = PhosphorIconsRegular.chatCircle;
  static const send_rounded = PhosphorIconsRegular.paperPlaneRight;
  static const campaign_outlined = PhosphorIconsRegular.megaphone;

  // Notifications
  static const notifications_none_rounded = PhosphorIconsRegular.bell;
  static const notifications_active_outlined = PhosphorIconsRegular.bellRinging;

  // Status & feedback
  static const check_rounded = PhosphorIconsRegular.check;
  static const done_all_rounded = PhosphorIconsRegular.checks;
  static const check_circle_rounded = PhosphorIconsRegular.checkCircle;
  static const check_circle_outline = PhosphorIconsRegular.checkCircle;
  static const check_circle_outline_rounded = PhosphorIconsRegular.checkCircle;
  static const task_alt_rounded = PhosphorIconsRegular.listChecks;
  static const verified_outlined = PhosphorIconsRegular.sealCheck;
  static const warning_rounded = PhosphorIconsRegular.warning;
  static const warning_amber_rounded = PhosphorIconsRegular.warning;
  static const report_problem_outlined = PhosphorIconsRegular.warning;
  static const priority_high_rounded = PhosphorIconsRegular.warning;
  static const error_outline_rounded = PhosphorIconsRegular.warningCircle;
  static const shield_outlined = PhosphorIconsRegular.shield;
  static const schedule_rounded = PhosphorIconsRegular.clock;
  static const timelapse_outlined = PhosphorIconsRegular.timer;
  static const hourglass_top_rounded = PhosphorIconsRegular.hourglass;
  static const pending_actions_rounded = PhosphorIconsRegular.clock;
  static const pending_actions = PhosphorIconsRegular.clock;
  static const radio_button_unchecked_rounded = PhosphorIconsRegular.circle;

  // Security & visibility
  static const lock_outline_rounded = PhosphorIconsRegular.lock;
  static const lock_rounded = PhosphorIconsRegular.lock;
  static const lock_reset_rounded = PhosphorIconsRegular.lockKey;
  static const pin_outlined = PhosphorIconsRegular.password;
  static const visibility = PhosphorIconsRegular.eye;
  static const visibility_outlined = PhosphorIconsRegular.eye;
  static const visibility_off = PhosphorIconsRegular.eyeSlash;
  static const visibility_off_outlined = PhosphorIconsRegular.eyeSlash;

  // Actions & misc
  static const add_rounded = PhosphorIconsRegular.plus;
  static const search_rounded = PhosphorIconsRegular.magnifyingGlass;
  static const clear_rounded = PhosphorIconsRegular.x;
  static const refresh_rounded = PhosphorIconsRegular.arrowClockwise;
  static const play_arrow_rounded = PhosphorIconsRegular.play;
  static const analytics_outlined = PhosphorIconsRegular.chartLine;
  static const smart_toy_outlined = PhosphorIconsRegular.robot;
  static const google = PhosphorIconsRegular.googleLogo;
  static const arrow_forward_rounded = PhosphorIconsRegular.arrowRight;
}
