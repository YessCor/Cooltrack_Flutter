import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/quote.dart';
import '../models/service_order.dart';
import '../models/user.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: '$', decimalDigits: 2);

  // Business Info Constants
  static const String companyName = 'CoolTrack HVAC Pro';
  static const String companyTaxId = 'NIT: 900.123.456-7';
  static const String companyAddress = 'Calle de la Climatización #123, Bogotá, Colombia';
  static const String companyPhone = '+57 (601) 555-0199';
  static const String companyEmail = 'servicios@cooltrack.pro';
  static const String companyWeb = 'www.cooltrack.pro';

  Future<void> previewQuotePdf(Quote quote, User? client) async {
    final doc = await generateQuotePdf(quote, client);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc,
      name: 'Cotizacion_QT-${quote.quoteNumber}.pdf',
    );
  }

  Future<void> previewOrderPdf(ServiceOrder order, User? client) async {
    final doc = await generateOrderPdf(order, client);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc,
      name: 'Orden_Servicio_${order.orderNumber}.pdf',
    );
  }

  Future<Uint8List> generateQuotePdf(Quote quote, User? client) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildBusinessHeader('COTIZACIÓN COMERCIAL'),
        footer: (context) => _buildBusinessFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildClientAndDocInfo(
            title: 'Cotización No:',
            docNumber: 'QT-${quote.quoteNumber.toString().padLeft(5, '0')}',
            date: quote.createdAt,
            client: client,
            validUntil: quote.validUntil,
          ),
          pw.SizedBox(height: 25),
          _buildItemsTable(quote.items ?? []),
          pw.SizedBox(height: 20),
          _buildTotalsSection(quote),
          pw.SizedBox(height: 30),
          if (quote.notes != null && quote.notes!.isNotEmpty) _buildSectionCard('NOTAS Y CONDICIONES', quote.notes!),
          pw.SizedBox(height: 20),
          _buildPaymentMethods(),
          pw.SizedBox(height: 20),
          _buildWarrantyInfo(),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateOrderPdf(ServiceOrder order, User? client) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildBusinessHeader('REPORTE TÉCNICO DE SERVICIO'),
        footer: (context) => _buildBusinessFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildClientAndDocInfo(
            title: 'Orden de Trabajo:',
            docNumber: '#${order.orderNumber}',
            date: order.createdAt,
            client: client,
          ),
          pw.SizedBox(height: 25),
          _buildServiceSummary(order),
          pw.SizedBox(height: 20),
          if (order.technicianNotes != null && order.technicianNotes!.isNotEmpty)
            _buildSectionCard('OBSERVACIONES DEL TÉCNICO', order.technicianNotes!),
          pw.SizedBox(height: 40),
          _buildProfessionalSignatureSection(),
        ],
      ),
    );

    return pdf.save();
  }

  // --- UI PDF Components ---

  pw.Widget _buildBusinessHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo Area
          pw.Row(
            children: [
              pw.Container(
                width: 45,
                height: 45,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'CT',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text(companyTaxId, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('$companyPhone | $companyEmail', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          // Document Title
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientAndDocInfo({
    required String title,
    required String docNumber,
    required DateTime date,
    User? client,
    DateTime? validUntil,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Client Info
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CLIENTE / FACTURAR A:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 5),
                pw.Text(client?.name ?? 'Cliente General', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (client != null) ...[
                  pw.Text('ID: ${client.id.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Email: ${client.email}', style: const pw.TextStyle(fontSize: 9)),
                  if (client.phone != null) pw.Text('Tel: ${client.phone}', style: const pw.TextStyle(fontSize: 9)),
                  if (client.address != null) pw.Text('Dir: ${client.address}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        // Document Info
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text(docNumber, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 10),
              _kvRow('Fecha Emisión:', _dateFormat.format(date)),
              if (validUntil != null) _kvRow('Válido Hasta:', _dateFormat.format(validUntil), color: PdfColors.red700),
              _kvRow('Moneda:', 'USD / Pesos'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _kvRow(String key, String val, {PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(key, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(val, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<QuoteItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2)
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _th('Descripción de Servicio / Producto'),
            _th('Cant.', align: pw.TextAlign.center),
            _th('Unitario', align: pw.TextAlign.right),
            _th('Subtotal', align: pw.TextAlign.right),
          ],
        ),
        ...items.map((item) => pw.TableRow(
          children: [
            _td(item.description),
            _td(item.quantity.toStringAsFixed(0), align: pw.TextAlign.center),
            _td(_currencyFormat.format(item.unitPrice), align: pw.TextAlign.right),
            _td(_currencyFormat.format(item.total), align: pw.TextAlign.right),
          ],
        )),
      ],
    );
  }

  pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9), textAlign: align),
  );

  pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align),
  );

  pw.Widget _buildTotalsSection(Quote quote) {
    return pw.Row(
      children: [
        pw.Spacer(flex: 2),
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _totalLine('SUBTOTAL:', _currencyFormat.format(quote.subtotal)),
                _totalLine('IVA (16%):', _currencyFormat.format(quote.taxAmount)),
                pw.Divider(color: PdfColors.grey400),
                _totalLine('TOTAL A PAGAR:', _currencyFormat.format(quote.total), isBold: true, fontSize: 13),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _totalLine(String label, String value, {bool isBold = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: isBold ? PdfColors.blue900 : PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _buildServiceSummary(ServiceOrder order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RESUMEN TÉCNICO', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 5),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoDetail('Tipo de Servicio:', order.serviceType),
              _infoDetail('Prioridad:', order.priority.toUpperCase()),
              _infoDetail('Dirección de Atención:', order.address),
              pw.SizedBox(height: 10),
              pw.Text('DESCRIPCIÓN DEL REQUERIMIENTO:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 3),
              pw.Text(order.description, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _infoDetail(String label, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 5),
          pw.Text(val, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildSectionCard(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 5),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Text(content, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
        ),
      ],
    );
  }

  pw.Widget _buildProfessionalSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _sigBox('FIRMA DEL CLIENTE / RECIBIDO'),
        _sigBox('FIRMA TÉCNICO ENCARGADO'),
      ],
    );
  }

  pw.Widget _sigBox(String label) {
    return pw.Column(
      children: [
        pw.Container(width: 180, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.Text('Confirmación de Conformidad', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
      ],
    );
  }

  pw.Widget _buildPaymentMethods() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('MÉTODOS DE PAGO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 5),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _paymentItem('Transferencia Bancaria', 'Banco CoolTrack\nCuenta Corriente: 123-45678-90\nNIT: 900.123.456-7'),
              _paymentItem('Pagos Digitales', 'Aceptamos todas las tarjetas\nLink de pago: pagos.cooltrack.pro\nQR disponible en oficina'),
              _paymentItem('Otros Medios', 'Efectivo en oficina\nConvenio de recaudo: #9988\nReferencia: No. de Cotización'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _paymentItem(String title, String details) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
          pw.SizedBox(height: 2),
          pw.Text(details, style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _buildWarrantyInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        color: PdfColors.blue50,
      ),
      child: pw.Text(
        'GARANTÍA: Todos nuestros servicios cuentan con una garantía de 30 días en mano de obra. '
        'Esta cotización es de carácter demostrativo para el sistema CoolTrack Pro.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900, fontStyle: pw.FontStyle.italic),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildBusinessFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generado por CoolTrack HVAC Pro - Soluciones Digitales', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
              pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
              pw.Text(companyWeb, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ],
          ),
        ],
      ),
    );
  }
}
