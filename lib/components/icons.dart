import 'package:flutter/material.dart';

class AppIcons {
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData dashboardFilled = Icons.dashboard;
  
  static const IconData clients = Icons.people_outline;
  static const IconData clientsFilled = Icons.people;
  
  static const IconData technicians = Icons.engineering_outlined;
  static const IconData techniciansFilled = Icons.engineering;
  
  static const IconData orders = Icons.assignment_outlined;
  static const IconData ordersFilled = Icons.assignment;
  
  static const IconData quotes = Icons.receipt_long_outlined;
  static const IconData quotesFilled = Icons.receipt_long;
  
  static const IconData equipment = Icons.hvac_outlined;
  static const IconData equipmentFilled = Icons.hvac;
  
  static const IconData home = Icons.home_outlined;
  static const IconData homeFilled = Icons.home;
  
  static const IconData profile = Icons.person_outline;
  static const IconData profileFilled = Icons.person;
  
  static const IconData services = Icons.build_outlined;
  static const IconData servicesFilled = Icons.build;
  
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsFilled = Icons.settings;
  
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsFilled = Icons.notifications;
  
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.sort;
  
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete_outline;
  static const IconData view = Icons.visibility_outlined;
  
  static const IconData camera = Icons.camera_alt_outlined;
  static const IconData photo = Icons.photo_outlined;
  static const IconData signature = Icons.draw_outlined;
  
  static const IconData location = Icons.location_on_outlined;
  static const IconData map = Icons.map_outlined;
  
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData clock = Icons.access_time;
  
  static const IconData phone = Icons.phone_outlined;
  static const IconData email = Icons.email_outlined;
  static const IconData whatsapp = Icons.chat_bubble_outline;
  
  static const IconData download = Icons.download_outlined;
  static const IconData share = Icons.share_outlined;
  static const IconData print = Icons.print_outlined;
  
  static const IconData check = Icons.check_circle_outline;
  static const IconData checkFilled = Icons.check_circle;
  static const IconData error = Icons.error_outline;
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData info = Icons.info_outline;
  
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData chevronLeft = Icons.chevron_left;
  static const IconData arrowBack = Icons.arrow_back;
  static const IconData arrowForward = Icons.arrow_forward;
  
  static const IconData menu = Icons.menu;
  static const IconData more = Icons.more_vert;
  static const IconData close = Icons.close;
  
  static const IconData wifi = Icons.wifi;
  static const IconData wifiOff = Icons.wifi_off;
  static const IconData sync = Icons.sync;
  static const IconData cloud = Icons.cloud_outlined;
  static const IconData cloudDone = Icons.cloud_done_outlined;
  
  static const IconData dollar = Icons.attach_money;
  static const IconData document = Icons.description_outlined;
  static const IconData folder = Icons.folder_outlined;
  
  static const IconData technician = Icons.support_agent;
  static const IconData user = Icons.account_circle_outlined;
  static const IconData users = Icons.group_outlined;
  
  static const IconData cooling = Icons.ac_unit;
  static const IconData heating = Icons.whatshot;
  static const IconData maintenance = Icons.handyman_outlined;
  static const IconData repair = Icons.construction;
}

class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final VoidCallback? onTap;

  const AppIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: size, color: color);

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: iconWidget);
    }

    return iconWidget;
  }
}