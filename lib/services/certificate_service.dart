import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class CertificateService {
  Future<File> generateCertificate({
    required String userName,
    required String activityTitle,
    required DateTime completionDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 10),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'CERTIFICATE OF APPRECIATION',
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'This is to certify that',
                  style: const pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  userName,
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'has successfully completed the volunteer activity',
                  style: const pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  activityTitle,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Completed on ${_formatDate(completionDate)}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 60),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 200,
                          height: 2,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Authorized Signature'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 200,
                          height: 2,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Date'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(
                    'Engage360 - Volunteer Management Platform',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/certificate_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
