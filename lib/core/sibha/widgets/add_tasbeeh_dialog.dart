import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/main.dart';

class AddTasbeehDialog extends StatefulWidget {
  Function function;

  AddTasbeehDialog({super.key, required this.function});

  @override
  State<AddTasbeehDialog> createState() => _AddTasbeehDialogState();
}

class _AddTasbeehDialogState extends State<AddTasbeehDialog> {
  TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDarkModeNotifier.value ? darkPrimaryColor.withOpacity(0.6) : backgroundColor,
      borderRadius: BorderRadius.circular(18.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 50.h,
          ),
          Text(
            "Add To Sibha".tr(),
            style: TextStyle(color: Colors.black, fontSize: 22.sp),
          ),
          SizedBox(
            height: 30.h,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: textEditingController,
              onChanged: (ca) {},
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "Enter Custom Zikr".tr(),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(width: 1, color: Colors.black)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(width: 1, color: Colors.black),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30.h,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                  onPressed: () {
                    if (textEditingController.text.isEmpty) {
                    } else {
                      widget.function(textEditingController.text);
                    }
                  },
                  child: Text(
                    "Add".tr(),
                    style: TextStyle(color: isDarkModeNotifier.value ? Colors.white : Colors.black),
                  )),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("cancel".tr(),
                      style: TextStyle(
                          color: isDarkModeNotifier.value ? Colors.white : Colors.black))),
            ],
          ),
          SizedBox(
            height: 30.h,
          ),
        ],
      ),
    );
  }
}
