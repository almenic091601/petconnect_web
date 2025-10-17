// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

/// Web implementation for printing HTML content
class WebPrinting {
  /// Displays and prints the provided HTML content
  static Future<void> printHtml(String contentHtml) async {
    final printContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <title>Tanod Reports</title>
          <style>
            /* Default styles */
            body { 
              font-family: Arial, sans-serif;
              margin: 0;
              padding: 16px;
            }
            
            /* Print-specific styles */
            @media print {
              body { 
                margin: 0;
                padding: 16px;
              }
              table { 
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
              }
              th, td { 
                padding: 8px;
                text-align: left;
                border: 1px solid #ddd;
              }
              th { 
                background-color: #f5f5f5 !important;
                -webkit-print-color-adjust: exact;
              }
              .timestamp { 
                color: #666;
                font-size: 0.9em;
              }
              /* Hide any non-essential elements */
              button, .no-print { 
                display: none !important;
              }
            }
          </style>
        </head>
        <body>
          <div class="report-content">
            $contentHtml
          </div>
          <script>
            window.onload = function() {
              window.print();
            }
          </script>
        </body>
      </html>
    ''';

    try {
      // Create a blob with the HTML content
      final blob = html.Blob([printContent], 'text/html');
      final url = html.Url.createObjectUrl(blob);

      // Open in a new window
      html.window.open(url, 'PrintWindow');
      
      // Clean up after a delay
      await Future.delayed(const Duration(seconds: 1));
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Failed to open print window: $e');
    }
  }
}