
import 'package:flutter/material.dart';

enum CustomerLayoutType {
  list,
  grid;

  IconData get icon {
    switch (this) {
      case CustomerLayoutType.list:
        return Icons.view_list_outlined;
      case CustomerLayoutType.grid:
        return Icons.grid_view_outlined;
    }
  }
}