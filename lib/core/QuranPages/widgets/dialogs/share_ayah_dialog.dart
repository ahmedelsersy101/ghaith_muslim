import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:easy_container/easy_container.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translation_info.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:ghaith/core/QuranPages/helpers/remove_html_tags.dart';
import 'package:ghaith/core/QuranPages/views/screenshot_preview.dart';

class ShareAyahDialog extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final int index;
  final dynamic jsonData;
  final List<TranslationData> translationDataList;

  const ShareAyahDialog({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.index,
    required this.jsonData,
    required this.translationDataList,
  });

  @override
  State<ShareAyahDialog> createState() => _ShareAyahDialogState();
}

class _ShareAyahDialogState extends State<ShareAyahDialog> {
  late int firstVerse;
  late int lastVerse;

  @override
  void initState() {
    super.initState();
    firstVerse = widget.verseNumber;
    lastVerse = widget.verseNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: softOffWhites[getValue("quranPageolorsIndex")],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                "share".tr(),
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  fontWeight: FontWeight.w700,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'fromayah'.tr(),
                style: TextStyle(
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(width: 10.0),
              DropdownButton<int>(
                dropdownColor: softOffWhites[getValue("quranPageolorsIndex")],
                value: firstVerse,
                onChanged: (newValue) {
                  if (newValue! > lastVerse) {
                    setState(() {
                      lastVerse = newValue;
                    });
                  }
                  setState(() {
                    firstVerse = newValue;
                  });
                },
                items: List.generate(
                  quran.getVerseCount(widget.surahNumber),
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20.0),
              Text(
                'toayah'.tr(),
                style: TextStyle(
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(width: 10.0),
              DropdownButton<int>(
                dropdownColor: softOffWhites[getValue("quranPageolorsIndex")],
                value: lastVerse,
                onChanged: (newValue) {
                  if (newValue! > firstVerse) {
                    setState(() {
                      lastVerse = newValue;
                    });
                  }
                },
                items: List.generate(
                  quran.getVerseCount(widget.surahNumber),
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          RadioListTile(
            activeColor: highlightColors[getValue("quranPageolorsIndex")],
            fillColor: WidgetStatePropertyAll(darkWarmBrowns[getValue("quranPageolorsIndex")]),
            title: Text(
              'asimage'.tr(),
              style: TextStyle(
                color: darkWarmBrowns[getValue("quranPageolorsIndex")],
              ),
            ),
            value: 0,
            groupValue: getValue("selectedShareTypeIndex"),
            onChanged: (value) {
              updateValue("selectedShareTypeIndex", value);
              setState(() {});
            },
          ),
          RadioListTile(
            activeColor: highlightColors[getValue("quranPageolorsIndex")],
            fillColor: WidgetStatePropertyAll(darkWarmBrowns[getValue("quranPageolorsIndex")]),
            title: Text(
              'astext'.tr(),
              style: TextStyle(
                color: darkWarmBrowns[getValue("quranPageolorsIndex")],
              ),
            ),
            value: 1,
            groupValue: getValue("selectedShareTypeIndex"),
            onChanged: (value) {
              updateValue("selectedShareTypeIndex", value);
              setState(() {});
            },
          ),
          if (getValue("selectedShareTypeIndex") == 1)
            Row(
              children: [
                Checkbox(
                  fillColor:
                      WidgetStatePropertyAll(darkWarmBrowns[getValue("quranPageolorsIndex")]),
                  checkColor: softOffWhites[getValue("quranPageolorsIndex")],
                  value: getValue("textWithoutDiacritics"),
                  onChanged: (newValue) {
                    updateValue("textWithoutDiacritics", newValue);
                    setState(() {});
                  },
                ),
                Text(
                  'withoutdiacritics'.tr(),
                  style: TextStyle(
                    color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Checkbox(
                fillColor: WidgetStatePropertyAll(darkWarmBrowns[getValue("quranPageolorsIndex")]),
                checkColor: softOffWhites[getValue("quranPageolorsIndex")],
                value: getValue("addAppSlogan"),
                onChanged: (newValue) {
                  updateValue("addAppSlogan", newValue);
                  setState(() {});
                },
              ),
              Text(
                'addappname'.tr(),
                style: TextStyle(
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                fillColor: WidgetStatePropertyAll(darkWarmBrowns[getValue("quranPageolorsIndex")]),
                checkColor: softOffWhites[getValue("quranPageolorsIndex")],
                value: getValue("addTafseer"),
                onChanged: (newValue) {
                  updateValue("addTafseer", newValue);
                  setState(() {});
                },
              ),
              Text(
                'addtafseer'.tr(),
                style: TextStyle(
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          if (getValue("addTafseer") == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 20),
                Directionality(
                  textDirection: m.TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        // Translation selection logic could be here or passed
                        // For simplicity, reusing the logic or extracting it further
                        // implies more complexity. We'll simplify this part
                        // by using a specialized dropdown or keeping it minimal
                        // or replicating the bottom sheet strictly for translation selection
                        // inside this dialog is tricky.
                        // For now, I'll simplify it to use the current translation
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * .7,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.translationDataList[getValue("addTafseerValue") ?? 0]
                                    .typeTextInRelatedLanguage,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontFamily:
                                        widget.translationDataList[getValue("addTafseerValue") ?? 0]
                                                    .typeInNativeLanguage ==
                                                "العربية"
                                            ? "cairo"
                                            : "roboto"),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 24,
                                color: secondaryColors[getValue("quranPageolorsIndex")],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (getValue("selectedShareTypeIndex") == 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: EasyContainer(
                  onTap: () async {
                    if (getValue("selectedShareTypeIndex") == 1) {
                      List verses = [];
                      for (int i = firstVerse; i <= lastVerse; i++) {
                        verses.add(quran.getVerse(widget.surahNumber, i, verseEndSymbol: true));
                      }
                      if (getValue("textWithoutDiacritics")) {
                        if (getValue("addTafseer")) {
                          String tafseer = "";
                          for (int verseNumber = firstVerse;
                              verseNumber <= lastVerse;
                              verseNumber++) {
                            String verseTafseer = quran.getVerseTranslation(
                              widget.surahNumber,
                              verseNumber,
                              getValue("addTafseerValue"),
                            );
                            tafseer = "$tafseer $verseTafseer";
                          }
                          Share.share(
                            "{${quran.removeDiacritics(verses.join(''))}} [${quran.getSurahNameArabic(widget.surahNumber)}: $firstVerse : $lastVerse]\n\n${removeHtmlTags(tafseer)}\n\n${getValue("addAppSlogan") ? "تطبيق غيث المسلم - faithful companion" : ""}",
                          );
                        } else {
                          Share.share(
                            "{${quran.removeDiacritics(verses.join(''))}} [${quran.getSurahNameArabic(widget.surahNumber)}: $firstVerse : $lastVerse]${getValue("addAppSlogan") ? "تطبيق غيث المسلم - faithful companion" : ""}",
                          );
                        }
                      } else {
                        if (getValue("addTafseer")) {
                          String tafseer = "";
                          for (int verseNumber = firstVerse;
                              verseNumber <= lastVerse;
                              verseNumber++) {
                            String cTafseer = quran.getVerseTranslation(
                                widget.surahNumber, verseNumber, getValue("addTafseerValue"));
                            tafseer = "$tafseer $cTafseer ";
                          }
                          Share.share(
                            "{${verses.join('')}} [${quran.getSurahNameArabic(widget.surahNumber)}: $firstVerse : $lastVerse]\n\n${getValue("addTafseerValue")}:\n${removeHtmlTags(tafseer)}\n\n${getValue("addAppSlogan") ? "تطبيق غيث المسلم" : ""}",
                          );
                        } else {
                          Share.share(
                            "{${verses.join('')}} [${quran.getSurahNameArabic(widget.surahNumber)}: $firstVerse : $lastVerse]${getValue("addAppSlogan") ? "تطبيق غيث المسلم" : ""}",
                          );
                        }
                      }
                    }
                  },
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  child: Text(
                    "astext".tr(),
                    style: TextStyle(color: softOffWhites[getValue("quranPageolorsIndex")]),
                  )),
            ),
          if (getValue("selectedShareTypeIndex") == 0)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: EasyContainer(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (builder) => ScreenShotPreviewPage(
                                index: widget.index,
                                surahNumber: widget.surahNumber,
                                jsonData: widget.jsonData,
                                firstVerse: firstVerse,
                                lastVerse: lastVerse)));
                  },
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  child: Text(
                    "preview".tr(),
                    style: TextStyle(color: softOffWhites[getValue("quranPageolorsIndex")]),
                  )),
            )
        ],
      ),
    );
  }
}
