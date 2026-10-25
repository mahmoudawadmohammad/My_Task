import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/task_model.dart';

class PdfService {
  // ============ توليد التقرير ============
  Future<void> generateReport({
    required List<TaskModel> tasks,
    required String userName,
    required String reportTitle,
    required String generatedOnLabel,
    required String totalLabel,
    required String completedLabel,
    required String pendingLabel,
    required bool isArabic,
  }) async {
    // تحميل الخطوط من Google Fonts (تلقائياً عبر PdfGoogleFonts)
    final regularFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    final pdf = pw.Document(
      theme: theme,
      title: reportTitle,
    );

    // حساب الإحصائيات
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final pending = total - completed;

    // تنسيق التاريخ
    final dateFormat = isArabic
        ? DateFormat('d MMMM yyyy', 'ar')
        : DateFormat('d MMMM yyyy', 'en');
    final timeFormat = DateFormat('hh:mm a');

    final now = DateTime.now();
    final generatedOn = '${dateFormat.format(now)} - ${timeFormat.format(now)}';

    // الألوان
    final primaryColor = PdfColor.fromHex('#5B9BD5');
    final darkText = PdfColor.fromHex('#1A1A1A');
    final lightText = PdfColor.fromHex('#666666');
    final greenColor = PdfColor.fromHex('#4CAF50');
    final orangeColor = PdfColor.fromHex('#FF9800');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return [
            // ============ الترويسة ============
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        reportTitle,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$generatedOnLabel: $generatedOn',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(30),
                        ),
                        child: pw.Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        userName,
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ============ الإحصائيات ============
            pw.Row(
              children: [
                _statCard(totalLabel, total.toString(), primaryColor),
                pw.SizedBox(width: 10),
                _statCard(completedLabel, completed.toString(), greenColor),
                pw.SizedBox(width: 10),
                _statCard(pendingLabel, pending.toString(), orangeColor),
              ],
            ),

            pw.SizedBox(height: 25),

            // ============ جدول المهام ============
            if (tasks.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Text(
                    isArabic ? 'لا توجد مهام' : 'No tasks',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: lightText,
                    ),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: isArabic
                    ? ['العنوان', 'التاريخ', 'الوقت', 'التصنيف', 'الحالة']
                    : ['Title', 'Date', 'Time', 'Priority', 'Status'],
                data: tasks.map((task) {
                  return [
                    task.title,
                    dateFormat.format(task.date),
                    '${task.startTime} - ${task.endTime}',
                    _getPriorityLabel(task.priority, isArabic),
                    task.isCompleted
                        ? (isArabic ? 'مكتملة' : 'Completed')
                        : (isArabic ? 'قيد الانتظار' : 'Pending'),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 11,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 10,
                  color: darkText,
                ),
                cellAlignment: isArabic
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                headerAlignment: isArabic
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2.5),
                  3: const pw.FlexColumnWidth(2.5),
                  4: const pw.FlexColumnWidth(2),
                },
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#E0E0E0'),
                  width: 0.5,
                ),
                oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F7FB'),
                ),
              ),

            pw.SizedBox(height: 30),

            // ============ التذييل ============
            pw.Divider(color: PdfColor.fromHex('#E0E0E0')),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isArabic
                      ? 'تم الإنشاء بواسطة تطبيق مهامي'
                      : 'Generated by My Task App',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: lightText,
                  ),
                ),
                pw.Text(
                  '© ${now.year}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: lightText,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // حفظ وعرض
    final Uint8List pdfBytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'task_report_${now.millisecondsSinceEpoch}.pdf',
    );
  }

  // ============ كارت إحصائي ============
  pw.Widget _statCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _getPriorityLabel(TaskPriority priority, bool isArabic) {
    if (isArabic) {
      switch (priority) {
        case TaskPriority.notImportant:
          return 'غير مهمة';
        case TaskPriority.normal:
          return 'عادية';
        case TaskPriority.important:
          return 'مهمة';
        case TaskPriority.veryImportant:
          return 'مهمة جداً';
      }
    } else {
      switch (priority) {
        case TaskPriority.notImportant:
          return 'Not Important';
        case TaskPriority.normal:
          return 'Normal';
        case TaskPriority.important:
          return 'Important';
        case TaskPriority.veryImportant:
          return 'Very Important';
      }
    }
  }
}