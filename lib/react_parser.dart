library react_parser;

import 'package:xml/xml.dart'; 

String parse(String html){
  XmlElement parsedHtml = XML.parse(html);
  return parseNode(parsedHtml, 0);
}

String parseNode(dynamic node, num indent){
  var indentBase = "  ";
  StringBuffer indentStringBuffer = new StringBuffer("");
  for(var i = 0; i < indent; ++i){
    indentStringBuffer.write(indentBase); 
  }
  var indentString = indentStringBuffer.toString();
  
  if(node is XmlElement){
    var props = [];
    node.attributes.forEach((key, value) => props.add('${_key(key)}: ${_value(value)}'));
    
    var children = [];
    node.children.forEach((child) => children.add(parseNode(child, indent + 1)));
    StringBuffer buildResult = new StringBuffer("$indentString${node.name}({${props.join(', ')}}, [");
    if (children.length > 0){
      buildResult.write("\n${children.join(',\n')}\n$indentString]");
    } else {
      buildResult.write("null");
    }
    buildResult.write(")");
    return buildResult.toString();
  } else if (node is XmlText){
    return "$indentString\"${node.text}\"";
  }
//  for
}

String _key(String key){
  if(key == "class"){
    return '"className"';
  }
  if(key == "for"){
    return '"htmFor"';
  }
  return '"$key"';
}

String _value(String value){
  if (value.contains(new RegExp(r'^\{.*\}$'))) {
    return value.replaceAll(new RegExp(r'(^\{)|(\}$)'), "");
  }
  return '"$value"';
}

