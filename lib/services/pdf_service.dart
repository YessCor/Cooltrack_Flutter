import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/quote.dart';
import '../../models/service_order.dart';
import '../../models/client.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  Future<Uint8List> generateQuotePdf(Quote quote, Client? client) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('COTIZACIÓN'),
          pw.SizedBox(height: 20),
          _buildQuoteInfo(quote),
          pw.SizedBox(height: 20),
          if (client != null) ...[
            _buildClientInfo(client),
            pw.SizedBox(height: 20),
          ],
          _buildItemsTable(quote.items),
          pw.SizedBox(height: 20),
          _buildTotals(quote),
          pw.SizedBox(height: 30),
          if (quote.notes != null) _buildNotes(quote.notes!),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateServiceOrderPdf(ServiceOrder order, Client? client) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('ORDEN DE SERVICIO'),
          pw.SizedBox(height: 20),
          _buildOrderInfo(order),
          pw.SizedBox(height: 20),
          if (client != null) ...[
            _buildClientInfo(client),
            pw.SizedBox(height: 20),
          ],
          _buildServiceDetails(order),
          if (order.technicianNotes != null) ...[
            pw.SizedBox(height: 20),
            _buildTechnicianNotes(order.technicianNotes!),
          ],
          pw.SizedBox(height: 40),
          _buildSignatureSection(),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
      child: pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        ),
      ),
    );
  }

  pw.Widget _buildQuoteInfo(Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Información de Cotización', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _infoRow('Número', quote.quoteNumber),
          _infoRow('Fecha', _dateFormat.format(quote.createdAt)),
          if (quote.validUntil != null) _infoRow('Válida hasta', _dateFormat.format(quote.validUntil!)),
          _infoRow('Estado', quote.statusLabel),
        ],
      ),
    );
  }

  pw.Widget _buildOrderInfo(ServiceOrder order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Información de Orden', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _infoRow('Número', order.orderNumber),
          _infoRow('Fecha', _dateFormat.format(order.createdAt)),
          _infoRow('Estado', order.statusLabel),
          _infoRow('Tipo de Servicio', order.serviceType),
          _infoRow('Prioridad', order.priority),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label), pw.Text(value)],
      ),
    );
  }

  pw.Widget _buildClientInfo(Client client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Datos del Cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _infoRow('Nombre', client.name),
          if (client.email != null) _infoRow('Email', client.email!),
          if (client.phone != null) _infoRow('Teléfono', client.phone!),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<QuoteItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(1.5)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [_tableHeader('Descripción'), _tableHeader('Cant.'), _tableHeader('Precio'), _tableHeader('Total')],
        ),
        ...items.map((item) => pw.TableRow(
          children: [
            _tableCell(item.description),
            _tableCell(item.quantity.toString()),
            _tableCell(_currencyFormat.format(item.unitPrice)),
            _tableCell(_currencyFormat.format(item.unitPrice * item.quantity)),
          ],
        )),
      ],
    );
  }

  pw.Widget _tableHeader(String text) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
  pw.Widget _tableCell(String text) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text));

  pw.Widget _buildTotals(Quote quote) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _infoRow('Subtotal', _currencyFormat.format(quote.subtotal)),
          pw.SizedBox(height: 5),
          _infoRow('IVA (16%)', _currencyFormat.format(quote.tax)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_currencyFormat.format(quote.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildServiceDetails(ServiceOrder order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Detalles del Servicio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Descripción: ${order.description}'),
        if (order.address.isNotEmpty) pw.Text('Dirección: ${order.address}'),
      ]),
    );
  }

  pw.Widget _buildTechnicianNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Notas del Técnico', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text(notes),
      ]),
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), color: PdfColors.grey100),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Notas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text(notes),
      ]),
    );
  }

  pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(children: [pw.Container(width: 150, height: 60, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)))), pw.SizedBox(height: 5), pw.Text('Firma del Cliente')]),
        pw.Column(children: [pw.Container(width: 150, height: 60, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)))), pw.SizedBox(height: 5), pw.Text('Firma del Técnico')]),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(alignment: pw.Alignment.center, child: pw.Text('Generado por CoolTrack - Sistema de Gestión de Servicios HVAC', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)));
  }
}