import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Simple SVG path parser for Christmas cutouts
class ChristmasSVGParser {
  /// Parse SVG path data string into a Flutter Path object
  static Path parseSVGPath(String pathData, {Size? viewBox}) {
    final path = Path();
    final commands = _tokenizePath(pathData);
    
    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;
    
    for (int i = 0; i < commands.length; i++) {
      final command = commands[i];
      if (command.isEmpty) continue;
      
      final cmd = command[0];
      final values = command.length > 1 
          ? command.substring(1).trim().split(RegExp(r'[\s,]+'))
              .where((v) => v.isNotEmpty)
              .map((v) => double.tryParse(v) ?? 0.0)
              .toList()
          : <double>[];
      
      final isAbsolute = cmd == cmd.toUpperCase();
      final cmdUpper = cmd.toUpperCase();
      
      switch (cmdUpper) {
        case 'M': // Move to
          if (values.length >= 2) {
            currentX = isAbsolute ? values[0] : currentX + values[0];
            currentY = isAbsolute ? values[1] : currentY + values[1];
            startX = currentX;
            startY = currentY;
            path.moveTo(currentX, currentY);
            
            // Handle multiple coordinates after M (implicit L commands)
            for (int j = 2; j < values.length; j += 2) {
              if (j + 1 < values.length) {
                currentX = isAbsolute ? values[j] : currentX + values[j];
                currentY = isAbsolute ? values[j + 1] : currentY + values[j + 1];
                path.lineTo(currentX, currentY);
              }
            }
          }
          break;
        case 'L': // Line to
          for (int j = 0; j < values.length; j += 2) {
            if (j + 1 < values.length) {
              currentX = isAbsolute ? values[j] : currentX + values[j];
              currentY = isAbsolute ? values[j + 1] : currentY + values[j + 1];
              path.lineTo(currentX, currentY);
            }
          }
          break;
        case 'C': // Cubic Bezier
          for (int j = 0; j < values.length; j += 6) {
            if (j + 5 < values.length) {
              final x1 = isAbsolute ? values[j] : currentX + values[j];
              final y1 = isAbsolute ? values[j + 1] : currentY + values[j + 1];
              final x2 = isAbsolute ? values[j + 2] : currentX + values[j + 2];
              final y2 = isAbsolute ? values[j + 3] : currentY + values[j + 3];
              currentX = isAbsolute ? values[j + 4] : currentX + values[j + 4];
              currentY = isAbsolute ? values[j + 5] : currentY + values[j + 5];
              path.cubicTo(x1, y1, x2, y2, currentX, currentY);
            }
          }
          break;
        case 'Z': // Close path
        case 'z':
          path.close();
          currentX = startX;
          currentY = startY;
          break;
        case 'H': // Horizontal line
          for (int j = 0; j < values.length; j++) {
            currentX = isAbsolute ? values[j] : currentX + values[j];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'V': // Vertical line
          for (int j = 0; j < values.length; j++) {
            currentY = isAbsolute ? values[j] : currentY + values[j];
            path.lineTo(currentX, currentY);
          }
          break;
      }
    }
    
    return path;
  }
  
  /// Tokenize SVG path string into commands
  static List<String> _tokenizePath(String pathData) {
    final commands = <String>[];
    String currentCommand = '';
    String currentValues = '';
    
    for (int i = 0; i < pathData.length; i++) {
      final char = pathData[i];
      final upperChar = char.toUpperCase();
      
      if (upperChar == 'M' || upperChar == 'L' || upperChar == 'C' || 
          upperChar == 'Z' || upperChar == 'H' || upperChar == 'V') {
        // Save previous command if exists
        if (currentCommand.isNotEmpty) {
          commands.add(currentCommand + currentValues);
        }
        // Start new command
        currentCommand = char;
        currentValues = '';
      } else {
        // Accumulate values
        currentValues += char;
      }
    }
    
    // Add last command
    if (currentCommand.isNotEmpty) {
      commands.add(currentCommand + currentValues);
    }
    
    return commands;
  }
  
  /// Transform path to fit within given size
  static Path transformPath(Path originalPath, Size targetSize, Size originalViewBox) {
    // Get the actual bounds of the path
    final bounds = originalPath.getBounds();
    
    // Calculate the center of the path bounds
    final pathCenterX = bounds.left + bounds.width / 2;
    final pathCenterY = bounds.top + bounds.height / 2;
    
    // Calculate scale to fit within target size (use path bounds, not viewBox)
    final scaleX = targetSize.width / bounds.width;
    final scaleY = targetSize.height / bounds.height;
    final scale = math.min(scaleX, scaleY) * 0.9; // 0.9 to add some padding
    
    // Calculate the center of the target size
    final targetCenterX = targetSize.width / 2;
    final targetCenterY = targetSize.height / 2;
    
    // Create transformation matrix:
    // Operations are applied in reverse order when transforming points
    // 1. Translate to center of target (in scaled coordinates)
    // 2. Scale around origin
    // 3. Translate path center to origin
    final matrix = Matrix4.identity()
      ..translate(targetCenterX, targetCenterY)
      ..scale(scale, scale)
      ..translate(-pathCenterX, -pathCenterY);
    
    return originalPath.transform(matrix.storage);
  }
}

