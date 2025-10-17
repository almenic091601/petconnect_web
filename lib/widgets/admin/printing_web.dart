import 'dart:async';
import 'dart:html' as html;

Future<void> printHtml(String contentHtml) async {
  // Create a hidden div for the print content
  final element = html.DivElement();
  element.setInnerHtml(contentHtml, validator: html.NodeValidatorBuilder()
    ..allowElement('table')
    ..allowElement('tr')
    ..allowElement('td')
    ..allowElement('th')
    ..allowElement('thead')
    ..allowElement('tbody')
    ..allowElement('div')
    ..allowElement('p')
    ..allowElement('h1')
    ..allowElement('h2')
    ..allowElement('h3')
    ..allowElement('br')
    ..allowElement('hr')
    ..allowElement('span')
    ..allowElement('b')

    
    ..allowElement('i')
    ..allowElement('strong')
    ..allowElement('em'));

  // Add to document temporarily
  html.document.body?.append(element);
  
  try {
    await Future.delayed(const Duration(milliseconds: 100));
    html.window.print();
  } finally {
    element.remove();
  }
}

